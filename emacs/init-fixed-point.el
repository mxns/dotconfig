;;; init-fixed-point.el --- Fixed-point navigation mode -*- lexical-binding: t -*-

;;; Commentary:
;;; Minor mode that keeps the cursor at a fixed screen position.
;;; Navigation commands scroll the buffer instead of moving the cursor.

;;; Code:

(require 'scroll-lock)

(defgroup mxns nil
  "Personal customizations."
  :prefix "mxns/"
  :group 'convenience)

;;; Viewport scrolling (line by line)

(defun mxns/fixed-point--update-goal-column ()
  "Update `scroll-lock-temporary-goal-column' if necessary."
  (unless (memq last-command '(mxns/fixed-point-scroll-up-line
                               mxns/fixed-point-scroll-down-line))
    (setq scroll-lock-temporary-goal-column (current-column))))

(defun mxns/fixed-point-scroll-up-line (&optional arg)
  "Scroll up ARG lines keeping point at the same screen position.
Does not scroll past the end of the buffer."
  (interactive "P")
  (or arg (setq arg 1))
  (mxns/fixed-point--update-goal-column)
  (let ((scroll-preserve-screen-position 1))
    (when (not (pos-visible-in-window-p (point-max)))
      (scroll-up arg)))
  (scroll-lock-move-to-column scroll-lock-temporary-goal-column))

(defun mxns/fixed-point-scroll-down-line (&optional arg)
  "Scroll down ARG lines keeping point at the same screen position."
  (interactive "P")
  (or arg (setq arg 1))
  (mxns/fixed-point--update-goal-column)
  (let ((scroll-preserve-screen-position 1))
    (scroll-down arg))
  (scroll-lock-move-to-column scroll-lock-temporary-goal-column))

;;; Page scrolling with preserved screen position

(defun mxns/fixed-point-scroll-up (&optional arg)
  "Scroll up ARG pages, keeping point at the same screen position.
ARG defaults to 1.  With universal argument, multiplied by 4."
  (interactive "p")
  (let ((scroll-preserve-screen-position 1))
    (dotimes (_ arg)
      (scroll-up-command))))

(defun mxns/fixed-point-scroll-down (&optional arg)
  "Scroll down ARG pages, keeping point at the same screen position.
ARG defaults to 1.  With universal argument, multiplied by 4."
  (interactive "p")
  (let ((scroll-preserve-screen-position 1))
    (dotimes (_ arg)
      (scroll-down-command))))

;;; Fixed-point recenter (for all other navigation commands)

(defvar-local mxns/fixed-point--target-line nil
  "Screen line to restore after movement commands.")

(defvar-local mxns/fixed-point--mod-tick nil
  "Buffer modification tick before command execution.")

(defcustom mxns/fixed-point-exclude-commands
  '(beginning-of-buffer end-of-buffer
    recenter-top-bottom recenter
    move-to-window-line-top-bottom
    mxns/fixed-point-scroll-up-line
    mxns/fixed-point-scroll-down-line
    mxns/fixed-point-scroll-up
    mxns/fixed-point-scroll-down
    mouse-set-point mouse-drag-region
    keyboard-quit abort-recursive-edit)
  "Commands after which the screen position should not be restored."
  :type '(repeat symbol)
  :group 'mxns)

(defun mxns/fixed-point--window-line ()
  "Return the 0-indexed screen line of point within the window.
Handles wrapped lines correctly."
  (let ((pos (point)))
    (save-excursion
      (goto-char (window-start))
      (let ((n 0))
        (while (let ((prev (point)))
                 (vertical-motion 1)
                 (and (> (point) prev)
                      (<= (point) pos)))
          (setq n (1+ n)))
        n))))

(defun mxns/fixed-point--save ()
  "Save current screen line and modification state before command."
  (setq mxns/fixed-point--target-line (mxns/fixed-point--window-line))
  (setq mxns/fixed-point--mod-tick (buffer-modified-tick)))

(defun mxns/fixed-point--restore ()
  "Restore screen line after a navigation command."
  (when (and mxns/fixed-point--target-line
             (eq (buffer-modified-tick) mxns/fixed-point--mod-tick)
             (not (memq this-command mxns/fixed-point-exclude-commands))
             (not (minibufferp))
             (not (bound-and-true-p isearch-mode)))
    (recenter mxns/fixed-point--target-line)))

;;; Mode definition

(defvar mxns/fixed-point-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-v") #'mxns/fixed-point-scroll-up)
    (define-key map (kbd "M-v") #'mxns/fixed-point-scroll-down)
    map)
  "Keymap for `mxns/fixed-point-mode'.")

(define-minor-mode mxns/fixed-point-mode
  "Minor mode that keeps the cursor at a fixed screen position.
When enabled, navigation commands scroll the buffer instead of
moving the cursor on screen.  Editing commands are excluded
automatically via `buffer-modified-tick'.

Bindings when active:
  M-n / M-p  Scroll buffer line by line (viewport scrolling)
  C-v / M-v  Scroll buffer page by page

All other navigation commands (C-n, C-p, M-f, M-b, forward-list,
down-list, etc.) also keep the cursor at its current screen line."
  :lighter " FP"
  :keymap mxns/fixed-point-mode-map
  :group 'mxns
  (if mxns/fixed-point-mode
      (progn
        (setq mxns/fixed-point--target-line nil)
        (add-hook 'pre-command-hook #'mxns/fixed-point--save nil t)
        (add-hook 'post-command-hook #'mxns/fixed-point--restore nil t))
    (remove-hook 'pre-command-hook #'mxns/fixed-point--save t)
    (remove-hook 'post-command-hook #'mxns/fixed-point--restore t)))

(global-set-key (kbd "C-c n") #'mxns/fixed-point-mode)

;;; init-fixed-point.el ends here
