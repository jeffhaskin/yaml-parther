;;;; emit.lisp --- The whole output side: native Lisp value -> YAML text.
;;;;
;;;; Secondary to the parser. One module for now (represent + serialize +
;;;; present together). A documented seam (docs/adr/0005) marks where this
;;;; splits into serialize/present IF faithful style-preservation ever becomes
;;;; a requirement.

(in-package #:yaml-parther)

(defun emit-scalar (value stream)
  "Emit a scalar VALUE to STREAM."
  (cond
    ((eq value 'null) (write-string "null" stream))
    ((eq value t) (write-string "true" stream))
    ((null value) (write-string "false" stream))
    ((integerp value) (format stream "~D" value))
    ((floatp value) (format stream "~F" value))
    ((stringp value)
     (if (or (zerop (length value))
             (find-if (lambda (c) (member c '(#\: #\# #\[ #\] #\{ #\} #\, #\Newline))) value)
             (string= value "true") (string= value "false")
             (string= value "null") (string= value "~")
             (string= value "yes") (string= value "no")
             (string= value "on") (string= value "off"))
         (progn
           (write-char #\" stream)
           (loop for c across value do
             (case c
               (#\Newline (write-string "\\n" stream))
               (#\" (write-string "\\\"" stream))
               (#\\ (write-string "\\\\" stream))
               (otherwise (write-char c stream))))
           (write-char #\" stream))
         (write-string value stream)))
    (t (format stream "~S" value))))

(defun emit-sequence (seq stream indent)
  "Emit a sequence SEQ to STREAM at INDENT level."
  (if (zerop (length seq))
      (write-string "[]" stream)
      (loop for i from 0 below (length seq)
            for item = (elt seq i)
            do (when (plusp i) (terpri stream))
               (dotimes (_ indent) (write-char #\Space stream))
               (write-string "- " stream)
               (emit-value item stream (+ indent 2)))))

(defun emit-mapping (ht stream indent)
  "Emit a hash-table HT as a mapping to STREAM at INDENT level."
  (if (zerop (hash-table-count ht))
      (write-string "{}" stream)
      (let ((first t))
        (maphash (lambda (k v)
                   (unless first (terpri stream))
                   (setf first nil)
                   (dotimes (_ indent) (write-char #\Space stream))
                   (emit-scalar k stream)
                   (write-string ": " stream)
                   (emit-value v stream (+ indent 2)))
                 ht))))

(defun emit-value (value stream indent)
  "Emit VALUE to STREAM at INDENT level."
  (cond
    ((hash-table-p value)
     (if (zerop (hash-table-count value))
         (write-string "{}" stream)
         (progn
           (terpri stream)
           (emit-mapping value stream indent))))
    ((and (vectorp value) (not (stringp value)))
     (if (zerop (length value))
         (write-string "[]" stream)
         (progn
           (terpri stream)
           (emit-sequence value stream indent))))
    (t (emit-scalar value stream))))

(defun emit-document (value stream)
  "Emit native Lisp VALUE as YAML to STREAM."
  (cond
    ((hash-table-p value)
     (emit-mapping value stream 0))
    ((and (vectorp value) (not (stringp value)))
     (emit-sequence value stream 0))
    (t (emit-scalar value stream)))
  (terpri stream))
