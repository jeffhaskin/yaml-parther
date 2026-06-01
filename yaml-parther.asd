;;;; yaml-parther.asd --- System definitions for the yaml-parther library.
;;;;
;;;; Two systems live here, by design:
;;;;   :yaml-parther       the delivered library -- ZERO runtime dependencies.
;;;;   :yaml-parther/test  the test suite -- depends on Parachute (test only).
;;;;
;;;; Keeping Parachute out of the delivered system's dependency graph is what
;;;; makes the "zero dependencies" promise literally true for consumers.
;;;;
;;;; Run the tests with Roswell:
;;;;   ros run -- --eval '(asdf:test-system :yaml-parther)' --quit

(asdf:defsystem #:yaml-parther
  :description "A from-scratch, zero-dependency YAML 1.2 parser and emitter for Common Lisp."
  :author "Jeff Haskin <jeffhaskin1@gmail.com>"
  :license "TODO: choose a license"
  :version "0.0.1"
  :serial t
  :pathname "src/"
  :components ((:file "packages")
               (:file "conditions")
               (:file "source")
               (:file "resolve")
               (:file "tags")
               (:file "reader")
               (:file "emit")
               (:file "api"))
  :in-order-to ((test-op (test-op #:yaml-parther/test))))

(asdf:defsystem #:yaml-parther/test
  :description "Parachute test suite for yaml-parther."
  :author "Jeff Haskin <jeffhaskin1@gmail.com>"
  :license "TODO: choose a license"
  :depends-on (#:yaml-parther #:parachute)
  :serial t
  :pathname "test/"
  :components ((:file "packages")
               (:file "main")
               (:file "comments")
               (:file "document-framing")
               (:file "directives")
               (:file "tags")
               (:file "quoted-scalars")
               (:file "explicit-keys")
               (:file "complex-keys")
               (:file "yaml-version")
               (:file "invalid-input")
               (:file "conformance-data")
               (:file "conformance"))
  :perform (test-op (op c)
             (uiop:symbol-call '#:parachute '#:test '#:yaml-parther/test)))
