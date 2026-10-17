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

### Prefix commands

   -   `C-a M-v`: enter `copy-mode`
   -   **`C-a SPC`:** cycle through window layouts
   -   **`C-a z`:** zoom current window
   -   **`C-a o`:** go to other window
   -   **`C-a C-o`:** rotate windows
   -   **`C-a [`:** enter copy-mode (emacs keys, `Escape` to exit)
   -   **`C-a I`:** install plugins (TPM)
   -   **`C-a U`:** update plugins (TPM)

### Server  commands

``` shell
tmux kill-server
tmux ls                                    # list sessions
tmux a -t <name>                           # attach to a session
tmux new -s <name>                         # new named session
tmux kill-session -t <name>                # kill one session, not the whole server
tmux source-file ~/.config/tmux/tmux.conf  # reload config without restarting
```
