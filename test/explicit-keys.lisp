;;;; explicit-keys.lisp --- Tests for explicit key (?) parsing.
;;;;
;;;; TDD tests for YAML explicit key support. The ? indicator marks an explicit
;;;; mapping key, allowing complex keys (multiline, non-scalar).

(in-package #:yaml-parther/test)

;;; ---------------------------------------------------------------------------
;;; Explicit key tests
;;; ---------------------------------------------------------------------------

(define-test explicit-keys
  :parent yaml-parther
  :description "Explicit key (?) parsing.")

(define-test explicit-key-simple
  :parent explicit-keys
  :description "? key followed by : value"
  (let* ((src (yaml::make-source "? foo
: bar"))
         (result (yaml::read-block-mapping src)))
    (is string= "bar" (gethash "foo" result))))

(define-test explicit-key-inline
  :parent explicit-keys
  :description "? key : value on same line"
  (let* ((src (yaml::make-source "? foo : bar"))
         (result (yaml::read-block-mapping src)))
    (is string= "bar" (gethash "foo" result))))

(define-test explicit-key-empty-value
  :parent explicit-keys
  :description "? key with implicit null value"
  (let* ((src (yaml::make-source "? foo
:"))
         (result (yaml::read-block-mapping src)))
    (is eq 'null (gethash "foo" result))))

(define-test explicit-key-null-key
  :parent explicit-keys
  :description "? with no key text creates null key"
  (let* ((src (yaml::make-source "?
: bar"))
         (result (yaml::read-block-mapping src)))
    (is string= "bar" (gethash 'null result))))
