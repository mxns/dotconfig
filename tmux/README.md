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
