;;;; invalid-input.lisp --- Tests for invalid input error handling.
;;;;
;;;; TDD tests ensuring invalid YAML input signals appropriate conditions
;;;; with position information.

(in-package #:yaml-parther/test)

;;; ---------------------------------------------------------------------------
;;; Invalid input tests
;;; ---------------------------------------------------------------------------

(define-test invalid-input
  :parent yaml-parther
  :description "Invalid input error handling.")

;;; Scanner errors (lexical)

(define-test unterminated-single-quote
  :parent invalid-input
  :description "Unterminated single-quoted string signals scanner error"
  (fail (yaml:parse "'unterminated") 'yaml:yaml-scanner-error))

(define-test unterminated-double-quote
  :parent invalid-input
  :description "Unterminated double-quoted string signals scanner error"
  (fail (yaml:parse "\"unterminated") 'yaml:yaml-scanner-error))

(define-test invalid-escape-sequence
  :parent invalid-input
  :description "Invalid escape in double-quoted string signals scanner error"
  (fail (yaml:parse "\"bad\\q\"") 'yaml:yaml-scanner-error))

;;; Structure errors
;;; Note: Inconsistent indentation detection requires more sophisticated
;;; indentation tracking. For now, the parser is permissive.

;;; Directive errors

(define-test invalid-yaml-version-format
  :parent invalid-input
  :description "Invalid %YAML version format signals directive error"
  (fail (yaml:parse "%YAML bad
---") 'yaml:yaml-directive-error))

;;; Reference errors

(define-test undefined-alias
  :parent invalid-input
  :description "Undefined alias signals reference error"
  (fail (yaml:parse "*undefined") 'yaml:yaml-reference-error))

;;; Duplicate key errors

(define-test duplicate-key-mapping
  :parent invalid-input
  :description "Duplicate key in mapping signals duplicate-key error"
  (fail (yaml:parse "foo: 1
foo: 2") 'yaml:yaml-duplicate-key-error))

;;; Error position tests

(define-test error-has-position
  :parent invalid-input
  :description "Parse errors include line/column position"
  (handler-case
      (progn
        (yaml:parse "'unterminated")
        (true nil "Should have signalled"))
    (yaml:yaml-error (e)
      (let ((pos (yaml:yaml-error-position e)))
        (true pos "Error should have position")
        (true (consp pos) "Position should be cons")
        (true (plusp (car pos)) "Line should be positive")))))
