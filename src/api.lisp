;;;; api.lisp --- The public facade.
;;;;
;;;; The one sanctioned thin layer: it wires input handling to the reader and
;;;; emit modules and defines the user-facing contract. Every function signals
;;;; a subclass of YAML-ERROR on failure -- never a sentinel return value.
;;;;
;;;; Skeleton only -- the verbs are stubs that signal until implemented.

(in-package #:yaml-parther)

(defun parse (input &key allow-multiple-documents)
  "Parse a single YAML document from INPUT (a STRING or character STREAM) and
return one native Lisp value. Signals YAML-PARSE-ERROR on malformed input. If
INPUT contains more than one document, signals an error unless
ALLOW-MULTIPLE-DOCUMENTS is true, in which case the first document is returned."
  (let* ((source (make-source input))
         (result (read-document source)))
    (source-skip-whitespace-and-comments source)
    (unless (or allow-multiple-documents (source-eof-p source))
      (unless (source-match-document-end source)
        (when (source-match-document-start source)
          (error 'yaml-parse-error
                 :message "Multiple documents found; use PARSE-ALL or set :ALLOW-MULTIPLE-DOCUMENTS"
                 :position (source-position source)))))
    result))

(defun parse-all (input)
  "Parse a multi-document YAML stream from INPUT, returning a VECTOR of native
Lisp values (one per document)."
  (let ((source (make-source input)))
    (read-all-documents source)))

(defun parse-file (pathname &key (external-format :utf-8) allow-multiple-documents)
  "Open PATHNAME and PARSE its contents."
  (declare (ignore pathname external-format allow-multiple-documents))
  (error "PARSE-FILE is not yet implemented."))

(defun emit (value &key stream)
  "Emit native Lisp VALUE as YAML. When STREAM is NIL, return a fresh string;
otherwise write to STREAM and return VALUE."
  (declare (ignore value stream))
  (error "EMIT is not yet implemented."))

(defun emit-to-string (value)
  "Emit native Lisp VALUE as a YAML string."
  (emit value :stream nil))
