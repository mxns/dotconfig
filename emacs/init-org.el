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
     "** TODO Skicka välkomstbrev\nSCHEDULED: " (funcall day -30)  "\n"
     "** TODO Återställa lösenord Aptus\nSCHEDULED: " (funcall day 0))))

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
               ("C-c N" . org-toggle-narrow-to-subtree))); focus one subtree
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (python . t)
     (R . t)
     (shell . t)))
  (setq org-agenda-files '("~/org/")
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

(provide 'init-org)
;;; init-org.el ends here
