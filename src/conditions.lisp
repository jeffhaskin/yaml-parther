;;;; conditions.lisp --- The failure taxonomy.
;;;;
;;;; LOUD-FAILURE CONTRACT
;;;; =====================
;;;; Malformed input or unresolvable references SIGNAL one of these conditions.
;;;; There are no silent fallbacks, no sentinel return values, and no best-effort
;;;; degradation anywhere in the library. Every error raised is a subclass of
;;;; YAML-ERROR. Every signalled condition carries a source position when one is
;;;; available.
;;;;
;;;; Hierarchy:
;;;;   yaml-error                   (root -- handle to catch everything)
;;;;     yaml-parse-error           (all parsing errors)
;;;;       yaml-scanner-error       (lexical: unexpected char, unterminated quote)
;;;;       yaml-structure-error     (indentation, nesting, document framing)
;;;;       yaml-reference-error     (undefined anchor, invalid alias)
;;;;       yaml-tag-error           (unknown tag, invalid tag URI)
;;;;       yaml-directive-error     (bad %YAML/%TAG directive)
;;;;       yaml-duplicate-key-error (repeated key in mapping)
;;;;     yaml-emit-error            (emission failures)
;;;;       yaml-circular-error      (circular reference during emit)
;;;;
;;;; Use YAML-PARSE-FAIL or YAML-EMIT-FAIL to signal with automatic position
;;;; capture. Never return a sentinel or swallow an error.

(in-package #:yaml-parther)

;;; ---------------------------------------------------------------------------
;;; Root condition
;;; ---------------------------------------------------------------------------

(define-condition yaml-error (error)
  ((message  :initarg :message  :initform nil :reader yaml-error-message)
   (position :initarg :position :initform nil :reader yaml-error-position
             :documentation "Source position as (LINE . COLUMN) when known, else NIL."))
  (:report (lambda (condition stream)
             (format stream "~@[~A~]~@[ at line ~D, column ~D~]"
                     (yaml-error-message condition)
                     (car (yaml-error-position condition))
                     (cdr (yaml-error-position condition)))))
  (:documentation "Root of the yaml-parther condition hierarchy. Handle this to catch everything."))

;;; ---------------------------------------------------------------------------
;;; Parse-time conditions
;;; ---------------------------------------------------------------------------

(define-condition yaml-parse-error (yaml-error) ()
  (:documentation "Signalled when input is not well-formed YAML 1.2."))

(define-condition yaml-scanner-error (yaml-parse-error) ()
  (:documentation "Lexical error: unexpected character, unterminated string, invalid escape."))

(define-condition yaml-structure-error (yaml-parse-error) ()
  (:documentation "Structural error: bad indentation, improper nesting, document framing."))

(define-condition yaml-reference-error (yaml-parse-error)
  ((anchor :initarg :anchor :initform nil :reader yaml-reference-error-anchor
           :documentation "The anchor name that could not be resolved."))
  (:report (lambda (condition stream)
             (format stream "~@[~A~]~@[ (anchor: ~A)~]~@[ at line ~D, column ~D~]"
                     (yaml-error-message condition)
                     (yaml-reference-error-anchor condition)
                     (car (yaml-error-position condition))
                     (cdr (yaml-error-position condition)))))
  (:documentation "Signalled for an unresolvable alias, undefined anchor, or malformed merge key."))

(define-condition yaml-tag-error (yaml-parse-error)
  ((tag :initarg :tag :initform nil :reader yaml-tag-error-tag
        :documentation "The tag that could not be resolved."))
  (:report (lambda (condition stream)
             (format stream "~@[~A~]~@[ (tag: ~A)~]~@[ at line ~D, column ~D~]"
                     (yaml-error-message condition)
                     (yaml-tag-error-tag condition)
                     (car (yaml-error-position condition))
                     (cdr (yaml-error-position condition)))))
  (:documentation "Signalled for an unknown tag or invalid tag URI."))

(define-condition yaml-directive-error (yaml-parse-error) ()
  (:documentation "Signalled for malformed %YAML or %TAG directives."))

(define-condition yaml-duplicate-key-error (yaml-parse-error)
  ((key :initarg :key :initform nil :reader yaml-duplicate-key-error-key
        :documentation "The duplicated key value."))
  (:report (lambda (condition stream)
             (format stream "~@[~A~]~@[ (key: ~S)~]~@[ at line ~D, column ~D~]"
                     (yaml-error-message condition)
                     (yaml-duplicate-key-error-key condition)
                     (car (yaml-error-position condition))
                     (cdr (yaml-error-position condition)))))
  (:documentation "Signalled when a mapping contains duplicate keys."))

;;; ---------------------------------------------------------------------------
;;; Emit-time conditions
;;; ---------------------------------------------------------------------------

(define-condition yaml-emit-error (yaml-error) ()
  (:documentation "Signalled when a Lisp value graph cannot be represented as YAML."))

(define-condition yaml-circular-error (yaml-emit-error) ()
  (:documentation "Signalled when a circular reference is detected during emission."))

;;; ---------------------------------------------------------------------------
;;; Signalling helpers -- ALWAYS use these; never ERROR directly.
;;; ---------------------------------------------------------------------------

(defun yaml-parse-fail (condition-type source message &rest format-args)
  "Signal a parse-time condition with the current position from SOURCE.
CONDITION-TYPE must be a subtype of YAML-PARSE-ERROR. MESSAGE is a format
string; FORMAT-ARGS are its arguments. Never returns."
  (error condition-type
         :message (apply #'format nil message format-args)
         :position (when source (source-position source))))

(defun yaml-emit-fail (condition-type message &rest format-args)
  "Signal an emit-time condition. CONDITION-TYPE must be a subtype of
YAML-EMIT-ERROR. MESSAGE is a format string; FORMAT-ARGS are its arguments.
Never returns."
  (error condition-type
         :message (apply #'format nil message format-args)))

(defmacro with-parse-error-context ((source) &body body)
  "Execute BODY, augmenting any YAML-PARSE-ERROR with position from SOURCE."
  (let ((src (gensym "SOURCE")))
    `(let ((,src ,source))
       (handler-bind
           ((yaml-parse-error
              (lambda (c)
                (when (and ,src (null (yaml-error-position c)))
                  (setf (slot-value c 'position) (source-position ,src))))))
         ,@body))))
