;;;; comments.lisp --- Tests for comment handling.

(in-package #:yaml-parther/test)

(define-test comments
  :parent yaml-parther
  :description "Comment stripping tests.")

(define-test source-skip-comment-basic
  :parent comments
  :description "source-skip-comment skips from # to end of line"
  (let ((src (yaml-parther::make-source (format nil "# a comment~%rest"))))
    (is = 11 (yaml-parther::source-skip-comment src))
    (is char= #\Newline (yaml-parther::source-peek src))))

(define-test source-skip-comment-no-comment
  :parent comments
  :description "source-skip-comment returns 0 when no # present"
  (let ((src (yaml-parther::make-source "not a comment")))
    (is = 0 (yaml-parther::source-skip-comment src))
    (is char= #\n (yaml-parther::source-peek src))))

(define-test source-skip-comment-preserves-linebreak
  :parent comments
  :description "source-skip-comment does not consume the line break"
  (let ((src (yaml-parther::make-source (format nil "#comment~%next"))))
    (yaml-parther::source-skip-comment src)
    (is char= #\Newline (yaml-parther::source-peek src))
    (yaml-parther::source-advance src)
    (is char= #\n (yaml-parther::source-peek src))))

(define-test source-skip-whitespace-and-comments-basic
  :parent comments
  :description "source-skip-whitespace-and-comments skips space then comment"
  (let ((src (yaml-parther::make-source (format nil "  # comment~%next"))))
    (yaml-parther::source-skip-whitespace-and-comments src)
    (is char= #\n (yaml-parther::source-peek src))))

(define-test source-skip-whitespace-and-comments-multiline
  :parent comments
  :description "source-skip-whitespace-and-comments skips multiple lines"
  (let ((src (yaml-parther::make-source (format nil "# line1~%  # line2~%  # line3~%content"))))
    (is = 3 (yaml-parther::source-skip-whitespace-and-comments src))
    (is char= #\c (yaml-parther::source-peek src))))

(define-test source-skip-whitespace-and-comments-blank-lines
  :parent comments
  :description "source-skip-whitespace-and-comments handles blank lines between comments"
  (let ((src (yaml-parther::make-source (format nil "# comment1~%~%# comment2~%value"))))
    (is = 3 (yaml-parther::source-skip-whitespace-and-comments src))
    (is char= #\v (yaml-parther::source-peek src))))

(define-test trailing-comment-sequence
  :parent comments
  :description "skip blanks then skip comment handles trailing comments"
  (let ((src (yaml-parther::make-source (format nil "value  # trailing comment~%next"))))
    (dotimes (i 5) (yaml-parther::source-advance src))
    (yaml-parther::source-skip-blanks src)
    (is char= #\# (yaml-parther::source-peek src))
    (yaml-parther::source-skip-comment src)
    (is char= #\Newline (yaml-parther::source-peek src))))
