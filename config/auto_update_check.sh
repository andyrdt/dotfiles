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

# Check for outdated global packages with a spinner
# pnpm outdated exits 1 when updates exist, 0 when up to date
_UPDATE_TMPFILE=$(mktemp)
pnpm outdated -g > "$_UPDATE_TMPFILE" 2>/dev/null &
_UPDATE_PID=$!

_UPDATE_FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
_UPDATE_I=0
while kill -0 $_UPDATE_PID 2>/dev/null; do
    printf "\r%s Checking for updates..." "${_UPDATE_FRAMES[$((_UPDATE_I % ${#_UPDATE_FRAMES[@]} + 1))]}"
    _UPDATE_I=$((_UPDATE_I + 1))
    sleep 0.1
done
wait $_UPDATE_PID 2>/dev/null || true
printf "\r\033[K"

OUTDATED=$(cat "$_UPDATE_TMPFILE")
rm -f "$_UPDATE_TMPFILE"
unset _UPDATE_TMPFILE _UPDATE_PID _UPDATE_FRAMES _UPDATE_I

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
