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

(define-test emit-works
  :parent yaml-parther
  :description "Emit produces YAML output."
  (is string= "42
" (yaml:emit 42) "Emit integer")
  (is string= "hello
" (yaml:emit "hello") "Emit string"))

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

(define-test duplicate-key-signals-error
  :parent block-mappings
  (fail (yaml:parse "a: 1
a: 2") 'yaml-parther:yaml-duplicate-key-error
      "Duplicate key signals error"))

;;; ---------------------------------------------------------------------------
;;; Block scalar tests
;;; ---------------------------------------------------------------------------

(define-test block-scalars
  :parent yaml-parther
  :description "Literal and folded block scalar parsing.")

(define-test simple-literal-scalar
  :parent block-scalars
  (let ((result (yaml-parther::read-literal-scalar
                 (yaml-parther::make-source "|
  line1
  line2
"))))
    (is equal (format nil "line1~%line2~%") result
        "Literal preserves newlines")))

(define-test simple-folded-scalar
  :parent block-scalars
  (let ((result (yaml-parther::read-folded-scalar
                 (yaml-parther::make-source ">
  line1
  line2
"))))
    (is equal (format nil "line1 line2~%") result
        "Folded converts newlines to spaces")))

(define-test literal-in-mapping
  :parent block-scalars
  (let ((result (yaml:parse "text: |
  line1
  line2
")))
    (is equal (format nil "line1~%line2~%") (gethash "text" result)
        "Literal scalar as mapping value")))

;;; ---------------------------------------------------------------------------
;;; Anchor tests
;;; ---------------------------------------------------------------------------

(define-test anchors
  :parent yaml-parther
  :description "Anchor parsing.")

(define-test scalar-with-anchor
  :parent anchors
  (let ((result (yaml:parse "key: &myanchor value")))
    (is equal "value" (gethash "key" result)
        "Anchor attached to scalar value")))

(define-test alias-resolves
  :parent anchors
  (let ((result (yaml:parse "a: &ref hello
b: *ref")))
    (is equal "hello" (gethash "a" result) "Anchor value")
    (is equal "hello" (gethash "b" result) "Alias resolves to anchor")))

(define-test undefined-alias-error
  :parent anchors
  (fail (yaml:parse "a: *undefined") 'yaml-parther:yaml-reference-error
      "Undefined alias signals error"))

;;; ---------------------------------------------------------------------------
;;; Merge key tests
;;; ---------------------------------------------------------------------------

(define-test merge-keys
  :parent yaml-parther
  :description "Merge key (<<) support.")

(define-test simple-merge
  :parent merge-keys
  (let ((result (yaml:parse "defaults: &d
  a: 1
actual:
  <<: *d
  b: 2")))
    (let ((actual (gethash "actual" result)))
      (is equal 1 (gethash "a" actual) "Merged key a")
      (is equal 2 (gethash "b" actual) "Local key b"))))

;;; ---------------------------------------------------------------------------
;;; Flow collection tests
;;; ---------------------------------------------------------------------------

(define-test flow-collections
  :parent yaml-parther
  :description "Flow sequence and mapping parsing.")

(define-test empty-flow-sequence
  :parent flow-collections
  (let ((result (yaml:parse "[]")))
    (true (vectorp result) "Result is a vector")
    (is = 0 (length result) "Empty sequence has length 0")))

(define-test single-item-flow-sequence
  :parent flow-collections
  (let ((result (yaml:parse "[1]")))
    (true (vectorp result) "Result is a vector")
    (is = 1 (length result) "Single item")
    (is = 1 (aref result 0) "Item is resolved integer")))

(define-test multi-item-flow-sequence
  :parent flow-collections
  (let ((result (yaml:parse "[1, 2, 3]")))
    (is equalp #(1 2 3) result "Multiple items parsed correctly")))

(define-test flow-sequence-with-strings
  :parent flow-collections
  (let ((result (yaml:parse "[a, b, c]")))
    (is equalp #("a" "b" "c") result "String items parsed correctly")))

(define-test flow-sequence-mixed-types
  :parent flow-collections
  (let ((result (yaml:parse "[1, true, null]")))
    (is equalp #(1 t null) result "Mixed types resolved correctly")))

(define-test nested-flow-sequence
  :parent flow-collections
  (let ((result (yaml:parse "[[1, 2], [3, 4]]")))
    (true (vectorp result) "Outer is vector")
    (is = 2 (length result) "Two nested sequences")
    (is equalp #(1 2) (aref result 0) "First nested")
    (is equalp #(3 4) (aref result 1) "Second nested")))

(define-test empty-flow-mapping
  :parent flow-collections
  (let ((result (yaml:parse "{}")))
    (true (hash-table-p result) "Result is hash-table")
    (is = 0 (hash-table-count result) "Empty mapping")))

(define-test single-pair-flow-mapping
  :parent flow-collections
  (let ((result (yaml:parse "{a: 1}")))
    (true (hash-table-p result) "Result is hash-table")
    (is = 1 (gethash "a" result) "Key maps to value")))

(define-test multi-pair-flow-mapping
  :parent flow-collections
  (let ((result (yaml:parse "{a: 1, b: 2, c: 3}")))
    (is = 3 (hash-table-count result) "Three entries")
    (is = 1 (gethash "a" result) "a=1")
    (is = 2 (gethash "b" result) "b=2")
    (is = 3 (gethash "c" result) "c=3")))

(define-test nested-flow-mapping
  :parent flow-collections
  (let ((result (yaml:parse "{outer: {inner: value}}")))
    (true (hash-table-p result) "Outer is hash-table")
    (true (hash-table-p (gethash "outer" result)) "Inner is hash-table")
    (is equal "value" (gethash "inner" (gethash "outer" result)) "Nested value")))

;;; ---------------------------------------------------------------------------
;;; Complex & empty key tests
;;; ---------------------------------------------------------------------------

(define-test complex-keys
  :parent yaml-parther
  :description "Complex and empty key parsing.")

(define-test flow-sequence-as-key
  :parent complex-keys
  :description "Flow sequence used as mapping key"
  (let ((result (yaml:parse "? [a, b]
: value")))
    (true (hash-table-p result) "Result is hash-table")
    (is = 1 (hash-table-count result) "One entry")))

(define-test flow-mapping-as-key
  :parent complex-keys
  :description "Flow mapping used as mapping key"
  (let ((result (yaml:parse "? {a: 1}
: value")))
    (true (hash-table-p result) "Result is hash-table")
    (is = 1 (hash-table-count result) "One entry")))

(define-test empty-key-with-value
  :parent complex-keys
  :description "Empty key (? :) with a value"
  (let ((result (yaml:parse "? : value")))
    (true (hash-table-p result) "Result is hash-table")
    (is equal "value" (gethash 'null result) "null key maps to value")))

(define-test quoted-string-as-key
  :parent complex-keys
  :description "Quoted string as explicit key"
  (let ((result (yaml:parse "? 'hello world'
: value")))
    (true (hash-table-p result) "Result is hash-table")
    (is equal "value" (gethash "hello world" result) "quoted key works")))

;;; ---------------------------------------------------------------------------
;;; Edge / boundary case tests
;;; ---------------------------------------------------------------------------

(define-test edge-cases
  :parent yaml-parther
  :description "Edge and boundary case parsing.")

(define-test empty-document
  :parent edge-cases
  :description "Zero-document streams signal; a bare --- is one null document"
  ;; YAML 1.2: a stream may contain ZERO documents. Single-document PARSE has
  ;; nothing to return for an empty / whitespace-only / comment-only stream, so
  ;; it must SIGNAL loudly rather than invent a null.
  (fail (yaml:parse "") 'yaml:yaml-parse-error)
  (fail (yaml:parse "   ") 'yaml:yaml-parse-error)
  (fail (yaml:parse "
") 'yaml:yaml-parse-error)
  ;; PARSE-ALL returns a vector with exactly one element per actual document;
  ;; a zero-document stream is the EMPTY vector.
  (is equalp #() (yaml:parse-all "") "Empty stream is zero documents")
  ;; A bare `---` document-start indicator with no content is ONE null document.
  (is eq 'null (yaml:parse "---") "Bare --- is a single null document"))

(define-test deeply-nested-flow
  :parent edge-cases
  :description "Deeply nested flow structures"
  (let ((result (yaml:parse "[[[1]]]")))
    (true (vectorp result) "Outer is vector")
    (true (vectorp (aref result 0)) "Middle is vector")
    (true (vectorp (aref (aref result 0) 0)) "Inner is vector")
    (is = 1 (aref (aref (aref result 0) 0) 0) "Value is 1")))

(define-test trailing-whitespace-scalar
  :parent edge-cases
  :description "Trailing whitespace in plain scalar"
  (let ((result (yaml:parse "key: value   ")))
    (is equal "value" (gethash "key" result) "Trailing whitespace trimmed")))

(define-test unicode-scalar
  :parent edge-cases
  :description "Unicode characters in scalars"
  (is equal "hello" (yaml:parse "\"hello\"") "Basic string")
  (is equal "αβγ" (yaml:parse "\"\\u03B1\\u03B2\\u03B3\"") "Greek via unicode escapes"))

(define-test mixed-flow-and-block
  :parent edge-cases
  :description "Flow collection inside block structure"
  (let ((result (yaml:parse "key: [1, 2, 3]")))
    (true (hash-table-p result) "Outer is mapping")
    (true (vectorp (gethash "key" result)) "Value is sequence")
    (is equalp #(1 2 3) (gethash "key" result) "Sequence contents")))

(define-test single-value-document
  :parent edge-cases
  :description "Document with single scalar value"
  (is = 42 (yaml:parse "42") "Numeric scalar")
  (is eq t (yaml:parse "true") "Boolean scalar")
  (is equal "hello" (yaml:parse "hello") "String scalar"))

(define-test flow-with-extra-spaces
  :parent edge-cases
  :description "Flow collections with extra whitespace"
  (let ((result (yaml:parse "[  1  ,  2  ,  3  ]")))
    (is equalp #(1 2 3) result "Spaces around items handled"))
  (let ((result (yaml:parse "{  a  :  1  ,  b  :  2  }")))
    (is = 1 (gethash "a" result) "Spaces in mapping")
    (is = 2 (gethash "b" result) "Second pair")))

(defun run ()
  "Run the whole suite. Convenience entry point for `ros run`."
  (parachute:test '#:yaml-parther/test))
