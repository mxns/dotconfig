;;; init-pass.el --- mxns config -*- lexical-binding: t; -*-

;;; Commentary:
;;; GUI integration with pass(1). Mirrors tmux/pass-to-pane.sh: pick an
;;; entry with completion, insert the password at point (never via the
;;; kill ring or clipboard), and remember the last entry used. The "last used" state
;;; is kept in the same cache file the tmux popup writes, so the two
;;; integrations share it -- an entry picked in one shows up as the
;;; default in the other.

;;; Code:

;; GUI Emacs (started from Dock/Spotlight/launchd, not a shell) does not
;; inherit PATH from shell rc files, so Homebrew's `pass'/`gpg' may not
;; resolve. Add the Homebrew bin dirs directly rather than spawning a
;; shell to scrape the environment (e.g. exec-path-from-shell) -- that
;; shells out to an interactive login shell, which re-runs .bashrc/.zshrc
;; and hangs Emacs startup solid if anything in there blocks or waits on
;; a tty.
(when (memq window-system '(mac ns))
  (dolist (dir '("/opt/homebrew/bin" "/opt/homebrew/sbin"))
    (when (and (file-directory-p dir) (not (member dir exec-path)))
      (setq exec-path (cons dir exec-path))
      (setenv "PATH" (concat dir ":" (getenv "PATH"))))))

(use-package password-store)
;; If your password store lives somewhere other than ~/.password-store,
;; set it here directly instead of relying on $PASSWORD_STORE_DIR being
;; inherited from the shell (password-store-dir checks getenv, not a
;; defcustom):
;; (setenv "PASSWORD_STORE_DIR" "/path/to/store")

(defvar mxns/pass-last-entry-file
  (expand-file-name "tmux-pass-last"
                     (or (getenv "XDG_CACHE_HOME") "~/.cache"))
  "Cache file shared with tmux/pass-to-pane.sh for the last used pass entry.")

(defun mxns/pass-last-entry ()
  "Return the last pass entry used (by this or the tmux picker), or nil."
  (when (file-readable-p mxns/pass-last-entry-file)
    (let ((s (with-temp-buffer
               (insert-file-contents mxns/pass-last-entry-file)
               (string-trim (buffer-string)))))
      (unless (string-empty-p s) s))))

(defun mxns/pass-remember-entry (entry)
  "Record ENTRY as the last used pass entry."
  (make-directory (file-name-directory mxns/pass-last-entry-file) t)
  (with-temp-file mxns/pass-last-entry-file
    (insert entry))
  (set-file-modes mxns/pass-last-entry-file #o600))

(defun mxns/pass-read-entry ()
  "Read a pass entry with completion; RET on empty input reuses the last one.

Allows recursive minibuffers only for the duration of this read, so
picking an entry works from inside another minibuffer prompt (e.g. a
Tramp password prompt) without turning that on globally."
  (let* ((enable-recursive-minibuffers t)
         (last (mxns/pass-last-entry))
         (prompt (if last (format "pass entry (default %s): " last)
                   "pass entry: ")))
    (completing-read prompt (password-store-list) nil t nil nil last)))

(defun mxns/pass-insert (entry)
  "Insert the password for ENTRY at point, without touching the kill ring."
  (interactive (list (mxns/pass-read-entry)))
  (let ((pw (password-store-get entry)))
    (unless pw (user-error "Could not decrypt '%s'" entry))
    (insert pw)
    (mxns/pass-remember-entry entry)))

;; Deliberately no copy command. `password-store-copy' puts the password
;; on the kill ring and the system clipboard, and its timer only blanks
;; the kill-ring entry -- the clipboard keeps the password, and the next
;; yank pulls it back into the kill ring as a fresh, untracked entry.
;; Inserting at point never touches either.
(global-set-key (kbd "C-c P") #'mxns/pass-insert)

;; `C-c P' is a lot to type at a password prompt. On Emacs 30+,
;; `read-passwd' -- what Tramp, sudo-edit, etc. use to ask for one --
;; turns on `read-passwd-mode' (for the password-visibility toggle),
;; whose keymap (`read-passwd-map') takes precedence over anything we
;; could set as the buffer's local map, so bind directly on it instead.
;; It's scoped to password prompts only, so M-p (normally minibuffer
;; history, which read-passwd never populates -- passwords aren't kept
;; in history) is free to repurpose here.
(with-eval-after-load 'auth-source
  (define-key read-passwd-map (kbd "M-p") #'mxns/pass-insert))

;;; init-pass.el ends here
