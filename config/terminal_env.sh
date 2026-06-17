#!/bin/sh
# Shared terminal compatibility for shells that may start before zsh.

fix_unknown_terminfo() {
    [ -n "${TERM:-}" ] || return 0

    if ! command -v infocmp >/dev/null 2>&1; then
        export TERM=xterm-256color
        return 0
    fi

    infocmp "$TERM" >/dev/null 2>&1 && return 0
    infocmp xterm-256color >/dev/null 2>&1 && export TERM=xterm-256color
}

fix_unknown_terminfo
unset -f fix_unknown_terminfo 2>/dev/null || true
