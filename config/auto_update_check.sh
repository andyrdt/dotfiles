#!/bin/bash
# Auto-update checker - prompts for pnpm global package updates once per day
# Sourced by zshrc.sh on shell startup

# Only run in interactive shells
[[ $- != *i* ]] && return 0

# Only check once per day
TIMESTAMP_FILE="$HOME/.cache/dotfiles_update_check"
mkdir -p "$HOME/.cache"
if [[ -f "$TIMESTAMP_FILE" ]]; then
    LAST_CHECK=$(cat "$TIMESTAMP_FILE")
    if (( $(date +%s) - LAST_CHECK < 86400 )); then
        return 0
    fi
fi

# Skip if pnpm isn't installed
command -v pnpm &> /dev/null || return 0

# Check for outdated global packages
# pnpm outdated exits 1 when updates exist, 0 when up to date
OUTDATED=$(pnpm outdated -g 2>/dev/null) || true

# Record that we checked (even if network failed, avoids retrying every shell)
echo "$(date +%s)" > "$TIMESTAMP_FILE"

# If no output, everything is up to date
[[ -z "$OUTDATED" ]] && return 0

echo ""
echo "pnpm global package updates available:"
echo "$OUTDATED"
echo ""
echo -n "Update now? (y/n): "
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    pnpm update -g
    echo ""
    echo "Done!"
fi
echo ""
