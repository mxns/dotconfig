;; navigation ---  -*- lexical-binding: t -*-

;;; Commentary:
;;; navigation

;;; Code:

(require 'scroll-lock)

(defgroup mxns nil
  "Personal customizations."
  :prefix "mxns/"
  :group 'convenience)

(defun mxns/do-while-preserving-screen-position (action &optional use-arg)
  "Return a function that perform ACTION while preserving screen position.
If USE-ARG is provided and ARG is present, ACTION is called with ARG.
Otherwise, ACTION is called without arguments."
  (lambda (&optional arg)
    (interactive "p")
    (let ((current-setting (if scroll-preserve-screen-position 1 nil)))
      (condition-case err
          (progn
	    (if (> (current-column) (or scroll-lock-temporary-goal-column 0)) (scroll-lock-update-goal-column))
            (setq scroll-preserve-screen-position 1)
            (let ((result (if (and arg use-arg)
			      (funcall action arg)
                            (funcall action))))
	      (setq scroll-preserve-screen-position current-setting)
	      result))
        (error
	 (set-goal-column t)
         (setq scroll-preserve-screen-position current-setting)
         (signal (car err) (cdr err)))))))

(defun mxns/do-while-not-preserving-screen-position (action &optional use-arg)
  "Return a function that perform ACTION while not preserving screen position.
If USE-ARG is provided and ARG is present, ACTION is called with ARG.
Otherwise, ACTION is called without arguments."
  (lambda (&optional arg)
    (interactive "p")
    (let ((current-setting (if scroll-preserve-screen-position 1 nil)))
      (condition-case err
          (progn
	    (if (> (current-column) (or goal-column 0)) (set-goal-column nil))
            (setq scroll-preserve-screen-position nil)
            (let ((result (if (and arg use-arg)
			      (funcall action arg)
                            (funcall action))))
	      (setq scroll-preserve-screen-position current-setting)
	      result))
        (error
	 (set-goal-column t)
         (setq scroll-preserve-screen-position current-setting)
         (signal (car err) (cdr err)))))))

(defun mxns/scroll-lock-update-goal-column ()
  "Update `scroll-lock-temporary-goal-column' if necessary."
  (unless (memq last-command '(mxns/scroll-lock-next-line
			       mxns/scroll-lock-previous-line
			       scroll-lock-forward-paragraph
			       scroll-lock-backward-paragraph))
    (setq scroll-lock-temporary-goal-column (current-column))))

(defun mxns/scroll-lock-next-line (&optional arg)
  "Scroll up ARG lines keeping point fixed."
  (interactive "P")
  (or arg (setq arg 1))
  (mxns/scroll-lock-update-goal-column)
  (let ((current-setting (if scroll-preserve-screen-position 1 nil)))
    (condition-case err
        (progn
          (setq scroll-preserve-screen-position 1)
          (if (not (pos-visible-in-window-p (point-max)))
	      (scroll-up arg))
          (setq scroll-preserve-screen-position current-setting))
      (error
       (setq scroll-preserve-screen-position current-setting)
       (signal (car err) (cdr err)))))
  (scroll-lock-move-to-column scroll-lock-temporary-goal-column))

(defun mxns/scroll-lock-previous-line (&optional arg)
  "Scroll up ARG lines keeping point fixed."
  (interactive "P")
  (or arg (setq arg 1))
  (mxns/scroll-lock-update-goal-column)
  (let ((current-setting (if scroll-preserve-screen-position 1 nil)))
    (condition-case err
        (progn
          (setq scroll-preserve-screen-position 1)
          (scroll-down arg)
          (setq scroll-preserve-screen-position current-setting))
      (error
       (setq scroll-preserve-screen-position current-setting)
       (signal (car err) (cdr err)))))
  (scroll-lock-move-to-column scroll-lock-temporary-goal-column))

(defvar mxns/nav-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "M-n") 'mxns/scroll-lock-next-line)
    (define-key map (kbd "M-p") 'mxns/scroll-lock-previous-line)
    (define-key map (kbd "M-N") 'scroll-lock-next-line)
    (define-key map (kbd "M-P") 'scroll-lock-previous-line)
    map)
  "Keymap for mxns/nav-mode.")

(define-minor-mode mxns/nav-mode
  "Minor mode to add navigation keybindings."
  :keymap mxns/nav-mode-map
  :group 'mxns)

(defcustom mxns/nav-mode-include-modes
  '(text-mode-hook
    prog-mode-hook
    conf-mode-hook)
  "Hooks where mxns/nav-mode should be enabled.
Most text and programming modes derive from \='text-mode\=' or \='prog-mode\='."
  :type '(repeat symbol)
  :group 'mxns)

;; Add to specific hooks instead of using define-globalized-minor-mode
(dolist (hook mxns/nav-mode-include-modes)
  (add-hook hook 'mxns/nav-mode))

(global-set-key (kbd "C-c n") #'mxns/nav-mode)
(global-set-key (kbd "C-v") (mxns/do-while-preserving-screen-position #'scroll-up-command))
(global-set-key (kbd "M-v") (mxns/do-while-preserving-screen-position #'scroll-down-command))

;;; init-nav.el ends here
