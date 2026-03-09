;;; init-eglot.el --- mxns config -*- lexical-binding: t; -*-

;;; Commentary:
;;; My eglot configuration

;;; Code:

(use-package eglot
  :delight
  :ensure t
  :hook
  ;; Enable for your languages - adjust as needed
  ((tsx-ts-mode . eglot-ensure)
   (typescript-ts-mode . eglot-ensure)
   (js-ts-mode . eglot-ensure)
   (python-ts-mode . eglot-ensure))

  :bind-keymap ("C-c l" . mxns/eglot-prefix-map)
  
  :config
  ;; Shutdown server when last buffer is killed
  (setq eglot-autoshutdown t)
  
  ;; Sync buffer changes immediately
  (setq eglot-send-changes-idle-time 0)
  
  ;; Don't log every event (improves performance)
  (setq eglot-events-buffer-config '(:size 0 :format full))
  
  ;; Show all available completions
  (setq eglot-ignored-server-capabilities '())
  
  ;; Use custom server commands if needed
  ;; (add-to-list 'eglot-server-programs
  ;;              '(java-mode . ("jdtls")))
  )

(use-package eglot-java
  :ensure t
  :hook (java-ts-mode . eglot-java-mode))

;; Enhance completion with corfu or company
;; (use-package corfu
;;   :ensure t
;;   :init (global-corfu-mode)
;;   :config
;;   (setq corfu-auto t
;;         corfu-auto-delay 0.1
;;         corfu-auto-prefix 2))

;; Better documentation popups
(use-package eldoc-box
  :delight
  :ensure t
  :hook (eglot-managed-mode . eldoc-box-hover-at-point-mode))

;; Breadcrumb in headerline (optional but nice)
(use-package breadcrumb
  :delight
  :ensure t
  :hook (eglot-managed-mode . breadcrumb-mode))

(defvar mxns/eglot-prefix-map
  (let ((map (make-sparse-keymap)))
    (define-key map "a" 'eglot-code-actions)
    (define-key map "r" 'eglot-rename)
    (define-key map "e" 'eldoc-doc-buffer)
    (define-key map "D" 'flymake-show-project-diagnostics)
    (define-key map "d" 'flymake-show-buffer-diagnostics)
    (define-key map "f" 'consult-flymake)
    (define-key map "n" 'flymake-goto-next-error)
    (define-key map "p" 'flymake-goto-prev-error)
    map)
  "Keymap for code commands.")

(which-key-add-keymap-based-replacements mxns/eglot-prefix-map
    "a" "Code Actions"
    "r" "Rename"
    "e" "Eldoc"
    "D" "Project diagnostics"
    "d" "Buffer diagnostics"
    "f" "Consult Flymake"
    "n" "Next Error"
    "p" "Prev Error"
    )


;;; init-eglot.el ends here
