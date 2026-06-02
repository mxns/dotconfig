;;; export-readme.el --- Export readme.org to GitHub-flavored README.md  -*- lexical-binding: t; -*-
;;
;; Defines a small Markdown backend (`gh-md') derived from the built-in `md'
;; exporter, with one tweak: source blocks are emitted as fenced ```lang code
;; blocks so GitHub highlights them. Everything else (headings, description
;; lists, nested lists) comes from the stock exporter, which renders cleanly
;; on GitHub.
;;
;; Two ways to use it:
;;
;;   * Batch (the pre-commit hook):
;;       emacs --batch --no-init-file --load export-readme.el \
;;         --eval '(my/export-readme "readme.org")'
;;
;;   * Interactively, from a running Emacs:
;;       Load this file once -- M-x load-file, or add
;;         (load "~/.config/.githooks/export-readme.el")
;;       to your init -- then, with readme.org in the current buffer:
;;         M-x my/export-readme        ;; or
;;         C-c C-e G                   ;; from the Org export dispatcher

(require 'ox-md)

(defun my/md-src-block (src-block _contents info)
  "Export Org SRC-BLOCK as a GitHub fenced code block."
  (let ((lang (org-element-property :language src-block))
        (code (org-export-format-code-default src-block info)))
    (format "```%s\n%s```" (or lang "") code)))

(defun my/export-readme (&optional org-file)
  "Export ORG-FILE to a sibling README.md as GitHub-flavored Markdown.
Interactively (or when ORG-FILE is nil) use the file visited by the
current buffer -- run this from readme.org.  Emits fenced code blocks and
prepends a \"generated\" banner, matching the pre-commit hook.

The export options are bound locally, so loading this file or running the
command does not change your global Org export settings."
  (interactive)
  (let* ((org-file (or org-file buffer-file-name
                       (user-error "No file to export; visit readme.org first")))
         (out (expand-file-name "README.md" (file-name-directory org-file)))
         (banner "<!-- Generated from readme.org by the pre-commit hook. Do not edit directly. -->\n\n")
         (org-export-with-toc nil)
         (org-export-with-author nil)
         (org-export-with-creator nil)
         (org-export-with-section-numbers nil)
         (org-export-headline-levels 6)
         (body (with-current-buffer (find-file-noselect org-file)
                 (org-export-as 'gh-md))))
    (with-temp-file out
      (insert banner body))
    (when (called-interactively-p 'any)
      (message "Wrote %s" out))
    out))

(org-export-define-derived-backend 'gh-md 'md
  :menu-entry '(?G "Export to GitHub README.md"
                   (lambda (&rest _) (my/export-readme)))
  :translate-alist '((src-block . my/md-src-block)))

(provide 'export-readme)
;;; export-readme.el ends here
