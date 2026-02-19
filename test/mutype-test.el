;;; mutype-test.el --- Tests for MuType -*- lexical-binding: t; -*-

;;; Commentary:

;; Basic test coverage for MuType MVP behavior.

;;; Code:

(require 'ert)
(require 'mutype)

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
  (let* ((buffer (get-buffer-create " *mutype-flow-test*"))
         (session (make-mutype-session
                   :id 1
                   :state 'running
                   :mode 'flow
                   :source-type 'builtin
                   :source-label "test"
                   :text "abc"
                   :length 3
                   :index 0
                   :start-time (float-time)
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
                   :buffer buffer)))
    (unwind-protect
        (progn
          (with-current-buffer buffer
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert "abc")
              (add-text-properties (point-min) (point-max) '(face mutype-pending-face))))
          (mutype--mark-current-char session)
          (mutype--handle-input session ?x)
          (should (= (mutype-session-index session) 1))
          (should (= (mutype-session-error-count session) 1))
          (should (= (mutype-session-total-count session) 1)))
      (when (buffer-live-p buffer)
        (kill-buffer buffer)))))

(ert-deftest mutype-precision-blocks-on-error ()
  (let* ((buffer (get-buffer-create " *mutype-precision-test*"))
         (session (make-mutype-session
                   :id 2
                   :state 'running
                   :mode 'precision
                   :source-type 'builtin
                   :source-label "test"
                   :text "abc"
                   :length 3
                   :index 0
                   :start-time (float-time)
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
                   :buffer buffer)))
    (unwind-protect
        (progn
          (with-current-buffer buffer
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert "abc")
              (add-text-properties (point-min) (point-max) '(face mutype-pending-face))))
          (mutype--mark-current-char session)
          (mutype--handle-input session ?x)
          (should (= (mutype-session-index session) 0))
          (should (= (mutype-session-error-count session) 1))
          (should (= (mutype-session-total-count session) 1)))
      (when (buffer-live-p buffer)
        (kill-buffer buffer)))))

(provide 'mutype-test)

;;; mutype-test.el ends here
