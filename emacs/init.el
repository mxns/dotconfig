;;; init.el --- mxns config -*- lexical-binding: t; -*-

;;; Commentary:
;;; My configuration

;;; Code:

(require 'package)
(require 'use-package)
(require 'xref)
(require 'recentf)
(require 'ansi-color)

(recentf-mode 1)

(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
;; (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'load-path (expand-file-name "local/" user-emacs-directory))

(package-initialize)
;;; (package-refresh-contents)

(when (fboundp 'tool-bar-mode) (tool-bar-mode 0))
(when (fboundp 'menu-bar-mode) (menu-bar-mode 0))

;;; Make the byte-compiler happy and get rid of warnings.
(defvar origami-mode-map)
(defvar hs-minor-mode-map)
(defvar xref-show-xrefs-function)
(defvar xref-show-definitions-function)
(defvar ns-right-option-modifier)
(defvar match-paren--idle-timer nil)
(defvar match-paren--delay 0.5)
(defvar consult-fd-args)
(defvar mxns/window-zoom-p nil "Track window zoom state.")
(defvar undo-fu-session-mode-hook-allow-list)

(setq confirm-kill-emacs 'y-or-n-p)
(setq ns-right-option-modifier 'option)
(setq ring-bell-function (lambda ()
                           (invert-face 'mode-line)
                           (run-with-timer 0.05 nil 'invert-face 'mode-line)))
(setq use-package-always-ensure t)
(setq read-file-name-completion-ignore-case t)
(setq read-buffer-completion-ignore-case t)
(setq-default indent-tabs-mode nil)
(setq suggest-key-bindings nil)
(setq delete-by-moving-to-trash t)
(setq compilation-scroll-output 'first-error)

;; (show-paren-mode 1)
;; (setq match-paren--idle-timer
;;       (run-with-idle-timer match-paren--delay t #'blink-matching-open))

;;;; per https://github.com/emacs-lsp/lsp-mode#performance
(setq read-process-output-max (* 10 1024 1024)) ;; 10mb
(setq gc-cons-threshold 200000000)
(setq garbage-collection-messages nil)

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file 'noerror 'nomessage))
;; (load (expand-file-name "init-nav" user-emacs-directory))
(use-package fixed-point
  :ensure nil
  :bind (("C-c n" . mxns/fixed-point-mode)
         ("C-v"   . mxns/fixed-point-scroll-up)
         ("M-v"   . mxns/fixed-point-scroll-down)))
(load (expand-file-name "init-neotree" user-emacs-directory))
(load (expand-file-name "init-sql-client" user-emacs-directory))
(load (expand-file-name "init-eglot" user-emacs-directory))
(xterm-mouse-mode 1)
(mouse-wheel-mode 1)

;; Decode modifyOtherKeys C-M- sequences (\e[27;7;<keycode>~) sent by Alacritty/tmux
(defun mxns/setup-terminal-keys ()
  (dolist (ch (string-to-list "abcdefghijklmnopqrstuvwxyz"))
    (define-key input-decode-map
      (format "\e[27;7;%d~" ch)
      (kbd (format "C-M-%c" ch))))
  (define-key input-decode-map "\e[27;7;32~" (kbd "C-M-SPC")))
(add-hook 'tty-setup-hook #'mxns/setup-terminal-keys)

;; macOS clipboard integration in terminal mode (works inside tmux)
(when (and (not (display-graphic-p))
           (eq system-type 'darwin))
  (defun mxns/pbcopy (text &optional _push)
    (let ((process-connection-type nil))
      (let ((proc (start-process "pbcopy" nil "pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc))))
  (defun mxns/pbpaste ()
    (let ((text (shell-command-to-string "pbpaste")))
      (unless (string= text "") text)))
  (setq interprogram-cut-function #'mxns/pbcopy)
  (setq interprogram-paste-function #'mxns/pbpaste))


(let ((aux-dir (expand-file-name "aux/" user-emacs-directory)))
  (when (>= emacs-major-version 28)
    (setq lock-file-name-transforms
          `(("\\`/.*/\\([^/]+\\)\\'" ,(concat aux-dir "\\1") t))))
  (setq auto-save-file-name-transforms
        `(("\\`/.*/\\([^/]+\\)\\'" ,(concat aux-dir "\\1") t)))
  (setq backup-directory-alist
        `((".*" . ,aux-dir))))


(add-hook 'occur-hook
          (lambda ()
            (switch-to-buffer-other-window "*Occur*")))


(defun mxns/toggle-window-zoom (&optional arg)
  "Toggle window zoom state.
With universal argument ARG, use current configuration."
  (interactive)
  (if arg
      (progn
        (window-configuration-to-register ?z)
        (delete-other-windows)
        (setq mxns/window-zoom-p t))
    (if mxns/window-zoom-p
        (condition-case err
            (progn
              (jump-to-register ?z)
              (setq mxns/window-zoom-p nil))
          (error
           (setq mxns/window-zoom-p nil)
           (message "Error while de-zooming window: %s" (error-message-string err))))
      (progn
        (window-configuration-to-register ?z)
        (delete-other-windows)
        (setq mxns/window-zoom-p t)))))

(define-advice delete-other-windows (:after (&rest _) reset-maximized)
  "Reset the window zoom state toggle."
  (setq mxns/window-zoom-p nil))

(global-set-key (kbd "C-c z") 'mxns/toggle-window-zoom)


(defun mxns/ansi-colorize-buffer ()
  "Interpret ANSI escape sequences in the current buffer."
  (interactive)
  (let ((inhibit-read-only t))
    (save-excursion
      (with-silent-modifications
        (ansi-color-apply-on-region (point-min) (point-max))))))


(defvar mxns/magit-prefix-map
  (let ((map (make-sparse-keymap)))
    (define-key map "m" 'magit-project-status)
    (define-key map "d" 'magit-diff-buffer-file)
    (define-key map "s" 'magit-file-stage)
    (define-key map "l" 'magit-log)
    map)
  "Keymap for magit commands.")

(which-key-add-keymap-based-replacements mxns/magit-prefix-map
    "m" "Status"
    "d" "Diff"
    "s" "Stage"
    "l" "Log"
    )


(defvar mxns/avy-prefix-map
  (let ((map (make-sparse-keymap)))
    (define-key map "c" 'avy-copy-line)
    (define-key map "f" 'avy-goto-word-0)
    (define-key map "g" 'avy-goto-word-1)
    (define-key map "\M-g" 'avy-goto-char-timer)
    (define-key map "l" 'avy-goto-line)
    (define-key map "\M-l" 'goto-line)
    (define-key map "r" 'avy-resume)
    map)
  "Keymap for avy commands.")


(defvar mxns/project-prefix-map
  (let ((map (make-sparse-keymap)))
    (define-key map "D" 'project-dired)
    (define-key map "c" 'mxns/tree-compile)
    (define-key map "d" 'project-find-dir)
    (define-key map "f" 'consult-find)
    (define-key map "g" 'consult-ripgrep)
    (define-key map "o" 'project-find-file)
    (define-key map "p" 'prosecco-switch-project)
    (define-key map "q" 'prosecco-kill-project)
    (define-key map "r" 'project-query-replace-regexp)
    (define-key map "s" 'prosecco-save-project)
    (define-key map "\C-b" 'project-list-buffers)
    (define-key map "\C-p" 'prosecco-select-project)
    map)
  "Keymap for project commands.")

(which-key-add-keymap-based-replacements mxns/project-prefix-map
    "D" "Open in Dired"
    "c" "Compile"
    "d" "Find directory"
    "f" "Fd"
    "g" "Rg"
    "o" "Open file"
    "p" "Switch project"
    "q" "Kill project"
    "r" "Query replace regexp"
    "s" "Save project"
    "C-b" "List buffers"
    "C-p" "Select project"
    )


;; Mark variable as safe when it's a list of strings
(put 'mxns/tree-compile-commands 'safe-local-variable
     (lambda (val)
       (and (listp val)
            (seq-every-p #'stringp val))))

(defun mxns/tree-compile ()
  "Choose and run a compile command for current project."
  (interactive)
  (if (boundp 'mxns/tree-compile-commands)
      (let ((cmd (completing-read
                  "Compile command: "
                  mxns/tree-compile-commands
                  nil nil nil nil
                  (car mxns/tree-compile-commands))))
        (compile cmd))
    (call-interactively 'compile)))  ; Fallback to normal compile


;; (use-package ranger)


(use-package avy
  :config
  (avy-setup-default)
  :bind-keymap
  ("M-g" . mxns/avy-prefix-map)
)


;; (use-package transpose-frame
;;   :ensure t
;;   :bind ("C-x 4 t" . transpose-frame))


(use-package delight
  :ensure t
  :config
  (delight '((eldoc-mode nil "eldoc")
             (mxns/nav-mode nil "nav"))))


(use-package xref
  :bind (("C-c <left>"  . xref-go-back)
         ("C-c <right>" . xref-go-forward)
         ("C-c b"  . xref-go-back)
         ("C-c f" . xref-go-forward)))


(use-package display-line-numbers
  :hook
  (nxml-mode . display-line-numbers-mode)
  (prog-mode . display-line-numbers-mode))


;; vundo and undo-tree are mutally exclusive
(use-package vundo
  :bind
  ("C-c u" . vundo))

(use-package undo-fu-session
  :ensure t
  :functions
  global-undo-fu-session-mode
  :config
  ;; Store undo session files in ~/.emacs.d/aux
  (setq undo-fu-session-directory (expand-file-name "aux" user-emacs-directory))
  
  ;; Exclude sensitive files
  (setq undo-fu-session-incompatible-files
        (list (concat "^" (expand-file-name "~/.secrets/"))))
  
  ;; Only enable for specific major modes
  (setq undo-fu-session-mode-hook-allow-list
        '(text-mode-hook
          prog-mode-hook
          conf-mode-hook))
  
  ;; Enable global mode
  (undo-fu-session-global-mode 1))

;; vundo and undo-tree are mutally exclusive
;; (use-package undo-tree
;;   :hook
;;   (prog-mode . undo-tree-mode)
;;   (conf-space-mode . undo-tree-mode)
;;   (yaml-mode . undo-tree-mode)
;;   (nxml-mode . undo-tree-mode)
;;   :bind
;;   ("C-c u" . undo-tree-visualize)
;;   :config
;;   (setq undo-tree-enable-undo-in-region t
;;         undo-tree-auto-save-history t
;;         undo-tree-history-directory-alist '((".*" . "~/.emacs.d/aux/"))
;;         undo-tree-visualizer-timestamps t
;;         undo-tree-visualizer-diff t)
;;   (make-directory "~/.emacs.d/aux/" t))


(use-package goggles
  :delight
  :hook ((prog-mode text-mode conf-mode) . goggles-mode)
  :config
  (setq-default goggles-pulse t)) ;; set to nil to disable pulsing


;; (use-package conf-space-mode
;;   :ensure nil)


(use-package vertico
  :custom
  (vertico-scroll-margin 0) ;; Different scroll margin
  (vertico-count 20) ;; Show more candidates
  ;; (vertico-resize t) ;; Grow and shrink the Vertico minibuffer
  (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :config
  (vertico-mode))


(use-package orderless
  :config
  (setq completion-styles '(orderless)))


(use-package savehist
  :config (savehist-mode))


(use-package rg
  :ensure-system-package rg
  :hook
  (grep-mode . (lambda () (toggle-truncate-lines 1))))


;; https://protesilaos.com/emacs/dotemacs#h:61863da4-8739-42ae-a30f-6e9d686e1995
(use-package embark
  :bind (("C-." . embark-act)
         :map minibuffer-local-map
         ("C-e C-c" . embark-collect)
         ("C-e C-e" . embark-export)))


(use-package embark-consult
  :ensure t)


(use-package consult
  :ensure-system-package fd
  :bind
  (("C-c r" . consult-buffer)
   ("C-<tab>" . consult-buffer)
   :map vertico-map
   ("C-<tab>". vertico-next))
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  (require 'consult-xref)
  :hook
  (completion-list-mode . consult-preview-at-point-mode))


(use-package marginalia
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle))
  ;; The :init section is always executed.
  :init
  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode))


(use-package which-key
  :delight
  :config
  (which-key-mode 1)
  )


(use-package company
  :delight
  :bind (("M-TAB" . company-complete))
  :init
  (global-company-mode))


;; https://protesilaos.com/emacs/dotemacs#h:9a3581df-ab18-4266-815e-2edd7f7e4852
(use-package wgrep
  :ensure t
  :bind ( :map grep-mode-map
          ("e" . wgrep-change-to-wgrep-mode)
          ("C-x C-q" . wgrep-change-to-wgrep-mode)
          ("C-c C-c" . wgrep-finish-edit)))


(use-package vimish-fold
  :ensure t
  :config
  (vimish-fold-global-mode 1)
  :bind (("C-c v f" . vimish-fold)
         ("C-c v u" . vimish-fold-unfold)
         ("C-c v t" . vimish-fold-toggle)
         ("C-c v d" . vimish-fold-delete)
         ("C-c v D" . vimish-fold-delete-all)))


;; (use-package project
;;   :ensure nil
;;   :bind-keymap
;;   ("C-c p" . mxns/project-prefix-map)
;;   :custom
;;   ;; Use our custom switch function that opens recent buffers/files
;;   (project-switch-commands 'prosecco-switch-project))


(use-package prosecco
  :load-path "~/devel/mxns/prosecco/"
  :demand t
  :bind-keymap
  ("C-x p" . mxns/project-prefix-map)
  ("C-c p" . mxns/project-prefix-map)
  :config
  (keymap-set prosecco-mode-map "C-x p" mxns/project-prefix-map)
  (prosecco-mode 1))


(use-package magit
  :bind-keymap
  ("C-c m" . mxns/magit-prefix-map))


(use-package yasnippet
  :delight yas-minor-mode
  :config
  (yas-global-mode))


(use-package terraform-mode
  :mode
  "\\.tf\\'")


(use-package treesit-auto
  :functions
  treesit-auto-add-to-auto-mode-alist
  global-treesit-auto-mode
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  ;; treesit-auto has a bug where some recipes (e.g. PHP) have a nil regexp,
  ;; which causes "wrong-type-argument stringp nil" for every file opened.
  (setq auto-mode-alist (seq-remove (lambda (x) (null (car x))) auto-mode-alist))
  (global-treesit-auto-mode))


(use-package yaml-mode
  :mode
  "\\.yml\\'"
  "\\.yaml\\'")


(use-package nxml-mode
  :delight
  :ensure nil
  :init
  (setq nxml-child-indent 4))


;; (use-package bash-ts-mode
;;   :ensure nil
;;   :mode
;;   "\\.sh\\'")

;; (use-package json-ts-mode
;;   :mode
;;   "\\.json\\'"
;;   :hook
;;   (json-ts-mode . hs-minor-mode)
;;   (json-ts-mode . electric-pair-mode))


(use-package typescript-ts-mode
  :delight
  :hook (typescript-ts-mode . electric-pair-mode))


(use-package java-ts-mode
  :delight
  :ensure nil
  :mode "\\.java\\'"
  :hook (java-ts-mode . electric-pair-mode))


(use-package apheleia
  :delight
  :ensure apheleia
  :delight
  :defines
  apheleia-formatters
  apheleia-mode-alist
  :functions
  apheleia-global-mode
  :config

  ;; Add commands to apheleia formatters
  (setf (alist-get 'prettier-js apheleia-formatters)
        '("prettier" "--stdin-filepath" filepath))
  (setf (alist-get 'prettier-java apheleia-formatters)
        '("prettier" "--plugin" "/opt/homebrew/lib/node_modules/prettier-plugin-java/dist/index.js" "--stdin-filepath" filepath))

  ;; Map modes to formatters
  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) 'prettier-js
        (alist-get 'tsx-ts-mode        apheleia-mode-alist) 'prettier-js)
  (setf (alist-get 'js-ts-mode         apheleia-mode-alist) 'prettier-js)
  (setf (alist-get 'json-ts-mode       apheleia-mode-alist) 'prettier-js)
  (setf (alist-get 'java-ts-mode       apheleia-mode-alist) 'prettier-java)

  ;; Format on save is annoying, use apheleia-format-buffer manually instead
  (apheleia-global-mode -1))


(use-package ess
  :mode (("\\.R\\'" . R-mode))
  :commands R)

;;; init.el ends here
(put 'dired-find-alternate-file 'disabled nil)
(put 'scroll-left 'disabled nil)
