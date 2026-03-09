;;; init-project.el --- mxns config -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

(defvar recentf-list)
(declare-function neo-global--window-exists-p "neotree")
(declare-function project-root "treemacs" (project))

(defun mxns/project-switch-project (&optional project-path)
  "Switch to the most recently used buffer in the target project.
If PROJECT-PATH is not provided, uses `project-current-directory-override'
if set (when called via `project-switch-project'), otherwise prompts.

Falls back through: recent buffer → recent file → project-switch-project."
  (interactive
   (list (unless project-current-directory-override
           (project-prompt-project-dir))))
  (setq project-path (or project-current-directory-override
                         project-path))
  (let* ((expanded-project-path (expand-file-name project-path))
         ;; Buffers in most-recently-used order
         (project-buffers (seq-filter
                           (lambda (buf)
                             (let ((file (buffer-file-name buf)))
                               (and file
                                    (string-prefix-p expanded-project-path
                                                     (expand-file-name file)))))
                           (buffer-list)))
         (most-recent-buffer (car project-buffers)))
    (cond
     (most-recent-buffer
      (switch-to-buffer most-recent-buffer)
      (message "Switched to buffer: %s" (buffer-name most-recent-buffer)))
     (t
      (let* ((recent-files-in-project
              (seq-filter
               (lambda (file)
                 (string-prefix-p expanded-project-path
                                  (expand-file-name file)))
               recentf-list))
             (most-recent-file (car recent-files-in-project)))
        
        (if most-recent-file
            (progn
              (find-file most-recent-file)
              (message "Opened recent file: %s" most-recent-file))
          ;; No recent buffers or files - fallback to finding a file
          (let ((default-directory expanded-project-path))
            (project-find-file))))))))


