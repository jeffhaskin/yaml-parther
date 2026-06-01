;;;; source.lisp --- Input cursor and position tracking.
;;;;
;;;; Hides how raw input (a string or a character stream) is traversed and how
;;;; line/column position is tracked. The reader walks input only through this
;;;; interface, so nothing downstream does arithmetic on offsets.

(in-package #:yaml-parther)

(defparameter *yaml-version* '(1 . 2)
  "The YAML version currently being parsed. Defaults to 1.2.
Set by %YAML directives during document parsing.")

(defstruct (source (:constructor %make-source))
  "An input cursor over YAML text, carrying line/column position and indent context."
  (text         "" :type string)
  (index        0  :type fixnum)
  (line         1  :type fixnum)
  (column       0  :type fixnum)
  (indent-stack nil :type list))

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

;;; ---------------------------------------------------------------------------
;;; Whitespace predicates
;;; ---------------------------------------------------------------------------

(defun whitespace-p (char)
  "Return T if CHAR is a YAML whitespace (space or tab)."
  (and char (or (char= char #\Space) (char= char #\Tab))))

(defun line-break-p (char)
  "Return T if CHAR is a line break (LF or CR)."
  (and char (or (char= char #\Newline) (char= char #\Return))))

(defun blank-p (char)
  "Return T if CHAR is whitespace or a line break."
  (or (whitespace-p char) (line-break-p char)))

;;; ---------------------------------------------------------------------------
;;; Indentation context stack
;;; ---------------------------------------------------------------------------

(defun source-push-indent (source column)
  "Push COLUMN onto the indent stack as the new required indent level."
  (push column (source-indent-stack source)))

(defun source-pop-indent (source)
  "Pop and return the top indent level from the stack."
  (pop (source-indent-stack source)))

(defun source-current-indent (source)
  "Return the current required indent level, or 0 if stack is empty."
  (or (car (source-indent-stack source)) 0))

(defun source-indent-depth (source)
  "Return the number of indent levels currently on the stack."
  (length (source-indent-stack source)))

;;; ---------------------------------------------------------------------------
;;; Indentation and line operations
;;; ---------------------------------------------------------------------------

(defun source-at-line-start-p (source)
  "Return T if the cursor is at the start of a line (column 0)."
  (zerop (source-column source)))

(defun source-count-indent (source)
  "Count leading spaces at current position without advancing.
Returns the number of consecutive space characters."
  (loop for i from 0
        for char = (source-peek source i)
        while (and char (char= char #\Space))
        count t))

(defun source-skip-indent (source)
  "Skip leading spaces and return the number skipped."
  (source-skip-while source (lambda (c) (char= c #\Space))))

(defun source-check-indent (source min-indent)
  "Return T if current indent level is at least MIN-INDENT.
Must be called at line start."
  (>= (source-count-indent source) min-indent))

(defun source-skip-blanks (source)
  "Skip whitespace (spaces and tabs), return the count skipped."
  (source-skip-while source #'whitespace-p))

(defun source-skip-to-eol (source)
  "Skip to end of line (but don't consume the line break).
Returns the number of characters skipped."
  (source-skip-while source (lambda (c) (not (line-break-p c)))))

(defun source-consume-line-break (source)
  "Consume a line break (LF, CR, or CRLF). Returns T if consumed, NIL otherwise."
  (let ((char (source-peek source)))
    (cond
      ((null char) nil)
      ((char= char #\Newline)
       (source-advance source)
       t)
      ((char= char #\Return)
       (source-advance source)
       (when (eql (source-peek source) #\Newline)
         (source-advance source))
       t)
      (t nil))))

(defun source-skip-blank-lines (source)
  "Skip any blank lines (lines containing only whitespace).
Returns the number of line breaks consumed."
  (loop for count from 0
        do (let ((start-index (source-index source)))
             (source-skip-blanks source)
             (unless (source-consume-line-break source)
               (setf (source-index source) start-index)
               (return count)))))

;;; ---------------------------------------------------------------------------
;;; Line folding primitives
;;; ---------------------------------------------------------------------------

(defun source-fold-line (source)
  "Consume a line break for line folding. Returns :FOLD if folded, :KEEP if
a blank line follows (which keeps the newline), or NIL if no line break."
  (unless (source-consume-line-break source)
    (return-from source-fold-line nil))
  (if (or (source-eof-p source)
          (line-break-p (source-peek source)))
      :keep
      :fold))

;;; ---------------------------------------------------------------------------
;;; Comment handling
;;; ---------------------------------------------------------------------------

(defun source-skip-comment (source)
  "Skip a YAML comment starting at #, consuming to end of line but not the line break.
Returns the number of characters consumed (0 if not at a comment)."
  (unless (eql (source-peek source) #\#)
    (return-from source-skip-comment 0))
  (source-skip-while source (lambda (c) (not (line-break-p c)))))

(defun source-skip-whitespace-and-comments (source)
  "Skip whitespace, then a comment if present, then line break, repeating.
Stops when non-whitespace, non-comment content is reached.
Returns the number of line breaks consumed."
  (loop for lines from 0
        do (source-skip-blanks source)
           (source-skip-comment source)
        while (source-consume-line-break source)
        finally (return lines)))

;;; ---------------------------------------------------------------------------
;;; Document markers
;;; ---------------------------------------------------------------------------

(defun source-match-marker (source marker)
  "Match MARKER followed by whitespace, newline, or EOF.
Advances past the marker if matched, returns T. Otherwise returns NIL."
  (let ((len (length marker)))
    (when (source-match source marker)
      (let ((next (source-peek source)))
        (if (or (null next) (whitespace-p next) (line-break-p next))
            t
            (progn
              (setf (source-index source) (- (source-index source) len))
              nil))))))

(defun source-match-document-start (source)
  "Match `---` followed by whitespace, newline, or EOF."
  (source-match-marker source "---"))

(defun source-match-document-end (source)
  "Match `...` followed by whitespace, newline, or EOF."
  (source-match-marker source "..."))
