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
# This copies your CLAUDE.md file to where Claude Code looks for it
if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
    echo ""
    echo "--- Deploying Claude Code Instructions ---"
    CLAUDE_DIR="$HOME/.claude"
    mkdir -p "$CLAUDE_DIR"

    # Always install as uppercase filename expected by Claude Code
    cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    echo "Claude instructions deployed to $CLAUDE_DIR/CLAUDE.md"
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
