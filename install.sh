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

# Check if basic tools are installed, install if missing
echo "Checking for zsh, curl, git..."
missing_tools=()
command -v zsh &> /dev/null || missing_tools+=("zsh")
command -v curl &> /dev/null || missing_tools+=("curl")
command -v git &> /dev/null || missing_tools+=("git")

if [ ${#missing_tools[@]} -eq 0 ]; then
    echo "All required tools are already installed!"
else
    echo "Missing tools: ${missing_tools[*]}"
    echo "Attempting to install..."

    if [ "$machine" == "Linux" ]; then
        # Try with sudo, but warn if it fails
        if sudo -n true 2>/dev/null; then
            sudo apt-get update -y
            sudo apt-get install -y "${missing_tools[@]}"
        else
            echo "Warning: sudo access required to install missing tools."
            echo "Please ask your system administrator to install: ${missing_tools[*]}"
            echo "Or install them manually in your user directory."
            exit 1
        fi
    elif [ "$machine" == "Mac" ]; then
        # Install via homebrew (Mac package manager)
        brew install "${missing_tools[@]}"
    fi
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
    curl -LsSf https://claude.ai/install.sh | bash
fi

# Install uv (fast Python package installer) if not already installed
if ! command -v uv &> /dev/null; then
    echo ""
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

echo ""
echo "Done! Run ./deploy.sh next"
