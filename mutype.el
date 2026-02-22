;;; mutype.el --- Type into stillness -*- lexical-binding: t; coding: utf-8; -*-

;; Author: MuType contributors
;; URL: https://github.com/suxiaogang223/mutype
;; Version: 0.1.0
;; Package-Requires: ((emacs "25.1"))
;; Keywords: convenience, typing

;;; Commentary:

;; MuType is a minimal typing practice loop for Emacs, designed for calm rhythm,
;; low-distraction focus, and steady flow (not a speed competition).
;;
;; Start a session with `M-x mutype-mode`. Use `C-u M-x mutype-mode` (or
;; `M-x mutype-mode-custom`) to choose practice mode, duration, and source text.
;;
;; During a session:
;; - `C-c C-p` toggles pause/resume
;; - `C-c C-q` stops the session
;; - `C-c C-n` / `C-c C-b` switches source text
;; - `M-x mutype-report-last-session` reopens the last report
;;
;; Source texts are bundled as plain .txt files under the package's "sources/"
;; directory.

;;; Code:

(require 'cl-lib)
(require 'subr-x)

(defun mutype--default-source-directory ()
  "Return the default source directory for MuType text files."
  (let* ((origin (or load-file-name
                     (and (boundp 'byte-compile-current-file)
                          byte-compile-current-file)
                     buffer-file-name
                     default-directory))
         (base (file-name-directory origin)))
    (expand-file-name "sources" base)))

(defgroup mutype nil
  "Minimal typing practice for entering flow."
  :group 'applications
  :prefix "mutype-")

(defcustom mutype-default-mode 'flow
  "Default practice mode.
Supported values are `flow` and `precision`."
  :type '(choice (const :tag "Flow" flow)
                 (const :tag "Precision" precision))
  :group 'mutype)

(defcustom mutype-default-duration-minutes 5
  "Default session duration in minutes.
Set to 0 for unlimited sessions."
  :type 'integer
  :group 'mutype)

(defcustom mutype-prompt-on-start nil
  "When non-nil, always prompt for session parameters on start.
When nil, `mutype-mode' starts immediately using defaults."
  :type 'boolean
  :group 'mutype)

(defvar mutype-source-directory (mutype--default-source-directory)
  "Internal source directory containing MuType text files.")

(defconst mutype-source-file-pattern "*.txt"
  "Filename pattern used when scanning `mutype-source-directory'.")

(defcustom mutype-zone-window-size 30
  "Number of recent keystrokes used for zone scoring."
  :type 'integer
  :group 'mutype)

(defcustom mutype-hud-refresh-interval 0.2
  "HUD refresh interval in seconds."
  :type 'number
  :group 'mutype)

(defcustom mutype-minimum-text-length 80
  "Minimum number of characters required in a source text."
  :type 'integer
  :group 'mutype)

(defcustom mutype-enable-guidance-text t
  "When non-nil, show guidance text in the HUD."
  :type 'boolean
  :group 'mutype)

(defcustom mutype-report-buffer-name "*MuType Report*"
  "Name of the report buffer."
  :type 'string
  :group 'mutype)

(defface mutype-pending-face
  '((t :inherit shadow))
  "Face for pending characters."
  :group 'mutype)

(defface mutype-done-face
  '((((class color) (background light))
     :foreground "black" :strike-through nil)
    (((class color) (background dark))
     :inherit default :strike-through nil)
    (t :inherit default :strike-through nil))
  "Face for completed characters."
  :group 'mutype)

(defface mutype-current-face
  '((t :weight bold :foreground "white" :background "gray25"))
  "Face for the current character anchor."
  :group 'mutype)

(defface mutype-error-face
  '((t :underline (:style wave :color "IndianRed3")))
  "Face for incorrect input feedback."
  :group 'mutype)

(defconst mutype-buffer-name "*MuType*"
  "Name of the training buffer.")

(defconst mutype--zone-symbols ["·" ":" "*" "●"]
  "Display symbols by zone level.")

(defcustom mutype-guidance-by-level
  ["settle in" "steady breath" "keep steady" "deep flow"]
  "HUD guidance text by zone level 0-3."
  :type '(vector string string string string)
  :group 'mutype)

(cl-defstruct mutype-session
  id
  state
  mode
  source-type
  source-label
  text
  length
  index
  start-time
  end-time
  duration-limit
  events
  recent-intervals
  recent-errors
  zone-score
  zone-level
  zone-history
  error-count
  correct-count
  total-count
  last-input-time
  pause-start-time
  timer
  buffer)

(defvar mutype--session-counter 0
  "Monotonic counter for session identifiers.")

(defvar mutype--current-session nil
  "Current MuType session object.")

(defvar mutype--last-report nil
  "Most recent MuType report plist.")

(defvar-local mutype--mode-line-status ""
  "Cached MuType status string rendered in mode line.")

(defvar mutype--mode-line-source-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line mouse-1] #'mutype-select-source)
    map)
  "Keymap for clickable source segment in MuType mode line.")

(defvar mutype-training-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-q") #'mutype-stop)
    (define-key map (kbd "C-c C-p") #'mutype-toggle-pause)
    (define-key map (kbd "C-c C-n") #'mutype-next-source)
    (define-key map (kbd "C-c C-b") #'mutype-prev-source)
    (define-key map [remap self-insert-command] #'mutype--dispatch-input)
    (define-key map (kbd "RET") #'mutype--dispatch-input)
    (define-key map (kbd "C-m") #'mutype--dispatch-input)
    (define-key map (kbd "DEL") #'mutype--backtrack-input)
    (define-key map (kbd "<backspace>") #'mutype--backtrack-input)
    map)
  "Keymap for `mutype-training-mode`.")

(define-derived-mode mutype-training-mode text-mode "MuType"
  "Major mode for MuType training sessions."
  (setq-local cursor-type nil)
  (setq-local truncate-lines nil)
  (setq-local word-wrap t)
  (setq-local mode-line-format
              '(" " (:eval (or mutype--mode-line-status "")) " "))
  (setq-local header-line-format nil)
  (setq-local buffer-undo-list t)
  (visual-line-mode 1))

(defun mutype--clamp (value min-value max-value)
  "Clamp VALUE into [MIN-VALUE, MAX-VALUE]."
  (max min-value (min value max-value)))

(defun mutype--default-duration ()
  "Return the default duration in seconds, or nil for unlimited."
  (if (> mutype-default-duration-minutes 0)
      (* 60 mutype-default-duration-minutes)
    nil))

(defun mutype--window-push (value list limit)
  "Push VALUE into LIST and keep at most LIMIT elements."
  (let ((new-list (cons value list)))
    (if (> (length new-list) limit)
        (cl-subseq new-list 0 limit)
      new-list)))

(defun mutype--mean (numbers)
  "Return the mean of NUMBERS, or 0 when NUMBERS is empty."
  (if numbers
      (/ (float (apply #'+ numbers)) (length numbers))
    0.0))

(defun mutype--stddev (numbers)
  "Return the population standard deviation for NUMBERS."
  (if (< (length numbers) 2)
      0.0
    (let* ((mean (mutype--mean numbers))
           (variance (/ (float (apply #'+
                                      (mapcar (lambda (x)
                                                (expt (- x mean) 2))
                                              numbers)))
                        (length numbers))))
      (sqrt variance))))

;;; Zone scoring

(defun mutype--zone-level-from-score (score)
  "Map SCORE in [0,1] to a zone level in [0,3]."
  (cond
   ((< score 0.45) 0)
   ((< score 0.65) 1)
   ((< score 0.82) 2)
   (t 3)))

(defun mutype--zone-symbol (level)
  "Return zone symbol for LEVEL."
  (aref mutype--zone-symbols (mutype--clamp level 0 3)))

(defun mutype--guidance-text (level)
  "Return guidance text for LEVEL."
  (aref mutype-guidance-by-level (mutype--clamp level 0 3)))

;;; Source handling

(defun mutype--list-source-files (&optional directory)
  "Return sorted source file paths from DIRECTORY.
DIRECTORY defaults to `mutype-source-directory'."
  (let* ((raw-dir (or directory mutype-source-directory))
         (source-dir (file-name-as-directory (expand-file-name raw-dir))))
    (unless (file-directory-p source-dir)
      (user-error "Source directory does not exist: %s" source-dir))
    (let* ((regex (wildcard-to-regexp mutype-source-file-pattern))
           (files (cl-remove-if-not
                   #'file-regular-p
                   (directory-files source-dir t regex t)))
           (sorted (sort files #'string-lessp)))
      (unless sorted
        (user-error "No source files found in: %s" source-dir))
      sorted)))

(defun mutype--source-label-from-path (file-path)
  "Return display label for FILE-PATH."
  (file-name-base file-path))

(defun mutype--load-source-file (file-path)
  "Load FILE-PATH and return a validated source plist."
  (let ((text (mutype--normalize-text (mutype--read-file-text file-path))))
    (list :type 'source-directory
          :label (mutype--source-label-from-path file-path)
          :text text
          :path file-path)))

(defun mutype--scan-source-directory (&optional directory)
  "Scan DIRECTORY and return validated source plists.
DIRECTORY defaults to `mutype-source-directory'."
  (let ((files (mutype--list-source-files directory))
        (sources nil))
    (dolist (file files)
      (condition-case nil
          (push (mutype--load-source-file file) sources)
        (error nil)))
    (setq sources (nreverse sources))
    (unless sources
      (user-error "No valid source text found in: %s"
                  (expand-file-name (or directory mutype-source-directory))))
    sources))

(defun mutype--source-from-directory-first (&optional directory)
  "Return the first valid source from DIRECTORY."
  (car (mutype--scan-source-directory directory)))

(defun mutype--source-index-by-label (sources label)
  "Return zero-based index of LABEL in SOURCES, or nil when missing."
  (cl-position label sources :key (lambda (source)
                                    (plist-get source :label))
               :test #'string=))

(defun mutype--adjacent-source (sources current-label step)
  "Return adjacent source from SOURCES around CURRENT-LABEL by STEP."
  (let* ((count (length sources))
         (index (or (mutype--source-index-by-label sources current-label) 0))
         (next-index (mod (+ index step) count)))
    (nth next-index sources)))

(defun mutype--quick-start-args ()
  "Return non-interactive startup arguments for quick start."
  (list mutype-default-mode
        (or (mutype--default-duration) 0)
        (mutype--source-from-directory-first)))

(defun mutype--format-clock (seconds)
  "Format SECONDS as MM:SS."
  (let* ((total (max 0 (floor seconds)))
         (minutes (/ total 60))
         (secs (% total 60)))
    (format "%02d:%02d" minutes secs)))

(defun mutype--session-live-p (session)
  "Return non-nil when SESSION is active and has a live buffer."
  (and (mutype-session-p session)
       (memq (mutype-session-state session) '(running paused))
       (buffer-live-p (mutype-session-buffer session))))

(defun mutype--session-elapsed (session &optional now)
  "Return elapsed seconds for SESSION.
NOW defaults to current wall clock time."
  (let ((end (or now (mutype-session-end-time session) (float-time))))
    (max 0.0 (- end (mutype-session-start-time session)))))

(defun mutype--time-limit-reached-p (session)
  "Return non-nil when SESSION has reached its time limit."
  (let ((limit (mutype-session-duration-limit session)))
    (and limit (>= (mutype--session-elapsed session) limit))))

(defun mutype--read-start-args ()
  "Read interactive arguments for `mutype-mode`."
  (list (mutype--read-mode)
        (mutype--read-duration)
        (mutype--read-source)))

(defun mutype--read-mode ()
  "Prompt for practice mode."
  (intern (completing-read "Mode: "
                           '("flow" "precision")
                           nil t nil nil
                           (symbol-name mutype-default-mode))))

(defun mutype--read-duration ()
  "Prompt for duration in seconds.
Return 0 for unlimited duration."
  (let ((minutes (read-number "Duration in minutes (0 for unlimited): "
                              mutype-default-duration-minutes)))
    (if (<= minutes 0)
        0
      (* 60 minutes))))

(defun mutype--read-source ()
  "Prompt for text source and return a plist with :type, :label, and :text."
  (let* ((sources (mutype--scan-source-directory))
         (choices (mapcar (lambda (source)
                            (cons (plist-get source :label) source))
                          sources))
         (name (completing-read "Source text: "
                                (mapcar #'car choices)
                                nil t)))
    (or (cdr (assoc name choices))
        (user-error "Unknown source text: %s" name))))

(defun mutype--read-file-text (file-path)
  "Read FILE-PATH and return file contents as a string."
  (with-temp-buffer
    (insert-file-contents file-path)
    (buffer-substring-no-properties (point-min) (point-max))))

(defun mutype--default-source ()
  "Return the default source plist."
  (mutype--source-from-directory-first))

(defun mutype--source-label-for-navigation ()
  "Return the current source label for next/previous navigation."
  (cond
   ((and (mutype--session-live-p mutype--current-session)
         (eq (mutype-session-source-type mutype--current-session) 'source-directory))
    (mutype-session-source-label mutype--current-session))
   ((and (listp mutype--last-report)
         (eq (plist-get mutype--last-report :source-type) 'source-directory))
    (plist-get mutype--last-report :source-label))
   (t
    (plist-get (mutype--source-from-directory-first) :label))))

(defun mutype--switch-source (step)
  "Switch source by STEP and start a new session."
  (let* ((sources (mutype--scan-source-directory))
         (current-label (mutype--source-label-for-navigation))
         (source (mutype--adjacent-source sources current-label step)))
    (mutype--switch-to-source source)))

(defun mutype--switch-to-source (source)
  "Switch to SOURCE and start a new session."
  (let* ((session mutype--current-session)
         (live (mutype--session-live-p session))
         (mode (if live
                   (mutype-session-mode session)
                 mutype-default-mode))
         (duration (if live
                       (or (mutype-session-duration-limit session) 0)
                     (or (mutype--default-duration) 0))))
    (when live
      ;; Skip report popup during source navigation; keep metrics in memory.
      (cl-letf (((symbol-function 'mutype--show-report)
                 (lambda (_report) nil)))
        (mutype-stop)))
    (mutype-mode mode duration source)))

(defun mutype--normalize-text (text)
  "Normalize source TEXT and validate minimum length."
  (unless (stringp text)
    (user-error "Source text must be a string"))
  (let ((normalized (replace-regexp-in-string "\r\n?" "\n" (string-trim text))))
    (when (< (length normalized) mutype-minimum-text-length)
      (user-error "Source text is too short (%d < %d)"
                  (length normalized)
                  mutype-minimum-text-length))
    normalized))

(defun mutype--set-char-face (session index face)
  "Apply FACE to character at INDEX in SESSION buffer."
  (let ((buffer (mutype-session-buffer session)))
    (when (and (buffer-live-p buffer)
               (>= index 0)
               (< index (mutype-session-length session)))
      (with-current-buffer buffer
        (let ((inhibit-read-only t)
              (start (1+ index)))
          (add-text-properties start (1+ start) (list 'face face)))))))

(defun mutype--mark-current-char (session &optional error)
  "Mark SESSION current character.
When ERROR is non-nil, combine current and error faces."
  (let ((face (if error
                  '(mutype-current-face mutype-error-face)
                'mutype-current-face)))
    (mutype--set-char-face session (mutype-session-index session) face)))

(defun mutype--goto-index (session)
  "Move point to SESSION current index in its live buffer."
  (let ((buffer (mutype-session-buffer session)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (goto-char (+ (point-min)
                      (mutype-session-index session)))))))

;;; HUD / mode line

(defun mutype--format-accuracy (correct total)
  "Format accuracy from CORRECT and TOTAL counts."
  (if (> total 0)
      (format "%.1f%%" (* 100.0 (/ (float correct) total)))
    "--"))

(defun mutype--mode-line-source-segment (label)
  "Return clickable mode line segment for source LABEL."
  (propertize (format "src:%s" label)
              'help-echo "mouse-1: Select source text"
              'mouse-face 'mode-line-highlight
              'local-map mutype--mode-line-source-map))

(defun mutype--build-mode-line-segments (session)
  "Return an alist of mode line segments for SESSION."
  (let* ((elapsed (mutype--session-elapsed session))
         (time-str (if (mutype-session-duration-limit session)
                       (mutype--format-clock
                        (- (mutype-session-duration-limit session) elapsed))
                     (mutype--format-clock elapsed)))
         (status (pcase (mutype-session-state session)
                   ('paused "paused")
                   ('running "running")
                   (_ (symbol-name (mutype-session-state session)))))
         (progress (format "p:%d/%d"
                           (mutype-session-index session)
                           (mutype-session-length session)))
         (accuracy (format "acc:%s"
                           (mutype--format-accuracy
                            (mutype-session-correct-count session)
                            (mutype-session-total-count session))))
         (source (mutype--mode-line-source-segment
                  (mutype-session-source-label session))))
    `((core . ,(format "%s %s %s"
                       (mutype--zone-symbol (mutype-session-zone-level session))
                       time-str
                       status))
      (progress . ,progress)
      (accuracy . ,accuracy)
      (source . ,source))))

(defun mutype--fit-mode-line-segments (segments max-width)
  "Fit SEGMENTS into MAX-WIDTH using priority-based fallback."
  (let* ((core (alist-get 'core segments))
         (progress (alist-get 'progress segments))
         (accuracy (alist-get 'accuracy segments))
         (source (alist-get 'source segments))
         (parts (delq nil (list core progress accuracy source)))
         (line (string-join parts "  ")))
    (when (> (string-width line) max-width)
      (setq source nil
            parts (delq nil (list core progress accuracy source))
            line (string-join parts "  ")))
    (when (> (string-width line) max-width)
      (setq accuracy nil
            parts (delq nil (list core progress accuracy source))
            line (string-join parts "  ")))
    (when (> (string-width line) max-width)
      (setq progress nil
            parts (delq nil (list core progress accuracy source))
            line (string-join parts "  ")))
    (if (> (string-width line) max-width)
        core
      line)))

(defun mutype--render-mode-line (session)
  "Render SESSION status into training buffer mode line."
  (let ((buffer (mutype-session-buffer session)))
    (when (buffer-live-p buffer)
      (let* ((window (get-buffer-window buffer t))
             (width (if (window-live-p window)
                        (window-total-width window)
                      (frame-width)))
             (segments (mutype--build-mode-line-segments session))
             (line (mutype--fit-mode-line-segments segments (max 10 width))))
        (with-current-buffer buffer
          (setq-local header-line-format nil)
          (setq-local mutype--mode-line-status line)
          (force-mode-line-update))))))

(defun mutype--update-hud (session)
  "Render HUD for SESSION."
  (mutype--render-mode-line session))

(defun mutype--update-zone (session error-bit interval)
  "Update SESSION zone metrics with ERROR-BIT and INTERVAL."
  (let ((window-size (max 3 mutype-zone-window-size)))
    (when interval
      (setf (mutype-session-recent-intervals session)
            (mutype--window-push interval
                                 (mutype-session-recent-intervals session)
                                 window-size)))
    (setf (mutype-session-recent-errors session)
          (mutype--window-push error-bit
                               (mutype-session-recent-errors session)
                               window-size))
    (let* ((errors (mutype-session-recent-errors session))
           (err-rate (if errors
                         (/ (float (apply #'+ errors)) (length errors))
                       0.0))
           (intervals (mutype-session-recent-intervals session))
           (stability (if (< (length intervals) 3)
                          0.5
                        (let* ((mean (mutype--mean intervals))
                               (std (mutype--stddev intervals))
                               (cv (if (> mean 0.0) (/ std mean) 1.0)))
                          (mutype--clamp (- 1.0 (/ cv 0.6)) 0.0 1.0))))
           (raw-score (+ (* 0.55 (- 1.0 err-rate))
                         (* 0.45 stability)))
           (previous (mutype-session-zone-score session))
           (smoothed (+ (* 0.3 raw-score) (* 0.7 previous)))
           (zone-level (mutype--zone-level-from-score smoothed)))
      (setf (mutype-session-zone-score session) smoothed
            (mutype-session-zone-level session) zone-level
            (mutype-session-zone-history session)
            (cons zone-level (mutype-session-zone-history session))))))

(defun mutype--normalize-input-char (char)
  "Normalize input CHAR for source matching."
  (if (= char ?\r) ?\n char))

(defun mutype--record-event (session index expected actual correct interval timestamp)
  "Record one typing event into SESSION."
  (setf (mutype-session-events session)
        (cons (list :index index
                    :expected expected
                    :actual actual
                    :correct correct
                    :interval interval
                    :time timestamp)
              (mutype-session-events session))))

(defun mutype--handle-input (session char)
  "Handle CHAR for SESSION."
  (let* ((index (mutype-session-index session))
         (expected (aref (mutype-session-text session) index))
         (actual (mutype--normalize-input-char char))
         (mode (mutype-session-mode session))
         (correct (= actual expected))
         (now (float-time))
         (last-time (mutype-session-last-input-time session))
         (interval (and last-time (- now last-time))))
    (setf (mutype-session-last-input-time session) now)
    (cl-incf (mutype-session-total-count session))
    (if correct
        (cl-incf (mutype-session-correct-count session))
      (cl-incf (mutype-session-error-count session)))
    (mutype--record-event session index expected actual correct interval now)
    (mutype--update-zone session (if correct 0 1) interval)
    (cond
     (correct
      (mutype--set-char-face session index 'mutype-done-face)
      (setq index (1+ index)))
     ((eq mode 'flow)
      (mutype--set-char-face session index '(mutype-done-face mutype-error-face))
      (setq index (1+ index)))
     (t
      (mutype--mark-current-char session t)))
    (setf (mutype-session-index session) index)
    (cond
     ((>= index (mutype-session-length session))
      (mutype--finish-session session 'finished "Text completed."))
     ((or correct (eq mode 'flow))
      (mutype--mark-current-char session)
      (mutype--goto-index session)
      (mutype--update-hud session))
     (t
      (mutype--goto-index session)
      (mutype--update-hud session)))))

(defun mutype--dispatch-input ()
  "Dispatch a training key from `mutype-training-mode`."
  (interactive)
  (let ((session mutype--current-session)
        (event last-command-event))
    (cond
     ((not (mutype--session-live-p session))
      (message "No active MuType session."))
     ((eq (mutype-session-state session) 'paused)
      (message "Session is paused. Use C-c C-p to resume."))
     ((not (characterp event))
      nil)
     (t
      (mutype--goto-index session)
      (mutype--handle-input session event)))))

(defun mutype--backtrack-input ()
  "Move one step backward so the previous character can be retyped."
  (interactive)
  (let ((session mutype--current-session))
    (cond
     ((not (mutype--session-live-p session))
      (message "No active MuType session."))
     ((eq (mutype-session-state session) 'paused)
      (message "Session is paused. Use C-c C-p to resume."))
     ((<= (mutype-session-index session) 0)
      (message "Already at the beginning of the text."))
     (t
      (let ((old-index (mutype-session-index session)))
        (setf (mutype-session-index session) (1- old-index))
        (mutype--set-char-face session old-index 'mutype-pending-face)
        (mutype--set-char-face session (mutype-session-index session) 'mutype-current-face)
        (mutype--goto-index session)
        (mutype--update-hud session))))))

(defun mutype--render-session (session)
  "Render SESSION into the training buffer."
  (let ((buffer (get-buffer-create mutype-buffer-name))
        (text (mutype-session-text session)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert text)
        (add-text-properties (point-min) (point-max) '(face mutype-pending-face))
        (mutype-training-mode))
      (setq-local header-line-format nil))
    (setf (mutype-session-buffer session) buffer)
    (mutype--mark-current-char session)
    (mutype--goto-index session)
    (mutype--update-hud session)
    (pop-to-buffer buffer)))

(defun mutype--cancel-timer (session)
  "Cancel timer from SESSION."
  (let ((timer (mutype-session-timer session)))
    (when (timerp timer)
      (cancel-timer timer)
      (setf (mutype-session-timer session) nil))))

;;; Reporting

(defun mutype--build-report (session reason)
  "Build a report plist from SESSION with REASON."
  (let* ((start (mutype-session-start-time session))
         (end (or (mutype-session-end-time session) (float-time)))
         (duration (max 0.001 (- end start)))
         (total (mutype-session-total-count session))
         (correct (mutype-session-correct-count session))
         (errors (mutype-session-error-count session))
         (accuracy (if (> total 0)
                       (* 100.0 (/ (float correct) total))
                     0.0))
         (cpm (* 60.0 (/ (float correct) duration)))
         (events (mutype-session-events session))
         (intervals (delq nil (mapcar (lambda (event)
                                        (plist-get event :interval))
                                      events)))
         (avg-interval (if intervals (mutype--mean intervals) 0.0))
         (zone-history (mutype-session-zone-history session))
         (zone-average (if zone-history (mutype--mean zone-history) 0.0))
         (zone-peak (if zone-history (apply #'max zone-history) 0))
         (timestamp (format-time-string "%Y-%m-%d %H:%M:%S"
                                        (seconds-to-time end))))
    (list :timestamp timestamp
          :state (mutype-session-state session)
          :reason reason
          :mode (mutype-session-mode session)
          :source-type (mutype-session-source-type session)
          :source-label (mutype-session-source-label session)
          :duration duration
          :duration-limit (mutype-session-duration-limit session)
          :total total
          :correct correct
          :errors errors
          :accuracy accuracy
          :cpm cpm
          :avg-interval avg-interval
          :zone-average zone-average
          :zone-peak zone-peak
          :zone-final (mutype-session-zone-level session))))

(defun mutype--show-report (report)
  "Render REPORT to `mutype-report-buffer-name`."
  (let ((buffer (get-buffer-create mutype-report-buffer-name)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "MuType Session Report\n")
        (insert "=====================\n\n")
        (insert (format "Timestamp: %s\n" (plist-get report :timestamp)))
        (insert (format "State: %s\n" (symbol-name (plist-get report :state))))
        (insert (format "Reason: %s\n" (plist-get report :reason)))
        (insert (format "Mode: %s\n" (symbol-name (plist-get report :mode))))
        (insert (format "Source: %s (%s)\n"
                        (plist-get report :source-label)
                        (symbol-name (plist-get report :source-type))))
        (insert (format "Duration: %.1f seconds\n" (plist-get report :duration)))
        (insert (format "Total Input: %d\n" (plist-get report :total)))
        (insert (format "Correct: %d\n" (plist-get report :correct)))
        (insert (format "Errors: %d\n" (plist-get report :errors)))
        (insert (format "Accuracy: %.2f%%\n" (plist-get report :accuracy)))
        (insert (format "CPM: %.2f\n" (plist-get report :cpm)))
        (insert (format "Average Interval: %.3fs\n" (plist-get report :avg-interval)))
        (insert (format "Zone Average: %.2f\n" (plist-get report :zone-average)))
        (insert (format "Zone Peak: %d (%s)\n"
                        (plist-get report :zone-peak)
                        (mutype--zone-symbol (plist-get report :zone-peak))))
        (insert (format "Zone Final: %d (%s)\n"
                        (plist-get report :zone-final)
                        (mutype--zone-symbol (plist-get report :zone-final))))
        (special-mode)))
    (display-buffer buffer)))

(defun mutype--finish-session (session state reason)
  "Finalize SESSION with STATE and REASON."
  (when (and (mutype-session-p session)
             (memq (mutype-session-state session) '(running paused)))
    (setf (mutype-session-state session) state
          (mutype-session-end-time session) (float-time))
    (mutype--cancel-timer session)
    (mutype--update-hud session)
    (setq mutype--last-report (mutype--build-report session reason))
    (setq mutype--current-session nil)
    (mutype--show-report mutype--last-report)
    (message "MuType session %s: %s"
             (if (eq state 'finished) "finished" "stopped")
             reason)))

(defun mutype--tick ()
  "Refresh HUD and enforce end conditions."
  (let ((session mutype--current-session))
    (when (mutype-session-p session)
      (cond
       ((and (memq (mutype-session-state session) '(running paused))
             (not (buffer-live-p (mutype-session-buffer session))))
        (mutype--finish-session session 'aborted "Training buffer was closed."))
       ((eq (mutype-session-state session) 'running)
        (when (mutype--time-limit-reached-p session)
          (mutype--finish-session session 'finished "Time limit reached."))
        (when (and mutype--current-session
                   (eq (mutype-session-state mutype--current-session) 'running))
          (mutype--update-hud mutype--current-session)))
       ((eq (mutype-session-state session) 'paused)
        (mutype--update-hud session))))))

;;;###autoload
(defun mutype-mode (&optional mode duration source)
  "Start a MuType session in the `*MuType*' training buffer.

Interactively, start immediately using defaults. With a prefix argument (or
when `mutype-prompt-on-start' is non-nil), prompt for practice mode, duration,
and source text.

MODE should be `flow' or `precision'. DURATION is in seconds, where 0 means
unlimited. SOURCE is a plist with :type, :label, and :text."
  (interactive
   (if (or current-prefix-arg mutype-prompt-on-start)
       (mutype--read-start-args)
     (mutype--quick-start-args)))
  (when (mutype--session-live-p mutype--current-session)
    (user-error "A MuType session is already active"))
  (let* ((mode (or mode mutype-default-mode))
         (duration (cond
                    ((null duration) (mutype--default-duration))
                    ((<= duration 0) nil)
                    (t duration)))
         (source (or source (mutype--default-source)))
         (text (mutype--normalize-text (plist-get source :text)))
         (session (make-mutype-session
                   :id (cl-incf mutype--session-counter)
                   :state 'running
                   :mode mode
                   :source-type (plist-get source :type)
                   :source-label (plist-get source :label)
                   :text text
                   :length (length text)
                   :index 0
                   :start-time (float-time)
                   :duration-limit duration
                   :events nil
                   :recent-intervals nil
                   :recent-errors nil
                   :zone-score 0.0
                   :zone-level 0
                   :zone-history nil
                   :error-count 0
                   :correct-count 0
                   :total-count 0
                   :last-input-time nil
                   :pause-start-time nil
                   :timer nil
                   :buffer nil)))
    (unless (memq mode '(flow precision))
      (user-error "Unsupported mode: %S" mode))
    (setq mutype--current-session session)
    (mutype--render-session session)
    (setf (mutype-session-timer session)
          (run-at-time 0 mutype-hud-refresh-interval #'mutype--tick))
    (message "MuType started: mode=%s source=%s (C-c C-p pause, C-c C-q stop)"
             (symbol-name mode)
             (mutype-session-source-label session))))

;;;###autoload
(defun mutype-mode-custom ()
  "Start a MuType session with interactive parameter prompts."
  (interactive)
  (apply #'mutype-mode (mutype--read-start-args)))

;;;###autoload
(defun mutype-select-source ()
  "Select a bundled source text and restart the session.

When a session is active, keep the current mode and duration. When no session
is active, start a new session using defaults."
  (interactive)
  (let* ((sources (mutype--scan-source-directory))
         (choices (mapcar (lambda (source)
                            (cons (plist-get source :label) source))
                          sources))
         (current-label (mutype--source-label-for-navigation))
         (name (completing-read "Source text: "
                                (mapcar #'car choices)
                                nil t nil nil
                                current-label))
         (source (or (cdr (assoc name choices))
                     (user-error "Unknown source text: %s" name))))
    (mutype--switch-to-source source)))

;;;###autoload
(defun mutype-next-source ()
  "Switch to the next source text by filename order."
  (interactive)
  (mutype--switch-source 1))

;;;###autoload
(defun mutype-prev-source ()
  "Switch to the previous source text by filename order."
  (interactive)
  (mutype--switch-source -1))

;;;###autoload
(defun mutype-stop ()
  "Stop the current MuType session."
  (interactive)
  (if (mutype--session-live-p mutype--current-session)
      (mutype--finish-session mutype--current-session 'aborted "Stopped by user.")
    (user-error "No active MuType session")))

;;;###autoload
(defun mutype-pause ()
  "Pause the current MuType session."
  (interactive)
  (if (and (mutype-session-p mutype--current-session)
           (eq (mutype-session-state mutype--current-session) 'running))
      (progn
        (setf (mutype-session-state mutype--current-session) 'paused
              (mutype-session-pause-start-time mutype--current-session) (float-time))
        (mutype--update-hud mutype--current-session)
        (message "MuType paused."))
    (user-error "No running MuType session")))

;;;###autoload
(defun mutype-resume ()
  "Resume a paused MuType session."
  (interactive)
  (if (and (mutype-session-p mutype--current-session)
           (eq (mutype-session-state mutype--current-session) 'paused))
      (let* ((session mutype--current-session)
             (paused-at (mutype-session-pause-start-time session))
             (delta (if paused-at (- (float-time) paused-at) 0.0)))
        ;; Move start time forward so paused time is excluded from elapsed metrics.
        (setf (mutype-session-start-time session)
              (+ (mutype-session-start-time session) delta)
              (mutype-session-pause-start-time session) nil
              (mutype-session-state session) 'running)
        (mutype--update-hud session)
        (message "MuType resumed."))
    (user-error "No paused MuType session")))

;;;###autoload
(defun mutype-toggle-pause ()
  "Toggle paused state for the current session."
  (interactive)
  (cond
   ((and (mutype-session-p mutype--current-session)
         (eq (mutype-session-state mutype--current-session) 'running))
    (mutype-pause))
   ((and (mutype-session-p mutype--current-session)
         (eq (mutype-session-state mutype--current-session) 'paused))
    (mutype-resume))
   (t
    (user-error "No active MuType session"))))

;;;###autoload
(defun mutype-report-last-session ()
  "Show the latest MuType session report buffer.

A report is produced when a session finishes or is stopped."
  (interactive)
  (if mutype--last-report
      (mutype--show-report mutype--last-report)
    (user-error "No MuType report is available yet")))

(provide 'mutype)

;;; mutype.el ends here
