;;; mutype-test.el --- Tests for MuType -*- lexical-binding: t; -*-

;;; Commentary:

;; Test coverage for mode behavior, source switching, HUD rendering,
;; session lifecycle, and report calculations.

;;; Code:

(require 'cl-lib)
(require 'ert)
(require 'mutype)

(defun mutype-test--face-has-p (face-value face-symbol)
  "Return non-nil when FACE-VALUE includes FACE-SYMBOL."
  (if (listp face-value)
      (memq face-symbol face-value)
    (eq face-value face-symbol)))

(cl-defun mutype-test--make-session
    (&key
     (id 1)
     (mode 'flow)
     (state 'running)
     (text "abc")
     (index 0)
     (start-time (float-time))
     duration-limit
     zone-score
     zone-level
     (source-type 'builtin)
     (source-label "test"))
  "Create a test session with a prepared training buffer."
  (let ((buffer (generate-new-buffer " *mutype-test*")))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (insert text)
        (add-text-properties (point-min) (point-max) '(face mutype-pending-face))
        (mutype-training-mode)))
    (make-mutype-session
     :id id
     :state state
     :mode mode
     :source-type source-type
     :source-label source-label
     :text text
     :length (length text)
     :index index
     :start-time start-time
     :duration-limit duration-limit
     :events nil
     :recent-intervals nil
     :recent-errors nil
     :zone-score (or zone-score 0.0)
     :zone-level (or zone-level 0)
     :zone-history nil
     :error-count 0
     :correct-count 0
     :total-count 0
     :last-input-time nil
     :pause-start-time nil
     :timer nil
     :buffer buffer)))

(defun mutype-test--cleanup-session (session)
  "Cancel timer and kill SESSION buffer."
  (when (timerp (mutype-session-timer session))
    (cancel-timer (mutype-session-timer session)))
  (when (buffer-live-p (mutype-session-buffer session))
    (kill-buffer (mutype-session-buffer session))))

(defmacro mutype-test--without-report-ui (&rest body)
  "Run BODY while suppressing report buffer display."
  `(cl-letf (((symbol-function 'mutype--show-report)
              (lambda (_report) nil))
             ((symbol-function 'display-buffer)
              (lambda (&rest _args) nil)))
     ,@body))

(defun mutype-test--long-text ()
  "Return a valid long text that passes minimum length validation."
  (make-string (+ mutype-minimum-text-length 5) ?x))

(ert-deftest mutype-window-push-truncates ()
  (should (equal (mutype--window-push 4 '(3 2 1) 3) '(4 3 2)))
  (should (equal (mutype--window-push 1 nil 3) '(1))))

(ert-deftest mutype-zone-level-thresholds ()
  (should (= (mutype--zone-level-from-score 0.10) 0))
  (should (= (mutype--zone-level-from-score 0.50) 1))
  (should (= (mutype--zone-level-from-score 0.70) 2))
  (should (= (mutype--zone-level-from-score 0.90) 3)))

(ert-deftest mutype-normalize-input-char ()
  (should (= (mutype--normalize-input-char ?\r) ?\n))
  (should (= (mutype--normalize-input-char ?a) ?a)))

(ert-deftest mutype-flow-advances-on-error ()
  "Acceptance: error feedback in flow mode is non-blocking."
  (let ((session (mutype-test--make-session :mode 'flow :text "abc")))
    (unwind-protect
        (progn
          (mutype--mark-current-char session)
          (mutype--handle-input session ?x)
          (should (= (mutype-session-index session) 1))
          (should (= (mutype-session-error-count session) 1))
          (should (= (mutype-session-total-count session) 1))
          (with-current-buffer (mutype-session-buffer session)
            (let ((face (get-text-property (point-min) 'face)))
              (should (mutype-test--face-has-p face 'mutype-done-face))
              (should (mutype-test--face-has-p face 'mutype-error-face)))))
      (mutype-test--cleanup-session session))))

(ert-deftest mutype-precision-blocks-on-error ()
  (let ((session (mutype-test--make-session :mode 'precision :text "abc")))
    (unwind-protect
        (progn
          (mutype--mark-current-char session)
          (mutype--handle-input session ?x)
          (should (= (mutype-session-index session) 0))
          (should (= (mutype-session-error-count session) 1))
          (should (= (mutype-session-total-count session) 1))
          (with-current-buffer (mutype-session-buffer session)
            (let ((face (get-text-property (point-min) 'face)))
              (should (mutype-test--face-has-p face 'mutype-current-face))
              (should (mutype-test--face-has-p face 'mutype-error-face)))))
      (mutype-test--cleanup-session session))))

(ert-deftest mutype-mode-starts-with-selected-mode ()
  "Acceptance: mode selection starts a session with expected mode."
  (let ((source (list :type 'builtin :label "t" :text (mutype-test--long-text))))
    (setq mutype--current-session nil)
    (unwind-protect
        (mutype-test--without-report-ui
          (mutype-mode 'precision 0 source)
          (should (mutype-session-p mutype--current-session))
          (should (eq (mutype-session-mode mutype--current-session) 'precision))
          (should (eq (mutype-session-state mutype--current-session) 'running))
          (mutype-stop)
          (should (null mutype--current-session)))
      (when (mutype-session-p mutype--current-session)
        (mutype-test--cleanup-session mutype--current-session))
      (setq mutype--current-session nil))))

(ert-deftest mutype-hud-shows-zone-and-paused-status ()
  "Acceptance: HUD updates with zone symbol and paused marker."
  (let* ((session (mutype-test--make-session
                   :state 'paused
                   :zone-level 2
                   :start-time (- (float-time) 12)
                   :duration-limit 180)))
    (unwind-protect
        (progn
          (mutype--update-hud session)
          (with-current-buffer (mutype-session-buffer session)
            (let ((hud header-line-format))
              (should (stringp hud))
              (should (string-match-p "\\*" hud))
              (should (string-match-p "paused" hud)))))
      (mutype-test--cleanup-session session))))

(ert-deftest mutype-source-switching ()
  "Acceptance: built-in, buffer, and file sources all work."
  (let* ((builtin-name (caar mutype-builtin-texts))
         (builtin (mutype--source-from-builtin builtin-name))
         (buffer (generate-new-buffer " *mutype-source-buffer*"))
         (temp-file (make-temp-file "mutype-source-" nil ".txt" "file text source")))
    (unwind-protect
        (progn
          (with-current-buffer buffer
            (insert "buffer text source"))
          (let ((from-buffer (mutype--source-from-buffer buffer))
                (from-file (mutype--source-from-file temp-file)))
            (should (equal (plist-get builtin :type) 'builtin))
            (should (equal (plist-get from-buffer :type) 'buffer))
            (should (equal (plist-get from-file :type) 'file))
            (should (string= (plist-get from-buffer :text) "buffer text source"))
            (should (string= (plist-get from-file :text) "file text source"))))
      (when (buffer-live-p buffer)
        (kill-buffer buffer))
      (delete-file temp-file))))

(ert-deftest mutype-normalize-text-rejects-short-input ()
  (let ((mutype-minimum-text-length 5))
    (should-error (mutype--normalize-text "abc"))))

(ert-deftest mutype-pause-resume-adjusts-clock ()
  (let* ((base-start (float-time))
         (session (mutype-test--make-session :start-time base-start)))
    (setq mutype--current-session session)
    (unwind-protect
        (progn
          (mutype-pause)
          (setf (mutype-session-pause-start-time session) (- (float-time) 5))
          (mutype-resume)
          (should (eq (mutype-session-state session) 'running))
          (should (> (- (mutype-session-start-time session) base-start) 4.0)))
      (setq mutype--current-session nil)
      (mutype-test--cleanup-session session))))

(ert-deftest mutype-tick-finishes-time-limited-session ()
  (let ((session (mutype-test--make-session
                  :start-time (- (float-time) 10)
                  :duration-limit 1)))
    (setq mutype--current-session session)
    (unwind-protect
        (mutype-test--without-report-ui
          (mutype--tick)
          (should (null mutype--current-session))
          (should (equal (plist-get mutype--last-report :state) 'finished))
          (should (string= (plist-get mutype--last-report :reason) "Time limit reached.")))
      (setq mutype--current-session nil)
      (mutype-test--cleanup-session session))))

(ert-deftest mutype-tick-aborts-when-buffer-closed ()
  (let ((session (mutype-test--make-session)))
    (setq mutype--current-session session)
    (unwind-protect
        (mutype-test--without-report-ui
          (kill-buffer (mutype-session-buffer session))
          (mutype--tick)
          (should (null mutype--current-session))
          (should (equal (plist-get mutype--last-report :state) 'aborted))
          (should (string= (plist-get mutype--last-report :reason)
                           "Training buffer was closed.")))
      (setq mutype--current-session nil))))

(ert-deftest mutype-build-report-zero-input ()
  (let ((session (mutype-test--make-session :text (mutype-test--long-text))))
    (unwind-protect
        (let ((report (mutype--build-report session "empty")))
          (should (= (plist-get report :total) 0))
          (should (= (plist-get report :errors) 0))
          (should (= (plist-get report :accuracy) 0.0))
          (should (>= (plist-get report :cpm) 0.0)))
      (mutype-test--cleanup-session session))))

(provide 'mutype-test)

;;; mutype-test.el ends here
