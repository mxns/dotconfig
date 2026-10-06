# CONFIG

# TMUX (`C-a`)

The prefix is `C-a`. This clashes with the ubiquitous
`move-beginning-of-line`, selected for being idempotent and
non-destructive - just press `C-a` twice.

## continuum and resurrect

### Auto-save

Every 15 minutes your full environment is written to disk.

### Auto-restore

When a fresh tmux server starts (after kill-server or reboot),
continuum automatically restores the last saved state. No manual step.

### Manual control

-   **`C-a C-s`:** save now
-   **`C-a C-r`:** restore now

## Useful commands

-   **`C-a SPC`:** cycle through window layouts
-   **`C-a z`:** zoom current window
-   **`C-a o`:** go to other window
-   **`C-a C-o`:** rotate windows

```shell
tmux kill-server
```

# EMACS

## General

-   **`package-install-upgrade-built-in`:** ensures that built-in packages are upgraded
-   **`package-autoremove`:** remove orphaned dependencies
-   **`native-compile-prune-cache`:** delete stale `.eln` files from old Emacs/package versions
-   **`describe-keymap`:** list a whole keymap, e.g. `mxns/project-prefix-map`
## 
## eglot-java

### Installing JDT LS

The download URL is:

<https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/1.58.0/jdt-language-server-1.58.0-202604151538.tar.gz>

Download that tarball and extract it into `~/.config/emacs/share/eclipse.jdt.ls/`.
Or do it automatically by calling `eglot-java-install-server`.

```shell
mkdir -p ~/.config/emacs/share/eclipse.jdt.ls
curl -L "https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/1.58.0/jdt-language-server-1.58.0-202604151538.tar.gz" \
  | tar -xz -C ~/.config/emacs/share/eclipse.jdt.ls
```

Alternatively, `brew install jdtls` and eglot-java will find it via CLASSPATH or the PATH.

### Troubleshooting

#### Example

Eenabling `eglot-java-mode` in a Java buffer fails immediately with:

    [eglot] -1: Server died
    jsonrpc--process-sentinel(... "exited abnormally with code 13")

eglot-java keeps one workspace per project under
`~/.config/emacs/eglot-java-eclipse-jdt-cache/<md5>/`. If the server
was killed without a clean shutdown (Emacs quit, machine slept,
crash), it leaves a dirty resource snapshot. On the next start JDT LS
tries to restore that snapshot, hits an `ObjectNotFoundException` for
a build artifact under `target/` that no longer exists, the
`org.eclipse.core.resources` bundle fails to start, and the OSGi
framework aborts with exit code 13.

#### Read the workspace log

```shell
ls -t ~/.config/emacs/eglot-java-eclipse-jdt-cache/*/.metadata/.log | head
# look for exceptions and errors
```

#### Clear the workspace cache

The cache is a pure regenerable index, so deleting it is safe (it just
re-indexes on next start). Wipe all of it:

```shell
rm -rf ~/.config/emacs/eglot-java-eclipse-jdt-cache/*
```

Then re-open the Java file or call `M-x eglot-java-mode`.

#### Workspace configuration

Keep JDT from indexing Maven/Gradle build output, is may go
stale. Exclude those dirs via the workspace config:

```emacs-lisp
(setq-default eglot-workspace-configuration
  '(:java (:import (:exclusions ["**/node_modules/**"
                                 "**/.git/**"
                                 "**/target/**"
                                 "**/build/**"]))))
```

#### File watching

JDT-LS asks eglot to watch files, which sometimes makes the process run out of file descriptors:

`"File watching not possible, no file descriptor left"`

To fix this, the registration method has been overridden with a
no-op. This means JDT-LS won't be auto-notified of files changed
outside Emacs (e.g. git pull, mvn generate-sources) — you have to M-x
eglot-reconnect after such changes.

## prosecco

Manage your projects. Find the menu under `C-c p`.

This minor mode hijacks the standard `C-x b` keybinding to switch
between buffers: it will show only buffers that belong to the current
project, plus any buffers that do not belong to any project. Use the
universal argument to retain the standard behavior of the keybinding.

-   **`project-forget-project`:** forget projects when the list is getting too long

## org

Everything lives in `~/org/` (own git repo); captures land in `inbox.org`.

