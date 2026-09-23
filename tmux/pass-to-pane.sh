#!/usr/bin/env bash
# Pick a pass(1) entry in a tmux popup and paste it straight into the pane that
# opened the popup -- no clipboard, no extra shell to close. Bound to <prefix> P.
#
# Usage: pass-to-pane.sh [pane-id]   (defaults to @pass-target)

set -u

# The binding stashes the invoking pane in @pass-target, because display-popup
# does NOT expand #{pane_id} in its command string. Fall back to the client's
# current pane if the option is missing.
pane="${1:-}"
[ -n "$pane" ] || pane=$(tmux show -gv @pass-target 2>/dev/null)
[ -n "$pane" ] || pane=$(tmux display-message -p '#{pane_id}' 2>/dev/null)

store="${PASSWORD_STORE_DIR:-$HOME/.password-store}"

# pinentry needs to know which tty to draw on; the popup's tty is not the one
# the outer shell exported.
GPG_TTY=$(tty); export GPG_TTY

# Remember the last entry used, so it can be reinserted with one keystroke
# (C-p in fzf, "!" in the fallback picker) instead of searching again.
cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-pass-last"
mkdir -p "$(dirname "$cache_file")" 2>/dev/null
last_entry=""
[ -r "$cache_file" ] && last_entry=$(cat "$cache_file" 2>/dev/null)

die() {
    printf '%s\n' "$*" >&2
    printf 'press enter to close ' >&2
    read -r _
    exit 1
}

entries() {
    find "$store" -type f -name '*.gpg' \
        | sed -e "s|^$store/||" -e 's|\.gpg$||' \
        | LC_ALL=C sort
}

pick() {
    printf '\033[1mpass\033[0m -> \033[1m%s\033[0m\n\n' "$target" >&2

    if command -v fzf >/dev/null 2>&1; then
        header="Enter inserts the password at the prompt in $target"
        list() {
            # Pin the last-used entry to the top so C-p (clear-query+first)
            # always lands on it, even if it's also further down the list.
            [ -n "$last_entry" ] && printf '%s\n' "$last_entry"
            entries
        }
        if [ -n "$last_entry" ]; then
            header="$header
C-p inserts the last used entry: $last_entry"
            list | fzf --reverse --height=100% --prompt='pass> ' \
                --header="$header" \
                --bind 'ctrl-p:clear-query+first+accept'
        else
            list | fzf --reverse --height=100% --prompt='pass> ' --header="$header"
        fi
        return
    fi

    # No fzf: substring filter, then pick by number. An empty filter (just
    # pressing RET) reuses the last entry instead of listing everything, as
    # long as there is one; "!" at the number prompt goes back to filtering
    # instead of having to cancel and reopen the popup.
    while true; do
        if [ -n "$last_entry" ]; then
            printf 'pass filter (RET for last used: %s)> ' "$last_entry" >&2
        else
            printf 'pass filter> ' >&2
        fi
        read -r query || return 1
        if [ -z "$query" ] && [ -n "$last_entry" ]; then
            printf '%s\n' "$last_entry"
            return
        fi

        matches=$(entries | grep -i -- "${query:-.}")
        if [ -z "$matches" ]; then
            printf 'no entry matching '"'"'%s'"'"'\n\n' "$query" >&2
            continue
        fi

        printf '%s\n' "$matches" | nl -w3 -s'  ' >&2
        printf '\nSelecting a number and pressing Enter inserts that password at the\n' >&2
        printf 'prompt in %s. \033[2mIt is typed straight into the pane,\n' "$target" >&2
        printf 'so nothing will echo -- press Enter there to submit.\033[0m\n' >&2
        printf '\033[2m! goes back to the filter prompt.\033[0m\n\n' >&2
        printf 'number> ' >&2
        read -r n || return 1
        [ "$n" = "!" ] && { printf '\n' >&2; continue; }

        sel=$(printf '%s\n' "$matches" | sed -n "${n}p")
        if [ -z "$sel" ]; then
            printf 'invalid selection\n\n' >&2
            continue
        fi
        printf '%s\n' "$sel"
        return
    done
}

tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qx -- "$pane" \
    || die "target pane '${pane:-<none>}' does not exist"

# Human-readable name for the pane we are typing into, e.g. "MXNS:2.1 (ssh)".
target=$(tmux display-message -p -t "$pane" \
    '#{session_name}:#{window_index}.#{pane_index} (#{pane_current_command})' 2>/dev/null)
[ -n "$target" ] || target="$pane"

entry=$(pick) || exit 0
[ -n "$entry" ] || exit 0

pw=$(pass show "$entry" | head -n 1)
[ -n "$pw" ] || die "no password for '$entry' (cancelled, or decrypt failed)"

printf '%s' "$entry" > "$cache_file" 2>/dev/null && chmod 600 "$cache_file" 2>/dev/null

# Keep the secret off every command line: hand it to tmux over stdin, paste it
# into the calling pane, and delete the buffer in the same command. No trailing
# newline, so you still press Enter yourself.
printf '%s' "$pw" | tmux load-buffer -b pass-tmp - \
    || die "could not hand the password to tmux"
if ! tmux paste-buffer -d -b pass-tmp -t "$pane"; then
    tmux delete-buffer -b pass-tmp 2>/dev/null
    die "could not paste into pane '$pane'"
fi
