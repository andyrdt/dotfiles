#!/bin/bash
# Deployment script - links your configurations to the right places
# Usage: ./deploy.sh
# Safe to run multiple times - just updates the links

# Exit on any error, undefined variables, or pipe failures
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/config/codex_config.sh"

install_managed_block() {
    local target_file="$1"
    local begin_marker="$2"
    local end_marker="$3"
    local block_content="$4"
    local tmp_file

    tmp_file="$(mktemp)"
    if [ -f "$target_file" ]; then
        awk -v begin="$begin_marker" -v end="$end_marker" '
            $0 == begin { skip = 1; next }
            $0 == end { skip = 0; next }
            !skip { print }
        ' "$target_file" > "$tmp_file"
    else
        : > "$tmp_file"
    fi

    if [ -s "$tmp_file" ] && [ "$(tail -c 1 "$tmp_file")" != "" ]; then
        printf '\n' >> "$tmp_file"
    fi
    printf '%s\n%s\n%s\n' "$begin_marker" "$block_content" "$end_marker" >> "$tmp_file"
    mv "$tmp_file" "$target_file"
}

echo "========================================="
echo "  Deploying Dotfiles"
echo "========================================="
echo ""

# Setup GitHub authentication (optional)
echo "--- GitHub Setup (Optional) ---"
read -p "Configure GitHub credentials? (y/n): " -n 1 configure_github
echo
if [[ "$configure_github" =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/setup_github.sh"
fi

# Setup HuggingFace configuration (optional)
# Check for HF CLI (might not be in PATH yet after fresh install)
HF_CLI=""
if command -v hf &> /dev/null; then
    HF_CLI="hf"
elif [ -f "$HOME/.local/bin/hf" ]; then
    HF_CLI="$HOME/.local/bin/hf"
fi

if [ -n "$HF_CLI" ]; then
    echo ""
    echo "--- HuggingFace Home Directory (Optional) ---"
    echo "By default, HuggingFace uses ~/.cache/huggingface"
    read -p "Do you want to set a custom HF_HOME directory? (y/n): " -n 1 set_hf_home
    echo
    if [[ "$set_hf_home" =~ ^[Yy]$ ]]; then
        echo "Example: /disk/u/andy/.cache/huggingface"
        read -p "Enter custom HF_HOME path: " hf_home_path
        if [ -n "$hf_home_path" ]; then
            # Create the directory if it doesn't exist
            mkdir -p "$hf_home_path" 2>/dev/null || true

            # Write HF_HOME export to machine-specific config file
            echo "export HF_HOME=\"$hf_home_path\"" > "$HOME/.hf_config.sh"
            echo "HF_HOME configured: $hf_home_path"
            echo "(Stored in ~/.hf_config.sh)"
        fi
    else
        # Remove HF config file if user doesn't want custom path
        rm -f "$HOME/.hf_config.sh" 2>/dev/null || true
    fi

    echo ""
    echo "--- HuggingFace Authentication (Optional) ---"
    read -p "Configure HuggingFace credentials? (y/n): " -n 1 configure_hf
    echo
    if [[ "$configure_hf" =~ ^[Yy]$ ]]; then
        echo ""
        echo "You'll need a token from https://huggingface.co/settings/tokens"
        "$HF_CLI" auth login
    fi
else
    echo ""
    echo "Note: HuggingFace CLI (hf) not found - skipping HuggingFace setup"
    echo "If you just ran install.sh, try restarting your shell and running deploy.sh again"
fi

echo ""
echo "========================================="
echo "  Deploying Configuration Files..."
echo "========================================="

# Deploy zsh config
echo ""
echo "--- Configuring ZSH ---"
echo "source $SCRIPT_DIR/config/zshenv.sh" > "$HOME/.zshenv"
echo "source $SCRIPT_DIR/config/zshrc.sh" > "$HOME/.zshrc"
echo "ZSH config deployed (~/.zshenv, ~/.zshrc)"

# Some managed hosts block chsh even when zsh is installed. Add a small bash
# login fallback so SSH sessions still land in the deployed zsh environment.
echo ""
echo "--- Configuring Bash login fallback ---"
BASH_PROFILE_FILE="$HOME/.bash_profile"
if [ ! -e "$BASH_PROFILE_FILE" ] && [ -f "$HOME/.profile" ]; then
    {
        echo '# Source ~/.profile first because bash ignores it when ~/.bash_profile exists.'
        echo 'if [ -f "$HOME/.profile" ]; then'
        echo '    . "$HOME/.profile"'
        echo 'fi'
        echo
    } > "$BASH_PROFILE_FILE"
fi
install_managed_block \
    "$BASH_PROFILE_FILE" \
    "# >>> dotfiles zsh login fallback >>>" \
    "# <<< dotfiles zsh login fallback <<<" \
    "export DOTFILES_CONFIG_DIR=\"$SCRIPT_DIR/config\"
if [ -f \"\$DOTFILES_CONFIG_DIR/bash_login.sh\" ]; then
    . \"\$DOTFILES_CONFIG_DIR/bash_login.sh\"
fi
unset DOTFILES_CONFIG_DIR"
echo "Bash login fallback configured (~/.bash_profile)"
unset BASH_PROFILE_FILE

# Deploy Codex config
echo ""
echo "--- Configuring Codex ---"
CODEX_CONFIG_FILE="$(ensure_codex_keymap)"
echo "Codex keymap configured ($CODEX_CONFIG_FILE)"
unset CODEX_CONFIG_FILE

# Deploy tmux config
# This creates ~/.tmux.conf which tells tmux to load our custom config
echo ""
echo "--- Configuring Tmux ---"
echo "source-file $SCRIPT_DIR/config/tmux.conf" > "$HOME/.tmux.conf"
echo "Tmux config deployed to ~/.tmux.conf"

# Change default shell to zsh
# This makes zsh start automatically when you open a new terminal
echo ""
echo "--- Setting ZSH as default shell ---"
ZSH_BIN="$(command -v zsh)"
if [ "$SHELL" != "$ZSH_BIN" ]; then
    # Try to change shell with timeout to avoid hanging
    # Some systems require password or restrict this entirely
    if timeout 5 chsh -s "$ZSH_BIN" 2>/dev/null; then
        echo "Default shell changed to zsh"
    else
        echo "Note: Could not change default shell automatically"
        echo "Bash login fallback is configured, so new SSH sessions will exec zsh."
        echo "You can also change it manually by running: chsh -s $ZSH_BIN"
    fi
else
    echo "ZSH is already your default shell"
fi
unset ZSH_BIN

echo ""
echo "========================================="
echo "  Deployment Complete!"
echo "========================================="
echo ""
echo "Restart your terminal or run: exec zsh"
echo ""

unset -f install_managed_block
