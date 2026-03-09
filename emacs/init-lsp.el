;;; init-lsp.el --- mxns config -*- lexical-binding: t; -*-

;;; Commentary:
;;; My LSP configuration

;;; Code:

;;; (setenv "LSP_USE_PLISTS" "true")

(declare-function lsp-java-type-hierarchy "lsp-java" ())
(declare-function lsp-find-definition "lsp" ())
(declare-function lsp-find-references "lsp" ())
(declare-function lsp-rename "lsp" ())
(declare-function lsp-ui-sideline--run "lsp-ui" ())


(use-package flycheck
  :config
  (add-hook 'after-init-hook #'global-flycheck-mode))


;;; thanks to https://www.ovistoica.com/blog/2024-7-05-modern-emacs-typescript-web-tsx-config
(use-package lsp-mode
  :diminish "LSP"

  :ensure t

  :functions
  lsp-workspaces
  lsp-workspace-folders-remove

  :init
  (setq lsp-use-plists nil)

  :bind
  ("M-RET" . lsp-execute-code-action)
  
  :hook ((lsp-mode . lsp-diagnostics-mode)
         (lsp-mode . lsp-enable-which-key-integration)
         ((tsx-ts-mode
           typescript-ts-mode
           js-ts-mode
           json-ts-mode
           bash-ts-mode
           java-ts-mode
           python-ts-mode) . lsp-deferred))

  :custom
  (lsp-keymap-prefix "C-c l")           ; Prefix for LSP actions
  (lsp-completion-provider :capf)       ; Using CAPF as the provider
  (lsp-diagnostics-provider :flycheck)
  (lsp-session-file (locate-user-emacs-file ".lsp-session"))
  (lsp-log-io nil)                      ; IMPORTANT! Use only for debugging! Drastically affects performance
  (lsp-keep-workspace-alive nil)        ; Close LSP server if all project buffers are closed
  (lsp-idle-delay 0.5)                  ; Debounce timer for `after-change-function'
  ;; core
  (lsp-enable-xref t)                   ; Use xref to find references
  (lsp-auto-configure t)                ; Used to decide between current active servers
  (lsp-eldoc-enable-hover t)            ; Display signature information in the echo area
  (lsp-enable-dap-auto-configure nil)     ; Debug support (causes error if X is not available)
  (lsp-enable-file-watchers nil)
  (lsp-enable-folding nil)              ; I disable folding since I use origami
  (lsp-enable-imenu t)
  (lsp-enable-indentation nil)          ; I use prettier
  (lsp-enable-links nil)                ; No need since we have `browse-url'
  (lsp-enable-on-type-formatting nil)   ; Prettier handles this
  (lsp-enable-suggest-server-download t) ; Useful prompt to download LSP providers
  (lsp-enable-symbol-highlighting t)     ; Shows usages of symbol at point in the current buffer
  (lsp-enable-text-document-color nil)   ; This is Treesitter's job

  (lsp-auto-execute-action nil)
  
  ;; completion
  (lsp-completion-enable t)
  (lsp-completion-enable-additional-text-edit t) ; Ex: auto-insert an import for a completion candidate
  (lsp-enable-snippet t)                         ; Important to provide full JSX completion
  (lsp-completion-show-kind t)                   ; Optional
  ;; headerline
  (lsp-headerline-breadcrumb-enable t)  ; Optional, I like the breadcrumbs
  (lsp-headerline-breadcrumb-enable-diagnostics nil) ; Don't make them red, too noisy
  (lsp-headerline-breadcrumb-enable-symbol-numbers nil)
  (lsp-headerline-breadcrumb-icons-enable nil)
  ;; modeline
  (lsp-modeline-code-actions-enable nil) ; Modeline should be relatively clean
  (lsp-modeline-diagnostics-enable nil)  ; Already supported through `flycheck'
  (lsp-modeline-workspace-status-enable nil) ; Modeline displays "LSP" when lsp-mode is enabled
  (lsp-signature-doc-lines 1)                ; Don't raise the echo area. It's distracting
  (lsp-eldoc-render-all nil)            ; This would be very useful if it would respect `lsp-signature-doc-lines', currently it's distracting
  ;; lens
  (lsp-lens-enable t)                 ; Optional, I don't need it
  ;; semantic
  (lsp-semantic-tokens-enable nil)      ; Related to highlighting, and we defer to treesitter
  )


