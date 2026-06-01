;;;; packages.lisp --- Package definition and the exported public surface.
;;;;
;;;; The exported surface lives in exactly one place (here). YAML `null`
;;;; resolves to the symbol CL:NULL, which is already accessible in every
;;;; package, so it is not (and need not be) re-exported.

(defpackage #:yaml-parther
  (:nicknames #:yaml)
  (:use #:cl)
  (:export
   ;; --- public verbs (implemented in api.lisp) ---
   #:parse
   #:parse-all
   #:parse-file
   ;; --- failure taxonomy (conditions.lisp) ---
   #:yaml-error
   #:yaml-error-message
   #:yaml-error-position
   ;; parse-time conditions
   #:yaml-parse-error
   #:yaml-scanner-error
   #:yaml-structure-error
   #:yaml-reference-error
   #:yaml-reference-error-anchor
   #:yaml-tag-error
   #:yaml-tag-error-tag
   #:yaml-directive-error
   #:yaml-duplicate-key-error
   #:yaml-duplicate-key-error-key
   ;; emit-time conditions
   #:yaml-emit-error
   #:yaml-circular-error))
