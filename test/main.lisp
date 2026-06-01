;;;; main.lisp --- Test suite root and harness sanity checks.
;;;;
;;;; This file proves the Parachute harness loads and runs against the library.
;;;; It also pins the LOUD-FAILURE contract at the skeleton stage: the public
;;;; verbs are stubs and must SIGNAL, never return a sentinel. As real behavior
;;;; lands, these stub-signal checks get replaced by the conformance suite and
;;;; the scalar-resolution unit tests.

(in-package #:yaml-parther/test)

(define-test yaml-parther
  :description "Root suite for the yaml-parther library.")

(define-test harness
  :parent yaml-parther
  (true t "Parachute harness loads and runs."))

(define-test stubs-signal-loudly
  :parent yaml-parther
  :description "Unimplemented verbs signal (no silent fallback)."
  (fail (yaml:emit 42) 'error))

;;; ---------------------------------------------------------------------------
;;; Scalar resolution tests (core schema)
;;; ---------------------------------------------------------------------------

(define-test scalar-resolution
  :parent yaml-parther
  :description "Core schema scalar resolution.")

(define-test null-resolution
  :parent scalar-resolution
  (is eq 'null (yaml-parther::resolve-scalar "")
      "Empty string resolves to CL:NULL")
  (is eq 'null (yaml-parther::resolve-scalar "~")
      "Tilde resolves to CL:NULL")
  (is eq 'null (yaml-parther::resolve-scalar "null")
      "lowercase null resolves to CL:NULL")
  (is eq 'null (yaml-parther::resolve-scalar "Null")
      "Titlecase Null resolves to CL:NULL")
  (is eq 'null (yaml-parther::resolve-scalar "NULL")
      "Uppercase NULL resolves to CL:NULL"))

(define-test boolean-resolution
  :parent scalar-resolution
  (is eq t (yaml-parther::resolve-scalar "true")
      "lowercase true resolves to T")
  (is eq t (yaml-parther::resolve-scalar "True")
      "Titlecase True resolves to T")
  (is eq t (yaml-parther::resolve-scalar "TRUE")
      "Uppercase TRUE resolves to T")
  (is eq nil (yaml-parther::resolve-scalar "false")
      "lowercase false resolves to NIL")
  (is eq nil (yaml-parther::resolve-scalar "False")
      "Titlecase False resolves to NIL")
  (is eq nil (yaml-parther::resolve-scalar "FALSE")
      "Uppercase FALSE resolves to NIL"))

(define-test integer-resolution
  :parent scalar-resolution
  (is = 42 (yaml-parther::resolve-scalar "42")
      "Positive decimal integer")
  (is = -42 (yaml-parther::resolve-scalar "-42")
      "Negative decimal integer")
  (is = 42 (yaml-parther::resolve-scalar "+42")
      "Explicit positive decimal integer")
  (is = 0 (yaml-parther::resolve-scalar "0")
      "Zero")
  (is = 15 (yaml-parther::resolve-scalar "0o17")
      "Octal integer")
  (is = 42 (yaml-parther::resolve-scalar "0x2A")
      "Hex integer")
  (is = 42 (yaml-parther::resolve-scalar "0x2a")
      "Hex integer lowercase"))

(define-test float-resolution
  :parent scalar-resolution
  (is = 3.14d0 (yaml-parther::resolve-scalar "3.14")
      "Simple float")
  (is = -3.14d0 (yaml-parther::resolve-scalar "-3.14")
      "Negative float")
  (is = 0.5d0 (yaml-parther::resolve-scalar ".5")
      "Leading decimal point")
  (is = 1.5d10 (yaml-parther::resolve-scalar "1.5e10")
      "Float with exponent")
  (is = most-positive-double-float (yaml-parther::resolve-scalar ".inf")
      "Positive infinity")
  (is = most-negative-double-float (yaml-parther::resolve-scalar "-.inf")
      "Negative infinity"))

(define-test string-resolution
  :parent scalar-resolution
  (is string= "hello" (yaml-parther::resolve-scalar "hello")
      "Plain string")
  (is string= "0o8" (yaml-parther::resolve-scalar "0o8")
      "Invalid octal stays string")
  (is string= "0xGG" (yaml-parther::resolve-scalar "0xGG")
      "Invalid hex stays string"))

(define-test explicit-tag-resolution
  :parent scalar-resolution
  (is string= "true" (yaml-parther::resolve-scalar "true" "tag:yaml.org,2002:str")
      "!!str forces string even for boolean text")
  (is = 42 (yaml-parther::resolve-scalar "42" "tag:yaml.org,2002:int")
      "!!int parses integer")
  (fail (yaml-parther::resolve-scalar "hello" "tag:yaml.org,2002:int") 'yaml-parther:yaml-tag-error
      "!!int rejects non-integer")
  (is eq t (yaml-parther::resolve-scalar "true" "tag:yaml.org,2002:bool")
      "!!bool parses true")
  (is eq nil (yaml-parther::resolve-scalar "false" "tag:yaml.org,2002:bool")
      "!!bool parses false")
  (fail (yaml-parther::resolve-scalar "hello" "tag:yaml.org,2002:bool") 'yaml-parther:yaml-tag-error
      "!!bool rejects non-boolean"))

;;; ---------------------------------------------------------------------------
;;; Block sequence tests
;;; ---------------------------------------------------------------------------

(define-test block-sequences
  :parent yaml-parther
  :description "Block sequence parsing.")

(define-test single-item-sequence
  :parent block-sequences
  (let ((result (yaml-parther::read-block-sequence
                 (yaml-parther::make-source "- foo"))))
    (is equalp #("foo") result
        "Single item sequence parses to vector")))

(define-test multi-item-sequence
  :parent block-sequences
  (let ((result (yaml-parther::read-block-sequence
                 (yaml-parther::make-source "- a
- b
- c"))))
    (is equalp #("a" "b" "c") result
        "Multi-item sequence parses to vector")))

(define-test sequence-with-scalar-resolution
  :parent block-sequences
  (let ((result (yaml-parther::read-block-sequence
                 (yaml-parther::make-source "- 1
- true
- null"))))
    (is equalp #(1 t null) result
        "Sequence items are resolved to native types")))

(define-test empty-sequence-item
  :parent block-sequences
  (let ((result (yaml-parther::read-block-sequence
                 (yaml-parther::make-source "-
- b"))))
    (is equalp #(null "b") result
        "Empty sequence item becomes null")))

;;; ---------------------------------------------------------------------------
;;; Block mapping tests
;;; ---------------------------------------------------------------------------

(define-test block-mappings
  :parent yaml-parther
  :description "Block mapping parsing.")

(define-test single-key-value-pair
  :parent block-mappings
  (let ((result (yaml-parther::read-block-mapping
                 (yaml-parther::make-source "key: value"))))
    (true (hash-table-p result) "Result is a hash-table")
    (is equal "value" (gethash "key" result) "key maps to value")))

(define-test multiple-key-value-pairs
  :parent block-mappings
  (let ((result (yaml-parther::read-block-mapping
                 (yaml-parther::make-source "a: 1
b: 2
c: 3"))))
    (is = 3 (hash-table-count result) "Three entries")
    (is = 1 (gethash "a" result) "a maps to 1")
    (is = 2 (gethash "b" result) "b maps to 2")
    (is = 3 (gethash "c" result) "c maps to 3")))

(define-test empty-value
  :parent block-mappings
  (let ((result (yaml-parther::read-block-mapping
                 (yaml-parther::make-source "key:"))))
    (is eq 'null (gethash "key" result) "empty value becomes null")))

(define-test value-scalar-resolution
  :parent block-mappings
  (let ((result (yaml-parther::read-block-mapping
                 (yaml-parther::make-source "bool: true
num: 42
str: hello"))))
    (is eq t (gethash "bool" result) "true resolves to T")
    (is = 42 (gethash "num" result) "42 resolves to integer")
    (is equal "hello" (gethash "str" result) "hello stays string")))

(define-test key-scalar-resolution
  :parent block-mappings
  (let ((result (yaml-parther::read-block-mapping
                 (yaml-parther::make-source "42: value"))))
    (is equal "value" (gethash 42 result) "numeric key resolves to integer")))

(define-test mapping-via-parse
  :parent block-mappings
  (let ((result (yaml:parse "key: value")))
    (true (hash-table-p result) "Result is a hash-table")
    (is equal "value" (gethash "key" result) "key maps to value")))

(defun run ()
  "Run the whole suite. Convenience entry point for `ros run`."
  (parachute:test '#:yaml-parther/test))
