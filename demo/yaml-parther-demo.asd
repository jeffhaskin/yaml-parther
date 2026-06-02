;;;; yaml-parther-demo.asd --- Demo web server system (NOT the delivered library).
;;;;
;;;; This system exists so the demo's dependencies live HERE, isolated from the
;;;; delivered `yaml-parther.asd`, which stays ZERO-dependency. Loading this
;;;; system pulls the parser plus the demo-only web stack (Hunchentoot + jzon).
;;;;
;;;; The runnable entry point is `demo/server.lisp`, which self-bootstraps
;;;; Quicklisp and these deps so it works under a bare `sbcl --load`:
;;;;
;;;;   sbcl --load demo/server.lisp        ;; or: ros run --load demo/server.lisp
;;;;
;;;; server.lisp is deliberately NOT an ASDF component (it is loaded
;;;; interpreted, top-level form by form, so the web packages exist by the time
;;;; later forms reference them).

(asdf:defsystem #:yaml-parther-demo
  :description "Local demo web server for yaml-parther. Not part of the zero-dependency library."
  :author "Jeff Haskin <jeffhaskin1@gmail.com>"
  :license "same as yaml-parther"
  :version "0.1.0"
  :depends-on (#:yaml-parther #:hunchentoot #:com.inuoe.jzon))
