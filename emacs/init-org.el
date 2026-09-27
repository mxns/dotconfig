;;; init-org.el --- Org mode configuration -*- lexical-binding: t; -*-

(defun my/recurring-task-template ()
  "Capture template for a recurring multi-step task.
Prompt once for a base date, then schedule each subtask relative
to it (base date plus or minus a fixed number of days)."
  (let* ((name (read-string "Lägenhetsnummer: "))
         (base (org-read-date nil t nil "Tillträde-datum"))        ; one prompt, returns a time value
         (day  (lambda (n)                                         ; base date +/- n days as an org stamp
                 (format-time-string
                  "<%Y-%m-%d %a>"
                  (time-add base (* n 86400))))))
    (concat
     "* TODO Tillträde lgh " name "\n"
     "** TODO Skicka välkomstbrev lgh " name "\nSCHEDULED: " (funcall day -30)  "\n"
     "** TODO Inflyttning lgh " name ": återställ lösenord Aptus\nSCHEDULED: " (funcall day 0))))

(defvar mxns/org-prefix-map
  (let ((map (make-sparse-keymap)))
    (define-key map "t" 'org-todo)
    (define-key map "s" 'org-schedule)
    (define-key map "d" 'org-deadline)
    (define-key map "r" 'org-refile)
    (define-key map "a" 'org-archive-subtree)
    (define-key map "m" 'mxns/org-set-reminder)
    map)
  "Keymap for my most-used org commands.")

(which-key-add-keymap-based-replacements mxns/org-prefix-map
    "t" "Todo state"
    "s" "Schedule"
    "d" "Deadline"
    "r" "Refile"
    "a" "Archive"
    "m" "Reminder")

(use-package org
  :ensure nil
  :mode ("\\.org\\'" . org-mode)
  :bind (("C-c c" . org-capture)
         ("C-c a" . org-agenda)
         (:map org-mode-map
               ("C-c '" . org-edit-special)
               ;; Snappier single-key navigation (C-c <letter> is user space).
               ("C-c n" . org-next-visible-heading)      ; next heading
               ("C-c p" . org-previous-visible-heading)  ; previous heading
               ("C-c u" . outline-up-heading)            ; up to parent
               ("C-c N" . org-toggle-narrow-to-subtree))) ; focus one subtree
  :config
  (define-key org-mode-map (kbd "C-c o") mxns/org-prefix-map)
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (python . t)
     (R . t)
     (shell . t)))
  (setq org-use-fast-todo-selection t  ; single-letter TODO state selection, shows the mapping popup
        org-agenda-files '("~/org/")
        org-confirm-babel-evaluate nil
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-src-preserve-indentation t
        org-src-window-setup 'current-window
        org-edit-src-content-indentation 0
        ;; org directory and capture
        org-directory "~/org/"
        org-default-notes-file "~/org/inbox.org"
        org-capture-templates
        '(("t" "Todo" entry (file "~/org/inbox.org")
           "* TODO %?\n  %U")
          ("b" "Bookmark" entry (file "~/org/inbox.org")
           "* TODO %?\n  %U\n  %a")
          ("n" "Note" entry (file "~/org/inbox.org")
           "* %?\n  %U")
          ("j" "Journal" entry (file+datetree "~/org/journal.org")
           "* %?\n  %U")
          ("r" "Tillträde" entry (file "~/org/inbox.org")
           (function my/recurring-task-template)
           :empty-lines 1))
        org-refile-targets '((org-agenda-files :maxlevel . 2))
        org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil
        org-refile-allow-creating-parent-nodes 'confirm
        org-cycle-separator-lines 1
        org-return-follows-link t       ; RET on a link follows it
        ;; Cleaner display
        org-startup-indented t          ; indent tree, hide leading stars
        org-hide-emphasis-markers t     ; show *bold* as bold, not with markers
        org-pretty-entities t           ; render \alpha, sub/superscripts, etc.
        org-ellipsis "…"
        ;; Agenda view
        org-agenda-window-setup 'current-window
        org-agenda-restore-windows-after-quit t
        org-agenda-span 'week
        org-agenda-start-on-weekday 1        ; weeks start on Monday
        org-agenda-start-day nil             ; ...but jump to today's week
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-skip-scheduled-if-deadline-is-shown t
        org-deadline-warning-days 7
        org-agenda-block-separator ?─        ; a clean rule between blocks
        org-agenda-tags-column 'auto         ; right-align tags to the edge
        org-agenda-current-time-string "◀── now ─────────────────────"
        org-agenda-time-grid
        '((daily today require-timed)
          (800 1000 1200 1400 1600 1800 2000)
          " ┄┄┄┄┄ " "┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈")
        ;; Compact, aligned prefixes: right-padded category, then time/state.
        org-agenda-prefix-format
        '((agenda . " %i %-14:c%?-12t% s")
          (todo   . " %i %-14:c")
          (tags   . " %i %-14:c")
          (search . " %i %-14:c")))
  )