(use-package lsp-treemacs
  :custom (lsp-treemacs-theme "Iconless"))


(use-package helm-lsp)


(use-package lsp-ui
  :after lsp-mode
  :hook (lsp-mode . lsp-ui-mode)
  :custom
  (lsp-ui-flycheck-list-position 'bottom)
  (lsp-ui-doc-enable nil)                ; causes error if X is not available
  (lsp-ui-sideline-show-hover t)      ; Sideline used only for diagnostics
  (lsp-ui-sideline-diagnostic-max-lines 20) ; 20 lines since typescript errors can be quite big
  (lsp-ui-sideline-show-code-actions t)
  (lsp-ui-doc-use-childframe t)              ; Show docs for symbol at point
  :bind
  (:map lsp-ui-flycheck-list-mode-map
        ("RET" . lsp-ui-flycheck-list--visit)
        ("M-RET" . lsp-ui-flycheck-list--view)
        ("n" . next-line)
        ("p" . previous-line)
        ))

;;; https://download.eclipse.org/jdtls/milestones/
(use-package lsp-java
  :init
  (setq lsp-java-jdt-download-url
        "https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/1.49.0/jdt-language-server-1.49.0-202507311558.tar.gz")
  (setq lsp-java-java-path
        "/Users/mxns/java/zulu23.32.11-ca-jdk23.0.2-macosx_aarch64/zulu-23.jdk/Contents/Home/bin/java")
  (setenv "JAVA_HOME"
          "/Users/mxns/java/zulu23.32.11-ca-jdk23.0.2-macosx_aarch64/zulu-23.jdk/Contents/Home/"))


(defcustom lsp-ui-sideline-cycle-start-state 0
  "Starting state for `lsp-ui-sideline-cycle-toggle'.
0: hover off, code-actions off
1: hover on, code-actions off
2: hover off, code-actions on
3: hover on, code-actions on"
  :type '(choice (const :tag "Both off" 0)
                 (const :tag "Hover only" 1)
                 (const :tag "Code actions only" 2)
                 (const :tag "Both on" 3))
  :group 'lsp-ui-sideline)

(defvar lsp-ui-sideline-cycle-state 3
  "Current state in the sideline cycle.
Initialized from `lsp-ui-sideline-cycle-start-state'.")

(defun lsp-ui-sideline-cycle-toggle ()
  "Cycle through LSP UI sideline display states.
State 0: hover off, code-actions off
State 1: hover on, code-actions off
State 2: hover off, code-actions on
State 3: hover on, code-actions on"
  (interactive)
  ;; Initialize state if nil
  (unless lsp-ui-sideline-cycle-state
    (setq lsp-ui-sideline-cycle-state lsp-ui-sideline-cycle-start-state))
  
  ;; Advance to next state
  (setq lsp-ui-sideline-cycle-state
        (mod (1+ lsp-ui-sideline-cycle-state) 4))
  
  ;; Apply settings based on state
  (pcase lsp-ui-sideline-cycle-state
    (0 (setq lsp-ui-sideline-show-hover nil
             lsp-ui-sideline-show-code-actions nil)
       (message "LSP UI Sideline: Both off"))
    (1 (setq lsp-ui-sideline-show-hover t
             lsp-ui-sideline-show-code-actions nil)
       (message "LSP UI Sideline: Hover only"))
    (2 (setq lsp-ui-sideline-show-hover nil
             lsp-ui-sideline-show-code-actions t)
       (message "LSP UI Sideline: Code actions only"))
    (3 (setq lsp-ui-sideline-show-hover t
             lsp-ui-sideline-show-code-actions t)
       (message "LSP UI Sideline: Both on")))
  
  ;; Refresh if lsp-ui-mode is active
  (when (bound-and-true-p lsp-ui-mode)
    (lsp-ui-sideline--run)))

(global-set-key (kbd "C-c i") 'lsp-ui-sideline-cycle-toggle)


;;; init-lsp.el ends here
