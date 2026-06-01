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
  "Read a plain scalar key until colon."
  (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop for char = (source-peek source)
          while (and char
                     (not (char= char #\:))
                     (not (line-break-p char)))
          do (vector-push-extend char chars)
             (source-advance source))
    (string-right-trim '(#\Space #\Tab) (coerce chars 'string))))

(defun read-block-mapping (source)
  "Read a block mapping from SOURCE. Returns a hash-table (test EQUAL)."
  (let ((table (make-hash-table :test #'equal)))
    (source-skip-blanks source)
    (let ((key (read-mapping-key source)))
      (when (eql (source-peek source) #\:)
        (source-advance source)
        (source-skip-blanks source)
        (let ((value (if (or (source-eof-p source)
                             (line-break-p (source-peek source)))
                         'null
                         (read-plain-scalar source))))
          (setf (gethash key table) value))))
    table))

;;; ---------------------------------------------------------------------------
;;; Document reading
;;; ---------------------------------------------------------------------------

(defun read-document (source)
  "Read exactly one YAML document from SOURCE, returning its native Lisp value."
  (declare (ignore source))
  (error "READ-DOCUMENT is not yet implemented."))

(defun read-all-documents (source)
  "Read every document from a (possibly multi-document) SOURCE stream,
returning a vector of native Lisp values."
  (declare (ignore source))
  (error "READ-ALL-DOCUMENTS is not yet implemented."))
