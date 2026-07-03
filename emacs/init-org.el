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
               ("C-c '" . org-edit-special)))
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
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
        org-cycle-separator-lines 1))

(provide 'init-org)
;;; init-org.el ends here
