;;;; demo/server.lisp --- Local demo web server for yaml-parther.
;;;;
;;;; NOT part of the delivered library. Serves the demo UI and a single JSON
;;;; endpoint that runs the REAL parser and walks the resulting Common Lisp
;;;; value into the typed-JSON contract the front end renders.
;;;;
;;;; Run:
;;;;   sbcl --load demo/server.lisp          (or: ros run --load demo/server.lisp)
;;;; Then open http://localhost:8080
;;;;
;;;; Loaded interpreted (top-level form by form) so the web packages exist by
;;;; the time later forms reference them.

;;; --------------------------------------------------------------------------
;;; Bootstrap: Quicklisp + the parser + the demo-only web stack.
;;; --------------------------------------------------------------------------
(require :asdf)

(defpackage #:yaml-demo (:use #:cl))
(in-package #:yaml-demo)

(defparameter *demo-dir*
  (uiop:pathname-directory-pathname (or *load-pathname* *compile-file-pathname*
                                        (truename "demo/"))))
(defparameter *repo-root* (uiop:pathname-parent-directory-pathname *demo-dir*))

(unless (find-package :quicklisp)
  (loop for p in (list (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))
                       (merge-pathnames ".roswell/lisp/quicklisp/setup.lisp"
                                        (user-homedir-pathname)))
        when (probe-file p) do (load p) (return)))
(unless (find-package :quicklisp)
  (error "Quicklisp not found. Install it, or run with `ros run --load demo/server.lisp`."))

(pushnew *repo-root* asdf:*central-registry* :test #'equal)
(funcall (intern "QUICKLOAD" :quicklisp)
         '(:yaml-parther :hunchentoot :com.inuoe.jzon) :silent t)

;;; --------------------------------------------------------------------------
;;; The value -> typed-JSON walker (the frozen /api/parse contract).
;;; --------------------------------------------------------------------------
(defun jobj (&rest kvs)
  "Build a string-keyed hash-table (jzon serializes it as a JSON object).
Order of insertion is irrelevant to the contract."
  (let ((h (make-hash-table :test 'equal)))
    (loop for (k v) on kvs by #'cddr do (setf (gethash k h) v))
    h))

(defun repl-of (value)
  "The genuine Lisp printed form, under the disclosed print environment."
  (let ((*print-readably* nil)
        (*print-pretty* t)
        (*print-level* 12)
        (*print-length* 200))
    (prin1-to-string value)))

(defun node (value)
  "Walk one native Lisp value into a typed-JSON NODE per the contract.
Detection order matters: the NULL/T/NIL symbols are checked before the
structural types, and STRING before VECTOR (a string is a vector)."
  (cond
    ((eq value 'cl:null) (jobj "type" "null"  "repl" "NULL"))
    ((eq value t)        (jobj "type" "true"  "repl" "T"))
    ((null value)        (jobj "type" "false" "repl" "NIL"))
    ((hash-table-p value)
     (let ((entries (make-array 0 :adjustable t :fill-pointer 0)))
       (maphash (lambda (k v)
                  (vector-push-extend (jobj "key" (node k) "val" (node v)) entries))
                value)
       (jobj "type" "hash-table"
             "test" (string-upcase (symbol-name (hash-table-test value)))
             "childCount" (hash-table-count value)
             "repl" (repl-of value)
             "entries" entries)))
    ((stringp value)
     (jobj "type" "string" "value" value "repl" (repl-of value)))
    ((and (vectorp value) (not (stringp value)))
     (let ((items (make-array (length value))))
       (dotimes (i (length value))
         (setf (aref items i) (node (aref value i))))
       (jobj "type" "vector"
             "childCount" (length value)
             "repl" (repl-of value)
             "items" items)))
    ((integerp value)
     (jobj "type" "integer" "value" value
           "lisp" (princ-to-string value) "repl" (repl-of value)))
    ((floatp value)
     (jobj "type" "float" "value" (coerce value 'double-float)
           "lisp" (repl-of value) "repl" (repl-of value)))
    (t ;; any other Lisp object: present its printed form as a string node
     (jobj "type" "string" "value" (princ-to-string value) "repl" (repl-of value)))))

(defun count-nodes (value depth)
  "Return (values total-node-count max-depth) for the contract stats line."
  (cond
    ((hash-table-p value)
     (let ((n 1) (maxd depth))
       (maphash (lambda (k v)
                  (multiple-value-bind (kn kd) (count-nodes k (1+ depth))
                    (incf n kn) (setf maxd (max maxd kd)))
                  (multiple-value-bind (vn vd) (count-nodes v (1+ depth))
                    (incf n vn) (setf maxd (max maxd vd))))
                value)
       (values n maxd)))
    ((and (vectorp value) (not (stringp value)))
     (let ((n 1) (maxd depth))
       (loop for x across value do
         (multiple-value-bind (xn xd) (count-nodes x (1+ depth))
           (incf n xn) (setf maxd (max maxd xd))))
       (values n maxd)))
    (t (values 1 depth))))

;;; --------------------------------------------------------------------------
;;; HTTP handlers.
;;; --------------------------------------------------------------------------
(defun handle-parse ()
  "POST /api/parse : { yaml, multi } -> typed-JSON tree (HTTP 200 either way)."
  (setf (hunchentoot:content-type*) "application/json; charset=utf-8")
  (let* ((raw (or (hunchentoot:raw-post-data :force-text t) ""))
         (req (handler-case (com.inuoe.jzon:parse raw)
                (error () (jobj))))
         (yaml-text (if (hash-table-p req) (gethash "yaml" req "") "")))
    (handler-case
        (let* ((docs (yaml:parse-all yaml-text))
               (root-value (cond ((zerop (length docs)) #())
                                 ((= 1 (length docs)) (aref docs 0))
                                 (t docs))))
          (multiple-value-bind (n d) (count-nodes root-value 1)
            (com.inuoe.jzon:stringify
             (jobj "ok" t
                   "stats" (jobj "nodes" n "levels" d "rendered" n)
                   "repl" (repl-of root-value)
                   "root" (node root-value)))))
      (yaml:yaml-error (e)
        (let ((pos (yaml:yaml-error-position e)))
          (com.inuoe.jzon:stringify
           (jobj "ok" nil
                 "error" (jobj "condition" (string-downcase (symbol-name (type-of e)))
                               "message" (or (yaml:yaml-error-message e)
                                             (princ-to-string e))
                               "line"   (if (consp pos) (or (car pos) 0) 0)
                               "column" (if (consp pos) (or (cdr pos) 0) 0)))))))))

(defun serve-index ()
  (hunchentoot:handle-static-file (merge-pathnames "index.html" *demo-dir*)))

(setf hunchentoot:*dispatch-table*
      (list (hunchentoot:create-prefix-dispatcher "/api/parse" #'handle-parse)
            (hunchentoot:create-regex-dispatcher "^/$" #'serve-index)
            (hunchentoot:create-folder-dispatcher-and-handler "/" *demo-dir*)))

;;; --------------------------------------------------------------------------
;;; Start.
;;; --------------------------------------------------------------------------
(defparameter *port* 8080)
(defvar *acceptor* nil)
(when *acceptor* (ignore-errors (hunchentoot:stop *acceptor*)))
(setf *acceptor* (make-instance 'hunchentoot:easy-acceptor
                                :port *port* :document-root *demo-dir*))
(hunchentoot:start *acceptor*)
(format t "~&~%  yaml-parther workbench live  ->  http://localhost:~D~%~%" *port*)
(force-output)

;; Keep the process alive when run via `sbcl --load` non-interactively.
;; (Interactively, Ctrl-C stops it.)
(loop (sleep 30))
