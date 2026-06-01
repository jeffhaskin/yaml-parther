;;;; reader.lisp --- The whole input side: lex + grammar + tree-building.
;;;;
;;;; One deep module. YAML 1.2 is context-sensitive -- indentation, the `?`/`:`
;;;; mapping ambiguity, flow-vs-block context, and key/value detection all need
;;;; grammar context to scan correctly -- so scanning, parsing, anchor/alias
;;;; composition, and native-value construction are FUSED into one recursive
;;;; descent over a single SOURCE cursor. The hash-tables and vectors are built
;;;; on the way back up the recursion; a separate token/event/node-graph
;;;; intermediate would only leak that context across module walls.
;;;; See docs/adr/0002 and docs/adr/0004.
;;;;
;;;; Representation: mappings -> hash-tables (TEST #'EQUAL); sequences -> vectors.

(in-package #:yaml-parther)

;;; ---------------------------------------------------------------------------
;;; Single-quoted scalar reading
;;; ---------------------------------------------------------------------------

(defun read-single-quoted-scalar (source)
  "Read a single-quoted scalar from SOURCE. Opening quote must be current char.
Single-quoted strings only escape '' as a literal '."
  (unless (eql (source-peek source) #\')
    (error 'yaml-scanner-error :message "Expected opening single quote"))
  (source-advance source) ; consume opening '
  (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop
      (let ((char (source-peek source)))
        (cond
          ((null char)
           (error 'yaml-scanner-error :message "Unterminated single-quoted scalar"))
          ((char= char #\')
           (source-advance source)
           (if (eql (source-peek source) #\')
               (progn
                 (vector-push-extend #\' chars)
                 (source-advance source))
               (return (coerce chars 'string))))
          (t
           (vector-push-extend char chars)
           (source-advance source)))))))

;;; ---------------------------------------------------------------------------
;;; Double-quoted scalar reading
;;; ---------------------------------------------------------------------------

(defun parse-double-quote-escape (source)
  "Parse an escape sequence after backslash in a double-quoted string.
Returns the character to insert."
  (let ((char (source-advance source)))
    (case char
      (#\n #\Newline)
      (#\t #\Tab)
      (#\r #\Return)
      (#\\ #\\)
      (#\" #\")
      (#\/ #\/)
      (#\b #\Backspace)
      (#\f (code-char 12)) ; form feed
      (#\0 #\Nul)
      (#\a (code-char 7))  ; bell
      (#\v (code-char 11)) ; vertical tab
      (#\e (code-char 27)) ; escape
      (#\Space #\Space)
      (#\_ #\No-Break_Space)
      (#\N (code-char #x85)) ; next line
      (#\L (code-char #x2028)) ; line separator
      (#\P (code-char #x2029)) ; paragraph separator
      (#\x ; 2-digit hex
       (let ((hex (make-string 2)))
         (setf (char hex 0) (source-advance source))
         (setf (char hex 1) (source-advance source))
         (code-char (parse-integer hex :radix 16))))
      (#\u ; 4-digit unicode
       (let ((hex (make-string 4)))
         (dotimes (i 4) (setf (char hex i) (source-advance source)))
         (code-char (parse-integer hex :radix 16))))
      (#\U ; 8-digit unicode
       (let ((hex (make-string 8)))
         (dotimes (i 8) (setf (char hex i) (source-advance source)))
         (code-char (parse-integer hex :radix 16))))
      (otherwise
       (error 'yaml-scanner-error
              :message (format nil "Invalid escape sequence: \\~C" char))))))

(defun read-double-quoted-scalar (source)
  "Read a double-quoted scalar from SOURCE. Opening quote must be current char.
Processes escape sequences like \\n, \\t, \\\\, \\\", \\xNN, \\uNNNN, \\UNNNNNNNN."
  (unless (eql (source-peek source) #\")
    (error 'yaml-scanner-error :message "Expected opening double quote"))
  (source-advance source) ; consume opening "
  (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop
      (let ((char (source-peek source)))
        (cond
          ((null char)
           (error 'yaml-scanner-error :message "Unterminated double-quoted scalar"))
          ((char= char #\")
           (source-advance source)
           (return (coerce chars 'string)))
          ((char= char #\\)
           (source-advance source) ; consume backslash
           (vector-push-extend (parse-double-quote-escape source) chars))
          (t
           (vector-push-extend char chars)
           (source-advance source)))))))

;;; ---------------------------------------------------------------------------
;;; Plain scalar reading
;;; ---------------------------------------------------------------------------

(defun read-plain-scalar (source)
  "Read a plain (unquoted) scalar from SOURCE.
Collects characters until end of content (whitespace, newline, EOF, or indicator)."
  (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop for char = (source-peek source)
          while (and char
                     (not (whitespace-p char))
                     (not (line-break-p char))
                     (not (find char ":#,[]{}"))
                     (not (and (char= char #\-) (source-at-line-start-p source))))
          do (vector-push-extend char chars)
             (source-advance source))
    (resolve-scalar (coerce chars 'string))))

;;; ---------------------------------------------------------------------------
;;; Block sequence reading
;;; ---------------------------------------------------------------------------

(defun read-block-sequence (source)
  "Read a block sequence from SOURCE. Expects to start at a '- ' indicator.
Returns a vector of items."
  (let ((items (make-array 0 :adjustable t :fill-pointer 0))
        (seq-indent (source-column source)))
    (loop
      (source-skip-blanks source)
      (unless (and (eql (source-peek source) #\-)
                   (or (whitespace-p (source-peek source 1))
                       (line-break-p (source-peek source 1))
                       (null (source-peek source 1))))
        (return))
      (source-advance source)
      (source-skip-blanks source)
      (let ((item (if (or (source-eof-p source)
                          (line-break-p (source-peek source)))
                      'null
                      (read-plain-scalar source))))
        (vector-push-extend item items))
      (source-skip-to-eol source)
      (source-consume-line-break source)
      (source-skip-blank-lines source)
      (let ((new-indent (source-count-indent source)))
        (when (< new-indent seq-indent)
          (return))
        (source-skip-indent source)))
    (coerce items 'vector)))

;;; ---------------------------------------------------------------------------
;;; Block mapping reading
;;; ---------------------------------------------------------------------------

(defun read-mapping-key (source)
  "Read a plain scalar key until colon, resolving via core schema."
  (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop for char = (source-peek source)
          while (and char
                     (not (char= char #\:))
                     (not (line-break-p char)))
          do (vector-push-extend char chars)
             (source-advance source))
    (resolve-scalar (string-right-trim '(#\Space #\Tab) (coerce chars 'string)))))

(defun read-block-mapping (source)
  "Read a block mapping from SOURCE. Returns a hash-table (test EQUAL)."
  (let ((table (make-hash-table :test #'equal))
        (map-indent (source-column source)))
    (loop
      (source-skip-blanks source)
      (when (source-eof-p source)
        (return))
      (let ((key (read-mapping-key source)))
        (when (and (stringp key) (string= key ""))
          (return))
        (unless (eql (source-peek source) #\:)
          (return))
        (source-advance source)
        (source-skip-blanks source)
        (let ((value (if (or (source-eof-p source)
                             (line-break-p (source-peek source)))
                         'null
                         (read-plain-scalar source))))
          (setf (gethash key table) value))
        (source-skip-to-eol source)
        (source-consume-line-break source)
        (source-skip-blank-lines source)
        (when (source-eof-p source)
          (return))
        (let ((new-indent (source-count-indent source)))
          (when (< new-indent map-indent)
            (return))
          (when (> new-indent map-indent)
            (return))
          (source-skip-indent source))))
    table))

;;; ---------------------------------------------------------------------------
;;; Document reading
;;; ---------------------------------------------------------------------------

(defun skip-document-preamble (source)
  "Skip whitespace, blank lines, and comments before document content.
Returns T if content follows, NIL if at EOF."
  (loop
    (source-skip-whitespace-and-comments source)
    (when (source-eof-p source)
      (return nil))
    (when (or (source-match-document-start source)
              (source-match-document-end source))
      (source-skip-blanks source)
      (source-skip-comment source)
      (source-consume-line-break source))
    (unless (or (source-eof-p source)
                (line-break-p (source-peek source)))
      (return t))))

(defun looks-like-mapping-key-p (source)
  "Check if current position looks like a mapping key (has ': ' on this line)."
  (loop for i from 0
        for char = (source-peek source i)
        while (and char (not (line-break-p char)))
        when (and (char= char #\:)
                  (let ((next (source-peek source (1+ i))))
                    (or (null next)
                        (whitespace-p next)
                        (line-break-p next))))
          return t
        finally (return nil)))

(defun read-document-content (source)
  "Read the content of a document. Dispatches based on first character."
  (source-skip-blanks source)
  (let ((char (source-peek source)))
    (cond
      ((null char) 'null)
      ((line-break-p char) 'null)
      ((eql char #\-)
       (if (and (eql (source-peek source 1) #\-)
                (eql (source-peek source 2) #\-)
                (let ((c (source-peek source 3)))
                  (or (null c) (whitespace-p c) (line-break-p c))))
           'null
           (if (or (whitespace-p (source-peek source 1))
                   (line-break-p (source-peek source 1))
                   (null (source-peek source 1)))
               (read-block-sequence source)
               (if (looks-like-mapping-key-p source)
                   (read-block-mapping source)
                   (read-plain-scalar source)))))
      ((looks-like-mapping-key-p source)
       (read-block-mapping source))
      (t (read-plain-scalar source)))))

(defun read-document (source)
  "Read exactly one YAML document from SOURCE, returning its native Lisp value."
  (source-skip-whitespace-and-comments source)
  (when (source-eof-p source)
    (return-from read-document 'null))
  (source-match-document-start source)
  (source-skip-blanks source)
  (source-skip-comment source)
  (source-consume-line-break source)
  (source-skip-whitespace-and-comments source)
  (let ((content (read-document-content source)))
    (source-skip-to-eol source)
    (source-consume-line-break source)
    (source-skip-whitespace-and-comments source)
    (source-match-document-end source)
    content))

(defun read-all-documents (source)
  "Read every document from a (possibly multi-document) SOURCE stream,
returning a vector of native Lisp values."
  (let ((docs (make-array 0 :adjustable t :fill-pointer 0)))
    (loop
      (source-skip-whitespace-and-comments source)
      (when (source-eof-p source)
        (return))
      (let ((had-start (source-match-document-start source)))
        (declare (ignore had-start))
        (source-skip-blanks source)
        (source-skip-comment source)
        (source-consume-line-break source)
        (source-skip-whitespace-and-comments source)
        (let ((content (read-document-content source)))
          (vector-push-extend content docs))
        (source-skip-to-eol source)
        (source-consume-line-break source)
        (source-skip-whitespace-and-comments source)
        (source-match-document-end source)
        (source-skip-blanks source)
        (source-skip-comment source)
        (source-consume-line-break source)))
    (coerce docs 'vector)))
