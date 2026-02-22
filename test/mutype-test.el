;;; mutype-test.el --- Tests for MuType -*- lexical-binding: t; -*-

;;; Commentary:

;; Test coverage for mode behavior, source switching, HUD rendering,
;; session lifecycle, and report calculations.

;;; Code:

(require 'cl-lib)
(require 'ert)
(setq load-prefer-newer t)
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
     (source-type 'source-directory)
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

(defun mutype-test--write-file (file-path text)
  "Write TEXT into FILE-PATH."
  (with-temp-file file-path
    (insert text)))

(defun mutype-test--make-source-dir (entries)
  "Create a temp source directory from ENTRIES.
ENTRIES is a list of (FILENAME . TEXT)."
  (let ((dir (make-temp-file "mutype-source-dir-" t)))
    (dolist (entry entries)
      (mutype-test--write-file (expand-file-name (car entry) dir) (cdr entry)))
    dir))

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

(ert-deftest mutype-done-face-does-not-inherit-shadow ()
  (should-not (eq (face-attribute 'mutype-done-face :inherit nil 'default)
                  'shadow)))

(ert-deftest mutype-training-mode-uses-text-layout ()
  (with-temp-buffer
    (mutype-training-mode)
    (should (derived-mode-p 'text-mode))
    (should (null truncate-lines))
    (should word-wrap)
    (should (bound-and-true-p visual-line-mode))
    (should mode-line-format)
    (should (null header-line-format))))

(ert-deftest mutype-training-mode-keymap-remaps-input-and-backtrack ()
  (with-temp-buffer
    (mutype-training-mode)
    (should (eq (lookup-key mutype-training-mode-map [remap self-insert-command])
                #'mutype--dispatch-input))
    (should (eq (local-key-binding (kbd "C-c C-n")) #'mutype-next-source))
    (should (eq (local-key-binding (kbd "C-c C-b")) #'mutype-prev-source))
    (should (eq (local-key-binding (kbd "RET")) #'mutype--dispatch-input))
    (should (eq (local-key-binding (kbd "DEL")) #'mutype--backtrack-input))
    (should (eq (local-key-binding (kbd "<backspace>")) #'mutype--backtrack-input))
    (should-not (lookup-key mutype-training-mode-map [t]))
    (should-not (eq (local-key-binding (kbd "<right>")) #'mutype--dispatch-input))
    (should-not (eq (local-key-binding (kbd "C-g")) #'mutype-stop))))

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

(ert-deftest mutype-dispatch-input-snaps-to-sequential-index ()
  (let ((session (mutype-test--make-session :mode 'flow :text "abc")))
    (setq mutype--current-session session)
    (unwind-protect
        (progn
          (mutype--mark-current-char session)
          (with-current-buffer (mutype-session-buffer session)
            (goto-char (point-max)))
          (let ((last-command-event ?a))
            (mutype--dispatch-input))
          (should (= (mutype-session-index session) 1))
          (with-current-buffer (mutype-session-buffer session)
            (should (= (point) 2))
            (let ((first-face (get-text-property 1 'face))
                  (second-face (get-text-property 2 'face)))
              (should (mutype-test--face-has-p first-face 'mutype-done-face))
              (should (mutype-test--face-has-p second-face 'mutype-current-face)))))
      (setq mutype--current-session nil)
      (mutype-test--cleanup-session session))))

(ert-deftest mutype-backtrack-input-reverts-one-position ()
  (let ((session (mutype-test--make-session :mode 'flow :text "abc")))
    (setq mutype--current-session session)
    (unwind-protect
        (progn
          (mutype--mark-current-char session)
          (mutype--handle-input session ?a)
          (mutype--handle-input session ?x)
          (let ((total (mutype-session-total-count session))
                (correct (mutype-session-correct-count session))
                (errors (mutype-session-error-count session)))
            (should (= (mutype-session-index session) 2))
            (mutype--backtrack-input)
            (should (= (mutype-session-index session) 1))
            (should (= (mutype-session-total-count session) total))
            (should (= (mutype-session-correct-count session) correct))
            (should (= (mutype-session-error-count session) errors)))
          (with-current-buffer (mutype-session-buffer session)
            (should (= (point) 2))
            (let ((first-face (get-text-property 1 'face))
                  (second-face (get-text-property 2 'face))
                  (third-face (get-text-property 3 'face)))
              (should (mutype-test--face-has-p first-face 'mutype-done-face))
              (should (mutype-test--face-has-p second-face 'mutype-current-face))
              (should-not (mutype-test--face-has-p second-face 'mutype-done-face))
              (should-not (mutype-test--face-has-p second-face 'mutype-error-face))
              (should (mutype-test--face-has-p third-face 'mutype-pending-face)))))
      (setq mutype--current-session nil)
      (mutype-test--cleanup-session session))))

(ert-deftest mutype-backtrack-input-does-nothing-when-paused ()
  (let ((session (mutype-test--make-session :mode 'flow :text "abc" :state 'paused :index 1)))
    (setq mutype--current-session session)
    (unwind-protect
        (progn
          (mutype--mark-current-char session)
          (mutype--backtrack-input)
          (should (= (mutype-session-index session) 1)))
      (setq mutype--current-session nil)
      (mutype-test--cleanup-session session))))

(ert-deftest mutype-backtrack-input-does-nothing-at-beginning ()
  (let ((session (mutype-test--make-session :mode 'flow :text "abc" :index 0)))
    (setq mutype--current-session session)
    (unwind-protect
        (progn
          (mutype--mark-current-char session)
          (mutype--backtrack-input)
          (should (= (mutype-session-index session) 0)))
      (setq mutype--current-session nil)
      (mutype-test--cleanup-session session))))

(ert-deftest mutype-mode-starts-with-selected-mode ()
  "Acceptance: mode selection starts a session with expected mode."
  (let ((source (list :type 'source-directory :label "t" :text (mutype-test--long-text))))
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

(ert-deftest mutype-mode-interactive-uses-quick-start-by-default ()
  (let ((source (list :type 'source-directory :label "quick" :text (mutype-test--long-text)))
        (called-read nil)
        (mutype-prompt-on-start nil))
    (setq mutype--current-session nil)
    (unwind-protect
        (mutype-test--without-report-ui
          (cl-letf (((symbol-function 'mutype--quick-start-args)
                     (lambda () (list 'flow 0 source)))
                    ((symbol-function 'mutype--read-start-args)
                     (lambda ()
                       (setq called-read t)
                       (error "should not prompt"))))
            (call-interactively #'mutype-mode)
            (should (not called-read))
            (should (mutype-session-p mutype--current-session))
            (should (eq (mutype-session-mode mutype--current-session) 'flow))
            (mutype-stop)))
      (when (mutype-session-p mutype--current-session)
        (mutype-test--cleanup-session mutype--current-session))
      (setq mutype--current-session nil))))

(ert-deftest mutype-mode-custom-uses-interactive-prompts ()
  (let ((source (list :type 'source-directory :label "custom" :text (mutype-test--long-text)))
        (called-read nil)
        (mutype-prompt-on-start nil))
    (setq mutype--current-session nil)
    (unwind-protect
        (mutype-test--without-report-ui
          (cl-letf (((symbol-function 'mutype--read-start-args)
                     (lambda ()
                       (setq called-read t)
                       (list 'precision 0 source))))
            (call-interactively #'mutype-mode-custom)
            (should called-read)
            (should (mutype-session-p mutype--current-session))
            (should (eq (mutype-session-mode mutype--current-session) 'precision))
            (mutype-stop)))
      (when (mutype-session-p mutype--current-session)
        (mutype-test--cleanup-session mutype--current-session))
      (setq mutype--current-session nil))))

(ert-deftest mutype-hud-shows-mode-line-status ()
  "Acceptance: HUD updates the MuType mode line status."
  (let* ((session (mutype-test--make-session
                   :state 'paused
                   :text "abcdefghij"
                   :source-label "chapter-01"
                   :zone-level 2
                   :index 7
                   :start-time (- (float-time) 12)
                   :duration-limit 180)))
    (unwind-protect
        (progn
          (setf (mutype-session-correct-count session) 8
                (mutype-session-total-count session) 10)
          (mutype--update-hud session)
          (with-current-buffer (mutype-session-buffer session)
            (let ((hud mutype--mode-line-status))
              (should (stringp hud))
              (should (string-match-p "\\*" hud))
              (should (string-match-p "paused" hud))
              (should (string-match-p "p:7/10" hud))
              (should (string-match-p "acc:80\\.0%" hud))
              (let ((source-pos (string-match "src:chapter-01" hud)))
                (should source-pos)
                (should (equal (get-text-property source-pos 'help-echo hud)
                               "mouse-1: Select source text"))
                (let ((map (get-text-property source-pos 'local-map hud)))
                  (should (keymapp map))
                  (should (eq (lookup-key map [mode-line mouse-1])
                              #'mutype-select-source))))
              (should (null header-line-format)))))
      (mutype-test--cleanup-session session))))

(ert-deftest mutype-hud-uses-accuracy-placeholder-at-zero-input ()
  (let* ((session (mutype-test--make-session :mode 'flow :text "abcde")))
    (unwind-protect
        (progn
          (mutype--update-hud session)
          (with-current-buffer (mutype-session-buffer session)
            (should (string-match-p "acc:--" mutype--mode-line-status))))
      (mutype-test--cleanup-session session))))

(ert-deftest mutype-fit-mode-line-segments-drops-lower-priority-fields ()
  (let ((segments '((core . "● 03:21 paused")
                    (progress . "p:120/800")
                    (accuracy . "acc:97.3%")
                    (source . "src:chapter-42"))))
    (should (string-match-p "acc:97\\.3%"
                            (mutype--fit-mode-line-segments segments 80)))
    (should (string-match-p "src:chapter-42"
                            (mutype--fit-mode-line-segments segments 80)))
    (let ((without-source (mutype--fit-mode-line-segments segments 36)))
      (should (string-match-p "acc:97\\.3%" without-source))
      (should (string-match-p "p:120/800" without-source))
      (should-not (string-match-p "src:chapter-42" without-source)))
    (let ((compact (mutype--fit-mode-line-segments segments 26)))
      (should (string-match-p "p:120/800" compact))
      (should-not (string-match-p "acc:97\\.3%" compact))
      (should-not (string-match-p "src:chapter-42" compact)))
    (let ((minimal (mutype--fit-mode-line-segments segments 13)))
      (should (string-match-p "03:21" minimal))
      (should (string-match-p "paused" minimal))
      (should-not (string-match-p "p:120/800" minimal))
      (should-not (string-match-p "acc:97\\.3%" minimal))
      (should-not (string-match-p "src:chapter-42" minimal)))))

(ert-deftest mutype-source-switching ()
  "Acceptance: source directory loading works."
  (let ((dir (mutype-test--make-source-dir
              `(("001-alpha.txt" . ,(mutype-test--long-text))
                ("002-beta.txt" . ,(concat (mutype-test--long-text) "a"))))))
    (unwind-protect
        (let* ((mutype-source-directory dir)
               (first (mutype--source-from-directory-first))
               (all (mutype--scan-source-directory)))
          (should (equal (plist-get first :type) 'source-directory))
          (should (equal (plist-get first :label) "001-alpha"))
          (should (= (length all) 2)))
      (delete-directory dir t))))

(ert-deftest mutype-list-source-files-sorts-by-name ()
  (let ((dir (mutype-test--make-source-dir
              '(("002-beta.txt" . "beta")
                ("001-alpha.txt" . "alpha")))))
    (unwind-protect
        (let ((files (mutype--list-source-files dir)))
          (should (equal (mapcar #'file-name-nondirectory files)
                         '("001-alpha.txt" "002-beta.txt"))))
      (delete-directory dir t))))

(ert-deftest mutype-source-from-directory-first-picks-first-file ()
  (let ((dir (mutype-test--make-source-dir
              `(("002-beta.txt" . ,(mutype-test--long-text))
                ("001-alpha.txt" . ,(concat (mutype-test--long-text) "a"))))))
    (unwind-protect
        (let* ((mutype-source-directory dir)
               (source (mutype--source-from-directory-first)))
          (should (equal (plist-get source :type) 'source-directory))
          (should (equal (plist-get source :label) "001-alpha")))
      (delete-directory dir t))))

(ert-deftest mutype-quick-start-args-use-source-directory-first ()
  (let ((dir (mutype-test--make-source-dir
              `(("002-second.txt" . ,(mutype-test--long-text))
                ("001-first.txt" . ,(concat (mutype-test--long-text) "b"))))))
    (unwind-protect
        (let* ((mutype-source-directory dir)
               (args (mutype--quick-start-args))
               (source (nth 2 args)))
          (should (equal (plist-get source :label) "001-first")))
      (delete-directory dir t))))

(ert-deftest mutype-scan-source-directory-error-cases ()
  (let ((missing-dir (expand-file-name "mutype-does-not-exist" temporary-file-directory))
        (empty-dir (make-temp-file "mutype-empty-" t))
        (invalid-dir (mutype-test--make-source-dir '(("001-short.txt" . "tiny")))))
    (unwind-protect
        (progn
          (should-error (mutype--scan-source-directory missing-dir))
          (should-error (mutype--scan-source-directory empty-dir))
          (let ((mutype-minimum-text-length 20))
            (should-error (mutype--scan-source-directory invalid-dir))))
      (delete-directory empty-dir t)
      (delete-directory invalid-dir t))))

(ert-deftest mutype-read-source-supports-source-directory-choice ()
  (let ((dir (mutype-test--make-source-dir
              `(("001-alpha.txt" . ,(mutype-test--long-text))
                ("002-beta.txt" . ,(mutype-test--long-text)))))
        (answers '("001-alpha")))
    (unwind-protect
        (let ((mutype-source-directory dir))
          (cl-letf (((symbol-function 'completing-read)
                     (lambda (&rest _args)
                       (prog1 (car answers)
                         (setq answers (cdr answers))))))
            (let ((source (mutype--read-source)))
              (should (equal (plist-get source :type) 'source-directory))
              (should (equal (plist-get source :label) "001-alpha")))))
      (delete-directory dir t))))

(ert-deftest mutype-next-source-switches-and-wraps ()
  (let ((dir (mutype-test--make-source-dir
              `(("001-alpha.txt" . ,(mutype-test--long-text))
                ("002-beta.txt" . ,(mutype-test--long-text))
                ("003-gamma.txt" . ,(mutype-test--long-text)))))
        (captured nil))
    (unwind-protect
        (let* ((mutype-source-directory dir)
               (session (mutype-test--make-session
                         :mode 'precision
                         :state 'running
                         :text "abcde"
                         :source-type 'source-directory
                         :source-label "003-gamma"
                         :duration-limit 90)))
          (setq mutype--current-session session)
          (cl-letf (((symbol-function 'mutype-mode)
                     (lambda (mode duration source)
                       (setq captured (list mode duration source))))
                    ((symbol-function 'mutype-stop)
                     (lambda ()
                       (setq mutype--current-session nil))))
            (mutype-next-source))
          (should (equal (nth 0 captured) 'precision))
          (should (= (nth 1 captured) 90))
          (should (equal (plist-get (nth 2 captured) :label) "001-alpha"))
          (mutype-test--cleanup-session session)
          (setq mutype--current-session nil))
      (delete-directory dir t))))

(ert-deftest mutype-prev-source-uses-last-report-when-inactive ()
  (let ((dir (mutype-test--make-source-dir
              `(("001-alpha.txt" . ,(mutype-test--long-text))
                ("002-beta.txt" . ,(mutype-test--long-text))
                ("003-gamma.txt" . ,(mutype-test--long-text)))))
        (captured nil))
    (unwind-protect
        (let ((mutype-source-directory dir)
              (mutype--current-session nil)
              (mutype--last-report
               (list :source-type 'source-directory
                     :source-label "001-alpha")))
          (cl-letf (((symbol-function 'mutype-mode)
                     (lambda (mode duration source)
                       (setq captured (list mode duration source)))))
            (mutype-prev-source))
          (should (equal (nth 0 captured) mutype-default-mode))
          (should (= (nth 1 captured) (or (mutype--default-duration) 0)))
          (should (equal (plist-get (nth 2 captured) :label) "003-gamma")))
      (delete-directory dir t))))

(ert-deftest mutype-select-source-switches-running-session ()
  (let ((dir (mutype-test--make-source-dir
              `(("001-alpha.txt" . ,(mutype-test--long-text))
                ("002-beta.txt" . ,(mutype-test--long-text)))))
        (captured nil)
        (answers '("002-beta")))
    (unwind-protect
        (let* ((mutype-source-directory dir)
               (session (mutype-test--make-session
                         :mode 'precision
                         :state 'running
                         :text "abcde"
                         :source-type 'source-directory
                         :source-label "001-alpha"
                         :duration-limit 75)))
          (setq mutype--current-session session)
          (cl-letf (((symbol-function 'completing-read)
                     (lambda (&rest _args)
                       (prog1 (car answers)
                         (setq answers (cdr answers)))))
                    ((symbol-function 'mutype-mode)
                     (lambda (mode duration source)
                       (setq captured (list mode duration source))))
                    ((symbol-function 'mutype-stop)
                     (lambda ()
                       (setq mutype--current-session nil))))
            (mutype-select-source))
          (should (equal (nth 0 captured) 'precision))
          (should (= (nth 1 captured) 75))
          (should (equal (plist-get (nth 2 captured) :label) "002-beta"))
          (mutype-test--cleanup-session session)
          (setq mutype--current-session nil))
      (delete-directory dir t))))

(ert-deftest mutype-select-source-uses-defaults-when-inactive ()
  (let ((dir (mutype-test--make-source-dir
              `(("001-alpha.txt" . ,(mutype-test--long-text))
                ("002-beta.txt" . ,(mutype-test--long-text)))))
        (captured nil)
        (answers '("001-alpha")))
    (unwind-protect
        (let ((mutype-source-directory dir)
              (mutype--current-session nil)
              (mutype--last-report nil))
          (cl-letf (((symbol-function 'completing-read)
                     (lambda (&rest _args)
                       (prog1 (car answers)
                         (setq answers (cdr answers)))))
                    ((symbol-function 'mutype-mode)
                     (lambda (mode duration source)
                       (setq captured (list mode duration source)))))
            (mutype-select-source))
          (should (equal (nth 0 captured) mutype-default-mode))
          (should (= (nth 1 captured) (or (mutype--default-duration) 0)))
          (should (equal (plist-get (nth 2 captured) :label) "001-alpha")))
      (delete-directory dir t))))

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
