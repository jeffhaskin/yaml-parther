;;;; directives.lisp --- Tests for YAML directives.
;;;;
;;;; Tests for %YAML version and %TAG handle declarations.

(in-package #:yaml-parther/test)

(define-test directives
  :parent yaml-parther
  :description "YAML directive parsing (%YAML, %TAG).")

;;; ---------------------------------------------------------------------------
;;; %YAML directive parsing
;;; ---------------------------------------------------------------------------

(define-test parse-yaml-directive
  :parent directives
  :description "Parse %YAML version directive"
  (let* ((src (yaml-parther::make-source "%YAML 1.2
"))
         (result (yaml-parther::parse-yaml-directive src)))
    (is = 1 (car result) "Major version is 1")
    (is = 2 (cdr result) "Minor version is 2")))

(define-test parse-yaml-directive-version-1.1
  :parent directives
  :description "Parse %YAML 1.1 version"
  (let* ((src (yaml-parther::make-source "%YAML 1.1
"))
         (result (yaml-parther::parse-yaml-directive src)))
    (is = 1 (car result) "Major version is 1")
    (is = 1 (cdr result) "Minor version is 1")))

(define-test parse-yaml-directive-errors-on-invalid
  :parent directives
  :description "Error on malformed %YAML directive"
  (let ((src (yaml-parther::make-source "%YAML foo")))
    (fail (yaml-parther::parse-yaml-directive src) 'yaml-parther:yaml-directive-error
          "Invalid version format signals error")))

;;; ---------------------------------------------------------------------------
;;; %TAG directive parsing
;;; ---------------------------------------------------------------------------

(define-test parse-tag-directive
  :parent directives
  :description "Parse %TAG directive"
  (let* ((src (yaml-parther::make-source "%TAG !yaml! tag:yaml.org,2002:
"))
         (result (yaml-parther::parse-tag-directive src)))
    (is string= "!yaml!" (car result) "Handle is !yaml!")
    (is string= "tag:yaml.org,2002:" (cdr result) "Prefix is tag:yaml.org,2002:")))

(define-test parse-tag-directive-secondary
  :parent directives
  :description "Parse %TAG !! secondary handle"
  (let* ((src (yaml-parther::make-source "%TAG !! tag:yaml.org,2002:
"))
         (result (yaml-parther::parse-tag-directive src)))
    (is string= "!!" (car result) "Handle is !!")
    (is string= "tag:yaml.org,2002:" (cdr result) "Prefix is tag:yaml.org,2002:")))

(define-test parse-tag-directive-named
  :parent directives
  :description "Parse %TAG with named handle"
  (let* ((src (yaml-parther::make-source "%TAG !e! tag:example.com:
"))
         (result (yaml-parther::parse-tag-directive src)))
    (is string= "!e!" (car result) "Handle is !e!")
    (is string= "tag:example.com:" (cdr result) "Prefix is tag:example.com:")))
