#!/bin/bash
# Main installation script - sets up terminal and tools
# Usage: ./install.sh

# Exit on any error, undefined variables, or pipe failures
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "========================================="
echo "  Minimal Dotfiles Setup"
echo "========================================="
echo ""

# Ask if user wants to configure GitHub authentication (optional)
# This is done first so you don't have to wait for other installations
read -p "Configure GitHub? (y/n): " configure_github
if [[ "$configure_github" =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/setup_github.sh"
fi

# Detect operating system (Linux or Mac)
operating_system="$(uname -s)"
case "${operating_system}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    *)          echo "Error: Unsupported OS" && exit 1
esac

echo "OS: $machine"
echo ""

# Install basic tools needed for development
echo "Installing zsh, curl, git..."
if [ "$machine" == "Linux" ]; then
    # Update package list and install via apt (Debian/Ubuntu)
    sudo apt-get update -y
    sudo apt-get install -y zsh curl git
elif [ "$machine" == "Mac" ]; then
    # Install via homebrew (Mac package manager)
    brew install zsh curl git
fi

# Install oh-my-zsh (zsh framework) and powerlevel10k theme (makes terminal look nice)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo ""
    echo "Installing oh-my-zsh and powerlevel10k theme..."

    # Install oh-my-zsh without prompting for user input
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Install powerlevel10k theme (the visual theme for your terminal)
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi

# Install Claude Code CLI if not already installed
if ! command -v claude &> /dev/null; then
    echo ""
    echo "Installing Claude Code..."
    curl -fsSL https://raw.githubusercontent.com/anthropics/claude-code/main/install.sh | sh
fi

echo ""
echo "Done! Run ./deploy.sh next"
