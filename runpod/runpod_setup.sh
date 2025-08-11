#!/bin/bash
set -euo pipefail

# 0) Setup linux dependencies
su -c 'apt-get update && apt-get install -y sudo'
sudo apt-get install -y less nano htop ncdu nvtop lsof rsync btop jq curl

# 1) Setup GitHub credentials
echo "Setting up GitHub..."
read -p "Would you like to set up GitHub credentials? (y/n) " setup_github
if [[ $setup_github =~ ^[Yy]$ ]]; then
    cd "$(dirname "$0")"
    if [ -f "./setup_github.sh" ]; then
        chmod +x ./setup_github.sh
        ./setup_github.sh
    else
        echo "Error: setup_github.sh not found in $(dirname "$0") directory"
        exit 1
    fi
fi

# 2) Setup linux dependencies
echo "Installing Linux dependencies..."
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    sudo \
    less \
    nano \
    htop \
    ncdu \
    nvtop \
    lsof \
    curl \
    zsh \
    tmux

# 3) Setup Python tools
echo "Setting up Python tools..."
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.local/bin/env
uv python install 3.11
uv pip install simple-gpu-scheduler

# 3.5) Install iTerm2/Cursor shell integration for zsh (used only when in Cursor Agent)
echo "Installing iTerm2/Cursor shell integration for zsh..."
curl -fsSL -o ~/.iterm2_shell_integration.zsh https://iterm2.com/shell_integration/zsh

# 4) Setup dotfiles and ZSH
echo "Setting up dotfiles and ZSH..."
mkdir -p ~/git && cd ~/git
DOTFILES_DIR="$HOME/git/dotfiles"
if [ -d "$DOTFILES_DIR" ] && [ -n "$(ls -A "$DOTFILES_DIR" 2>/dev/null || true)" ]; then
    echo "Destination path '$DOTFILES_DIR' already exists and is not empty."
    read -p "Delete and re-clone? This will rm -rf $DOTFILES_DIR (y/n): " confirm_reclone
    if [[ $confirm_reclone =~ ^[Yy]$ ]]; then
        echo "Removing $DOTFILES_DIR..."
        rm -rf "$DOTFILES_DIR"
    else
        echo "Aborting per user choice. Remove '$DOTFILES_DIR' to continue." >&2
        exit 1
    fi
fi

git clone https://github.com/andyrdt/dotfiles.git
cd dotfiles
git fetch origin andyrdt/custom
git checkout andyrdt/custom
./install.sh --zsh --tmux
chsh -s /usr/bin/zsh
./deploy.sh # Note: This starts a new shell, ending this script
