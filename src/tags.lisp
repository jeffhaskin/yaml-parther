;;;; tags.lisp --- Tag-handle and shorthand machinery.
;;;;
;;;; Hides %TAG directive handling, tag-shorthand expansion (e.g. !!str, !h!foo,
;;;; verbatim !<...>), and the non-specific tag rules. Consulted by both the
;;;; reader and emit; it does not touch the input cursor.

(in-package #:yaml-parther)

(defparameter *default-tag-handles*
  '(("!!" . "tag:yaml.org,2002:")
    ("!" . "!"))
  "Default tag handle mappings. !! maps to the YAML core schema prefix.")

(defvar *tag-handles* nil
  "Per-document alist of (handle . prefix) accumulated from %TAG directives.
Bound by the document reader. Handles declared here override the defaults; the
defaults remain available for handles not redeclared.")

(defun current-tag-handles ()
  "Return the active tag-handle alist: any %TAG-declared handles take precedence,
falling back to the default handles for !! and !."
  (append *tag-handles* *default-tag-handles*))

(defun expand-tag-shorthand (handle suffix tag-handles)
  "Expand a tag shorthand like !!str to its full URI.
HANDLE is the tag handle (e.g., !!, !, !e!).
SUFFIX is the part after the handle (e.g., str, int).
TAG-HANDLES is an alist of (handle . prefix) from %TAG directives.
Returns the expanded tag URI."
  (let* ((handles (or tag-handles *default-tag-handles*))
         (prefix (cdr (assoc handle handles :test #'string=))))
    (if prefix
        (concatenate 'string prefix suffix)
        (error 'yaml-tag-error
               :tag (concatenate 'string handle suffix)
               :message (format nil "Unknown tag handle: ~A" handle)))))

(defun parse-verbatim-tag (string)
  "Extract the URI from a verbatim tag like !<uri>.
Returns the URI without the !< and > delimiters."
  (unless (and (>= (length string) 3)
               (char= (char string 0) #\!)
               (char= (char string 1) #\<)
               (char= (char string (1- (length string))) #\>))
    (error 'yaml-tag-error
           :tag string
           :message "Invalid verbatim tag format"))
  (subseq string 2 (1- (length string))))

(defun read-tag (source &optional tag-handles)
  "Read a tag from SOURCE and return its expanded form.
TAG-HANDLES is an alist from %TAG directives; when NIL the active
*TAG-HANDLES* (plus the defaults) are used.
Handles: !!type, !handle!suffix, !local, !<verbatim>."
  (setf tag-handles (or tag-handles (current-tag-handles)))
  (unless (eql (source-peek source) #\!)
    (return-from read-tag nil))
  (source-advance source)
  (let ((handle (make-array 1 :element-type 'character
                              :initial-contents '(#\!)
                              :adjustable t :fill-pointer 1))
        (suffix (make-array 0 :element-type 'character
                              :adjustable t :fill-pointer 0)))
    (cond
      ((eql (source-peek source) #\<)
       (source-advance source)
       (loop for char = (source-peek source)
             until (or (null char) (char= char #\>))
             do (vector-push-extend char suffix)
                (source-advance source))
       (when (eql (source-peek source) #\>)
         (source-advance source))
       (coerce suffix 'string))
      ((eql (source-peek source) #\!)
       (vector-push-extend (source-advance source) handle)
       (loop for char = (source-peek source)
             while (and char (not (whitespace-p char)) (not (line-break-p char))
                        ;; Flow indicators terminate a tag and are never part of
                        ;; a shorthand suffix.
                        (not (find char ",[]{}")))
             do (vector-push-extend char suffix)
                (source-advance source))
       (expand-tag-shorthand (coerce handle 'string) (coerce suffix 'string) tag-handles))
      (t
       ;; A named handle (`!m!suffix`) carries a closing `!` after the handle
       ;; name; a bare local tag (`!local`) has none. Read up to whitespace, a
       ;; flow indicator, or that closing `!`.
       (let ((named-handle nil))
         (loop for char = (source-peek source)
               while (and char (not (whitespace-p char)) (not (line-break-p char))
                          (not (find char ",[]{}")))
               do (cond
                    ((char= char #\!)
                     ;; Closing `!` of a named handle: the chars read so far were
                     ;; the handle name, not the suffix. The handle is
                     ;; `!` + name + `!`.
                     (loop for c across suffix do (vector-push-extend c handle))
                     (vector-push-extend char handle)
                     (setf (fill-pointer suffix) 0)
                     (source-advance source)
                     (setf named-handle t)
                     (return))
                    (t
                     (vector-push-extend char suffix)
                     (source-advance source))))
         (when named-handle
           ;; After the closing `!`, the remaining chars form the suffix.
           (loop for char = (source-peek source)
                 while (and char (not (whitespace-p char)) (not (line-break-p char))
                            (not (find char ",[]{}")))
                 do (vector-push-extend char suffix)
                    (source-advance source)))
         (if (> (length handle) 1)
             (expand-tag-shorthand (coerce handle 'string) (coerce suffix 'string) tag-handles)
             (expand-tag-shorthand "!" (coerce suffix 'string) tag-handles)))))))
