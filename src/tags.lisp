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

(defun read-tag (source tag-handles)
  "Read a tag from SOURCE and return its expanded form.
TAG-HANDLES is an alist from %TAG directives.
Handles: !!type, !handle!suffix, !local, !<verbatim>."
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
             while (and char (not (whitespace-p char)) (not (line-break-p char)))
             do (vector-push-extend char suffix)
                (source-advance source))
       (expand-tag-shorthand (coerce handle 'string) (coerce suffix 'string) tag-handles))
      (t
       (loop for char = (source-peek source)
             while (and char (not (whitespace-p char)) (not (line-break-p char))
                        (not (char= char #\!)))
             do (if (char= char #\!)
                    (progn
                      (vector-push-extend char handle)
                      (source-advance source)
                      (return))
                    (progn
                      (vector-push-extend char suffix)
                      (source-advance source))))
       (if (> (length handle) 1)
           (expand-tag-shorthand (coerce handle 'string) (coerce suffix 'string) tag-handles)
           (expand-tag-shorthand "!" (coerce suffix 'string) tag-handles))))))
