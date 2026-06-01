;;;; resolve.lisp --- Scalar resolution: YAML scalar text -> native Lisp value.
;;;;
;;;; The single place the scalar typing decision is made (YAML 1.2 core schema):
;;;;
;;;;   null    -> the symbol CL:NULL   (a distinct sentinel, accessible everywhere)
;;;;   false   -> NIL
;;;;   true    -> T
;;;;   integer -> a Lisp integer
;;;;   float   -> a Lisp float (double-float for precision)
;;;;   else    -> a string
;;;;
;;;; Consulted by the reader (resolving on the way in) and by emit (deciding
;;;; whether a string must be quoted so it does not re-resolve as a bool/number).
;;;; See docs/adr/0001.

(in-package #:yaml-parther)

;;; ---------------------------------------------------------------------------
;;; Core schema patterns (YAML 1.2 section 10.3.2)
;;; ---------------------------------------------------------------------------

(defun null-p (text)
  "Return T if TEXT represents a YAML null."
  (or (string= text "")
      (string= text "~")
      (string-equal text "null")))

(defun true-p (text)
  "Return T if TEXT represents a YAML true boolean."
  (string-equal text "true"))

(defun false-p (text)
  "Return T if TEXT represents a YAML false boolean."
  (string-equal text "false"))

(defun integer-text-p (text)
  "Return T if TEXT matches the YAML 1.2 integer pattern.
Patterns: [-+]?[0-9]+ | 0o[0-7]+ | 0x[0-9a-fA-F]+"
  (let ((len (length text)))
    (when (zerop len)
      (return-from integer-text-p nil))
    (let ((start 0))
      (when (and (> len 0) (find (char text 0) "+-"))
        (setf start 1))
      (when (>= start len)
        (return-from integer-text-p nil))
      (cond
        ((and (>= (- len start) 2)
              (char= (char text start) #\0)
              (char-equal (char text (1+ start)) #\o))
         (loop for i from (+ start 2) below len
               always (digit-char-p (char text i) 8)))
        ((and (>= (- len start) 2)
              (char= (char text start) #\0)
              (char-equal (char text (1+ start)) #\x))
         (loop for i from (+ start 2) below len
               always (digit-char-p (char text i) 16)))
        (t
         (loop for i from start below len
               always (digit-char-p (char text i))))))))

(defun parse-yaml-integer (text)
  "Parse TEXT as a YAML integer, returning a Lisp integer."
  (let ((start 0)
        (sign 1))
    (when (and (> (length text) 0) (char= (char text 0) #\-))
      (setf sign -1 start 1))
    (when (and (> (length text) 0) (char= (char text 0) #\+))
      (setf start 1))
    (cond
      ((and (>= (- (length text) start) 2)
            (char= (char text start) #\0)
            (char-equal (char text (1+ start)) #\o))
       (* sign (parse-integer text :start (+ start 2) :radix 8)))
      ((and (>= (- (length text) start) 2)
            (char= (char text start) #\0)
            (char-equal (char text (1+ start)) #\x))
       (* sign (parse-integer text :start (+ start 2) :radix 16)))
      (t
       (* sign (parse-integer text :start start))))))

(defun float-text-p (text)
  "Return T if TEXT matches the YAML 1.2 float pattern.
Patterns: [-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?([eE][-+]?[0-9]+)?) | [-+]?\\.inf | \\.nan"
  (let ((len (length text)))
    (when (zerop len)
      (return-from float-text-p nil))
    (let ((start 0))
      (when (and (> len 0) (find (char text 0) "+-"))
        (setf start 1))
      (when (>= start len)
        (return-from float-text-p nil))
      (cond
        ((string-equal text ".inf" :start1 start)
         t)
        ((and (zerop start) (string-equal text ".nan"))
         t)
        (t
         (let ((pos start)
               (has-digit nil)
               (has-dot nil))
           (when (and (< pos len) (char= (char text pos) #\.))
             (setf has-dot t)
             (incf pos)
             (unless (and (< pos len) (digit-char-p (char text pos)))
               (return-from float-text-p nil))
             (loop while (and (< pos len) (digit-char-p (char text pos)))
                   do (incf pos) (setf has-digit t)))
           (unless has-dot
             (unless (and (< pos len) (digit-char-p (char text pos)))
               (return-from float-text-p nil))
             (loop while (and (< pos len) (digit-char-p (char text pos)))
                   do (incf pos) (setf has-digit t))
             (when (and (< pos len) (char= (char text pos) #\.))
               (setf has-dot t)
               (incf pos)
               (loop while (and (< pos len) (digit-char-p (char text pos)))
                     do (incf pos))))
           (unless has-dot
             (return-from float-text-p nil))
           (when (and (< pos len) (find (char text pos) "eE"))
             (incf pos)
             (when (and (< pos len) (find (char text pos) "+-"))
               (incf pos))
             (unless (and (< pos len) (digit-char-p (char text pos)))
               (return-from float-text-p nil))
             (loop while (and (< pos len) (digit-char-p (char text pos)))
                   do (incf pos)))
           (and has-digit (= pos len))))))))

(defun parse-yaml-float (text)
  "Parse TEXT as a YAML float, returning a Lisp double-float.
Handles .inf, -.inf, +.inf, and .nan."
  (let ((start 0)
        (sign 1.0d0))
    (when (and (> (length text) 0) (char= (char text 0) #\-))
      (setf sign -1.0d0 start 1))
    (when (and (> (length text) 0) (char= (char text 0) #\+))
      (setf start 1))
    (cond
      ((string-equal text ".inf" :start1 start)
       (if (minusp sign)
           most-negative-double-float
           most-positive-double-float))
      ((and (zerop start) (string-equal text ".nan"))
       (let ((zero 0.0d0))
         (/ zero zero)))
      (t
       (let ((*read-default-float-format* 'double-float))
         (read-from-string text))))))

;;; ---------------------------------------------------------------------------
;;; Main entry point
;;; ---------------------------------------------------------------------------

(defun resolve-scalar (text &optional tag)
  "Resolve plain scalar TEXT (optionally carrying an explicit TAG) to a native
Lisp value per the core schema: CL:NULL / NIL / T / integer / float / string.

When TAG is provided, it overrides implicit resolution:
  - tag:yaml.org,2002:null  -> CL:NULL
  - tag:yaml.org,2002:bool  -> T or NIL (must match true/false pattern)
  - tag:yaml.org,2002:int   -> integer
  - tag:yaml.org,2002:float -> float
  - tag:yaml.org,2002:str   -> string (no conversion)"
  (cond
    (tag
     (cond
       ((string= tag "tag:yaml.org,2002:null")
        'null)
       ((string= tag "tag:yaml.org,2002:bool")
        (cond ((true-p text) t)
              ((false-p text) nil)
              (t (error 'yaml-tag-error
                        :tag tag
                        :message (format nil "~S is not a valid boolean" text)))))
       ((string= tag "tag:yaml.org,2002:int")
        (if (integer-text-p text)
            (parse-yaml-integer text)
            (error 'yaml-tag-error
                   :tag tag
                   :message (format nil "~S is not a valid integer" text))))
       ((string= tag "tag:yaml.org,2002:float")
        (if (float-text-p text)
            (parse-yaml-float text)
            (error 'yaml-tag-error
                   :tag tag
                   :message (format nil "~S is not a valid float" text))))
       ((string= tag "tag:yaml.org,2002:str")
        text)
       (t text)))
    ((null-p text) 'null)
    ((true-p text) t)
    ((false-p text) nil)
    ((integer-text-p text) (parse-yaml-integer text))
    ((float-text-p text) (parse-yaml-float text))
    (t text)))
