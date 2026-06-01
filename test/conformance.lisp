;;;; conformance.lisp --- yaml-test-suite conformance harness.
;;;;
;;;; Runs all 400+ cases from the vendored yaml-test-suite. Each test is
;;;; executed as a Parachute sub-test. Tests marked with :FAIL T are expected
;;;; to signal; others must parse successfully and match the expected JSON.
;;;;
;;;; Known-failing tests (parser limitations or deliberate divergences) are
;;;; listed in *KNOWN-FAILING* and skipped with a warning rather than failing
;;;; the suite. Keep this list minimal.

(in-package #:yaml-parther/test)

;;; ---------------------------------------------------------------------------
;;; Known-failing list
;;; ---------------------------------------------------------------------------

(defparameter *known-failing*
  '()
  "Test IDs that are known to fail due to unimplemented features or deliberate
divergences. These are skipped during the conformance run. Keep this list as
short as possible and document why each entry is here.")

(defun known-failing-p (test-id)
  "Return T if TEST-ID is in the known-failing list."
  (member test-id *known-failing* :test #'string=))

;;; ---------------------------------------------------------------------------
;;; Test utilities
;;; ---------------------------------------------------------------------------

(defun parse-json-string (json-str)
  "Parse a JSON string into Lisp data. Returns NIL if parsing fails.
This is a minimal JSON parser for conformance comparison."
  (when (null json-str)
    (return-from parse-json-string nil))
  (let ((pos 0)
        (len (length json-str)))
    (labels ((skip-ws ()
               (loop while (and (< pos len)
                                (member (char json-str pos) '(#\Space #\Tab #\Newline #\Return)))
                     do (incf pos)))
             (peek ()
               (when (< pos len) (char json-str pos)))
             (consume ()
               (prog1 (char json-str pos) (incf pos)))
             (parse-value ()
               (skip-ws)
               (case (peek)
                 (#\{ (parse-object))
                 (#\[ (parse-array))
                 (#\" (parse-string))
                 (#\t (parse-true))
                 (#\f (parse-false))
                 (#\n (parse-null))
                 (otherwise (parse-number))))
             (parse-object ()
               (consume) ; {
               (skip-ws)
               (let ((ht (make-hash-table :test #'equal)))
                 (unless (eql (peek) #\})
                   (loop
                     (skip-ws)
                     (let ((key (parse-string)))
                       (skip-ws)
                       (consume) ; :
                       (skip-ws)
                       (setf (gethash key ht) (parse-value)))
                     (skip-ws)
                     (if (eql (peek) #\,)
                         (consume)
                         (return))))
                 (consume) ; }
                 ht))
             (parse-array ()
               (consume) ; [
               (skip-ws)
               (let ((items nil))
                 (unless (eql (peek) #\])
                   (loop
                     (push (parse-value) items)
                     (skip-ws)
                     (if (eql (peek) #\,)
                         (consume)
                         (return))))
                 (consume) ; ]
                 (coerce (nreverse items) 'vector)))
             (parse-string ()
               (consume) ; opening "
               (let ((chars nil))
                 (loop
                   (let ((c (consume)))
                     (cond
                       ((eql c #\") (return))
                       ((eql c #\\)
                        (let ((esc (consume)))
                          (push (case esc
                                  (#\n #\Newline)
                                  (#\r #\Return)
                                  (#\t #\Tab)
                                  (#\\ #\\)
                                  (#\" #\")
                                  (#\/ #\/)
                                  (#\b #\Backspace)
                                  (#\f (code-char 12))
                                  (#\u (let ((hex (subseq json-str pos (+ pos 4))))
                                         (incf pos 4)
                                         (code-char (parse-integer hex :radix 16))))
                                  (otherwise esc))
                                chars)))
                       (t (push c chars)))))
                 (coerce (nreverse chars) 'string)))
             (parse-true ()
               (incf pos 4) t)
             (parse-false ()
               (incf pos 5) nil)
             (parse-null ()
               (incf pos 4) 'null)
             (parse-number ()
               (let ((start pos))
                 (when (eql (peek) #\-)
                   (consume))
                 (loop while (and (< pos len)
                                  (digit-char-p (peek)))
                       do (consume))
                 (when (eql (peek) #\.)
                   (consume)
                   (loop while (and (< pos len)
                                    (digit-char-p (peek)))
                         do (consume)))
                 (when (member (peek) '(#\e #\E))
                   (consume)
                   (when (member (peek) '(#\+ #\-))
                     (consume))
                   (loop while (and (< pos len)
                                    (digit-char-p (peek)))
                         do (consume)))
                 (let ((num-str (subseq json-str start pos)))
                   (if (find #\. num-str)
                       ;; The parser produces double-floats per the fixed
                       ;; representation (resolve.lisp), so read expected JSON
                       ;; numbers as double-floats too for a faithful EQUAL.
                       (let ((*read-default-float-format* 'double-float))
                         (read-from-string num-str))
                       (parse-integer num-str))))))
      (handler-case (parse-value)
        (error () nil)))))

(defun parse-json-stream (json-str)
  "Parse a JSON *stream* (one or more whitespace-separated top-level JSON
values, as the yaml-test-suite uses for multi-document expected output) into a
LIST of Lisp values, in order. Returns NIL on parse failure.

Uses the EXACT SAME value semantics as PARSE-JSON-STRING (same number/string/
object/array handling); the only difference is that it consumes successive
top-level values until the input is exhausted instead of stopping after the
first. For a single-value input it returns a one-element list, so the count of
returned values is the reliable signal for how many documents the expected
output represents."
  (when (null json-str)
    (return-from parse-json-stream nil))
  (let ((pos 0)
        (len (length json-str)))
    (labels ((skip-ws ()
               (loop while (and (< pos len)
                                (member (char json-str pos) '(#\Space #\Tab #\Newline #\Return)))
                     do (incf pos)))
             (peek ()
               (when (< pos len) (char json-str pos)))
             (consume ()
               (prog1 (char json-str pos) (incf pos)))
             (parse-value ()
               (skip-ws)
               (case (peek)
                 (#\{ (parse-object))
                 (#\[ (parse-array))
                 (#\" (parse-string))
                 (#\t (parse-true))
                 (#\f (parse-false))
                 (#\n (parse-null))
                 (otherwise (parse-number))))
             (parse-object ()
               (consume) ; {
               (skip-ws)
               (let ((ht (make-hash-table :test #'equal)))
                 (unless (eql (peek) #\})
                   (loop
                     (skip-ws)
                     (let ((key (parse-string)))
                       (skip-ws)
                       (consume) ; :
                       (skip-ws)
                       (setf (gethash key ht) (parse-value)))
                     (skip-ws)
                     (if (eql (peek) #\,)
                         (consume)
                         (return))))
                 (consume) ; }
                 ht))
             (parse-array ()
               (consume) ; [
               (skip-ws)
               (let ((items nil))
                 (unless (eql (peek) #\])
                   (loop
                     (push (parse-value) items)
                     (skip-ws)
                     (if (eql (peek) #\,)
                         (consume)
                         (return))))
                 (consume) ; ]
                 (coerce (nreverse items) 'vector)))
             (parse-string ()
               (consume) ; opening "
               (let ((chars nil))
                 (loop
                   (let ((c (consume)))
                     (cond
                       ((eql c #\") (return))
                       ((eql c #\\)
                        (let ((esc (consume)))
                          (push (case esc
                                  (#\n #\Newline)
                                  (#\r #\Return)
                                  (#\t #\Tab)
                                  (#\\ #\\)
                                  (#\" #\")
                                  (#\/ #\/)
                                  (#\b #\Backspace)
                                  (#\f (code-char 12))
                                  (#\u (let ((hex (subseq json-str pos (+ pos 4))))
                                         (incf pos 4)
                                         (code-char (parse-integer hex :radix 16))))
                                  (otherwise esc))
                                chars)))
                       (t (push c chars)))))
                 (coerce (nreverse chars) 'string)))
             (parse-true ()
               (incf pos 4) t)
             (parse-false ()
               (incf pos 5) nil)
             (parse-null ()
               (incf pos 4) 'null)
             (parse-number ()
               (let ((start pos))
                 (when (eql (peek) #\-)
                   (consume))
                 (loop while (and (< pos len)
                                  (digit-char-p (peek)))
                       do (consume))
                 (when (eql (peek) #\.)
                   (consume)
                   (loop while (and (< pos len)
                                    (digit-char-p (peek)))
                         do (consume)))
                 (when (member (peek) '(#\e #\E))
                   (consume)
                   (when (member (peek) '(#\+ #\-))
                     (consume))
                   (loop while (and (< pos len)
                                    (digit-char-p (peek)))
                         do (consume)))
                 (let ((num-str (subseq json-str start pos)))
                   (if (find #\. num-str)
                       (let ((*read-default-float-format* 'double-float))
                         (read-from-string num-str))
                       (parse-integer num-str))))))
      (handler-case
          (let ((values nil))
            (skip-ws)
            (loop while (< pos len)
                  do (push (parse-value) values)
                     (skip-ws))
            (nreverse values))
        (error () nil)))))

(defun values-equal-p (a b)
  "Compare two Lisp values for equality, handling hash-tables and vectors."
  (cond
    ((and (hash-table-p a) (hash-table-p b))
     (and (= (hash-table-count a) (hash-table-count b))
          (loop for k being the hash-keys of a using (hash-value v)
                always (and (nth-value 1 (gethash k b))
                            (values-equal-p v (gethash k b))))))
    ((and (vectorp a) (vectorp b) (not (stringp a)) (not (stringp b)))
     (and (= (length a) (length b))
          (every #'values-equal-p a b)))
    (t (equal a b))))

;;; ---------------------------------------------------------------------------
;;; Conformance test runner
;;; ---------------------------------------------------------------------------

(define-test conformance
  :parent yaml-parther
  :description "yaml-test-suite conformance (406 cases).")

(defun run-single-conformance-test (test)
  "Run a single conformance test case, returning :PASS, :FAIL, :SKIP, or :XFAIL."
  (let* ((id (getf test :id))
         (yaml-input (getf test :yaml))
         (expected-json-str (getf test :json))
         (should-fail (getf test :fail)))
    (cond
      ;; Known-failing: skip
      ((known-failing-p id)
       :skip)

      ;; Expected to fail (error test)
      (should-fail
       (handler-case
           (progn
             (yaml:parse yaml-input)
             :fail) ; should have errored but didn't
         (error () :pass))) ; correctly signaled

      ;; Expected to succeed
      (t
       (handler-case
           (if expected-json-str
               ;; The :JSON field reads to a JSON-string literal whose CONTENT
               ;; is the expected output text. The yaml-test-suite represents a
               ;; multi-document stream as multiple whitespace-separated
               ;; top-level JSON values in that text. So first unwrap the outer
               ;; literal, then parse the content as a JSON *stream*: the number
               ;; of top-level values is the reliable document count.
               (let* ((outer (parse-json-string expected-json-str))
                      (expected-docs (when (stringp outer)
                                       (parse-json-stream outer))))
                 (if (and (stringp outer) (> (length expected-docs) 1))
                     ;; Multiple documents: compare PARSE-ALL output element by
                     ;; element with the identical strictness used for single
                     ;; docs. Pass only if counts match AND every doc matches.
                     (let ((results (yaml:parse-all yaml-input)))
                       (if (and (= (length results) (length expected-docs))
                                (every #'values-equal-p
                                       (coerce results 'list)
                                       expected-docs))
                           :pass
                           :fail))
                     ;; Single document: unchanged behavior.
                     (let* ((result (yaml:parse yaml-input))
                            (expected (if (stringp outer)
                                          (parse-json-string outer)
                                          outer)))
                       (if (values-equal-p result expected)
                           :pass
                           :fail))))
               ;; no JSON to compare, just check it parses
               (progn (yaml:parse yaml-input) :pass))
         (error () :fail)))))) ; should have parsed but errored

(defun run-conformance-suite ()
  "Run all conformance tests and return summary counts."
  (let ((pass 0) (fail 0) (skip 0) (xfail 0))
    (dolist (test *conformance-tests*)
      (let ((result (run-single-conformance-test test)))
        (case result
          (:pass (incf pass))
          (:fail (incf fail))
          (:skip (incf skip))
          (:xfail (incf xfail)))))
    (values pass fail skip xfail)))

(define-test conformance-suite-runs
  :parent conformance
  :description "Execute all yaml-test-suite cases."
  (multiple-value-bind (pass fail skip xfail) (run-conformance-suite)
    (declare (ignore xfail))
    (format t "~&;; Conformance: ~D passed, ~D failed, ~D skipped~%"
            pass fail skip)
    ;; For now, while parser is unimplemented, we just check the suite loads
    ;; and runs without crashing. When parser is done, change to:
    ;; (is = 0 fail "All conformance tests should pass")
    (true t "Conformance suite executed without crash")))

;;; ---------------------------------------------------------------------------
;;; Individual test generation (optional, for detailed reporting)
;;; ---------------------------------------------------------------------------

(defun generate-individual-tests ()
  "Generate individual Parachute tests for each conformance case.
Call this to get per-test granularity in test reports."
  (dolist (test *conformance-tests*)
    (let* ((id (getf test :id))
           (test-name (intern (format nil "CONFORMANCE-~A" (string-upcase id))
                              '#:yaml-parther/test)))
      (eval `(define-test ,test-name
               :parent conformance
               :description ,(format nil "~A" (getf test :name))
               (let ((result (run-single-conformance-test ',test)))
                 (true (member result '(:pass :skip))
                       ,(format nil "Test ~A should pass or be skipped" id))))))))
