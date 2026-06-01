;;;; yaml-version.lisp --- Tests for YAML version handling.
;;;;
;;;; Tests for %YAML directive version handling and version-specific behavior.

(in-package #:yaml-parther/test)

(define-test yaml-version
  :parent yaml-parther
  :description "YAML version handling and 1.3 divergence.")

;;; ---------------------------------------------------------------------------
;;; Version variable
;;; ---------------------------------------------------------------------------

(define-test default-yaml-version
  :parent yaml-version
  :description "*yaml-version* defaults to 1.2"
  (is = 1 (car yaml-parther::*yaml-version*)
      "Default major version is 1")
  (is = 2 (cdr yaml-parther::*yaml-version*)
      "Default minor version is 2"))

;;; ---------------------------------------------------------------------------
;;; Parse with version directive
;;; ---------------------------------------------------------------------------

(define-test parse-with-yaml-12
  :parent yaml-version
  :description "%YAML 1.2 document"
  (let ((result (yaml:parse "%YAML 1.2
---
hello")))
    (is string= "hello" result
        "Parses 1.2 document correctly")))

(define-test parse-with-yaml-11
  :parent yaml-version
  :description "%YAML 1.1 document"
  (let ((result (yaml:parse "%YAML 1.1
---
hello")))
    (is string= "hello" result
        "Parses 1.1 document correctly")))
