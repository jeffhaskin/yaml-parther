;;;; reader.lisp --- The whole input side: lex + grammar + tree-building.
;;;;
;;;; One deep module. YAML 1.2 is context-sensitive -- indentation, the `?`/`:`
;;;; mapping ambiguity, flow-vs-block context, and key/value detection all need
;;;; grammar context to scan correctly -- so scanning, parsing, anchor/alias
;;;; composition, and native-value construction are FUSED into one recursive
;;;; descent over a single SOURCE cursor. The hash-tables and vectors are built
;;;; on the way back up the recursion; a separate token/event/node-graph
;;;; intermediate would only leak that context across module walls.
;;;; See docs/adr/0002 and docs/adr/0004.
;;;;
;;;; Representation: mappings -> hash-tables (TEST #'EQUAL); sequences -> vectors.

(in-package #:yaml-parther)

;;; ---------------------------------------------------------------------------
;;; Single-quoted scalar reading
;;; ---------------------------------------------------------------------------

(defvar *quoted-min-indent* nil
  "When non-NIL, the minimum column a quoted-scalar continuation line must reach;
a continuation line below it signals a structure error.")

(defvar *flow-indent* nil
  "When non-NIL, the minimum column a flow-collection continuation line must
reach. Set when a flow collection is entered from block context; a continuation
line at or below it is an under-indentation error.")

(defvar *root-on-marker-line* nil
  "Bound non-NIL when a document's root node begins on the same line as its
`---` start marker. A block collection that starts there is anchored at the
document root (column 0): any continuation line indented past column 0 is
over-indented and malformed (yaml-test-suite 9KBC).")

(defvar *in-explicit-entry* nil
  "Bound non-NIL while reading the key or value node of an explicit `?`/`:`
mapping entry. A nested single-line mapping is legitimate there, so the
same-line trailing-`:` malformed-content check is suppressed.")

(defvar *node-indent-floor* nil
  "When bound to an integer, the indentation of the block context that ENCLOSES
a node-property block read on its own line. The node those properties decorate
may be LESS indented than the property line itself (a `!tag` or `&anchor` may be
written more-indented than the block scalar / collection it applies to), but it
must still be indented strictly past this floor. Used by
READ-NODE-PROPERTIES-AND-VALUE to accept such dedented nodes (yaml-test-suite
M5C3) without swallowing a shallower sibling.")

(defvar *pending-tag* nil
  "When non-NIL, the resolved tag URI that applies to the next scalar node being
read. Bound by the node-property readers around the scalar's read so the scalar
resolution can honour an explicit tag (e.g. !!str forces a string, !!int forces
integer typing). A non-specific `!` or a non-core (local/unknown/verbatim) tag
on a scalar suppresses implicit typing, yielding the literal string content.")

(defun apply-scalar-tag (text)
  "Resolve plain-scalar TEXT honouring *PENDING-TAG* (if any). A core-schema tag
delegates to RESOLVE-SCALAR's tag path; a non-specific `!` or any non-core tag
suppresses implicit typing and yields TEXT verbatim as a string."
  (let ((tag *pending-tag*))
    (cond
      ((null tag) (resolve-scalar text))
      ;; A collection tag on a scalar node is a type mismatch: signal loudly.
      ((or (string= tag "tag:yaml.org,2002:map")
           (string= tag "tag:yaml.org,2002:seq"))
       (error 'yaml-tag-error
              :tag tag
              :message (format nil "Collection tag ~A applied to a scalar" tag)))
      ;; Core schema scalar tags drive explicit typing.
      ((and (>= (length tag) 19)
            (string= tag "tag:yaml.org,2002:" :end1 18))
       (resolve-scalar text tag))
      ;; Non-specific `!` and local/unknown/verbatim tags: literal string.
      (t text))))

(defun fold-quoted-line-break (source chars)
  "At a line break inside a quoted scalar, consume the break(s) and append the
folded result to CHARS: a single break folds to one space; N consecutive breaks
fold to N-1 newlines; leading whitespace on the continuation line is stripped.
Returns T on success (a break was folded), NIL at EOF before content."
  (let ((breaks 0))
    (loop
      ;; trailing whitespace on the current line is already not appended
      (unless (source-consume-line-break source)
        (return))
      (incf breaks)
      ;; A quoted-scalar continuation line may not begin with a tab when the
      ;; scalar sits in an indented (block) context: its leading indentation must
      ;; be spaces (yaml-test-suite DK95/01). A tab following spaces is folded
      ;; content (DK95/02), and a root-context quoted scalar with no indentation
      ;; requirement folds a leading tab as content (7A4E/PRH3).
      (when (and *quoted-min-indent* (> *quoted-min-indent* 0)
                 (eql (source-peek source) #\Tab))
        (yaml-parse-fail 'yaml-scanner-error source
                         "Tab character used as indentation"))
      (source-skip-blanks source)
      ;; A document marker line may not appear inside a quoted scalar.
      (when (looks-like-document-marker source)
        (yaml-parse-fail 'yaml-scanner-error source
                         "Document marker inside quoted scalar"))
      ;; A continuation line must satisfy the surrounding indentation.
      (when (and *quoted-min-indent*
                 (not (line-break-p (source-peek source)))
                 (not (source-eof-p source))
                 (< (source-column source) *quoted-min-indent*))
        (yaml-parse-fail 'yaml-structure-error source
                         "Quoted scalar continuation is under-indented"))
      (unless (line-break-p (source-peek source))
        (return)))
    (cond
      ((source-eof-p source)
       ;; Unterminated will be detected by caller; emit nothing here.
       (> breaks 0))
      ((= breaks 1)
       (vector-push-extend #\Space chars)
       t)
      (t
       (dotimes (i (1- breaks)) (vector-push-extend #\Newline chars))
       t))))

(defun read-single-quoted-scalar (source)
  "Read a single-quoted scalar from SOURCE. Opening quote must be current char.
Single-quoted strings only escape '' as a literal '. Line breaks fold."
  (unless (eql (source-peek source) #\')
    (error 'yaml-scanner-error :message "Expected opening single quote"))
  (source-advance source) ; consume opening '
  (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop
      (let ((char (source-peek source)))
        (cond
          ((null char)
           (yaml-parse-fail 'yaml-scanner-error source "Unterminated single-quoted scalar"))
          ((char= char #\')
           (source-advance source)
           (if (eql (source-peek source) #\')
               (progn
                 (vector-push-extend #\' chars)
                 (source-advance source))
               (return (coerce chars 'string))))
          ((line-break-p char)
           ;; Strip trailing whitespace already-collected on this line.
           (loop while (and (> (fill-pointer chars) 0)
                            (whitespace-p (aref chars (1- (fill-pointer chars)))))
                 do (decf (fill-pointer chars)))
           (fold-quoted-line-break source chars))
          (t
           (vector-push-extend char chars)
           (source-advance source)))))))

;;; ---------------------------------------------------------------------------
;;; Double-quoted scalar reading
;;; ---------------------------------------------------------------------------

(defun parse-double-quote-escape (source)
  "Parse an escape sequence after backslash in a double-quoted string.
Returns the character to insert."
  (let ((char (source-advance source)))
    (case char
      (#\n #\Newline)
      (#\t #\Tab)
      (#\r #\Return)
      (#\\ #\\)
      (#\" #\")
      (#\/ #\/)
      (#\b #\Backspace)
      (#\f (code-char 12)) ; form feed
      (#\0 #\Nul)
      (#\a (code-char 7))  ; bell
      (#\v (code-char 11)) ; vertical tab
      (#\e (code-char 27)) ; escape
      (#\Space #\Space)
      (#\_ #\No-Break_Space)
      (#\N (code-char #x85)) ; next line
      (#\L (code-char #x2028)) ; line separator
      (#\P (code-char #x2029)) ; paragraph separator
      (#\x ; 2-digit hex
       (let ((hex (make-string 2)))
         (setf (char hex 0) (source-advance source))
         (setf (char hex 1) (source-advance source))
         (code-char (parse-integer hex :radix 16))))
      (#\u ; 4-digit unicode
       (let ((hex (make-string 4)))
         (dotimes (i 4) (setf (char hex i) (source-advance source)))
         (code-char (parse-integer hex :radix 16))))
      (#\U ; 8-digit unicode
       (let ((hex (make-string 8)))
         (dotimes (i 8) (setf (char hex i) (source-advance source)))
         (code-char (parse-integer hex :radix 16))))
      (otherwise
       (error 'yaml-scanner-error
              :message (format nil "Invalid escape sequence: \\~C" char))))))

(defun read-double-quoted-scalar (source)
  "Read a double-quoted scalar from SOURCE. Opening quote must be current char.
Processes escape sequences like \\n, \\t, \\\\, \\\", \\xNN, \\uNNNN, \\UNNNNNNNN."
  (unless (eql (source-peek source) #\")
    (error 'yaml-scanner-error :message "Expected opening double quote"))
  (source-advance source) ; consume opening "
  (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
        ;; Index up to which trailing-whitespace stripping at a line break is
        ;; forbidden: escaped whitespace (e.g. \t) must be preserved.
        (protected 0))
    (loop
      (let ((char (source-peek source)))
        (cond
          ((null char)
           (yaml-parse-fail 'yaml-scanner-error source "Unterminated double-quoted scalar"))
          ((char= char #\")
           (source-advance source)
           (return (coerce chars 'string)))
          ((char= char #\\)
           ;; A backslash immediately before a line break is an escaped
           ;; line continuation: the break (and following indentation) is
           ;; removed with no folding.
           (if (line-break-p (source-peek source 1))
               (progn
                 (source-advance source)        ; consume backslash
                 (source-consume-line-break source)
                 (source-skip-blanks source))
               (progn
                 (source-advance source)         ; consume backslash
                 (vector-push-extend (parse-double-quote-escape source) chars)
                 (setf protected (fill-pointer chars)))))
          ((line-break-p char)
           (loop while (and (> (fill-pointer chars) protected)
                            (whitespace-p (aref chars (1- (fill-pointer chars)))))
                 do (decf (fill-pointer chars)))
           (fold-quoted-line-break source chars)
           (setf protected (fill-pointer chars)))
          (t
           (vector-push-extend char chars)
           (source-advance source)))))))

;;; ---------------------------------------------------------------------------
;;; Plain scalar reading
;;; ---------------------------------------------------------------------------

(defun plain-scalar-end-here-p (source in-flow)
  "Return T if the current position ends a plain scalar (within one line):
a comment start (# preceded by space/line-start) or a `:` followed by blank,
or a flow indicator when IN-FLOW."
  (let ((char (source-peek source)))
    (cond
      ((null char) t)
      ((line-break-p char) t)
      ;; `#` starts a comment only when preceded by whitespace or at line start.
      ((and (char= char #\#)
            (let ((prev (source-peek source -1)))
              (or (null prev) (whitespace-p prev) (line-break-p prev))))
       t)
      ;; `: ` (colon followed by space/break/EOF) ends a plain scalar (key/value).
      ((and (char= char #\:)
            (let ((next (source-peek source 1)))
              (or (null next) (whitespace-p next) (line-break-p next)
                  (and in-flow (find next ",[]{}")))))
       t)
      ;; Flow indicators terminate plain scalars in flow context.
      ((and in-flow (find char ",[]{}"))
       t)
      (t nil))))

(defun read-plain-line-segment (source in-flow)
  "Read one physical line of a plain scalar into a fresh string, stopping at the
line break, EOF, a comment, or (in flow) a flow indicator. Trailing spaces/tabs
on the segment are trimmed by the caller via folding."
  (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop until (plain-scalar-end-here-p source in-flow)
          do (vector-push-extend (source-peek source) chars)
             (source-advance source))
    (coerce chars 'string)))

(defun read-plain-scalar (source &optional (min-indent 1))
  "Read a plain (unquoted) multi-line scalar from SOURCE in block context.

Continuation lines (indented at least MIN-INDENT columns) fold per YAML rules:
a single line break between non-empty lines folds to one space; N blank lines
fold to N-1 newlines. Leading and trailing whitespace on lines is stripped.
Returns the resolved native value."
  (let ((result (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
        (first-segment (string-right-trim '(#\Space #\Tab)
                                          (read-plain-line-segment source nil))))
    (loop for ch across first-segment do (vector-push-extend ch result))
    ;; Fold any continuation lines.
    (loop
      (unless (line-break-p (source-peek source))
        (return))
      ;; Tentatively consume line breaks, counting blank lines.
      (let ((save-index (source-index source))
            (save-line (source-line source))
            (save-column (source-column source))
            (breaks 0))
        (loop
          (unless (source-consume-line-break source)
            (return))
          (incf breaks)
          (source-skip-blanks source)
          (when (or (line-break-p (source-peek source))
                    (source-eof-p source))
            ;; blank line: keep scanning
            nil)
          (unless (or (line-break-p (source-peek source))
                      (source-eof-p source))
            (return)))
        (let ((indent (source-column source)))
          (cond
            ;; Continuation only if sufficiently indented and real content that
            ;; is not a document marker.
            ((and (not (source-eof-p source))
                  (>= indent min-indent)
                  (not (eql (source-peek source) #\#))
                  (not (and (eql (source-peek source) #\-)
                            (let ((n (source-peek source 1)))
                              (or (null n) (whitespace-p n) (line-break-p n)))))
                  (not (looks-like-document-marker source))
                  ;; A line that forms a mapping key starts a new entry, not a
                  ;; continuation of this plain scalar.
                  (not (looks-like-mapping-key-p source)))
             (if (= breaks 1)
                 (vector-push-extend #\Space result)
                 (dotimes (i (1- breaks)) (vector-push-extend #\Newline result)))
             (let ((seg (string-right-trim '(#\Space #\Tab)
                                           (read-plain-line-segment source nil))))
               (loop for ch across seg do (vector-push-extend ch result))))
            (t
             ;; Not a continuation: rewind to before the line breaks.
             (setf (source-index source) save-index
                   (source-line source) save-line
                   (source-column source) save-column)
             (return))))))
    (apply-scalar-tag (coerce result 'string))))

(defun looks-like-document-marker (source)
  "Return T if the cursor sits at a `---` or `...` document marker."
  (and (source-at-line-start-p source)
       (let ((a (source-peek source 0))
             (b (source-peek source 1))
             (c (source-peek source 2))
             (d (source-peek source 3)))
         (and (or (and (eql a #\-) (eql b #\-) (eql c #\-))
                  (and (eql a #\.) (eql b #\.) (eql c #\.)))
              (or (null d) (whitespace-p d) (line-break-p d))))))

;;; ---------------------------------------------------------------------------
;;; Tagged value reading
;;; ---------------------------------------------------------------------------

(defun read-tagged-value (source &optional (min-indent 1))
  "Read a value after a tag has been consumed. Tags are currently ignored."
  (let ((char (source-peek source)))
    (cond
      ((null char) 'null)
      ((line-break-p char) 'null)
      ((eql char #\[) (let ((*flow-indent* (1- min-indent))) (read-flow-sequence source)))
      ((eql char #\{) (let ((*flow-indent* (1- min-indent))) (read-flow-mapping source)))
      ((eql char #\') (read-single-quoted-scalar source))
      ((eql char #\") (read-double-quoted-scalar source))
      (t (read-plain-scalar source min-indent)))))

;;; ---------------------------------------------------------------------------
;;; Block sequence reading
;;; ---------------------------------------------------------------------------

(defun block-construct-here-p (source)
  "Return T if the cursor sits at the start of a nested block construct: a `-`
sequence entry, an explicit `?` key, or a `key:` block-mapping entry. Used to
decide whether a preceding tab is being (illegally) used as indentation."
  (let ((c (source-peek source)))
    (and c
         (or (and (or (char= c #\-) (char= c #\?))
                  (let ((n (source-peek source 1)))
                    (or (null n) (whitespace-p n) (line-break-p n))))
             (looks-like-mapping-key-p source)))))

(defun read-block-sequence (source)
  "Read a block sequence from SOURCE. Expects to start at a '- ' indicator.
Returns a vector of items."
  (let ((items (make-array 0 :adjustable t :fill-pointer 0))
        (seq-indent (source-column source))
        (*pending-tag* nil))
    (loop
      (source-skip-blanks source)
      (unless (and (eql (source-peek source) #\-)
                   (or (whitespace-p (source-peek source 1))
                       (line-break-p (source-peek source 1))
                       (null (source-peek source 1))))
        (return))
      (let ((dash-col (source-column source))
            (consumed-newline-p nil)
            (flow-item-p nil)
            (sep-has-tab nil))
        (source-advance source)
        ;; Record whether the separation after `-` contains a tab. A tab is fine
        ;; before an inline scalar (`- \tfoo`), but if it precedes a nested block
        ;; construct (another `-`, or an explicit `?` key) it is being used as
        ;; indentation, which is forbidden (yaml-test-suite Y79Y/04, Y79Y/05).
        (loop for c = (source-peek source)
              while (and c (whitespace-p c))
              do (when (char= c #\Tab) (setf sep-has-tab t))
                 (source-advance source))
        (when (and sep-has-tab
                   (let ((c (source-peek source)))
                     (and c
                          (or (and (char= c #\-)
                                   (let ((n (source-peek source 1)))
                                     (or (null n) (whitespace-p n) (line-break-p n))))
                              (and (char= c #\?)
                                   (let ((n (source-peek source 1)))
                                     (or (null n) (whitespace-p n) (line-break-p n))))))))
          (yaml-parse-fail 'yaml-scanner-error source
                           "Tab character used as indentation"))
        (let ((item (cond
                      ((source-eof-p source)
                       'null)
                      ;; A comment after `-` (`- # comment`) means the item node
                      ;; sits on a following, more-indented line, exactly as a
                      ;; bare line break would.
                      ((or (line-break-p (source-peek source))
                           (eql (source-peek source) #\#))
                       (setf consumed-newline-p t)
                       (source-skip-comment source)
                       (source-consume-line-break source)
                       (source-skip-blank-lines source)
                       (if (source-eof-p source)
                           'null
                           (let ((nested-indent (source-count-indent source)))
                             (if (> nested-indent dash-col)
                                 (progn
                                   (source-skip-indent source)
                                   (read-nested-value source nested-indent))
                                 'null))))
                      ((node-properties-here-p source)
                       (let* ((line0 (source-line source))
                              (v (read-node-properties-and-value source dash-col)))
                         ;; A collection value, or an empty value whose
                         ;; properties spanned the whole line (leaving the
                         ;; cursor parked at a later line), must suppress the
                         ;; trailing eol-consumption.
                         (when (or (hash-table-p v)
                                   (and (vectorp v) (not (stringp v)))
                                   (/= (source-line source) line0))
                           (setf consumed-newline-p t))
                         v))
                      ((eql (source-peek source) #\|)
                       (setf consumed-newline-p t)
                       (read-literal-scalar source dash-col))
                      ((eql (source-peek source) #\>)
                       (setf consumed-newline-p t)
                       (read-folded-scalar source dash-col))
                      ((eql (source-peek source) #\*)
                       (read-alias source))
                      ;; A nested block sequence beginning on the same line:
                      ;; `- - x`. The nested sequence's items align at the
                      ;; inner dash column.
                      ((and (eql (source-peek source) #\-)
                            (let ((n (source-peek source 1)))
                              (or (null n) (whitespace-p n) (line-break-p n))))
                       (setf consumed-newline-p t)
                       (read-block-sequence source))
                      ((eql (source-peek source) #\[)
                       (setf flow-item-p t)
                       (let ((*flow-indent* dash-col)) (read-flow-sequence source)))
                      ((eql (source-peek source) #\{)
                       (setf flow-item-p t)
                       (let ((*flow-indent* dash-col)) (read-flow-mapping source)))
                      ((eql (source-peek source) #\')
                       (read-single-quoted-scalar source))
                      ((eql (source-peek source) #\")
                       (read-double-quoted-scalar source))
                      ((looks-like-mapping-key-p source)
                       ;; A block mapping item leaves the cursor at the next
                       ;; line; running the eol-consumption would swallow it.
                       (setf consumed-newline-p t)
                       (read-block-mapping source))
                      (t (read-plain-scalar source (1+ dash-col))))))
          (vector-push-extend item items)
          ;; After a flow collection item, only whitespace and a comment may
          ;; follow on the line; inline trailing content (`- {y: z}- invalid`)
          ;; is malformed.
          (when flow-item-p
            (let ((blanks (source-skip-blanks source))
                  (c (source-peek source)))
              (when (and c (not (line-break-p c))
                         (not (and (char= c #\#) (> blanks 0))))
                (yaml-parse-fail 'yaml-structure-error source
                                 "Unexpected content after flow collection item"))))
          (unless consumed-newline-p
            (source-skip-to-eol source)
            (source-consume-line-break source)
            (source-skip-blank-and-comment-lines source))))
      (when (source-eof-p source)
        (return))
      ;; A comment-only line between entries (at any indent) is skipped; the
      ;; next real content line determines whether the sequence continues.
      (source-skip-blank-and-comment-lines source)
      (when (source-eof-p source)
        (return))
      (let ((new-indent (source-count-indent source)))
        (when (< new-indent seq-indent)
          (return))
        (when (> new-indent seq-indent)
          ;; A sequence entry indented deeper than its siblings is invalid.
          (when (let ((c (source-peek source new-indent)))
                  (and (eql c #\-)
                       (let ((n (source-peek source (1+ new-indent))))
                         (or (null n) (whitespace-p n) (line-break-p n)))))
            (source-skip-indent source)
            (yaml-parse-fail 'yaml-structure-error source
                             "Bad indentation of sequence entry"))
          (return))
        (source-skip-indent source)))
    (coerce items 'vector)))

;;; ---------------------------------------------------------------------------
;;; Literal block scalar reading
;;; ---------------------------------------------------------------------------

(defun parse-block-scalar-header (source)
  "Parse a block scalar header following the `|`/`>` indicator (already
consumed). Returns (values EXPLICIT-INDENT CHOMPING) where EXPLICIT-INDENT is
an integer 1-9 or NIL, and CHOMPING is :CLIP, :STRIP, or :KEEP. Signals on a
malformed header. Consumes through the trailing line break."
  (let ((explicit-indent nil)
        (chomping :clip))
    (dotimes (i 2)
      (let ((c (source-peek source)))
        (cond
          ((and (null explicit-indent) c (digit-char-p c) (char/= c #\0))
           (setf explicit-indent (digit-char-p c))
           (source-advance source))
          ((and c (char= c #\+))
           (when (eq chomping :strip)
             (yaml-parse-fail 'yaml-scanner-error source "Conflicting chomping indicators"))
           (setf chomping :keep)
           (source-advance source))
          ((and c (char= c #\-))
           (when (eq chomping :keep)
             (yaml-parse-fail 'yaml-scanner-error source "Conflicting chomping indicators"))
           (setf chomping :strip)
           (source-advance source))
          (t (return)))))
    ;; Reject any other indicator character (e.g. a 0 explicit indent) before
    ;; the line break / comment.
    (let ((blanks (source-skip-blanks source))
          (c (source-peek source)))
      (when (and c (not (line-break-p c))
                 ;; A comment must be separated by whitespace.
                 (not (and (char= c #\#) (> blanks 0))))
        (yaml-parse-fail 'yaml-scanner-error source
                         "Invalid block scalar header indicator")))
    (source-skip-comment source)
    (source-consume-line-break source)
    (values explicit-indent chomping)))

(defun apply-chomping (chars trailing-breaks chomping)
  "Append the chomped trailing line breaks to CHARS. TRAILING-BREAKS is the
number of line breaks following the last non-empty content line."
  (case chomping
    (:strip nil)
    (:clip (when (> trailing-breaks 0) (vector-push-extend #\Newline chars)))
    (:keep (dotimes (i trailing-breaks) (vector-push-extend #\Newline chars)))))

(defun read-block-scalar (source foldedp parent-indent)
  "Read a block scalar; FOLDEDP selects `>` folding vs `|` literal. PARENT-INDENT
is the indentation of the construct owning this scalar (keys/dashes); content
must be more indented than it. Handles indent/chomping indicators per YAML 1.2."
  (source-advance source) ; consume | or >
  (multiple-value-bind (explicit-indent chomping) (parse-block-scalar-header source)
    (let ((content-indent (when explicit-indent (+ parent-indent explicit-indent)))
          (lines '())            ; reversed list of (indent-stripped) content lines
          (leading-empties 0)
          (max-leading-empty-spaces 0) ; widest indentation among leading blank lines
          (auto-indent (null explicit-indent))
          (seen-content nil))
      ;; Phase 1: collect lines, auto-detecting indent from first non-empty line.
      (loop
        (when (source-eof-p source)
          (return))
        ;; Measure this line's leading spaces.
        (let ((spaces (source-count-indent source)))
          ;; Determine if it's an empty line (only spaces then break/eof).
          (let ((after (source-peek source spaces)))
            (cond
              ;; Empty / whitespace-only line.
              ((or (null after) (line-break-p after))
               (if seen-content
                   ;; A blank line indented past the content-indent keeps its
                   ;; extra spaces as content (e.g. the ` ` between paragraphs of
                   ;; a literal block); a blank line at or below content-indent
                   ;; is a true empty line (yaml-test-suite DWX9/T26H).
                   (if (and content-indent (> spaces content-indent))
                       (push (make-string (- spaces content-indent)
                                          :initial-element #\Space)
                             lines)
                       (push :empty lines))
                   (progn
                     (incf leading-empties)
                     (when (> spaces max-leading-empty-spaces)
                       (setf max-leading-empty-spaces spaces))
                     ;; A leading empty line more indented than detected content
                     ;; is tracked; if it exceeds content-indent the extra is
                     ;; content. We approximate by recording the spaces only when
                     ;; content-indent known.
                     (when (and content-indent (> spaces content-indent))
                       (push (make-string (- spaces content-indent) :initial-element #\Space) lines)
                       (setf seen-content t)
                       (setf leading-empties (1- leading-empties)))))
               (source-skip-to-eol source)
               (unless (source-consume-line-break source) (return)))
              ;; A `---`/`...` document marker at column 0 terminates the block
              ;; scalar: document markers can never be scalar content, even when
              ;; the scalar's content indent is 0 (a root block scalar such as
              ;; `--- |` whose content also sits at column 0). yaml-test-suite
              ;; W4TN / M7A3.
              ((and (zerop spaces)
                    (looks-like-document-marker source))
               (return))
              (t
               ;; Non-empty line. Establish content-indent if not yet known.
               (unless content-indent
                 (setf content-indent (max spaces (1+ parent-indent)))
                 ;; With auto-detected indentation, a preceding leading empty
                 ;; line may not be more indented than the first non-empty
                 ;; content line; doing so makes the indentation ambiguous and
                 ;; is a malformed block scalar (yaml-test-suite 5LLU/W9L4).
                 (when (and auto-indent (> max-leading-empty-spaces content-indent))
                   (yaml-parse-fail 'yaml-scanner-error source
                                    "Leading empty line more indented than block scalar content")))
               (when (< spaces content-indent)
                 ;; Dedent: scalar ends here.
                 (return))
               (setf seen-content t)
               (dotimes (i content-indent) (source-advance source))
               (let ((line (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
                 (loop for c = (source-peek source)
                       while (and c (not (line-break-p c)))
                       do (vector-push-extend c line)
                          (source-advance source))
                 (push (coerce line 'string) lines))
               (unless (source-consume-line-break source) (return)))))))
      (setf lines (nreverse lines))
      ;; Phase 2: assemble. Separate trailing empties for chomping.
      (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
        ;; Leading empty lines (before any content) contribute newlines.
        (dotimes (i leading-empties) (vector-push-extend #\Newline chars))
        ;; Count trailing :empty markers.
        (let* ((rev (reverse lines))
               (trailing 0))
          (loop for x in rev while (eq x :empty) do (incf trailing))
          (let ((content-lines (subseq lines 0 (- (length lines) trailing))))
            (if foldedp
                ;; Fold text lines, counting the empty lines between them. With
                ;; E empty lines between two text lines: emit E newlines, plus
                ;; one more newline if either line is "more indented" (kept
                ;; verbatim), or a single space when E=0 and neither is.
                (let ((emitted-text nil)
                      (prev-more nil)
                      (pending-empties 0))
                  (dolist (ln content-lines)
                    (if (eq ln :empty)
                        (incf pending-empties)
                        (let ((more (and (> (length ln) 0)
                                         (member (char ln 0) '(#\Space #\Tab)))))
                          (when emitted-text
                            (dotimes (i pending-empties) (vector-push-extend #\Newline chars))
                            (cond
                              ((or more prev-more)
                               (vector-push-extend #\Newline chars))
                              ((zerop pending-empties)
                               (vector-push-extend #\Space chars))))
                          (loop for c across ln do (vector-push-extend c chars))
                          (setf emitted-text t prev-more more pending-empties 0)))))
                ;; Literal: keep every line break.
                (let ((first t))
                  (dolist (ln content-lines)
                    (unless first (vector-push-extend #\Newline chars))
                    (setf first nil)
                    (if (eq ln :empty)
                        nil
                        (loop for c across ln do (vector-push-extend c chars))))))
            ;; trailing breaks = number of empties after last content + the
            ;; line break that ended the last content line (clip keeps one).
            (apply-chomping chars
                            (if (or content-lines (> leading-empties 0))
                                (+ trailing (if content-lines 1 0))
                                trailing)
                            chomping)))
        (coerce chars 'string)))))

(defun read-literal-scalar (source &optional (parent-indent 0))
  "Read a literal block scalar (|). Expects cursor at '|'."
  (unless (eql (source-peek source) #\|)
    (error 'yaml-scanner-error :message "Expected '|' for literal scalar"))
  (read-block-scalar source nil parent-indent))

(defun read-folded-scalar (source &optional (parent-indent 0))
  "Read a folded block scalar (>). Expects cursor at '>'."
  (unless (eql (source-peek source) #\>)
    (error 'yaml-scanner-error :message "Expected '>' for folded scalar"))
  (read-block-scalar source t parent-indent))

;;; ---------------------------------------------------------------------------
;;; Anchor/Alias handling
;;; ---------------------------------------------------------------------------

(defvar *anchor-table* nil
  "During parsing, maps anchor names to their resolved values.")

(defun anchor-char-p (char)
  "Return T if CHAR is valid in an anchor/alias name. Per YAML 1.2 an anchor name
is one or more non-whitespace characters excluding the flow indicators
`,`, `[`, `]`, `{`, `}`."
  (and char
       (not (whitespace-p char))
       (not (line-break-p char))
       (not (find char ",[]{}"))))

(defun read-anchor-name (source)
  "Read an anchor/alias name starting after & or *."
  (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop for char = (source-peek source)
          while (anchor-char-p char)
          do (vector-push-extend char chars)
             (source-advance source))
    (coerce chars 'string)))

(defun read-anchor (source)
  "Read an anchor definition (&name). Returns the anchor name."
  (unless (eql (source-peek source) #\&)
    (return-from read-anchor nil))
  (source-advance source)
  (let ((name (read-anchor-name source)))
    (source-skip-blanks source)
    name))

(defun read-alias (source)
  "Read an alias (*name) and resolve to the anchored value.
Signals yaml-reference-error if the anchor is undefined."
  (unless (eql (source-peek source) #\*)
    (return-from read-alias nil))
  (let ((pos (source-position source)))
    (source-advance source)
    (let ((name (read-anchor-name source)))
      (multiple-value-bind (value found-p) (gethash name *anchor-table*)
        (unless found-p
          (error 'yaml-reference-error
                 :anchor name
                 :message (format nil "Undefined anchor: ~A" name)
                 :position pos))
        value))))

;;; ---------------------------------------------------------------------------
;;; Block mapping reading
;;; ---------------------------------------------------------------------------

(defun read-mapping-key (source)
  "Read a mapping key. Quoted keys read as quoted scalars (preserving their
string value); plain keys read up to the `:` indicator and resolve via the
core schema."
  (let ((char (source-peek source)))
    (cond
      ((eql char #\') (read-single-quoted-scalar source))
      ((eql char #\") (read-double-quoted-scalar source))
      (t
       (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
             (prev nil))
         (loop for c = (source-peek source)
               while (and c
                          (not (line-break-p c))
                          ;; A `#` preceded by whitespace begins a comment and
                          ;; ends the plain key (`foo # bar` -> key `foo`).
                          (not (and (char= c #\#)
                                    (or (null prev) (whitespace-p prev))))
                          (not (and (char= c #\:)
                                    (let ((n (source-peek source 1)))
                                      (or (null n) (whitespace-p n) (line-break-p n))))))
               do (vector-push-extend c chars)
                  (setf prev c)
                  (source-advance source))
         (apply-scalar-tag (string-right-trim '(#\Space #\Tab) (coerce chars 'string))))))))

(defun read-explicit-key (source)
  "Read an explicit key after '?' indicator. Returns the key value.
Supports complex keys: block sequences/scalars on a following line, flow
collections, quoted strings, node properties, and plain scalars."
  (let ((q-indent (source-current-line-indent source)))
    (source-advance source) ; consume '?'
    ;; A tab in the separation after `?` that precedes a nested block construct
    ;; (a `-` sequence, a nested `?`, or a `key:` mapping) is a tab used as
    ;; indentation, which is forbidden (yaml-test-suite Y79Y/06, Y79Y/08).
    (let ((sep-has-tab nil))
      (loop for c = (source-peek source)
            while (and c (whitespace-p c))
            do (when (char= c #\Tab) (setf sep-has-tab t))
               (source-advance source))
      (when (and sep-has-tab (block-construct-here-p source))
        (yaml-parse-fail 'yaml-scanner-error source
                         "Tab character used as indentation")))
  (let ((char (source-peek source)))
    (cond
      ((eql char #\:)
       'null)
      ;; The key node sits on the following, more-indented line(s): a block
      ;; sequence, block scalar, or block mapping. A comment may follow the `?`
      ;; on its own line (`? # comment`), in which case the key node likewise
      ;; sits on the following line.
      ((or (null char) (line-break-p char) (eql char #\#))
       (source-skip-comment source)
       (source-consume-line-break source)
       (source-skip-blank-and-comment-lines source)
       (if (source-eof-p source)
           'null
           (let ((ni (source-count-indent source)))
             (if (> ni q-indent)
                 (progn (source-skip-indent source)
                        (read-nested-value source ni))
                 'null))))
      ((node-properties-here-p source)
       (read-node-properties-and-value source q-indent))
      ((and (eql char #\-)
            (let ((n (source-peek source 1)))
              (or (null n) (whitespace-p n) (line-break-p n))))
       (read-block-sequence source))
      ((eql char #\|) (read-literal-scalar source q-indent))
      ((eql char #\>) (read-folded-scalar source q-indent))
      ((eql char #\[)
       (let ((*flow-indent* (source-current-line-indent source))) (read-flow-sequence source)))
      ((eql char #\{)
       (let ((*flow-indent* (source-current-line-indent source))) (read-flow-mapping source)))
      ((eql char #\')
       (read-single-quoted-scalar source))
      ((eql char #\")
       (read-double-quoted-scalar source))
      (t
       (let ((chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
         (loop for c = (source-peek source)
               while (and c
                          (not (line-break-p c))
                          (not (and (char= c #\:)
                                    (or (null (source-peek source 1))
                                        (whitespace-p (source-peek source 1))
                                        (line-break-p (source-peek source 1))))))
               do (vector-push-extend c chars)
                  (source-advance source))
         (apply-scalar-tag (string-right-trim '(#\Space #\Tab) (coerce chars 'string)))))))))

(defun node-properties-here-p (source)
  "Return T if the cursor is at a node-property indicator (`&` anchor or `!` tag)."
  (let ((c (source-peek source)))
    (and c (or (char= c #\&) (char= c #\!)))))

(defun read-node-properties-and-value (source indent)
  "Read optional node properties (`&anchor` and/or `!tag`, in either order) at
the cursor, then the node they decorate, at block INDENT. The node may sit on
the same line or, after a line break, as a more-indented block collection.
Registers the anchor and returns the value."
  (let ((anchor nil)
        (tag nil)
        ;; Column where the property block begins. When the properties occupy
        ;; their whole line, the node they decorate may begin on the following
        ;; line at this same column (a bare `&anchor` on its own line decorating
        ;; an equally-indented block collection — yaml-test-suite U3XV/9KAX).
        (prop-col (source-column source)))
    ;; Consume any sequence of anchor/tag properties separated by blanks.
    (loop
      (cond
        ((eql (source-peek source) #\&)
         ;; READ-ANCHOR consumes the trailing separation itself.
         (setf anchor (read-anchor source)))
        ((eql (source-peek source) #\!)
         (setf tag (read-tag source nil))
         ;; A tag must be separated from a following property or its node by
         ;; whitespace (or end the line). Content glued to the tag
         ;; (`!!str, xxx`, `!invalid{}tag`) is malformed.
         (let ((c (source-peek source)))
           (when (and c (not (whitespace-p c)) (not (line-break-p c)))
             (yaml-parse-fail 'yaml-structure-error source
                              "Tag must be separated from its node by whitespace"))))
        (t (return)))
      (source-skip-blanks source))
    (let ((value
            (cond
              ;; Properties were the whole line (optionally followed by a
              ;; comment): the node is on the next, more-indented line (a block
              ;; collection) or is empty.
              ((or (null (source-peek source)) (line-break-p (source-peek source))
                   (eql (source-peek source) #\#))
               (source-skip-comment source)
               (source-consume-line-break source)
               (source-skip-blank-and-comment-lines source)
               (if (source-eof-p source)
                   ;; Empty node: `!!str` forces the empty string.
                   (if (equal tag "tag:yaml.org,2002:str") "" 'null)
                   (let ((nested (source-count-indent source)))
                     ;; The decorated node follows on its own line. It belongs to
                     ;; these properties when it is indented past the parent
                     ;; context (`> indent`) OR exactly at the property block's
                     ;; own column (`= prop-col`): a bare `&anchor` line anchors
                     ;; the equally-indented collection beneath it. When a
                     ;; *floor* is known (the enclosing block's indent), the node
                     ;; may even be SHALLOWER than the property line, as long as
                     ;; it stays strictly past that floor: a `!tag`/`&anchor`
                     ;; written more-indented than the block scalar it decorates
                     ;; (yaml-test-suite M5C3: `f:\n   !foo\n  >1\n value`).
                     (if (or (> nested indent)
                             (and (= nested prop-col) (>= prop-col 0))
                             (and *node-indent-floor*
                                  (> nested *node-indent-floor*)))
                         (progn (source-skip-indent source)
                                ;; A node may carry at most one anchor. If this
                                ;; property block already supplied an anchor and
                                ;; the node on the following line is itself a
                                ;; bare anchored scalar (`&a\n  &b scalar`), both
                                ;; anchors target the same node, which is invalid
                                ;; (yaml-test-suite 4JVG).
                                (when (and anchor
                                           (eql (source-peek source) #\&)
                                           (not (looks-like-mapping-key-p source)))
                                  (yaml-parse-fail 'yaml-structure-error source
                                                   "Node carries more than one anchor"))
                                (let ((*pending-tag* tag))
                                  (read-nested-value source nested)))
                         (if (equal tag "tag:yaml.org,2002:str") "" 'null)))))
              ;; A block-sequence indicator (`-`) cannot follow node properties
              ;; on the same line: `&anchor - sequence entry` is malformed.
              ((and (eql (source-peek source) #\-)
                    (let ((n (source-peek source 1)))
                      (or (null n) (whitespace-p n) (line-break-p n))))
               (yaml-parse-fail 'yaml-structure-error source
                                "Block sequence cannot follow node properties on the same line"))
              (t (let ((*pending-tag* tag))
                   (read-nested-value source indent))))))
      (when (and anchor *anchor-table*)
        (setf (gethash anchor *anchor-table*) value))
      value)))

(defun read-nested-value (source indent)
  "Read a nested value at the given INDENT level. Dispatches based on first character."
  (let ((char (source-peek source))
        ;; The node-indent floor applies only to THIS node: a block scalar (its
        ;; explicit indent indicator is relative to the floor) or a node-property
        ;; block that decorates a dedented node. For collections, which establish
        ;; their own indentation context, clear it so it cannot leak inward.
        (floor *node-indent-floor*))
    (cond
      ((null char) 'null)
      ((and (or (node-properties-here-p source) (eql char #\*))
            (looks-like-mapping-key-p source))
       (let ((*node-indent-floor* nil)) (read-block-mapping source)))
      ((node-properties-here-p source)
       (read-node-properties-and-value source indent))
      ((eql char #\*) (read-alias source))
      ((and (eql char #\-)
            (let ((n (source-peek source 1)))
              (or (null n) (whitespace-p n) (line-break-p n))))
       (let ((*node-indent-floor* nil)) (read-block-sequence source)))
      ((eql char #\[) (let ((*flow-indent* (1- indent)) (*node-indent-floor* nil)) (read-flow-sequence source)))
      ((eql char #\{) (let ((*flow-indent* (1- indent)) (*node-indent-floor* nil)) (read-flow-mapping source)))
      ((eql char #\') (read-single-quoted-scalar source))
      ((eql char #\") (read-double-quoted-scalar source))
      ;; A block scalar's explicit indent indicator is relative to the enclosing
      ;; block. Normally that is `(1- indent)`, but when this block scalar was
      ;; reached as a dedented node beneath a node-property line, the `>`/`|`
      ;; column no longer reflects the parent; *NODE-INDENT-FLOOR* carries the
      ;; true enclosing indent (yaml-test-suite M5C3).
      ((eql char #\|)
       (read-literal-scalar source (or floor (max 0 (1- indent)))))
      ((eql char #\>)
       (read-folded-scalar source (or floor (max 0 (1- indent)))))
      ((and (eql char #\?)
            (let ((n (source-peek source 1)))
              (or (null n) (whitespace-p n) (line-break-p n))))
       (let ((*node-indent-floor* nil)) (read-block-mapping source)))
      ((looks-like-mapping-key-p source)
       (let ((*node-indent-floor* nil)) (read-block-mapping source)))
      (t (read-plain-scalar source indent)))))

(defun read-explicit-value (source map-indent)
  "Read the value following an explicit key's `:` indicator (already consumed,
along with any inline comment). MAP-INDENT is the mapping's key indentation.
Handles inline scalars/collections and values on a following, deeper line, plus
a block sequence written at MAP-INDENT."
  (cond
    ((source-eof-p source) 'null)
    ((line-break-p (source-peek source))
     (source-consume-line-break source)
     (source-skip-blank-and-comment-lines source)
     (if (source-eof-p source)
         'null
         (let ((ni (source-count-indent source)))
           (cond
             ((> ni map-indent)
              (source-skip-indent source)
              (read-nested-value source ni))
             ;; A block sequence may sit at the mapping indent.
             ((and (= ni map-indent)
                   (eql (source-peek source ni) #\-)
                   (let ((n (source-peek source (1+ ni))))
                     (or (null n) (whitespace-p n) (line-break-p n))))
              (source-skip-indent source)
              (read-block-sequence source))
             (t 'null)))))
    ((node-properties-here-p source)
     ;; The decorated node sits inline after the `:`; a plain-scalar value must
     ;; fold continuations at the entry indent + 1, matching the bare-scalar
     ;; case below, so a following dedented `? key` is not swallowed.
     (read-node-properties-and-value source (1+ map-indent)))
    ((eql (source-peek source) #\*) (read-alias source))
    ((eql (source-peek source) #\|) (read-literal-scalar source map-indent))
    ((eql (source-peek source) #\>) (read-folded-scalar source map-indent))
    ((eql (source-peek source) #\[)
     (let ((*flow-indent* map-indent)) (read-flow-sequence source)))
    ((eql (source-peek source) #\{)
     (let ((*flow-indent* map-indent)) (read-flow-mapping source)))
    ((eql (source-peek source) #\') (read-single-quoted-scalar source))
    ((eql (source-peek source) #\") (read-double-quoted-scalar source))
    ;; A block sequence introduced inline (`: - one`) is a compact in-line
    ;; sequence belonging to the explicit key.
    ((and (eql (source-peek source) #\-)
          (let ((n (source-peek source 1)))
            (or (null n) (whitespace-p n) (line-break-p n))))
     (read-block-sequence source))
    (t (read-plain-scalar source (1+ map-indent)))))

(defun read-block-mapping (source)
  "Read a block mapping from SOURCE. Returns a hash-table (test EQUAL).
Supports both implicit keys (key: value) and explicit keys (? key : value)."
  (let ((table (make-hash-table :test #'equal))
        (map-indent (source-column source))
        (saw-explicit nil)
        ;; A mapping that begins on a `---` marker line is anchored at the
        ;; document root: it may only occupy that one line. The flag is consumed
        ;; here so nested collections do not inherit it.
        (root-marker-p *root-on-marker-line*)
        (*root-on-marker-line* nil)
        (*pending-tag* nil))
    (loop named outer do
     (block iter
      (source-skip-blanks source)
      (when (source-eof-p source)
        (return-from outer))
      ;; A document marker at the mapping indent ends the mapping.
      (when (looks-like-document-marker source)
        (return-from outer))
      ;; A mapping that began on the `---` marker line may not continue onto a
      ;; following line: the continuation is over-indented relative to the
      ;; document root (yaml-test-suite 9KBC).
      (when (and root-marker-p (> (hash-table-count table) 0))
        (yaml-parse-fail 'yaml-structure-error source
                         "Block mapping on document-start line cannot continue"))
      ;; --- Explicit key (`? key` / `: value`) --------------------------------
      (when (and (eql (source-peek source) #\?)
                 (let ((n (source-peek source 1)))
                   (or (null n) (whitespace-p n) (line-break-p n))))
        (setf saw-explicit t)
        (let* ((key-line0 (source-line source))
               (key (let ((*in-explicit-entry* t)) (read-explicit-key source)))
               (at-line-start nil))   ; T once the cursor is parked at a fresh line
          ;; If reading the key already advanced past its line AND parked the
          ;; cursor at a dedented sibling/parent line (e.g. an empty anchored key
          ;; `? &d` whose properties spanned the whole line, leaving the cursor
          ;; on the next, less-indented entry), there is no `:` pairing: the key
          ;; is null-valued and the cursor is already at the next entry.
          (when (and (/= (source-line source) key-line0)
                     (not (source-eof-p source))
                     (< (source-count-indent source) map-indent))
            (setf at-line-start t))
          ;; Locate the matching `:` (possibly after blank / comment lines at the
          ;; mapping indent) or conclude a null-valued key.
          (source-skip-blanks source)
          (source-skip-comment source)
          (let ((had-colon
                  (cond
                    (at-line-start nil)
                    ((eql (source-peek source) #\:) t)
                    ((or (null (source-peek source)) (line-break-p (source-peek source)))
                     (source-consume-line-break source)
                     (source-skip-blank-and-comment-lines source)
                     (cond
                       ((and (not (source-eof-p source))
                             (= (source-count-indent source) map-indent)
                             (eql (source-peek source map-indent) #\:))
                        (source-skip-indent source)
                        t)
                       (t (setf at-line-start t) nil)))
                    (t nil))))
            (let ((value
                    (if had-colon
                        (progn
                          (source-advance source) ; consume :
                          ;; A tab in the separation after the explicit-value `:`
                          ;; that precedes a nested block construct is a tab used
                          ;; as indentation (yaml-test-suite Y79Y/07, Y79Y/09).
                          (let ((sep-has-tab nil))
                            (loop for c = (source-peek source)
                                  while (and c (whitespace-p c))
                                  do (when (char= c #\Tab) (setf sep-has-tab t))
                                     (source-advance source))
                            (when (and sep-has-tab (block-construct-here-p source))
                              (yaml-parse-fail 'yaml-scanner-error source
                                               "Tab character used as indentation")))
                          (source-skip-comment source)
                          (let ((v (let ((*in-explicit-entry* t))
                                     (read-explicit-value source map-indent))))
                            ;; A collection value parks at a line start.
                            (when (or (hash-table-p v)
                                      (and (vectorp v) (not (stringp v))))
                              (setf at-line-start t))
                            v))
                        'null)))
              (when (nth-value 1 (gethash key table))
                (error 'yaml-duplicate-key-error
                       :key key
                       :message (format nil "Duplicate mapping key: ~S" key)
                       :position (source-position source)))
              (setf (gethash key table) value)))
          ;; Position at the next entry / end.
          (unless at-line-start
            (source-skip-to-eol source)
            (source-consume-line-break source)
            (source-skip-blank-and-comment-lines source)))
        (when (source-eof-p source)
          (return-from outer))
        (let ((ni (source-count-indent source)))
          (when (< ni map-indent) (return-from outer))
          (when (> ni map-indent) (return-from outer))
          (source-skip-indent source))
        (return-from iter))
      ;; A key may carry node properties (`&anchor` / `!tag`) or be an alias
      ;; (`*alias`). Consume any leading property block, registering an anchor to
      ;; the key node and resolving an alias key by shared object identity.
      (let ((key-anchor nil)
            (key-alias-value nil)
            (key-is-alias nil)
            (key-tagged nil)
            (key-tag nil))
        (loop
          (let ((c (source-peek source)))
            (cond
              ((eql c #\&) (setf key-anchor (read-anchor source)))
              ((eql c #\!) (setf key-tag (read-tag source nil)) (setf key-tagged t)
               (source-skip-blanks source))
              ((eql c #\*)
               ;; An alias node takes no node properties: `&b *a` is invalid.
               (when (or key-anchor key-tagged)
                 (yaml-parse-fail 'yaml-structure-error source
                                  "Alias node cannot carry node properties"))
               (setf key-alias-value (read-alias source) key-is-alias t)
               (source-skip-blanks source)
               (return))
              (t (return)))))
      ;; A node property (`&anchor` / `!tag`) on a mapping key that begins on the
      ;; `---` marker line is malformed: the anchored/tagged node would have to
      ;; start on the marker line, which is not allowed (yaml-test-suite CXX2).
      (when (and root-marker-p (= (hash-table-count table) 0)
                 (or key-anchor key-tagged))
        (yaml-parse-fail 'yaml-structure-error source
                         "Node property on mapping key on document-start line"))
      (let* ((key-quoted-p (or (eql (source-peek source) #\')
                               (eql (source-peek source) #\")))
             (key-start-line (source-line source))
             (key (cond
                    (key-is-alias key-alias-value)
                    (t (let ((*pending-tag* key-tag))
                         (read-mapping-key source))))))
        (declare (ignorable key-tagged))
        (when key-anchor
          (setf (gethash key-anchor *anchor-table*) key))
        ;; An implicit key that is a quoted scalar must fit on a single line.
        (when (and key-quoted-p (/= (source-line source) key-start-line))
          (yaml-parse-fail 'yaml-structure-error source
                           "Multi-line implicit mapping key is not allowed"))
        (when (and (stringp key) (string= key ""))
          (return-from outer))
        (source-skip-blanks source)
        (unless (eql (source-peek source) #\:)
          ;; A non-empty scalar that is not followed by `:` does not form a
          ;; mapping entry. Inside an established mapping this is malformed
          ;; trailing content (e.g. `top1:\n  k: v\ntop2`).
          (when (and (> (hash-table-count table) 0)
                     (or (and (stringp key)
                              (> (length key) 0)
                              ;; Exclude indicator-led lines handled elsewhere.
                              (not (member (char key 0) '(#\- #\? #\:))))
                         ;; Node properties (`&anchor` / `!tag`) consumed but no
                         ;; `:` follows: malformed trailing content.
                         key-anchor key-tagged))
            (yaml-parse-fail 'yaml-structure-error source
                             "Expected ':' in block mapping entry"))
          (return-from outer))
        (source-advance source)
        (source-skip-blanks source)
        ;; A comment may follow the `:` on the key line; the value then sits on
        ;; a following line.
        (when (eql (source-peek source) #\#)
          (source-skip-comment source))
        (when (nth-value 1 (gethash key table))
          (error 'yaml-duplicate-key-error
                 :key key
                 :message (format nil "Duplicate mapping key: ~S" key)
                 :position (source-position source)))
        (let ((anchor-name nil)
              (nested-p nil)
              (quoted-value-p nil)
              (flow-value-p nil))
          ;; The value may carry node properties (`&anchor` and/or `!tag`, in
          ;; either order) before the node itself.
          (let ((had-property nil)
                (val-tag nil))
            (loop
              (cond
                ((eql (source-peek source) #\&)
                 (setf anchor-name (read-anchor source) had-property t))
                ((eql (source-peek source) #\!)
                 (setf val-tag (read-tag source nil)) (setf had-property t)
                 (source-skip-blanks source))
                (t (return))))
            ;; An alias node takes no node properties: `key: &b *a` is invalid.
            (when (and had-property (eql (source-peek source) #\*))
              (yaml-parse-fail 'yaml-structure-error source
                               "Alias node cannot carry node properties"))
          (setf quoted-value-p (or (eql (source-peek source) #\')
                                   (eql (source-peek source) #\")))
          (let ((value (let ((*pending-tag* val-tag)) (cond
                         ((source-eof-p source)
                          'null)
                         ;; A comment after the value's node properties
                         ;; (`key: &anchor # comment`) means the node itself sits
                         ;; on a following line, just as a bare line break would.
                         ((or (line-break-p (source-peek source))
                              (and had-property (eql (source-peek source) #\#)))
                          (source-skip-comment source)
                          (source-consume-line-break source)
                          (source-skip-blank-and-comment-lines source)
                          (if (source-eof-p source)
                              ;; Cursor is at EOF: nothing more to consume.
                              (progn (setf nested-p t) 'null)
                              (let ((nested-indent (source-count-indent source)))
                                (cond
                                  ((> nested-indent map-indent)
                                   (source-skip-indent source)
                                   ;; A node may carry at most one anchor. If the
                                   ;; value already supplied an anchor and the
                                   ;; node on the following line is a bare
                                   ;; anchored scalar (`k: &a\n  &b scalar`),
                                   ;; both anchors target the same node, which is
                                   ;; invalid (yaml-test-suite 4JVG).
                                   (when (and anchor-name
                                              (eql (source-peek source) #\&)
                                              (not (looks-like-mapping-key-p source)))
                                     (yaml-parse-fail 'yaml-structure-error source
                                                      "Node carries more than one anchor"))
                                   (let ((v (let ((*node-indent-floor* map-indent))
                                              (read-nested-value source nested-indent))))
                                     ;; Collections position the cursor past
                                     ;; their content; leaf scalars leave it
                                     ;; on the trailing line, so let the
                                     ;; common eol-consumption run for them.
                                     (when (or (hash-table-p v) (and (vectorp v) (not (stringp v))))
                                       (setf nested-p t))
                                     v))
                                  ;; A block sequence may be written at the same
                                  ;; indentation as its parent mapping key.
                                  ((and (= nested-indent map-indent)
                                        (eql (source-peek source nested-indent) #\-)
                                        (let ((n (source-peek source (1+ nested-indent))))
                                          (or (null n) (whitespace-p n) (line-break-p n))))
                                   (source-skip-indent source)
                                   (setf nested-p t)
                                   (read-block-sequence source))
                                  ;; Empty value: the next line belongs to a
                                  ;; sibling/ancestor, not this entry. The cursor
                                  ;; is parked at that line's start, so suppress
                                  ;; the trailing eol-consumption.
                                  (t (setf nested-p t) 'null)))))
                         ((eql (source-peek source) #\*)
                          (read-alias source))
                         ((eql (source-peek source) #\|)
                          (setf nested-p t)
                          (read-literal-scalar source map-indent))
                         ((eql (source-peek source) #\>)
                          (setf nested-p t)
                          (read-folded-scalar source map-indent))
                         ((eql (source-peek source) #\[)
                          (setf flow-value-p t)
                          (let ((*flow-indent* map-indent)) (read-flow-sequence source)))
                         ((eql (source-peek source) #\{)
                          (setf flow-value-p t)
                          (let ((*flow-indent* map-indent)) (read-flow-mapping source)))
                         ((eql (source-peek source) #\')
                          (let ((*quoted-min-indent* (1+ map-indent)))
                            (read-single-quoted-scalar source)))
                         ((eql (source-peek source) #\")
                          (let ((*quoted-min-indent* (1+ map-indent)))
                            (read-double-quoted-scalar source)))
                         (t (read-plain-scalar source (1+ map-indent)))))))
            (when (and anchor-name *anchor-table*)
              (setf (gethash anchor-name *anchor-table*) value))
            (if (and (stringp key) (string= key "<<") (hash-table-p value))
                (maphash (lambda (k v)
                           (unless (nth-value 1 (gethash k table))
                             (setf (gethash k table) v)))
                         value)
                (setf (gethash key table) value))
            (unless nested-p
              ;; After a quoted scalar value, only whitespace and a comment may
              ;; follow on the line; trailing content is an error.
              (when quoted-value-p
                (let ((blanks (source-skip-blanks source))
                      (c (source-peek source)))
                  (when (and c (not (line-break-p c))
                             (not (and (char= c #\#) (> blanks 0))))
                    (yaml-parse-fail 'yaml-structure-error source
                                     "Unexpected content after quoted scalar value"))))
              ;; After a flow collection value, only whitespace and a comment may
              ;; follow on the line; inline trailing content (`x: {y: z}in`) is
              ;; malformed.
              (when flow-value-p
                (let ((blanks (source-skip-blanks source))
                      (c (source-peek source)))
                  (when (and c (not (line-break-p c))
                             (not (and (char= c #\#) (> blanks 0))))
                    (yaml-parse-fail 'yaml-structure-error source
                                     "Unexpected content after flow collection value"))))
              ;; After a plain scalar value, a second `:` mapping indicator on the
              ;; same line (`a: b: c: d`) is malformed: a block mapping value
              ;; cannot itself be a bare `key: value` pair on the value line.
              ;; This applies only to a genuine implicit `key: value` entry in a
              ;; mapping with no explicit `?`/`:` entries (where a `:` at the
              ;; mapping indent is an explicit-value indicator, not trailing
              ;; content) and not while reading an explicit entry's node.
              (unless (or quoted-value-p flow-value-p *in-explicit-entry*
                          saw-explicit (not (stringp value)))
                (let ((c (source-peek source)))
                  (when (and (eql c #\:)
                             (let ((n (source-peek source 1)))
                               (or (null n) (whitespace-p n) (line-break-p n))))
                    (yaml-parse-fail 'yaml-structure-error source
                                     "Unexpected ':' after mapping value"))))
              (source-skip-to-eol source)
              (source-consume-line-break source)
              (source-skip-blank-and-comment-lines source)))))
        (when (source-eof-p source)
          (return-from outer))
        (let ((new-indent (source-count-indent source)))
          ;; A tab in the position where a mapping continuation line's
          ;; indentation ends (`\tb:` or `  \tb:`) is a tab used as indentation,
          ;; which YAML forbids (yaml-test-suite 4EJS, DK95/06).
          (when (eql (source-peek source new-indent) #\Tab)
            (yaml-parse-fail 'yaml-scanner-error source
                             "Tab character used as indentation"))
          (when (< new-indent map-indent)
            (return-from outer))
          (when (> new-indent map-indent)
            ;; A following line indented deeper than the mapping's keys that
            ;; itself forms a new `key:` entry is invalid indentation. Other
            ;; deeper content (explicit `?` keys, blanks) is left to the caller.
            (source-skip-indent source)
            (cond
              ((and (not saw-explicit) (looks-like-mapping-key-p source))
               (yaml-parse-fail 'yaml-structure-error source
                                "Bad indentation of mapping entry"))
              ;; Deeper content that begins with a plain word (no YAML indicator)
              ;; and forms no `key:` entry is stray over-indented content:
              ;; malformed (e.g. `key:\n - a\n invalid`).
              ((and (not saw-explicit)
                    (let ((c (source-peek source)))
                      (and c (or (alphanumericp c)
                                 (find c "._/\\")))))
               (yaml-parse-fail 'yaml-structure-error source
                                "Bad indentation of mapping entry"))
              (t
               (setf (source-index source) (- (source-index source) new-indent)
                     (source-column source) 0)
               (return-from outer))))
          (source-skip-indent source))))))
    table))

;;; ---------------------------------------------------------------------------
;;; Directive parsing
;;; ---------------------------------------------------------------------------

(defun parse-yaml-directive (source)
  "Parse a %YAML version directive. Returns (MAJOR . MINOR) version cons.
Expects cursor to be at the '%' of '%YAML'."
  (unless (source-match source "%YAML")
    (error 'yaml-directive-error :message "Expected %YAML directive"))
  (source-skip-blanks source)
  (let ((major-chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
        (minor-chars (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop for char = (source-peek source)
          while (and char (digit-char-p char))
          do (vector-push-extend char major-chars)
             (source-advance source))
    (unless (eql (source-peek source) #\.)
      (error 'yaml-directive-error :message "Expected '.' in YAML version"))
    (source-advance source)
    (loop for char = (source-peek source)
          while (and char (digit-char-p char))
          do (vector-push-extend char minor-chars)
             (source-advance source))
    (when (zerop (length major-chars))
      (error 'yaml-directive-error :message "Missing major version in %YAML"))
    (when (zerop (length minor-chars))
      (error 'yaml-directive-error :message "Missing minor version in %YAML"))
    ;; The version must be terminated by whitespace, a comment, a line break, or
    ;; EOF. Trailing junk glued to the version (e.g. `%YAML 1.1#...`) is invalid.
    (let ((c (source-peek source)))
      (unless (or (null c) (whitespace-p c) (line-break-p c))
        (error 'yaml-directive-error
               :message "Unexpected content after %YAML version")))
    (cons (parse-integer (coerce major-chars 'string))
          (parse-integer (coerce minor-chars 'string)))))

(defun parse-tag-directive (source)
  "Parse a %TAG directive. Returns (HANDLE . PREFIX) cons.
Expects cursor to be at the '%' of '%TAG'.
Handle is like !yaml!, !!, or !e!. Prefix is a URI prefix."
  (unless (source-match source "%TAG")
    (error 'yaml-directive-error :message "Expected %TAG directive"))
  (source-skip-blanks source)
  (let ((handle (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
        (prefix (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (unless (eql (source-peek source) #\!)
      (error 'yaml-directive-error :message "Tag handle must start with !"))
    (vector-push-extend (source-advance source) handle)
    (loop for char = (source-peek source)
          while (and char (not (whitespace-p char)))
          do (vector-push-extend char handle)
             (source-advance source))
    (source-skip-blanks source)
    (loop for char = (source-peek source)
          while (and char (not (whitespace-p char)) (not (line-break-p char)))
          do (vector-push-extend char prefix)
             (source-advance source))
    (cons (coerce handle 'string)
          (coerce prefix 'string))))

;;; ---------------------------------------------------------------------------
;;; Flow sequence reading
;;; ---------------------------------------------------------------------------

(defun read-flow-sequence (source)
  "Read a flow sequence [...] from SOURCE. Opening bracket must be current char.
Returns a vector of items."
  (unless (eql (source-peek source) #\[)
    (error 'yaml-scanner-error :message "Expected opening bracket"))
  (let ((items (make-array 0 :adjustable t :fill-pointer 0))
        (*pending-tag* nil))
    (source-advance source) ; consume [
    (flow-skip-separation source)
    (loop
      (flow-skip-separation source)
      (when (eql (source-peek source) #\])
        (source-advance source)
        (return (coerce items 'vector)))
      (when (source-eof-p source)
        (error 'yaml-scanner-error :message "Unterminated flow sequence"))
      ;; A `,` where a flow entry is expected is an empty entry (leading comma
      ;; `[ , a]` or doubled comma `[a, , b]`): invalid.
      (when (eql (source-peek source) #\,)
        (yaml-parse-fail 'yaml-structure-error source
                         "Empty entry in flow sequence"))
      ;; A flow sequence entry may itself be `key: value` (a single-pair flow
      ;; mapping) when a `:` follows the node.
      (multiple-value-bind (item colon-after-break) (read-flow-node source)
        (let ((sep-breaks (flow-skip-separation source)))
        ;; A flow-sequence entry that is a single `key: value` pair requires the
        ;; key and its `:` to be on the same line.
        (when (and (or (> sep-breaks 0) colon-after-break)
                   (eql (source-peek source) #\:)
                   (let ((n (source-peek source 1)))
                     (or (null n) (whitespace-p n) (line-break-p n)
                         (find n ",[]{}"))))
          (yaml-parse-fail 'yaml-structure-error source
                           "Implicit flow key and its ':' span multiple lines"))
        (if (and (eql (source-peek source) #\:)
                 (let ((n (source-peek source 1)))
                   (or (null n) (whitespace-p n) (line-break-p n)
                       (find n ",[]{}"))))
            (progn
              (source-advance source) ; consume :
              (source-skip-flow-whitespace source)
              (let ((value (if (or (null (source-peek source))
                                   (find (source-peek source) ",]}"))
                               'null
                               (read-flow-node source)))
                    (ht (make-hash-table :test #'equal)))
                (setf (gethash item ht) value)
                (vector-push-extend ht items)))
            (vector-push-extend item items))))
      (flow-skip-separation source)
      (cond
        ((eql (source-peek source) #\,)
         (source-advance source))
        ((eql (source-peek source) #\])
         nil) ; will be consumed on next iteration
        (t
         (error 'yaml-scanner-error :message "Expected , or ] in flow sequence"))))))

(defun flow-skip-separation (source)
  "Skip inter-token separation in flow context (blanks, line breaks, comments),
then enforce flow rules on the line landed on: continuation content must be
indented past *FLOW-INDENT*, document markers may not appear, and a `#` that
begins a comment must be preceded by whitespace. Returns the line-break count."
  (let ((breaks (source-skip-flow-whitespace source)))
    (when (> breaks 0)
      (let ((c (source-peek source)))
        (when (and c (not (line-break-p c)))
          ;; A flow continuation line carrying content may not begin its
          ;; indentation with a tab (yaml-test-suite Y79Y/03). The leading
          ;; whitespace must be spaces; a tab as the line's first character is a
          ;; tab used as indentation. (A tab on an otherwise-blank line is fine,
          ;; and a leading tab before a flow open with no preceding break is also
          ;; fine -- both leave us with breaks accounted for / no content here.)
          (let ((line-start (- (source-index source) (source-column source))))
            (when (and *flow-indent* (>= *flow-indent* 0)
                       (< line-start (length (source-text source)))
                       (char= (char (source-text source) line-start) #\Tab))
              (yaml-parse-fail 'yaml-scanner-error source
                               "Tab character used as indentation")))
          (when (and *flow-indent* (<= (source-column source) *flow-indent*))
            (yaml-parse-fail 'yaml-structure-error source
                             "Flow content is under-indented"))
          (when (looks-like-document-marker source)
            (yaml-parse-fail 'yaml-structure-error source
                             "Document marker inside flow collection")))))
    breaks))

(defun read-flow-node (source)
  "Read a flow node (scalar, sequence, or mapping) within flow context. Returns
the node, and as a second value T when a plain scalar ended at a `:` reached
only after a line break (a multi-line implicit-key situation)."
  (flow-skip-separation source)
  ;; A flow node may carry node properties (`&anchor` and/or `!tag`).
  (let ((anchor nil) (tag nil))
    (loop
      (cond
        ((eql (source-peek source) #\&) (setf anchor (read-anchor source)))
        ((eql (source-peek source) #\!) (setf tag (read-tag source nil)))
        (t (return)))
      (flow-skip-separation source))
    (let ((char (source-peek source))
          (*pending-tag* tag))
      (multiple-value-bind (node colon-after-break)
          (cond
            ((null char) 'null)
            ;; An empty flow node (the next token closes/separates the entry, or
            ;; is a value-introducing `:`) takes the null value, which `!!str`
            ;; forces to the empty string. A `:` that is NOT followed by a
            ;; separator begins a plain scalar (`:x`) and is not empty.
            ((or (find char ",]}")
                 (and (eql char #\:)
                      (let ((n (source-peek source 1)))
                        (or (null n) (whitespace-p n) (line-break-p n)
                            (find n ",[]{}")))))
             (if (equal tag "tag:yaml.org,2002:str") "" 'null))
            ((eql char #\[) (read-flow-sequence source))
            ((eql char #\{) (read-flow-mapping source))
            ((eql char #\') (read-single-quoted-scalar source))
            ((eql char #\") (read-double-quoted-scalar source))
            (t (read-flow-plain-scalar source)))
        (when (and anchor *anchor-table*)
          (setf (gethash anchor *anchor-table*) node))
        (values node colon-after-break)))))

(defun flow-plain-scalar-end-here-p (source)
  "Return T if the cursor ends a flow plain scalar: at a flow indicator, or at a
`:` that is followed by whitespace/break/flow-indicator/EOF, or at a `#` comment
preceded by whitespace, or at a line break/EOF."
  (let ((char (source-peek source)))
    (cond
      ((null char) t)
      ((line-break-p char) t)
      ((find char ",[]{}") t)
      ((and (char= char #\:)
            (let ((n (source-peek source 1)))
              (or (null n) (whitespace-p n) (line-break-p n)
                  (find n ",[]{}"))))
       t)
      (t nil))))

(defun read-flow-plain-scalar (source)
  "Read a (possibly multi-line) plain scalar within flow context. Terminates at
flow indicators, at a `:` that introduces a value, at a comment, or at the end
of the flow collection. Interior line breaks fold like block plain scalars."
  ;; A plain scalar may not begin with the comment indicator.
  (when (eql (source-peek source) #\#)
    (yaml-parse-fail 'yaml-scanner-error source
                     "Plain scalar may not begin with '#'"))
  ;; A `-` (block sequence indicator) followed by whitespace/break/flow-
  ;; indicator/EOF is not a valid flow scalar: `[-]`, `[-, -]`.
  (when (and (eql (source-peek source) #\-)
             (let ((n (source-peek source 1)))
               (or (null n) (whitespace-p n) (line-break-p n)
                   (find n ",[]{}"))))
    (yaml-parse-fail 'yaml-scanner-error source
                     "'-' is not a valid flow scalar"))
  (let ((result (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
        (colon-after-break nil))
    (labels ((read-segment ()
               (let ((seg (make-array 0 :element-type 'character
                                        :adjustable t :fill-pointer 0)))
                 (loop until (flow-plain-scalar-end-here-p source)
                       do ;; `#` starts a comment only when preceded by space.
                          (when (and (eql (source-peek source) #\#)
                                     (let ((p (source-peek source -1)))
                                       (or (null p) (whitespace-p p))))
                            (return))
                          (vector-push-extend (source-peek source) seg)
                          (source-advance source))
                 (string-right-trim '(#\Space #\Tab) (coerce seg 'string)))))
      (loop for ch across (read-segment) do (vector-push-extend ch result))
      ;; Fold continuation lines until a flow indicator or end. A comment line
      ;; interrupting the scalar terminates it (the next token must then be a
      ;; separator, else a structure error).
      (loop
        (unless (line-break-p (source-peek source))
          (return))
        (let ((breaks 0)
              (saw-comment nil))
          (loop
            (let ((blanks (source-skip-blanks source)))
              (cond
                ((and (eql (source-peek source) #\#)
                      (let ((p (source-peek source -1)))
                        (or (> blanks 0) (null p) (line-break-p p))))
                 (setf saw-comment t)
                 (source-skip-comment source))
                ((line-break-p (source-peek source))
                 (source-consume-line-break source)
                 (incf breaks))
                (t (return)))))
          (when (or saw-comment
                    (source-eof-p source)
                    (find (source-peek source) ",[]{}")
                    (eql (source-peek source) #\:)
                    (and (> breaks 0) *flow-indent*
                         (<= (source-column source) *flow-indent*)))
            (when (and (> breaks 0) *flow-indent* (not saw-comment)
                       (not (source-eof-p source))
                       (not (find (source-peek source) ",[]{}:"))
                       (<= (source-column source) *flow-indent*))
              (yaml-parse-fail 'yaml-structure-error source
                               "Flow content is under-indented"))
            (when (and (> breaks 0) (eql (source-peek source) #\:))
              (setf colon-after-break t))
            (return))
          (if (= breaks 1)
              (vector-push-extend #\Space result)
              (dotimes (i (1- breaks)) (vector-push-extend #\Newline result)))
          (loop for ch across (read-segment) do (vector-push-extend ch result)))))
    (values (apply-scalar-tag (coerce result 'string)) colon-after-break)))

;;; ---------------------------------------------------------------------------
;;; Flow mapping reading
;;; ---------------------------------------------------------------------------

(defun read-flow-mapping (source)
  "Read a flow mapping {...} from SOURCE. Opening brace must be current char.
Returns a hash-table (test EQUAL)."
  (unless (eql (source-peek source) #\{)
    (error 'yaml-scanner-error :message "Expected opening brace"))
  (let ((table (make-hash-table :test #'equal))
        (*pending-tag* nil))
    (source-advance source) ; consume {
    (flow-skip-separation source)
    (loop
      (flow-skip-separation source)
      (when (eql (source-peek source) #\})
        (source-advance source)
        (return table))
      (when (source-eof-p source)
        (error 'yaml-scanner-error :message "Unterminated flow mapping"))
      (cond
        ;; Explicit key: `? key : value` inside flow.
        ((and (eql (source-peek source) #\?)
              (let ((n (source-peek source 1)))
                (or (null n) (whitespace-p n) (line-break-p n))))
         (source-advance source)
         (source-skip-flow-whitespace source)
         (let ((key (if (or (eql (source-peek source) #\:)
                            (find (source-peek source) ",}"))
                        'null
                        (read-flow-node source))))
           (source-skip-flow-whitespace source)
           (let ((value (if (eql (source-peek source) #\:)
                            (progn
                              (source-advance source)
                              (source-skip-flow-whitespace source)
                              (if (find (source-peek source) ",}")
                                  'null
                                  (read-flow-node source)))
                            'null)))
             (setf (gethash key table) value))))
        (t
         (let ((key (read-flow-mapping-key source)))
           (source-skip-flow-whitespace source)
           (let ((value (cond
                          ((eql (source-peek source) #\:)
                           (source-advance source) ; consume :
                           (source-skip-flow-whitespace source)
                           (if (find (source-peek source) ",}")
                               'null
                               (read-flow-node source)))
                          ;; A bare entry with no `:` is a key with null value
                          ;; only at a separator/close (e.g. `{a, b}`).
                          ((find (source-peek source) ",}")
                           'null)
                          (t
                           (error 'yaml-scanner-error
                                  :message "Expected : after mapping key")))))
             (setf (gethash key table) value)))))
      (source-skip-flow-whitespace source)
      (cond
        ((eql (source-peek source) #\,)
         (source-advance source))
        ((eql (source-peek source) #\})
         nil) ; will be consumed on next iteration
        (t
         (error 'yaml-scanner-error :message "Expected , or } in flow mapping"))))))

(defun read-flow-mapping-key (source)
  "Read a flow mapping key (which may carry node properties, e.g. `!!str`)."
  (values (read-flow-node source)))

;;; ---------------------------------------------------------------------------
;;; Document reading
;;; ---------------------------------------------------------------------------

(defun skip-document-preamble (source)
  "Skip whitespace, blank lines, and comments before document content.
Returns T if content follows, NIL if at EOF."
  (loop
    (source-skip-whitespace-and-comments source)
    (when (source-eof-p source)
      (return nil))
    (when (or (source-match-document-start source)
              (source-match-document-end source))
      (source-skip-blanks source)
      (source-skip-comment source)
      (source-consume-line-break source))
    (unless (or (source-eof-p source)
                (line-break-p (source-peek source)))
      (return t))))

(defun looks-like-mapping-key-p (source)
  "Check if current position looks like a mapping key: a `:` followed by a
blank/EOF appears on this line, outside of any quoted region. Quoted spans
(single and double) are skipped so a `:` inside them does not count."
  (let ((i 0))
    ;; Skip a leading node-property / alias prefix (`&anchor`, `!tag`, `*alias`,
    ;; in any order, blank-separated) so that an anchored or aliased KEY such as
    ;; `&a a: b` or `*alias : v` is still recognised as a mapping key.
    (loop
      (let ((c (source-peek source i)))
        (cond
          ((and c (member c '(#\& #\* #\!)))
           (incf i)
           (loop for d = (source-peek source i)
                 while (and d (not (whitespace-p d)) (not (line-break-p d)))
                 do (incf i))
           (loop for d = (source-peek source i)
                 while (and d (whitespace-p d))
                 do (incf i)))
          (t (return)))))
    (loop
      (let ((char (source-peek source i)))
        (cond
          ((or (null char) (line-break-p char))
           (return nil))
          ;; A quote only opens a quoted span at a node boundary (start of line
          ;; or after whitespace); elsewhere it is an ordinary plain character.
          ((and (char= char #\')
                (let ((p (source-peek source (1- i))))
                  (or (zerop i) (null p) (whitespace-p p))))
           (incf i)
           (loop
             (let ((c (source-peek source i)))
               (cond
                 ((or (null c) (line-break-p c)) (return-from looks-like-mapping-key-p nil))
                 ((char= c #\')
                  (if (eql (source-peek source (1+ i)) #\')
                      (incf i 2)
                      (progn (incf i) (return))))
                 (t (incf i))))))
          ;; Skip a double-quoted span: "..." with \" escapes.
          ((and (char= char #\")
                (let ((p (source-peek source (1- i))))
                  (or (zerop i) (null p) (whitespace-p p))))
           (incf i)
           (loop
             (let ((c (source-peek source i)))
               (cond
                 ((or (null c) (line-break-p c)) (return-from looks-like-mapping-key-p nil))
                 ((char= c #\\) (incf i 2))
                 ((char= c #\") (incf i) (return))
                 (t (incf i))))))
          ((and (char= char #\:)
                (let ((next (source-peek source (1+ i))))
                  (or (null next) (whitespace-p next) (line-break-p next))))
           (return t))
          (t (incf i)))))))

(defun read-document-content (source)
  "Read the content of a document. Dispatches based on first character."
  (source-skip-blanks source)
  (let ((char (source-peek source)))
    (cond
      ((null char) 'null)
      ((line-break-p char) 'null)
      ;; A document marker (`---` or `...`) where content is expected means the
      ;; document is empty; its node takes the null value.
      ((looks-like-document-marker source) 'null)
      ;; An anchored / tagged / aliased KEY (`&a a: b`, `*alias : v`) introduces
      ;; a block mapping, not a single anchored node.
      ((and (or (node-properties-here-p source) (eql char #\*))
            (looks-like-mapping-key-p source))
       (read-block-mapping source))
      ((node-properties-here-p source)
       (read-node-properties-and-value source -1))
      ((eql char #\*) (read-alias source))
      ((eql char #\|) (read-literal-scalar source -1))
      ((eql char #\>) (read-folded-scalar source -1))
      ((eql char #\[) (let ((*flow-indent* -1)) (read-flow-sequence source)))
      ((eql char #\{) (let ((*flow-indent* -1)) (read-flow-mapping source)))
      ((eql char #\')
       (if (looks-like-mapping-key-p source)
           (read-block-mapping source)
           (read-single-quoted-scalar source)))
      ((eql char #\")
       (if (looks-like-mapping-key-p source)
           (read-block-mapping source)
           (read-double-quoted-scalar source)))
      ((and (eql char #\?)
            (let ((next (source-peek source 1)))
              (or (null next) (whitespace-p next) (line-break-p next))))
       (read-block-mapping source))
      ((eql char #\-)
       (if (and (eql (source-peek source 1) #\-)
                (eql (source-peek source 2) #\-)
                (let ((c (source-peek source 3)))
                  (or (null c) (whitespace-p c) (line-break-p c))))
           'null
           (if (or (whitespace-p (source-peek source 1))
                   (line-break-p (source-peek source 1))
                   (null (source-peek source 1)))
               (read-block-sequence source)
               (if (looks-like-mapping-key-p source)
                   (read-block-mapping source)
                   (read-plain-scalar source 0)))))
      ((looks-like-mapping-key-p source)
       (read-block-mapping source))
      (t (read-plain-scalar source 0)))))

(defun read-directives (source)
  "Read any YAML directives at the start of a document.
Updates *yaml-version* for %YAML directives. Returns T if directives were found."
  (let ((found nil)
        (yaml-seen nil))
    (loop
      (source-skip-whitespace-and-comments source)
      (when (source-eof-p source)
        (return))
      (unless (eql (source-peek source) #\%)
        (return))
      (cond
        ((and (eql (source-peek source 1) #\Y)
              (eql (source-peek source 2) #\A)
              (eql (source-peek source 3) #\M)
              (eql (source-peek source 4) #\L))
         ;; At most one %YAML directive per document.
         (when yaml-seen
           (error 'yaml-directive-error
                  :message "Multiple %YAML directives in a document"))
         (setf yaml-seen t)
         (let ((version (parse-yaml-directive source)))
           (setf *yaml-version* version)
           (setf found t)))
        ((and (eql (source-peek source 1) #\T)
              (eql (source-peek source 2) #\A)
              (eql (source-peek source 3) #\G))
         (let ((decl (parse-tag-directive source)))
           ;; A handle may not be declared twice in the same document.
           (when (assoc (car decl) *tag-handles* :test #'string=)
             (error 'yaml-directive-error
                    :message (format nil "Duplicate %TAG handle: ~A" (car decl))))
           (push decl *tag-handles*))
         (setf found t))
        (t
         ;; Unknown/reserved directive: ignore its whole line (per spec, a
         ;; conforming parser skips reserved directives with a warning).
         (source-skip-to-eol source)
         (setf found t)))
      (source-skip-blanks source)
      (source-skip-comment source)
      (source-consume-line-break source))
    found))

(defun content-after-properties-on-line-p (source)
  "Without moving the cursor, scan forward over leading node properties
(`!tag` / `&anchor`, blank-separated) on the current line and return T if any
non-blank, non-comment content still follows them on that same line (e.g. the
`x:` in `--- &a x: y`). Returns NIL if the properties run to end of line (the
node sits on a following line, e.g. `--- !!set`)."
  (let ((off 0))
    (flet ((pk (o) (source-peek source (+ off o))))
      (loop
        (let ((c (pk 0)))
          (cond
            ((or (null c) (line-break-p c)) (return nil))
            ((or (char= c #\!) (char= c #\&))
             ;; Consume the property token up to whitespace / line break.
             (loop for d = (pk 0)
                   while (and d (not (whitespace-p d)) (not (line-break-p d)))
                   do (incf off))
             ;; Consume the blank separation that must follow.
             (loop for d = (pk 0) while (and d (whitespace-p d)) do (incf off)))
            ((char= c #\#) (return nil))
            (t (return t))))))))

(defun read-document (source)
  "Read exactly one YAML document from SOURCE, returning its native Lisp value."
  (let ((*anchor-table* (make-hash-table :test #'equal))
        (*tag-handles* nil)
        (had-start nil))
    (source-skip-whitespace-and-comments source)
    (when (source-eof-p source)
      (return-from read-document 'null))
    (let ((had-directives (read-directives source)))
      (source-skip-whitespace-and-comments source)
      (setf had-start (source-match-document-start source))
      ;; When directives are present, an explicit `---` document start is
      ;; mandatory; a missing or `...`-only follow is malformed.
      (when (and had-directives (not had-start))
        (error 'yaml-directive-error
               :position (source-position source)
               :message "Directives must be followed by a '---' document start")))
    (source-skip-blanks source)
    (source-skip-comment source)
    ;; If a `---` marker was matched and real collection content follows it on
    ;; the SAME line (not just blanks/comment, and not merely node properties
    ;; whose node sits on the next line), the root node begins on the marker
    ;; line. Node properties (`!tag` / `&anchor`) on the marker line do not
    ;; anchor a following-line collection, so they do not set the flag.
    (let ((*root-on-marker-line*
            (and had-start
                 (let ((c (source-peek source)))
                   (and c (not (line-break-p c))
                        (if (member c '(#\! #\&))
                            ;; Leading node properties: the flag applies only if
                            ;; real content (a node) still follows them on this
                            ;; same line (`--- &a x: y`), not if the node sits on
                            ;; the next line (`--- !!set` then `? k`).
                            (content-after-properties-on-line-p source)
                            t))))))
    (source-consume-line-break source)
    (source-skip-whitespace-and-comments source)
    (let* ((root-flow-p (member (source-peek source) '(#\[ #\{)))
           (start-line (source-line source))
           (content (read-document-content source)))
      (declare (ignorable content))
      ;; A multi-line root flow node used as an implicit block-mapping key
      ;; (`[23\n]: 42`) is malformed: an implicit key must be a single line.
      (when (and root-flow-p (> (source-line source) start-line))
        (let ((m (source-index source)) (ml (source-line source)) (mc (source-column source)))
          (source-skip-blanks source)
          (when (and (eql (source-peek source) #\:)
                     (let ((n (source-peek source 1)))
                       (or (null n) (whitespace-p n) (line-break-p n))))
            (yaml-parse-fail 'yaml-structure-error source
                             "Multi-line flow node used as implicit key"))
          (setf (source-index source) m (source-line source) ml (source-column source) mc)))
      ;; Only blanks and a trailing comment may follow the content node on its
      ;; line. Arbitrary inline trailing content (e.g. `[a,b,c] ]`) is
      ;; malformed. Block constructs leave the cursor at a line start, where
      ;; this check is a no-op.
      (when (and root-flow-p
                 (not (source-at-line-start-p source)))
        ;; A `#` glued directly to the flow close (no separating whitespace) is
        ;; not a valid comment: `[a, b, c, ]#invalid`.
        (when (eql (source-peek source) #\#)
          (yaml-parse-fail 'yaml-structure-error source
                           "Comment must be separated from flow node by whitespace"))
        (source-skip-blanks source)
        (let ((c (source-peek source)))
          ;; A flow collection followed inline by a stray flow indicator
          ;; (e.g. `[a, b, c] ]`) is malformed. A following `:` is a complex
          ;; mapping key and is handled elsewhere, so it is not flagged here.
          (when (and c (find c "]}"))
            (yaml-parse-fail 'yaml-structure-error source
                             "Trailing content after flow node"))))
      ;; A root flow collection followed by trailing block content that is
      ;; neither a comment nor a document marker is malformed (the flow node is
      ;; the whole document). E.g. `[\n a\n]\ninvalid`.
      (when root-flow-p
        (let ((mark (source-index source))
              (mline (source-line source))
              (mcol (source-column source)))
          (source-skip-blanks source)
          (source-skip-comment source)
          (when (source-consume-line-break source)
            (source-skip-whitespace-and-comments source)
            (when (and (source-peek source)
                       (not (looks-like-document-marker source)))
              (yaml-parse-fail 'yaml-structure-error source
                               "Trailing content after flow document")))
          (setf (source-index source) mark
                (source-line source) mline
                (source-column source) mcol)))
      ;; The content node parked at a line start that is itself a `---`
      ;; directives-end marker: this document is complete and the next document
      ;; begins at that marker. Return now without consuming it, so the caller
      ;; (READ-ALL-DOCUMENTS) sees and counts the following document. (Without
      ;; this, the trailing-content handling below would SKIP-TO-EOL over the
      ;; marker line and silently swallow the next document — e.g. `---\n---\n`
      ;; would yield one document instead of two.)
      (let ((mark (source-index source))
            (mline (source-line source))
            (mcol (source-column source)))
        (when (and (source-at-line-start-p source)
                   (source-match-document-start source))
          ;; SOURCE-MATCH-DOCUMENT-START consumed the `---`; restore the saved
          ;; position so the marker remains for the next READ-DOCUMENT.
          (setf (source-index source) mark
                (source-line source) mline
                (source-column source) mcol)
          (return-from read-document content)))
      ;; A `...` document-end marker on the line the content node ended at must
      ;; be honoured here (not skipped as trailing content), and nothing but
      ;; blanks/comment may follow it on that line (`... invalid` is malformed).
      (when (and (source-at-line-start-p source)
                 (source-match-document-end source))
        (let ((blanks (source-skip-blanks source))
              (c (source-peek source)))
          (when (and c (not (line-break-p c))
                     (not (and (char= c #\#) (> blanks 0))))
            (yaml-parse-fail 'yaml-structure-error source
                             "Content after document-end marker"))
          (setf *document-ended-explicitly* t)
          (return-from read-document content)))
      ;; A block construct parks the cursor at a fresh line start. Once the root
      ;; node is complete, the only things that may follow at the document level
      ;; are blank/comment lines, a `...` end marker, a `---` new-document start,
      ;; or EOF. Any other content here is malformed trailing content that
      ;; belongs to no node (e.g. `- a\n- b\ninvalid: x`). Detect it loudly
      ;; rather than silently dropping the line. (Document markers and multi-doc
      ;; handling fall through to the normal path below.)
      (when (source-at-line-start-p source)
        (let ((mark (source-index source))
              (mline (source-line source))
              (mcol (source-column source)))
          (source-skip-whitespace-and-comments source)
          (when (and (not (source-eof-p source))
                     (not (looks-like-document-marker source)))
            (yaml-parse-fail 'yaml-structure-error source
                             "Trailing content after document node"))
          (setf (source-index source) mark
                (source-line source) mline
                (source-column source) mcol)))
      ;; The content node ended mid-line (a scalar with a trailing comment, say)
      ;; or parked on the line of a document marker. Note whether the line we are
      ;; about to consume is a `---`/`...` marker: if so, a new document (or its
      ;; end) follows and is the caller's concern, so we do NOT treat the next
      ;; line as trailing content. Otherwise, consume the rest of this line; any
      ;; non-blank/comment, non-marker content on a following line belongs to no
      ;; node and is malformed (e.g. `word1 # c\nword2`, `this\n is\n  invalid: x`).
      (let ((on-marker (looks-like-document-marker source)))
        (source-skip-to-eol source)
        (let ((had-break (source-consume-line-break source)))
          (let ((mark (source-index source))
                (mline (source-line source))
                (mcol (source-column source)))
            (source-skip-whitespace-and-comments source)
            ;; Only a scalar root node is checked here: a collection root that
            ;; left the cursor mid-stream indicates an incompletely-parsed
            ;; complex construct, not stray trailing content, and must not be
            ;; mis-reported (it is the caller's / a richer parse's concern).
            (when (and had-break (not on-marker)
                       (or (stringp content)
                           (not (or (hash-table-p content)
                                    (and (vectorp content) (not (stringp content))))))
                       (not (source-eof-p source))
                       (not (looks-like-document-marker source)))
              (yaml-parse-fail 'yaml-structure-error source
                               "Trailing content after document node"))
            (setf (source-index source) mark
                  (source-line source) mline
                  (source-column source) mcol))))
      (source-skip-whitespace-and-comments source)
      (setf *document-ended-explicitly* (source-match-document-end source))
      content))))

(defun read-all-documents (source)
  "Read every document from a (possibly multi-document) SOURCE stream,
returning a vector of native Lisp values.

Document boundaries follow YAML 1.2: a `---` directives-end marker begins a new
document, a `...` document-end marker terminates the current one, and directives
(`%YAML` / `%TAG`) introduce a fresh document. Each document is read by the same
full-fidelity READ-DOCUMENT used for single-document parsing, so all framing,
anchoring and trailing-content rules apply identically per document. The reliable
document count is therefore the number of READ-DOCUMENT calls that consumed real
input."
  (let ((docs (make-array 0 :adjustable t :fill-pointer 0)))
    (loop
      (let ((*document-ended-explicitly* nil))
        ;; Skip inter-document blank lines and comments. What remains is either
        ;; EOF, a `...` end marker left by the previous document, a `---` start
        ;; marker, a directive, or the first content of a bare document.
        (source-skip-whitespace-and-comments source)
        ;; Consume any standalone `...` end markers separating documents. A `...`
        ;; on its own does not by itself create a document; it closes one.
        (loop while (and (source-at-line-start-p source)
                         (source-match-document-end source))
              do (source-skip-blanks source)
                 (source-skip-comment source)
                 (source-consume-line-break source)
                 (source-skip-whitespace-and-comments source))
        (when (source-eof-p source)
          (return))
        ;; READ-DOCUMENT binds its own *ANCHOR-TABLE* / *TAG-HANDLES* and handles
        ;; directives, the optional `---`, the body, and a trailing `...`.
        (let ((before (source-index source))
              (content (read-document source)))
          (vector-push-extend content docs)
          ;; Guard against a non-advancing call (would loop forever): if the
          ;; cursor did not move and we are not at EOF, treat the remainder as a
          ;; single empty document already captured and stop.
          (when (and (= (source-index source) before)
                     (not (source-eof-p source)))
            (return)))))
    (coerce docs 'vector)))
