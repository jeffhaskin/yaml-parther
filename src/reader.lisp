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
           (yaml-parse-fail 'yaml-scanner-error source "Unterminated single-quoted scalar"))
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
;;; Tagged value reading
;;; ---------------------------------------------------------------------------

(defun read-tagged-value (source)
  "Read a value after a tag has been consumed. Tags are currently ignored."
  (let ((char (source-peek source)))
    (cond
      ((null char) 'null)
      ((line-break-p char) 'null)
      ((eql char #\[) (read-flow-sequence source))
      ((eql char #\{) (read-flow-mapping source))
      ((eql char #\') (read-single-quoted-scalar source))
      ((eql char #\") (read-double-quoted-scalar source))
      (t (read-plain-scalar source)))))

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
      (let ((dash-col (source-column source))
            (consumed-newline-p nil))
        (source-advance source)
        (source-skip-blanks source)
        (let ((item (cond
                      ((source-eof-p source)
                       'null)
                      ((line-break-p (source-peek source))
                       (setf consumed-newline-p t)
                       (source-consume-line-break source)
                       (source-skip-blank-lines source)
                       (if (source-eof-p source)
                           'null
                           (let ((nested-indent (source-count-indent source)))
                             (if (> nested-indent dash-col)
                                 (progn
                                   (source-skip-indent source)
                                   (read-nested-value source nested-indent))
                                 'null))))
                      ((eql (source-peek source) #\!)
                       (read-tag source nil)
                       (source-skip-blanks source)
                       (read-tagged-value source))
                      ((eql (source-peek source) #\[)
                       (read-flow-sequence source))
                      ((eql (source-peek source) #\{)
                       (read-flow-mapping source))
                      ((eql (source-peek source) #\')
                       (read-single-quoted-scalar source))
                      ((eql (source-peek source) #\")
                       (read-double-quoted-scalar source))
                      ((looks-like-mapping-key-p source)
                       (read-block-mapping source))
                      (t (read-plain-scalar source)))))
          (vector-push-extend item items)
          (unless consumed-newline-p
            (source-skip-to-eol source)
            (source-consume-line-break source)
            (source-skip-blank-lines source))))
      (when (source-eof-p source)
        (return))
      (let ((new-indent (source-count-indent source)))
        (when (< new-indent seq-indent)
          (return))
        (source-skip-indent source)))
    (coerce items 'vector)))

;;; ---------------------------------------------------------------------------
;;; Literal block scalar reading
;;; ---------------------------------------------------------------------------

(defun read-literal-scalar (source)
  "Read a literal block scalar (|) from SOURCE. Preserves newlines.
Expects cursor at '|'."
  (unless (eql (source-peek source) #\|)
    (error 'yaml-scanner-error :message "Expected '|' for literal scalar"))
  (source-advance source)
  (source-skip-blanks source)
  (source-consume-line-break source)
  (let ((content-indent (source-count-indent source))
        (chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (when (zerop content-indent)
      (return-from read-literal-scalar ""))
    (loop
      (when (source-eof-p source)
        (return))
      (let ((line-indent (source-count-indent source)))
        (when (and (< line-indent content-indent)
                   (not (line-break-p (source-peek source))))
          (return))
        (source-skip-indent source)
        (loop for char = (source-peek source)
              while (and char (not (line-break-p char)))
              do (vector-push-extend char chars)
                 (source-advance source))
        (vector-push-extend #\Newline chars)
        (unless (source-consume-line-break source)
          (return))))
    (coerce chars 'string)))

;;; ---------------------------------------------------------------------------
;;; Folded block scalar reading
;;; ---------------------------------------------------------------------------

(defun read-folded-scalar (source)
  "Read a folded block scalar (>) from SOURCE. Folds newlines to spaces.
Expects cursor at '>'."
  (unless (eql (source-peek source) #\>)
    (error 'yaml-scanner-error :message "Expected '>' for folded scalar"))
  (source-advance source)
  (source-skip-blanks source)
  (source-consume-line-break source)
  (let ((content-indent (source-count-indent source))
        (chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
        (first-line t))
    (when (zerop content-indent)
      (return-from read-folded-scalar ""))
    (loop
      (when (source-eof-p source)
        (return))
      (let ((line-indent (source-count-indent source)))
        (when (and (< line-indent content-indent)
                   (not (line-break-p (source-peek source))))
          (return))
        (source-skip-indent source)
        (unless first-line
          (vector-push-extend #\Space chars))
        (setf first-line nil)
        (loop for char = (source-peek source)
              while (and char (not (line-break-p char)))
              do (vector-push-extend char chars)
                 (source-advance source))
        (unless (source-consume-line-break source)
          (vector-push-extend #\Newline chars)
          (return))))
    (vector-push-extend #\Newline chars)
    (coerce chars 'string)))

;;; ---------------------------------------------------------------------------
;;; Anchor/Alias handling
;;; ---------------------------------------------------------------------------

(defvar *anchor-table* nil
  "During parsing, maps anchor names to their resolved values.")

(defun anchor-char-p (char)
  "Return T if CHAR is valid in an anchor name."
  (and char
       (or (alphanumericp char)
           (find char "-_"))))

(defun read-anchor-name (source)
  "Read an anchor/alias name starting after & or *."
  (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop for char = (source-peek source)
          while (anchor-char-p char)
          do (vector-push-extend char chars)
             (source-advance source))
    (coerce chars 'string)))

(defun read-anchor (source)
  "Read an anchor definition (&name). Returns the anchor name."
  (unless (eql (source-peek source) #\&)
    (return-from read-anchor nil))
  (source-advance source)
  (let ((name (read-anchor-name source)))
    (source-skip-blanks source)
    name))

(defun read-alias (source)
  "Read an alias (*name) and resolve to the anchored value.
Signals yaml-reference-error if the anchor is undefined."
  (unless (eql (source-peek source) #\*)
    (return-from read-alias nil))
  (let ((pos (source-position source)))
    (source-advance source)
    (let ((name (read-anchor-name source)))
      (multiple-value-bind (value found-p) (gethash name *anchor-table*)
        (unless found-p
          (error 'yaml-reference-error
                 :anchor name
                 :message (format nil "Undefined anchor: ~A" name)
                 :position pos))
        value))))

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

(defun read-explicit-key (source)
  "Read an explicit key after '?' indicator. Returns the key value.
Supports complex keys: flow collections, quoted strings, and plain scalars."
  (source-advance source) ; consume '?'
  (source-skip-blanks source)
  (let ((char (source-peek source)))
    (cond
      ((or (null char) (line-break-p char))
       'null)
      ((eql char #\:)
       'null)
      ((eql char #\[)
       (read-flow-sequence source))
      ((eql char #\{)
       (read-flow-mapping source))
      ((eql char #\')
       (read-single-quoted-scalar source))
      ((eql char #\")
       (read-double-quoted-scalar source))
      (t
       (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
         (loop for c = (source-peek source)
               while (and c
                          (not (line-break-p c))
                          (not (and (char= c #\:)
                                    (or (null (source-peek source 1))
                                        (whitespace-p (source-peek source 1))
                                        (line-break-p (source-peek source 1))))))
               do (vector-push-extend c chars)
                  (source-advance source))
         (resolve-scalar (string-right-trim '(#\Space #\Tab) (coerce chars 'string))))))))

(defun read-nested-value (source indent)
  "Read a nested value at the given INDENT level. Dispatches based on first character."
  (declare (ignore indent))
  (let ((char (source-peek source)))
    (cond
      ((null char) 'null)
      ((eql char #\-) (read-block-sequence source))
      ((eql char #\[) (read-flow-sequence source))
      ((eql char #\{) (read-flow-mapping source))
      ((eql char #\') (read-single-quoted-scalar source))
      ((eql char #\") (read-double-quoted-scalar source))
      ((eql char #\|) (read-literal-scalar source))
      ((eql char #\>) (read-folded-scalar source))
      ((looks-like-mapping-key-p source) (read-block-mapping source))
      (t (read-plain-scalar source)))))

(defun read-block-mapping (source)
  "Read a block mapping from SOURCE. Returns a hash-table (test EQUAL).
Supports both implicit keys (key: value) and explicit keys (? key : value)."
  (let ((table (make-hash-table :test #'equal))
        (map-indent (source-column source)))
    (loop
      (source-skip-blanks source)
      (when (source-eof-p source)
        (return))
      (let* ((explicit-key-p (eql (source-peek source) #\?))
             (key (if explicit-key-p
                      (read-explicit-key source)
                      (read-mapping-key source))))
        (when (and (not explicit-key-p) (stringp key) (string= key ""))
          (return))
        (source-skip-blanks source)
        (when (and explicit-key-p (line-break-p (source-peek source)))
          (source-consume-line-break source)
          (source-skip-blank-lines source)
          (source-skip-indent source))
        (source-skip-blanks source)
        (unless (eql (source-peek source) #\:)
          (return))
        (source-advance source)
        (source-skip-blanks source)
        (when (nth-value 1 (gethash key table))
          (error 'yaml-duplicate-key-error
                 :key key
                 :message (format nil "Duplicate mapping key: ~S" key)
                 :position (source-position source)))
        (let ((anchor-name (when (eql (source-peek source) #\&)
                             (read-anchor source)))
              (nested-p nil))
          (let ((value (cond
                         ((source-eof-p source)
                          'null)
                         ((line-break-p (source-peek source))
                          (source-consume-line-break source)
                          (source-skip-blank-lines source)
                          (if (source-eof-p source)
                              'null
                              (let ((nested-indent (source-count-indent source)))
                                (if (> nested-indent map-indent)
                                    (progn
                                      (setf nested-p t)
                                      (source-skip-indent source)
                                      (read-nested-value source nested-indent))
                                    'null))))
                         ((eql (source-peek source) #\*)
                          (read-alias source))
                         ((eql (source-peek source) #\|)
                          (read-literal-scalar source))
                         ((eql (source-peek source) #\>)
                          (read-folded-scalar source))
                         ((eql (source-peek source) #\[)
                          (read-flow-sequence source))
                         ((eql (source-peek source) #\{)
                          (read-flow-mapping source))
                         ((eql (source-peek source) #\')
                          (read-single-quoted-scalar source))
                         ((eql (source-peek source) #\")
                          (read-double-quoted-scalar source))
                         (t (read-plain-scalar source)))))
            (when (and anchor-name *anchor-table*)
              (setf (gethash anchor-name *anchor-table*) value))
            (if (and (stringp key) (string= key "<<") (hash-table-p value))
                (maphash (lambda (k v)
                           (unless (nth-value 1 (gethash k table))
                             (setf (gethash k table) v)))
                         value)
                (setf (gethash key table) value))
            (unless nested-p
              (source-skip-to-eol source)
              (source-consume-line-break source)
              (source-skip-blank-lines source))))
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
;;; Directive parsing
;;; ---------------------------------------------------------------------------

(defun parse-yaml-directive (source)
  "Parse a %YAML version directive. Returns (MAJOR . MINOR) version cons.
Expects cursor to be at the '%' of '%YAML'."
  (unless (source-match source "%YAML")
    (error 'yaml-directive-error :message "Expected %YAML directive"))
  (source-skip-blanks source)
  (let ((major-chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
        (minor-chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop for char = (source-peek source)
          while (and char (digit-char-p char))
          do (vector-push-extend char major-chars)
             (source-advance source))
    (unless (eql (source-peek source) #\.)
      (error 'yaml-directive-error :message "Expected '.' in YAML version"))
    (source-advance source)
    (loop for char = (source-peek source)
          while (and char (digit-char-p char))
          do (vector-push-extend char minor-chars)
             (source-advance source))
    (when (zerop (length major-chars))
      (error 'yaml-directive-error :message "Missing major version in %YAML"))
    (when (zerop (length minor-chars))
      (error 'yaml-directive-error :message "Missing minor version in %YAML"))
    (cons (parse-integer (coerce major-chars 'string))
          (parse-integer (coerce minor-chars 'string)))))

(defun parse-tag-directive (source)
  "Parse a %TAG directive. Returns (HANDLE . PREFIX) cons.
Expects cursor to be at the '%' of '%TAG'.
Handle is like !yaml!, !!, or !e!. Prefix is a URI prefix."
  (unless (source-match source "%TAG")
    (error 'yaml-directive-error :message "Expected %TAG directive"))
  (source-skip-blanks source)
  (let ((handle (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
        (prefix (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (unless (eql (source-peek source) #\!)
      (error 'yaml-directive-error :message "Tag handle must start with !"))
    (vector-push-extend (source-advance source) handle)
    (loop for char = (source-peek source)
          while (and char (not (whitespace-p char)))
          do (vector-push-extend char handle)
             (source-advance source))
    (source-skip-blanks source)
    (loop for char = (source-peek source)
          while (and char (not (whitespace-p char)) (not (line-break-p char)))
          do (vector-push-extend char prefix)
             (source-advance source))
    (cons (coerce handle 'string)
          (coerce prefix 'string))))

;;; ---------------------------------------------------------------------------
;;; Flow sequence reading
;;; ---------------------------------------------------------------------------

(defun read-flow-sequence (source)
  "Read a flow sequence [...] from SOURCE. Opening bracket must be current char.
Returns a vector of items."
  (unless (eql (source-peek source) #\[)
    (error 'yaml-scanner-error :message "Expected opening bracket"))
  (source-advance source) ; consume [
  (source-skip-blanks source)
  (let ((items (make-array 0 :adjustable t :fill-pointer 0)))
    (loop
      (source-skip-blanks source)
      (when (eql (source-peek source) #\])
        (source-advance source)
        (return (coerce items 'vector)))
      (when (source-eof-p source)
        (error 'yaml-scanner-error :message "Unterminated flow sequence"))
      (let ((item (read-flow-node source)))
        (vector-push-extend item items))
      (source-skip-blanks source)
      (cond
        ((eql (source-peek source) #\,)
         (source-advance source))
        ((eql (source-peek source) #\])
         nil) ; will be consumed on next iteration
        (t
         (error 'yaml-scanner-error :message "Expected , or ] in flow sequence"))))))

(defun read-flow-node (source)
  "Read a flow node (scalar, sequence, or mapping) within flow context."
  (source-skip-blanks source)
  (let ((char (source-peek source)))
    (cond
      ((null char) 'null)
      ((eql char #\[) (read-flow-sequence source))
      ((eql char #\{) (read-flow-mapping source))
      ((eql char #\') (read-single-quoted-scalar source))
      ((eql char #\") (read-double-quoted-scalar source))
      (t (read-flow-plain-scalar source)))))

(defun read-flow-plain-scalar (source)
  "Read a plain scalar within flow context.
Terminates at flow indicators: , ] } and :"
  (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop for char = (source-peek source)
          while (and char
                     (not (whitespace-p char))
                     (not (line-break-p char))
                     (not (find char ",]}:")))
          do (vector-push-extend char chars)
             (source-advance source))
    (resolve-scalar (coerce chars 'string))))

;;; ---------------------------------------------------------------------------
;;; Flow mapping reading
;;; ---------------------------------------------------------------------------

(defun read-flow-mapping (source)
  "Read a flow mapping {...} from SOURCE. Opening brace must be current char.
Returns a hash-table (test EQUAL)."
  (unless (eql (source-peek source) #\{)
    (error 'yaml-scanner-error :message "Expected opening brace"))
  (source-advance source) ; consume {
  (source-skip-blanks source)
  (let ((table (make-hash-table :test #'equal)))
    (loop
      (source-skip-blanks source)
      (when (eql (source-peek source) #\})
        (source-advance source)
        (return table))
      (when (source-eof-p source)
        (error 'yaml-scanner-error :message "Unterminated flow mapping"))
      (let ((key (read-flow-mapping-key source)))
        (source-skip-blanks source)
        (unless (eql (source-peek source) #\:)
          (error 'yaml-scanner-error :message "Expected : after mapping key"))
        (source-advance source) ; consume :
        (source-skip-blanks source)
        (let ((value (if (find (source-peek source) ",}")
                         'null
                         (read-flow-node source))))
          (setf (gethash key table) value)))
      (source-skip-blanks source)
      (cond
        ((eql (source-peek source) #\,)
         (source-advance source))
        ((eql (source-peek source) #\})
         nil) ; will be consumed on next iteration
        (t
         (error 'yaml-scanner-error :message "Expected , or } in flow mapping"))))))

(defun read-flow-mapping-key (source)
  "Read a flow mapping key until colon."
  (source-skip-blanks source)
  (let ((char (source-peek source)))
    (cond
      ((eql char #\') (read-single-quoted-scalar source))
      ((eql char #\") (read-double-quoted-scalar source))
      (t (read-flow-plain-scalar source)))))

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
      ((eql char #\*) (read-alias source))
      ((eql char #\[) (read-flow-sequence source))
      ((eql char #\{) (read-flow-mapping source))
      ((eql char #\')
       (if (looks-like-mapping-key-p source)
           (read-block-mapping source)
           (read-single-quoted-scalar source)))
      ((eql char #\")
       (if (looks-like-mapping-key-p source)
           (read-block-mapping source)
           (read-double-quoted-scalar source)))
      ((and (eql char #\?)
            (let ((next (source-peek source 1)))
              (or (null next) (whitespace-p next) (line-break-p next))))
       (read-block-mapping source))
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

(defun read-directives (source)
  "Read any YAML directives at the start of a document.
Updates *yaml-version* for %YAML directives. Returns T if directives were found."
  (let ((found nil))
    (loop
      (source-skip-whitespace-and-comments source)
      (when (source-eof-p source)
        (return))
      (unless (eql (source-peek source) #\%)
        (return))
      (cond
        ((and (eql (source-peek source 1) #\Y)
              (eql (source-peek source 2) #\A)
              (eql (source-peek source 3) #\M)
              (eql (source-peek source 4) #\L))
         (let ((version (parse-yaml-directive source)))
           (setf *yaml-version* version)
           (setf found t)))
        ((and (eql (source-peek source 1) #\T)
              (eql (source-peek source 2) #\A)
              (eql (source-peek source 3) #\G))
         (parse-tag-directive source)
         (setf found t))
        (t (return)))
      (source-skip-blanks source)
      (source-skip-comment source)
      (source-consume-line-break source))
    found))

(defun read-document (source)
  "Read exactly one YAML document from SOURCE, returning its native Lisp value."
  (let ((*anchor-table* (make-hash-table :test #'equal)))
    (source-skip-whitespace-and-comments source)
    (when (source-eof-p source)
      (return-from read-document 'null))
    (read-directives source)
    (source-skip-whitespace-and-comments source)
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
      content)))

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