(defun mxns/project-kill-project (arg)
  "Kill the buffers belonging to the current project. Only the buffers that match a condition in
`project-kill-buffer-conditions' will be killed. With the prefix argument, kill the buffers belonging
to all other projects instead, using the same conditions."
  (interactive "P")
  (if arg
      (if-let ((current-proj (project-current)))
          (let* ((current-root (project-root current-proj))
                 (other-project-bufs
                  (seq-filter
                   (lambda (buf)
                     (when-let ((buf-proj (with-current-buffer buf
                                            (project-current))))
                       ;; Buffer belongs to a different project
                       (and (not (equal (project-root buf-proj) current-root))
                            ;; And it matches the kill conditions
                            (project--buffer-check buf project-kill-buffer-conditions))))
                   (buffer-list))))
            (if other-project-bufs
                (when (yes-or-no-p (format "Kill %d buffers from other projects? "
                                           (length other-project-bufs)))
                  (mapc #'kill-buffer other-project-bufs)
                  (message "Killed %d buffers from other projects" (length other-project-bufs)))
              (message "No buffers from other projects to kill")))
        (message "Not in a project"))
    (project-kill-buffers)))


(defun mxns/kill-buffer-project-aware (arg)
  "Kill buffer (with completion) and switch to most recent buffer in same project.
With prefix argument, kill all other project buffers instead.
If no project buffers remain, invoke `project-switch-project'."
  (interactive "P")
  (let* ((proj (project-current)))
    (if (not proj)
        ;; Not in a project - simple kill
        (kill-buffer (if arg
                        (current-buffer)
                      (get-buffer (read-buffer "Kill buffer: " 
                                              (current-buffer) 
                                              t))))
      ;; In a project - compute filtered buffers ONCE at the start
      (let* ((project-buffers (project-buffers proj))
             (filtered-project-buffers
              (seq-filter (lambda (buf)
                            (project--buffer-check buf project-kill-buffer-conditions))
                          project-buffers))
             (buffer-to-kill
              (if arg
                  (current-buffer)
                ;; Use the already-filtered list for completion
                (get-buffer
                 (completing-read "Kill buffer: "
                                 (mapcar #'buffer-name filtered-project-buffers)
                                 nil t nil nil
                                 (buffer-name (current-buffer)))))))

        ;; Handle the different cases
        (if arg
            ;; Prefix arg: kill all other project buffers
            (let ((other-project-buffers
                   (seq-filter (lambda (buf)
                                (not (eq buf buffer-to-kill)))
                              filtered-project-buffers)))
              (when (yes-or-no-p (format "Kill %d other project buffers? "
                                        (length other-project-buffers)))
                (mapc #'kill-buffer other-project-buffers)))

          ;; No prefix: kill buffer FIRST, then determine where to switch
          ;; This ensures cleanup hooks (like Eglot shutdown) run before we
          ;; decide which buffer to switch to
          ;; (kill-buffer buffer-to-kill)

          ;; Re-calculate remaining project buffers after kill + cleanup
          (let* ((remaining-buffers
                  (seq-filter (lambda (buf)
                                (and (project--buffer-check buf project-kill-buffer-conditions)
                                     (buffer-file-name buf)
                                     (not (eq buf buffer-to-kill))))
                              (project-buffers proj)))
                 (target-buffer (car remaining-buffers)))

            (if target-buffer
                (progn (switch-to-buffer target-buffer)
                       (kill-buffer buffer-to-kill))
              ;; No buffers left in project
              (let ((project-root (project-root proj)))
                (project-find-file)
                (kill-buffer buffer-to-kill)))))))))




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


;; Mark variable as safe when it's a list of strings
(put 'mxns/tree-compile-commands 'safe-local-variable
     (lambda (val)
       (and (listp val)
            (seq-every-p #'stringp val))))


(use-package project
  :ensure nil
  :bind-keymap
  ("C-c p" . mxns/project-prefix-map)
  :custom
  ;; Use our custom switch function that opens recent buffers/files
  (project-switch-commands 'mxns/project-switch-project))


(use-package neotree
  :ensure t
  :bind
  (("C-c t" . neotree-project-root-toggle)
   ("C-c T" . neotree-project-collapse-others))
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

  (defun neotree-project-root ()
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
  
  (defun neotree-project-root-toggle ()
    "Toggle neotree at the project root and find current file."
    (interactive)
    (if (neo-global--window-exists-p)
        (neotree-hide)
      (neotree-project-root)))

  (defun neotree-project-collapse-others ()
    "Collapse all neotree nodes and show current file."
    (interactive)
    (when (neo-global--window-exists-p)
      (save-selected-window
        (neo-global--select-window)
        (neotree-collapse-all)))
    (neotree-project-root))
  
  (defun neotree-project-root-after-switch (&rest _args)
    "Open neotree at project root after switching projects."
    (when (and (project-current)
               (not current-prefix-arg))  ; skip if called with C-u
      (neotree-project-root)))
  
  (advice-add 'mxns/project-switch-project :after #'neotree-project-root-after-switch)
)



(defun mxns/project-mode-line ()
  "Return project name for mode-line."
  (let ((project (project-current)))
    (when project
      (propertize
       (concat " ["
               (file-name-nondirectory
                (directory-file-name (project-root project)))
               "]")
       'face 'font-lock-keyword-face))))

;; Add to mode-line-misc-info
(add-to-list 'mode-line-misc-info '(:eval (mxns/project-mode-line)) t)


(defvar mxns/project-prefix-map
  (let ((map (make-sparse-keymap)))
    (define-key map "c" 'mxns/tree-compile)
    (define-key map "p" 'project-switch-project)
    (define-key map "q" 'mxns/project-kill-project)
    (define-key map "k" 'mxns/kill-buffer-project-aware)
    (define-key map "f" 'consult-fd)
    (define-key map "g" 'consult-ripgrep)
    (define-key map "r" 'project-query-replace-regexp)
    (define-key map "b" 'project-switch-to-buffer)
    (define-key map "d" 'project-find-dir)
    (define-key map "D" 'project-dired)
    (define-key map "v" 'project-vc-dir)
    (define-key map "\C-b" 'project-list-buffers)
    ;; (define-key map "F" 'project-or-external-find-file)
    ;; (define-key map "G" 'project-or-external-find-regexp)
    map)
  "Keymap for project commands.")

(which-key-add-keymap-based-replacements mxns/project-prefix-map
    "c" "Compile"
    "p" "Switch project"
    "q" "Kill project"
    "k" "Kill buffer"
    "f" "Find file (fd)"
    "g" "Grep (rg)"
    "r" "Query replace regexp"
    "b" "Switch to buffer"
    "d" "Find directory"
    "D" "Open in Dired"
    "v" "VC directory"
    "C-b" "List buffers"
    )

;;; init-project.el ends here