;; Proportional font for prose. mixed-pitch is smarter than variable-pitch-mode:
;; it keeps code blocks, tables, timestamps, etc. monospace (via
;; mixed-pitch-fixed-pitch-faces) while prose uses the variable-pitch font.
;; The agenda buffer (org-agenda-mode) is left untouched so its columns align.
(use-package mixed-pitch
  :pin "melpa-stable"                     ; only archive that carries it
  :hook (org-mode . mixed-pitch-mode))

;; org-modern: modern bullets, pill-shaped TODO keywords and timestamps.
(use-package org-modern
  :pin "gnu"                             ; melpa-stable's tarball 404s; use GNU ELPA
  :after org
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :config
  (setq org-modern-star 'replace
        ;; Heading bullets per level (cycles): ◎ ○ ✳ — matches jakebox.
        org-modern-replace-stars "◎○✳"
        ;; Plain-list items get a florette, like jakebox's org-superstar setup.
        org-modern-list '((?- . "✿")
                          (?+ . "✿")
                          (?* . "•"))))

;; Version control for the org files themselves (~/org is its own Git repo).
;; `git-auto-commit-mode' is the usual package for this, but it commits one
;; file per save, so a single `org-save-all-org-buffers' would land as several
;; one-file commits. Hang off that command instead and record the whole batch
;; as a single commit.
(defun mxns/org-git-commit ()
  "Stage and commit everything under `org-directory' as a single commit.
Does nothing when that directory is not a Git repo, or has no changes."
  (interactive)
  (let ((default-directory (expand-file-name org-directory)))
    (when (file-directory-p ".git")
      (with-temp-buffer
        (call-process "git" nil t nil "status" "--porcelain")
        (unless (zerop (buffer-size))       ; nothing changed, nothing to do
          (erase-buffer)
          (unless (and (zerop (call-process "git" nil t nil "add" "-A"))
                       (zerop (call-process "git" nil t nil "commit" "-m"
                                            (format-time-string
                                             "org: %Y-%m-%d %H:%M"))))
            (message "org auto-commit failed: %s"
                     (string-trim (buffer-string)))))))))

(advice-add 'org-save-all-org-buffers :after #'mxns/org-git-commit)

;; Reminders: a REMIND property holding a timestamp with a time. The Android
;; app (~/devel/mxns/org-reminders) pulls ~/org and notifies at that time.
(defun mxns/org-set-reminder (&optional remove)
  "Set the REMIND property of the item at point to a date and time.
Defaults to the item's SCHEDULED time.  With prefix argument REMOVE,
delete the reminder instead.  Works in org buffers and the agenda."
  (interactive "P")
  (if (derived-mode-p 'org-agenda-mode)
      (let ((marker (or (org-get-at-bol 'org-hd-marker) (org-agenda-error))))
        (org-agenda-with-point-at marker
          (mxns/org-set-reminder remove)))
    (if remove
        (progn (org-entry-delete nil "REMIND")
               (message "Reminder removed"))
      (let* ((sched (org-entry-get nil "SCHEDULED"))
             (input (org-read-date t nil nil "Påminnelse"
                                   (and sched (org-time-string-to-time sched)))))
        (unless (string-match-p "[0-9]:[0-9]" input)
          (user-error "A reminder needs a time, e.g. \"fri 12:30\""))
        (let ((stamp (format-time-string "<%Y-%m-%d %a %H:%M>"
                                         (org-time-string-to-time input))))
          (org-entry-put nil "REMIND" stamp)
          (message "Reminder set: %s" stamp))))))

(with-eval-after-load 'org-agenda
  (define-key org-agenda-mode-map (kbd "C-c o m") #'mxns/org-set-reminder))

(provide 'init-org)
;;; init-org.el ends here
