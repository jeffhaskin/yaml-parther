;;;; packages.lisp --- Test package.
;;;;
;;;; Imports only the Parachute API we use, to avoid surprises from :USE.

(defpackage #:yaml-parther/test
  (:use #:cl)
  (:import-from #:parachute
                #:define-test
                #:true
                #:is
                #:fail)
  (:export #:run))
