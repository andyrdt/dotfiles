#!/bin/bash
# Deployment script - links your configurations to the right places
# Usage: ./deploy.sh
# Safe to run multiple times - just updates the links

# Exit on any error, undefined variables, or pipe failures
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "========================================="
echo "  Deploying Dotfiles"
echo "========================================="
echo ""

# Deploy zsh config
# This creates ~/.zshrc which tells zsh to load our custom config
echo "--- Configuring ZSH ---"
echo "source $SCRIPT_DIR/config/zshrc.sh" > $HOME/.zshrc
echo "ZSH config deployed to ~/.zshrc"

# Deploy tmux config
# This creates ~/.tmux.conf which tells tmux to load our custom config
echo ""
echo "--- Configuring Tmux ---"
echo "source $SCRIPT_DIR/config/tmux.conf" > $HOME/.tmux.conf
echo "Tmux config deployed to ~/.tmux.conf"

# Deploy Claude Code custom instructions
# This copies your claude.md file to where Claude Code looks for it
if [ -f "$SCRIPT_DIR/claude.md" ]; then
    echo ""
    echo "--- Deploying Claude Code Instructions ---"

    # Claude Code looks in different places on Linux vs Mac
    if [ -d "$HOME/.config/claude" ]; then
        CLAUDE_DIR="$HOME/.config/claude"
    elif [ -d "$HOME/Library/Application Support/Claude" ]; then
        CLAUDE_DIR="$HOME/Library/Application Support/Claude"
    else
        # Create the directory if it doesn't exist yet
        CLAUDE_DIR="$HOME/.config/claude"
        mkdir -p "$CLAUDE_DIR"
    fi

    # Copy claude.md to the Claude Code config directory
    cp "$SCRIPT_DIR/claude.md" "$CLAUDE_DIR/claude.md"
    echo "Claude instructions deployed to $CLAUDE_DIR/claude.md"
fi

# Change default shell to zsh
# This makes zsh start automatically when you open a new terminal
echo ""
echo "--- Setting ZSH as default shell ---"
if [ "$SHELL" != "$(which zsh)" ]; then
    # Try to change shell, but don't fail if we can't (some systems restrict this)
    chsh -s $(which zsh) 2>/dev/null || echo "Note: Could not change default shell automatically. Run: chsh -s \$(which zsh)"
else
    echo "ZSH is already your default shell"
fi

echo ""
echo "========================================="
echo "  Deployment Complete!"
echo "========================================="
echo ""
echo "Restart your terminal or run: exec zsh"
echo ""
