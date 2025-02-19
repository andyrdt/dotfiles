#!/bin/bash

# 0) Setup linux dependencies
su -c 'apt-get update && apt-get install -y sudo'
sudo apt-get install -y less nano htop ncdu nvtop lsof rsync btop jq

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
    zsh \
    tmux

# 3) Setup Python tools
echo "Setting up Python tools..."
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.local/bin/env
uv python install 3.11
uv pip install simple-gpu-scheduler

# 4) Setup dotfiles and ZSH
echo "Setting up dotfiles and ZSH..."
mkdir -p ~/git && cd ~/git
git clone https://github.com/andyrdt/dotfiles.git
cd dotfiles
./install.sh --zsh --tmux
chsh -s $(which zsh)
./deploy.sh # Note: This starts a new shell, ending this script