-   **`C-c c`:** capture: `t` todo, `b` bookmark (with link), `n` note, `j` journal, `r` tillträde (subtasks scheduled from one date)
-   **`C-c a`:** agenda (week view, starts Monday)
-   **`C-c o`:** `t` todo, `s` schedule, `d` deadline, `r` refile, `a` archive, `m` reminder
-   **`C-c n` / `C-c p` / `C-c u`:** next / previous / parent heading
-   **`C-c N`:** toggle narrow to subtree
-   **`C-c '`:** edit src block; `C-c C-c` runs it without confirmation (elisp, python, R, shell)

### Reminders

`C-c o m` sets a `REMIND` timestamp (defaults to SCHEDULED, must have a
time); `C-u` to remove. Works in the agenda too. Picked up by the
org-reminders Android app.

### Auto-commit

`org-save-all-org-buffers` (`s` in the agenda) commits all of `~/org/`
as one commit. Commits only, never pushes.

## Find stuff

`C-x p g` ripgrep, `C-x p f` fd. `C-c p` works too, except in org and
markdown buffers, where it's heading nav. `C-u` first to pick the
directory. `M-n` pulls in the symbol at point.

Input is `pattern -flags`: everything from the first ` -` goes to the
command, no shell quoting. Lead with `#` to add a local filter on the
results: `#defun -g *.el#hook`.

### consult-ripgrep

-   **`-g some_dir/**/*.json`:** limit to glob, repeatable; `-g !*.min.js` excludes
-   **`-t py` / `-T py`:** only / skip a file type (`rg --type-list`)
-   **`-uu`:** include ignored and hidden files (`-u` is ignored only)
-   **`-F` / `-w`:** literal string / whole words
-   smart case: all lowercase ignores case

### consult-fd

-   **`some_dir/**/*.json -g`:** input is a glob, matched against the full path
-   **`-e json`:** by extension
-   **`-t f` / `-t d`:** files / directories only
-   **`-E node_modules`:** exclude
-   **`-u`:** include ignored and hidden files

### Edit across files

`C-; e` (embark-export) the ripgrep hits into a grep buffer, `e` to
edit in place (wgrep), `C-c C-c` to apply, `C-x s` to save.

## Useful tricks

-   **`consult-theme`:** switch theme
-   **`consult-buffer`:** recent files and buffers
-   `yank-from-kill-ring` while in minibuffer
    1.  Type `C-y` to yank the most recent kill (paste).
    2.  Press `M-y` (Alt + y) to cycle through the kill ring.
-   **`dired-jump`:** open dired buffer corresponding to current buffer
-   **`embark-act`:** use while in minibuffer with `C-.`
-   **`transpose-frame`:** transpose the frame layout
-   **`M-q`:** runs `fill-paragraph`, which re-wraps the current paragraph to fit within `fill-column` (default 70, often set higher)

## Troubleshooting

### When packages starts to fail

Odd breakage after an update usually means a package and its dependencies
are on incompatible versions. The quick fix to realign them:

-   **`package-upgrade-all`:** bring everything to mutually compatible versions
-   **restart Emacs:** the running session still holds the old definitions in memory

If that doesn't help, or if you want to be more specific, here are some other things to try:

-   **`toggle-debug-on-error`:** show a backtrace so you can see which package is at fault
-   **`package-refresh-contents`:** refresh the archive listings so the latest versions are visible
-   **`package-reinstall`:** reinstall the offending package against the current dependencies
-   **`byte-recompile-directory` or `package-recompile-all`:** rebuild stale `.elc` files left over from the old version

### When a single function starts to fail

If one specific command starts erroring (especially with `wrong-number-of-arguments`
or a missing prompt), suspect advice before the function itself. List it with
`M-x describe-function` (the "This function has :around/:after advice" note), then
strip the advice and retry:

-   **`advice-mapc` + `advice-remove`:** temporarily remove all advice from the symbol and see if the error disappears
-   **if it does:** one of the advices is the culprit; re-add them one at a time to find which

A common trap: adding an **interactive** command as advice. Its interactive form can
override the original's, so the underlying function runs with the wrong arguments.
Advice functions should be plain (non-interactive) and accept `&rest` args.

