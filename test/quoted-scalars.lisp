;;;; quoted-scalars.lisp --- Tests for single- and double-quoted scalar parsing.
;;;;
;;;; TDD tests for YAML quoted scalar support. Each test drives the
;;;; implementation of read-single-quoted-scalar and read-double-quoted-scalar.

(in-package #:yaml-parther/test)

;;; ---------------------------------------------------------------------------
;;; Single-quoted scalar tests
;;; ---------------------------------------------------------------------------

(define-test single-quoted-scalars
  :parent yaml-parther
  :description "Single-quoted scalar parsing.")

(define-test single-quoted-simple
  :parent single-quoted-scalars
  :description "read-single-quoted-scalar reads 'hello' as \"hello\""
  (let* ((src (yaml::make-source "'hello'"))
         (result (yaml::read-single-quoted-scalar src)))
    (is string= "hello" result)))

(define-test single-quoted-empty
  :parent single-quoted-scalars
  :description "read-single-quoted-scalar reads '' as empty string"
  (let* ((src (yaml::make-source "''"))
         (result (yaml::read-single-quoted-scalar src)))
    (is string= "" result)))

(define-test single-quoted-escaped-quote
  :parent single-quoted-scalars
  :description "read-single-quoted-scalar reads 'it''s' as \"it's\""
  (let* ((src (yaml::make-source "'it''s'"))
         (result (yaml::read-single-quoted-scalar src)))
    (is string= "it's" result)))

(define-test single-quoted-no-escapes
  :parent single-quoted-scalars
  :description "read-single-quoted-scalar preserves backslash literally"
  (let* ((src (yaml::make-source "'line\\nfoo'"))
         (result (yaml::read-single-quoted-scalar src)))
    (is string= "line\\nfoo" result)))

;;; ---------------------------------------------------------------------------
;;; Double-quoted scalar tests
;;; ---------------------------------------------------------------------------

(define-test double-quoted-scalars
  :parent yaml-parther
  :description "Double-quoted scalar parsing.")

(define-test double-quoted-simple
  :parent double-quoted-scalars
  :description "read-double-quoted-scalar reads \"hello\" as \"hello\""
  (let* ((src (yaml::make-source "\"hello\""))
         (result (yaml::read-double-quoted-scalar src)))
    (is string= "hello" result)))

(define-test double-quoted-empty
  :parent double-quoted-scalars
  :description "read-double-quoted-scalar reads \"\" as empty string"
  (let* ((src (yaml::make-source "\"\""))
         (result (yaml::read-double-quoted-scalar src)))
    (is string= "" result)))

(define-test double-quoted-newline-escape
  :parent double-quoted-scalars
  :description "read-double-quoted-scalar reads \\n as newline"
  (let* ((src (yaml::make-source "\"line\\nfoo\""))
         (result (yaml::read-double-quoted-scalar src)))
    (is string= (format nil "line~%foo") result)))

(define-test double-quoted-tab-escape
  :parent double-quoted-scalars
  :description "read-double-quoted-scalar reads \\t as tab"
  (let* ((src (yaml::make-source "\"tab\\there\""))
         (result (yaml::read-double-quoted-scalar src)))
    (is string= (format nil "tab~Chere" #\Tab) result)))

(define-test double-quoted-backslash-escape
  :parent double-quoted-scalars
  :description "read-double-quoted-scalar reads \\\\ as \\"
  (let* ((src (yaml::make-source "\"back\\\\slash\""))
         (result (yaml::read-double-quoted-scalar src)))
    (is string= "back\\slash" result)))

(define-test double-quoted-quote-escape
  :parent double-quoted-scalars
  :description "read-double-quoted-scalar reads \\\" as \""
  (let* ((src (yaml::make-source "\"say\\\"hi\\\"\""))
         (result (yaml::read-double-quoted-scalar src)))
    (is string= "say\"hi\"" result)))

(define-test double-quoted-hex-escape
  :parent double-quoted-scalars
  :description "read-double-quoted-scalar reads \\x41 as A"
  (let* ((src (yaml::make-source "\"\\x41\""))
         (result (yaml::read-double-quoted-scalar src)))
    (is string= "A" result)))

(define-test double-quoted-unicode-4
  :parent double-quoted-scalars
  :description "read-double-quoted-scalar reads \\u0041 as A"
  (let* ((src (yaml::make-source "\"\\u0041\""))
         (result (yaml::read-double-quoted-scalar src)))
    (is string= "A" result)))

(define-test double-quoted-unicode-8
  :parent double-quoted-scalars
  :description "read-double-quoted-scalar reads \\U00000041 as A"
  (let* ((src (yaml::make-source "\"\\U00000041\""))
         (result (yaml::read-double-quoted-scalar src)))
    (is string= "A" result)))
