<!-- Generated from readme.org by the pre-commit hook. Do not edit directly. -->


# Config

This file is the source of truth. `README.md` is generated from it by a
git pre-commit hook (see `.githooks/`) and renders the result on GitHub, so
edit `readme.org` here and never `README.md` by hand. On a fresh clone, run
`git config core.hooksPath .githooks` once to enable the hook.

To regenerate it by hand, load `.githooks/export-readme.el` and run
`M-x my/export-readme` (or `C-c C-e G`) from this buffer.


# tmux

The prefix is `C-a`. This clashes with the ubiquitous
`move-beginning-of-line`, which is idempotent and non-destructive -
just press `C-a` twice.

```shell
tmux kill-server
```


## continuum and resurrect


### Auto-save

Every 15 minutes your full environment is written to disk.


### Auto-restore

When a fresh tmux server starts (after kill-server or reboot),
continuum automatically restores the last saved state. No manual step.


### Manual control

-   **`C-a C-s`:** save now
-   **`C-a C-r`:** restore now


# emacs


## eglot


### eglot-java


#### Installing JDT LS

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


## prosecco

Manage your projects. Find all commands under `C-c p`.


## Find stuff


### consult-ripgrep

Requires `rg` to be installed. Useful parameters:

-   **`--glob=some_dir/**/*.json`:** can use multiple globs. negate with `!`
-   **`--hidden, --no-ignore, -u`:** grep in hidden/ignored files
-   use with universal argument to grep in selected subdir

Read the `rg` man pages for more info.


### consult-fd

Requires `fd` to be installed. Useful parameters:

-   **`--glob=some_dir/**/*.json`:** can use multiple globs. negate with `!`
-   **`--hidden, --no-ignore, -u`:** grep in hidden/ignored files
-   use with universal argument to find under selected subdir

Read the `fd` man pages for more info.


## Useful tricks

-   **`consult-theme`:** switch theme
-   **`consult-buffer`:** recent files and buffers
-   `yank-from-kill-ring` while in minibuffer
    1.  Type `C-y` to yank the most recent kill (paste).
    2.  Press `M-y` (Alt + y) to cycle through the kill ring.
-   **`dired-jump`:** open dired buffer corresponding to current buffer
-   **`embark-act`:** use while in minibuffer with `C-.`


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

