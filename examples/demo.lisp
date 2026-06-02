;;;; examples/demo.lisp --- A quick taste of yaml-parther.
;;;; Run:  ros run -- --eval '(ql:register-local-projects)' \
;;;;                  --eval '(ql:quickload :yaml-parther :silent t)' \
;;;;                  --load examples/demo.lisp --quit

(let ((doc (yaml:parse "name: yaml-parther
version: 1
stable: true
meta: null
tags:
  - lisp
  - parser
author:
  name: jeff
  rating: 4.5")))
  (format t "~&top-level type : ~A~%" (type-of doc))
  (format t "name           : ~S~%" (gethash "name" doc))
  (format t "version        : ~S  (~A)~%" (gethash "version" doc) (type-of (gethash "version" doc)))
  (format t "stable         : ~S~%" (gethash "stable" doc))
  (format t "meta           : ~S  (YAML null)~%" (gethash "meta" doc))
  (format t "tags           : ~S  (~A)~%" (gethash "tags" doc) (type-of (gethash "tags" doc)))
  (format t "author.rating  : ~S~%" (gethash "rating" (gethash "author" doc))))

(format t "~%multi-document : ~S~%"
        (yaml:parse-all "---
a: 1
---
b: 2"))

(handler-case (yaml:parse "")
  (yaml:yaml-error (e)
    (format t "~%empty input    : signals ~A -- ~A~%" (type-of e) e)))
