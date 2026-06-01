;;;; tags.lisp --- Tests for YAML tag handling.
;;;;
;;;; Tests for !!type, !local, and verbatim tag resolution.

(in-package #:yaml-parther/test)

(define-test tag-handling
  :parent yaml-parther
  :description "YAML tag parsing and expansion.")

;;; ---------------------------------------------------------------------------
;;; Tag shorthand expansion
;;; ---------------------------------------------------------------------------

(define-test expand-tag-shorthand-str
  :parent tag-handling
  :description "!!str expands to tag:yaml.org,2002:str"
  (is string= "tag:yaml.org,2002:str"
      (yaml-parther::expand-tag-shorthand "!!" "str" nil)
      "!!str expands to full URI"))

(define-test expand-tag-shorthand-int
  :parent tag-handling
  :description "!!int expands to tag:yaml.org,2002:int"
  (is string= "tag:yaml.org,2002:int"
      (yaml-parther::expand-tag-shorthand "!!" "int" nil)
      "!!int expands to full URI"))

(define-test expand-tag-shorthand-bool
  :parent tag-handling
  :description "!!bool expands to tag:yaml.org,2002:bool"
  (is string= "tag:yaml.org,2002:bool"
      (yaml-parther::expand-tag-shorthand "!!" "bool" nil)))

(define-test expand-tag-shorthand-null
  :parent tag-handling
  :description "!!null expands to tag:yaml.org,2002:null"
  (is string= "tag:yaml.org,2002:null"
      (yaml-parther::expand-tag-shorthand "!!" "null" nil)))

;;; ---------------------------------------------------------------------------
;;; Local tag expansion
;;; ---------------------------------------------------------------------------

(define-test expand-local-tag
  :parent tag-handling
  :description "!foo expands to local tag !foo"
  (is string= "!foo"
      (yaml-parther::expand-tag-shorthand "!" "foo" nil)
      "Local tag passes through with prefix"))

;;; ---------------------------------------------------------------------------
;;; Custom handle from %TAG
;;; ---------------------------------------------------------------------------

(define-test expand-custom-handle
  :parent tag-handling
  :description "Custom %TAG handle expands correctly"
  (let ((handles '(("!e!" . "tag:example.com:"))))
    (is string= "tag:example.com:mytype"
        (yaml-parther::expand-tag-shorthand "!e!" "mytype" handles)
        "Custom handle uses registered prefix")))

;;; ---------------------------------------------------------------------------
;;; Verbatim tags
;;; ---------------------------------------------------------------------------

(define-test parse-verbatim-tag
  :parent tag-handling
  :description "!<uri> returns verbatim tag"
  (is string= "tag:yaml.org,2002:str"
      (yaml-parther::parse-verbatim-tag "!<tag:yaml.org,2002:str>")
      "Verbatim tag extracts URI"))

;;; ---------------------------------------------------------------------------
;;; Parse tag from source
;;; ---------------------------------------------------------------------------

(define-test read-tag-shorthand
  :parent tag-handling
  :description "Read !!str tag from source"
  (let* ((src (yaml-parther::make-source "!!str hello"))
         (tag (yaml-parther::read-tag src nil)))
    (is string= "tag:yaml.org,2002:str" tag
        "!!str reads and expands correctly")))
