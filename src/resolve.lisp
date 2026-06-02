;;;; resolve.lisp --- Scalar resolution: YAML scalar text -> native Lisp value.
;;;;
;;;; The single place the scalar typing decision is made. The baseline is the
;;;; YAML 1.2 core schema:
;;;;
;;;;   null    -> the symbol CL:NULL   (a distinct sentinel, accessible everywhere)
;;;;   false   -> NIL
;;;;   true    -> T
;;;;   integer -> a Lisp integer
;;;;   float   -> a Lisp float (double-float for precision)
;;;;   else    -> a string
;;;;
;;;; We support BOTH schemas, selected by the document's YAML version (the
;;;; `%YAML` directive, tracked in *YAML-VERSION*; a document with no directive
;;;; defaults to 1.2). Where 1.1 and 1.2 disagree on a token, the version
;;;; decides -- it is never a tradeoff. The 1.1-only readings, enabled only
;;;; when the document declares `%YAML 1.1`, are:
;;;;
;;;;   yes/no/on/off       -> bool      (1.1 boolean spellings; 1.2: strings)
;;;;   leading-zero octal  -> integer   (1.1: 0777 == 511; 1.2: decimal 777)
;;;;   sexagesimal         -> integer   (1.1: 20:03:20 == base-60; 1.2: string)
;;;;
;;;; Single-letter `y`/`n` are deliberately NOT treated as booleans in either
;;;; version: a bare `y` is overwhelmingly a string or a key (e.g. a `y`
;;;; coordinate), so honoring 1.1's `y`/`n` booleans breaks more than it helps.
;;;;
;;;; Consulted by the reader (resolving on the way in) and by emit (deciding
;;;; whether a string must be quoted so it does not re-resolve as a bool/number).
;;;; See docs/adr/0001.

(in-package #:yaml-parther)

;;; ---------------------------------------------------------------------------
;;; Core schema patterns (YAML 1.2 section 10.3.2)
;;; ---------------------------------------------------------------------------

(defun yaml-1.1-p ()
  "True when the document currently being parsed declares YAML 1.1, which
enables the 1.1-only scalar readings (yes/no/on/off booleans, leading-zero
octals, sexagesimal integers). Defaults to NIL, i.e. strict 1.2."
  (and (consp *yaml-version*)
       (eql (car *yaml-version*) 1)
       (eql (cdr *yaml-version*) 1)))

(defun null-p (text)
  "Return T if TEXT represents a YAML null."
  (or (string= text "")
      (string= text "~")
      (string-equal text "null")))

(defun true-p (text)
  "Return T if TEXT represents a true boolean. Always accepts the 1.2 spelling
`true`; under YAML 1.1 also accepts `yes`/`on` (case-insensitive). The
single-letter `y`/`Y` is never accepted (see file header)."
  (or (string-equal text "true")
      (and (yaml-1.1-p)
           (or (string-equal text "yes")
               (string-equal text "on")))))

(defun false-p (text)
  "Return T if TEXT represents a false boolean. Always accepts the 1.2 spelling
`false`; under YAML 1.1 also accepts `no`/`off` (case-insensitive). The
single-letter `n`/`N` is never accepted (see file header)."
  (or (string-equal text "false")
      (and (yaml-1.1-p)
           (or (string-equal text "no")
               (string-equal text "off")))))

(defun integer-text-p (text)
  "Return T if TEXT matches an integer pattern.
1.2 patterns: [-+]?[0-9]+ | 0o[0-7]+ | 0x[0-9a-fA-F]+
1.1 addition:  leading-zero octal 0[0-7]+ (e.g. 0777). Note `08`/`09` are not
octal; they fall through to the decimal branch (matching 1.2 today)."
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
        ;; 1.1 leading-zero octal: 0 followed by one or more octal digits.
        ;; Only under 1.1; in 1.2 `010` is decimal (the (t) branch below).
        ((and (yaml-1.1-p)
              (>= (- len start) 2)
              (char= (char text start) #\0)
              (loop for i from (1+ start) below len
                    always (digit-char-p (char text i) 8)))
         t)
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
      ;; 1.1 leading-zero octal: parse the whole digit run in base 8.
      ((and (yaml-1.1-p)
            (>= (- (length text) start) 2)
            (char= (char text start) #\0)
            (loop for i from (1+ start) below (length text)
                  always (digit-char-p (char text i) 8)))
       (* sign (parse-integer text :start start :radix 8)))
      (t
       (* sign (parse-integer text :start start))))))

(defun sexagesimal-int-text-p (text)
  "Return T if TEXT matches the YAML 1.1 sexagesimal (base-60) integer pattern:
  [-+]?[1-9][0-9]*(:[0-5]?[0-9])+   e.g. 190:20:30, 20:03:20
The first group has no leading zero; each subsequent colon-group is 1-2 digits
with value 0-59. This token resolves to a string under the 1.2 core schema; we
accept it for 1.1 backwards compatibility."
  (let ((len (length text))
        (start 0))
    (when (zerop len)
      (return-from sexagesimal-int-text-p nil))
    (when (find (char text 0) "+-")
      (setf start 1))
    (when (>= start len)
      (return-from sexagesimal-int-text-p nil))
    ;; First group: [1-9][0-9]* -- must start with a non-zero digit.
    (unless (and (digit-char-p (char text start))
                 (char/= (char text start) #\0))
      (return-from sexagesimal-int-text-p nil))
    (let ((i (1+ start))
          (groups 0))
      (loop while (and (< i len) (digit-char-p (char text i))) do (incf i))
      ;; One or more :dd groups, each 1-2 digits valued 0-59.
      (loop
        (when (>= i len) (return))
        (unless (char= (char text i) #\:)
          (return-from sexagesimal-int-text-p nil))
        (incf i)                        ; consume ':'
        (let ((g-start i))
          (loop while (and (< i len) (digit-char-p (char text i))) do (incf i))
          (let ((glen (- i g-start)))
            (unless (<= 1 glen 2)
              (return-from sexagesimal-int-text-p nil))
            (unless (<= 0 (parse-integer text :start g-start :end i) 59)
              (return-from sexagesimal-int-text-p nil))))
        (incf groups))
      (and (= i len) (>= groups 1)))))

(defun parse-sexagesimal-int (text)
  "Parse TEXT as a YAML 1.1 sexagesimal (base-60) integer, returning an integer.
Assumes TEXT already satisfies SEXAGESIMAL-INT-TEXT-P."
  (let ((start 0)
        (sign 1)
        (len (length text)))
    (when (and (> len 0) (char= (char text 0) #\-))
      (setf sign -1 start 1))
    (when (and (> len 0) (char= (char text 0) #\+))
      (setf start 1))
    (let ((acc 0)
          (i start)
          (g-start start))
      (loop
        (cond
          ((or (>= i len) (char= (char text i) #\:))
           (setf acc (+ (* acc 60) (parse-integer text :start g-start :end i)))
           (when (>= i len) (return))
           (incf i)                     ; skip ':'
           (setf g-start i))
          (t (incf i))))
      (* sign acc))))

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
       ;; A quiet NaN. SBCL traps the :INVALID operation by default, so the
       ;; naive (/ 0 0) signals rather than yielding a NaN; mask the trap while
       ;; we construct it. Other implementations generally just produce a NaN.
       #+sbcl (sb-int:with-float-traps-masked (:invalid)
                (/ 0.0d0 0.0d0))
       #-sbcl (/ 0.0d0 0.0d0))
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
    ((and (yaml-1.1-p) (sexagesimal-int-text-p text)) (parse-sexagesimal-int text))
    ((float-text-p text) (parse-yaml-float text))
    (t text)))
