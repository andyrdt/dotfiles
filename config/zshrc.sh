#!/bin/zsh
# ZSH configuration - makes terminal look nice and adds useful features

# Get the directory where this config file lives
CONFIG_DIR=$(dirname $(realpath ${(%):-%x}))

# Setup oh-my-zsh framework with powerlevel10k theme
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"  # The theme that makes terminal look nice
ZSH_DISABLE_COMPFIX=true  # Don't warn about insecure completion directories

# Enable git plugin - adds tab completion for git commands/branches
plugins=(git)

# Load oh-my-zsh framework
source $ZSH/oh-my-zsh.sh

# Load powerlevel10k theme config (has all the visual settings)
source $CONFIG_DIR/p10k.zsh

# History settings - remember commands across sessions
HISTSIZE=10000              # Remember 10,000 commands in memory
SAVEHIST=10000              # Save 10,000 commands to disk
setopt SHARE_HISTORY        # Share history across all terminal windows
setopt HIST_IGNORE_DUPS     # Don't save duplicate commands
setopt HIST_IGNORE_SPACE    # Don't save commands that start with a space

# Smart history search with arrow keys
# Type part of a command, then press up/down to cycle through matching commands
bindkey '^[[A' history-beginning-search-backward  # Up arrow
bindkey '^[[B' history-beginning-search-forward   # Down arrow

# Display a random inspirational quote on shell startup
REPO_DIR=$(dirname "$CONFIG_DIR")
if [[ -f "$REPO_DIR/start/display_quote.sh" ]]; then
    bash "$REPO_DIR/start/display_quote.sh"
fi
