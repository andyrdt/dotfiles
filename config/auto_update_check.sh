#!/bin/bash
# Auto-update checker - prompts for pnpm global package + Cursor CLI updates once per day
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

# Suppress zsh job control notifications ([1] PID / [1] done ...)
setopt LOCAL_OPTIONS NO_MONITOR

# Check for outdated pnpm global packages with a spinner
if command -v pnpm &> /dev/null; then
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

    if [[ -n "$OUTDATED" ]]; then
        echo ""
        echo "pnpm global package updates available:"
        echo "$OUTDATED"
        echo ""
        echo -n "Update now? (y/n): "
        read -r -k 1 response
        echo

        if [[ "$response" =~ ^[Yy]$ ]]; then
            # Check for stale NFS handles that would cause pnpm to hang
            source "$CONFIG_DIR/pnpm_nfs_check.sh"
            if check_stale_pnpm_processes; then
                # --latest ignores semver ranges so packages like @openai/codex actually update
                pnpm update -g --latest
                echo ""
                echo "Done!"
            fi
        fi
    fi
fi

# Record that we checked (even if network failed, avoids retrying every shell)
echo "$(date +%s)" > "$TIMESTAMP_FILE"

# Check for Cursor CLI updates (managed separately since it's not an npm package)
# Use the install directory as the check — "agent" is too generic a binary name
if [[ -d "$HOME/.local/share/cursor-agent" ]] && command -v agent &> /dev/null; then
    echo ""
    agent update || true
fi
echo ""
