;;;; complex-keys.lisp --- Tests for complex and empty key parsing.
;;;;
;;;; TDD tests for YAML complex keys (non-scalar) and empty keys.
;;;; Complex keys use explicit notation (?) with flow collections as keys.

(in-package #:yaml-parther/test)

;;; ---------------------------------------------------------------------------
;;; Complex key tests
;;; ---------------------------------------------------------------------------

(define-test complex-keys
  :parent yaml-parther
  :description "Complex and empty key parsing.")

(define-test complex-key-flow-sequence
  :parent complex-keys
  :description "? [1, 2] : value - flow sequence as key"
  (let* ((src (yaml::make-source "? [1, 2] : value"))
         (result (yaml::read-block-mapping src)))
    (true (hash-table-p result))
    (is = 1 (hash-table-count result))))

(define-test complex-key-flow-mapping
  :parent complex-keys
  :description "? {a: 1} : value - flow mapping as key"
  (let* ((src (yaml::make-source "? {a: 1} : value"))
         (result (yaml::read-block-mapping src)))
    (true (hash-table-p result))
    (is = 1 (hash-table-count result))))

;;; ---------------------------------------------------------------------------
;;; Empty key tests
;;; ---------------------------------------------------------------------------

(define-test empty-key-implicit
  :parent complex-keys
  :description ": value - implicit empty key"
  (let* ((src (yaml::make-source ": value"))
         (result (yaml::read-block-mapping src)))
    (true (hash-table-p result))
    (is string= "value" (gethash 'null result))))

(define-test empty-key-explicit
  :parent complex-keys
  :description "? : value - explicit empty key"
  (let* ((src (yaml::make-source "?
: value"))
         (result (yaml::read-block-mapping src)))
    (true (hash-table-p result))
    (is string= "value" (gethash 'null result))))

(define-test empty-key-and-value
  :parent complex-keys
  :description ": - empty key and value"
  (let* ((src (yaml::make-source ":"))
         (result (yaml::read-block-mapping src)))
    (true (hash-table-p result))
    (is eq 'null (gethash 'null result))))
