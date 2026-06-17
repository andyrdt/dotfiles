#!/bin/sh
# Login-shell fallback for hosts where chsh is blocked.

CONFIG_DIR="${DOTFILES_CONFIG_DIR:-}"
if [ -z "$CONFIG_DIR" ]; then
    CONFIG_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
fi

if [ -f "$CONFIG_DIR/terminal_env.sh" ]; then
    . "$CONFIG_DIR/terminal_env.sh"
fi

if [ -t 0 ] && [ -t 1 ] && [ -z "${DOTFILES_ZSH_LOGIN_FALLBACK:-}" ] && command -v zsh >/dev/null 2>&1; then
    export DOTFILES_ZSH_LOGIN_FALLBACK=1
    export SHELL="$(command -v zsh)"
    exec zsh -l
fi
