;;;; document-framing.lisp --- Tests for document start/end markers.
;;;;
;;;; Tests for `---` (document start) and `...` (document end) marker detection
;;;; and multi-document stream handling.

(in-package #:yaml-parther/test)

(define-test document-framing
  :parent yaml-parther
  :description "Document start/end markers and multi-document streams.")

;;; ---------------------------------------------------------------------------
;;; Low-level marker detection
;;; ---------------------------------------------------------------------------

(define-test source-match-document-start
  :parent document-framing
  :description "source-match-document-start detects --- followed by boundary"
  (let ((src (yaml-parther::make-source "---
")))
    (true (yaml-parther::source-match-document-start src)
          "--- followed by newline is a document start")))

(define-test source-match-document-start-requires-boundary
  :parent document-framing
  :description "source-match-document-start requires whitespace/newline/EOF after ---"
  (let ((src (yaml-parther::make-source "---x")))
    (is eq nil (yaml-parther::source-match-document-start src)
        "---x is not a document start (no boundary)")
    (is = 0 (yaml-parther::source-index src)
        "Cursor should not advance on failed match")))

(define-test source-match-document-end
  :parent document-framing
  :description "source-match-document-end detects ... followed by boundary"
  (let ((src (yaml-parther::make-source "...
")))
    (true (yaml-parther::source-match-document-end src)
          "... followed by newline is a document end")))

(define-test source-match-document-end-requires-boundary
  :parent document-framing
  :description "source-match-document-end requires whitespace/newline/EOF after ..."
  (let ((src (yaml-parther::make-source "...x")))
    (is eq nil (yaml-parther::source-match-document-end src)
        "...x is not a document end (no boundary)")
    (is = 0 (yaml-parther::source-index src)
        "Cursor should not advance on failed match")))

;;; ---------------------------------------------------------------------------
;;; High-level parse tests
;;; ---------------------------------------------------------------------------

(define-test parse-empty-string
  :parent document-framing
  :description "Empty input parses to null"
  (is eq 'null (yaml:parse "")
      "Empty string returns null"))

(define-test parse-implicit-document
  :parent document-framing
  :description "Single value without markers"
  (is string= "hello" (yaml:parse "hello")
      "Plain scalar without document markers"))

(define-test parse-explicit-document-start
  :parent document-framing
  :description "Document with --- marker"
  (is string= "hello" (yaml:parse "---
hello")
      "--- followed by content"))

(define-test parse-document-with-end-marker
  :parent document-framing
  :description "Document with both --- and ..."
  (is string= "hello" (yaml:parse "---
hello
...")
      "--- content ... pattern"))

(define-test parse-all-empty-string
  :parent document-framing
  :description "Empty input returns empty vector"
  (is = 0 (length (yaml:parse-all ""))
      "Empty string returns empty vector"))

(define-test parse-all-single-document
  :parent document-framing
  :description "Single document in vector"
  (let ((docs (yaml:parse-all "hello")))
    (is = 1 (length docs)
        "Single document produces length-1 vector")
    (is string= "hello" (aref docs 0)
        "Content is preserved")))

(define-test parse-all-two-documents
  :parent document-framing
  :description "Two documents separated by ---"
  (let ((docs (yaml:parse-all "hello
---
world")))
    (is = 2 (length docs)
        "Two documents separated by ---")
    (is string= "hello" (aref docs 0))
    (is string= "world" (aref docs 1))))

(define-test parse-all-with-end-markers
  :parent document-framing
  :description "Documents with ... and ---"
  (let ((docs (yaml:parse-all "hello
...
---
world")))
    (is = 2 (length docs)
        "... then --- separates documents")))
