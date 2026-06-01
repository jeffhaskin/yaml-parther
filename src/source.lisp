;;;; source.lisp --- Input cursor and position tracking.
;;;;
;;;; Hides how raw input (a string or a character stream) is traversed and how
;;;; line/column position is tracked. The reader walks input only through this
;;;; interface, so nothing downstream does arithmetic on offsets.

(in-package #:yaml-parther)

(defstruct (source (:constructor %make-source))
  "An input cursor over YAML text, carrying line/column position."
  (text   "" :type string)
  (index  0  :type fixnum)
  (line   1  :type fixnum)
  (column 0  :type fixnum))

(defun make-source (input)
  "Build a SOURCE over INPUT, which is a STRING or a character input STREAM.
Streams are slurped into a string for uniform random-access."
  (let ((text (etypecase input
                (string input)
                (stream (let ((contents (make-string-output-stream)))
                          (loop for char = (read-char input nil nil)
                                while char
                                do (write-char char contents))
                          (get-output-stream-string contents))))))
    (%make-source :text text :index 0 :line 1 :column 0)))

(defun source-eof-p (source)
  "Return T if SOURCE is at end-of-input."
  (>= (source-index source) (length (source-text source))))

(defun source-peek (source &optional (offset 0))
  "Return the character OFFSET positions ahead of the cursor without advancing.
Returns NIL if that position is past end-of-input."
  (let ((pos (+ (source-index source) offset)))
    (if (< pos (length (source-text source)))
        (char (source-text source) pos)
        nil)))

(defun source-advance (source)
  "Consume the current character and advance the cursor.
Updates line/column tracking. Returns the consumed character, or NIL at EOF."
  (when (source-eof-p source)
    (return-from source-advance nil))
  (let ((char (char (source-text source) (source-index source))))
    (incf (source-index source))
    (if (char= char #\Newline)
        (progn
          (incf (source-line source))
          (setf (source-column source) 0))
        (incf (source-column source)))
    char))

(defun source-position (source)
  "Return the current position as (LINE . COLUMN) for error reporting."
  (cons (source-line source) (source-column source)))

(defun source-match (source string)
  "If the upcoming characters match STRING, advance past them and return T.
Otherwise leave the cursor unchanged and return NIL."
  (let ((len (length string)))
    (when (and (<= (+ (source-index source) len) (length (source-text source)))
               (string= string (source-text source)
                        :start2 (source-index source)
                        :end2 (+ (source-index source) len)))
      (dotimes (i len t)
        (source-advance source)))))

(defun source-skip-while (source predicate)
  "Advance while PREDICATE returns true for the current character.
Returns the number of characters skipped."
  (loop for count from 0
        while (and (not (source-eof-p source))
                   (funcall predicate (source-peek source)))
        do (source-advance source)
        finally (return count)))
