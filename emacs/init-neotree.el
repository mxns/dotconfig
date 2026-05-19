;;; init-neotree.el --- mxns config -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

(declare-function neo-global--window-exists-p "neotree")


(defvar mxns/neotree-prefix-map
  (let ((map (make-sparse-keymap)))
    (define-key map "T" 'mxns/neotree-project-root)
    (define-key map "g" 'mxns/neotree-increase-width)
    (define-key map "r" 'mxns/neotree-reset-width)
    (define-key map "t" 'neotree-toggle)
    (define-key map "f" 'neotree-find)
    (define-key map "v" 'neotree-enter-vertical-split)
    (define-key map "h" 'neotree-enter-horizontal-split)
    (define-key map "c" 'neotree-copy-filepath-to-yank-ring)
    map)
  "Keymap for neotree commands.")


(use-package neotree
  :ensure t
  :bind-keymap
  ("C-c t" . mxns/neotree-prefix-map)
  :hook
  (neotree-mode . hl-line-mode)
  :custom-face
  (hl-line ((t (:inverse-video t))))
  :config
  (setq neo-show-hidden-files t)
  (setq neo-autorefresh t)
  (setq neo-theme 'arrow)
  (setq neo-smart-open t)
  (setq neo-window-width 30)

  (defun mxns/neotree-project-root ()
    "Open neotree at the project root and find current file."
    (interactive)
    (let* ((project-root (if-let ((project (project-current)))
                             (project-root project)
                           default-directory))
           (current-file (buffer-file-name)))
      (save-selected-window
        (if (neo-global--window-exists-p)
            (progn
              (neotree-dir project-root)
              (when current-file (neotree-find current-file)))
          (progn
            (neotree-show)
            (neotree-dir project-root)
            (when current-file
              (run-with-idle-timer 0.1 nil
                                   (lambda ()
                                     (save-selected-window
                                       (neotree-find current-file))))))))))
  
  (defun mxns/neotree-project-root-toggle ()
    "Toggle neotree at the project root and find current file."
    (interactive)
    (if (neo-global--window-exists-p)
        (neotree-hide)
      (mxns/neotree-project-root)))

  (defun mxns/neotree-project-collapse-others ()
    "Collapse all neotree nodes and show current file."
    (interactive)
    (when (neo-global--window-exists-p)
      (save-selected-window
        (neo-global--select-window)
        (neotree-collapse-all)))
    (mxns/neotree-project-root))
  
  (defun mxns/neotree-increase-width (&optional delta)
    "Increase the neotree window width by DELTA (default 4)."
    (interactive "p")
    (let ((delta (if (= (or delta 1) 1) 4 delta)))
      (setq neo-window-width (+ neo-window-width delta))
      (when (neo-global--window-exists-p)
        (neo-global--set-window-width neo-window-width))))

  (defun mxns/neotree-reset-width ()
    "Reset the neotree window width to the default (30)."
    (interactive)
    (setq neo-window-width 30)
    (when (neo-global--window-exists-p)
      (neo-global--set-window-width neo-window-width)))

  (defun mxns/neotree-project-root-after-switch (&rest _args)
    "Open neotree at project root after switching projects."
    (when (and (project-current)
               (not current-prefix-arg))  ; skip if called with C-u
      (mxns/neotree-project-root)))
  
  (advice-add 'prosecco-switch-project :after #'mxns/neotree-project-root)
  (advice-add 'prosecco-select-project :after #'mxns/neotree-project-root)
  (advice-add 'project-switch-project :after #'mxns/neotree-project-root)
)

;;; init-neotree.el ends here
