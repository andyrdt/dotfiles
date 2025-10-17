#!/bin/bash
# GitHub configuration script - sets up git authentication
# Usage: ./setup_github.sh (or run via install.sh)

# Exit on any error, undefined variables, or pipe failures
set -euo pipefail

echo "GitHub Setup"
echo "------------"
echo ""
echo "You'll need:"
echo "1. Your GitHub email"
echo "2. Your GitHub name (display name)"
echo "3. A GitHub Personal Access Token (create at: https://github.com/settings/tokens)"
echo ""

# Prompt for GitHub credentials
read -p "Enter your GitHub email: " email
read -p "Enter your GitHub name: " name
read -p "Enter your GitHub token: " github_token

# Make sure all fields were filled in
if [ -z "$email" ] || [ -z "$name" ] || [ -z "$github_token" ]; then
    echo "Error: Email, name, and token are required"
    exit 1
fi

# Configure git with your identity
# This is used for commit author information
echo "Configuring git identity..."
git config --global user.email "$email"
git config --global user.name "$name"

# Setup GitHub token authentication
# This allows you to push/pull without entering password each time
echo "Setting up GitHub token authentication..."
git config --global credential.helper store

# Store the token in ~/.git-credentials file
# The token is stored in the format: https://oauth2:TOKEN@github.com
HOME_DIR="${HOME:-/root}"
echo "https://oauth2:${github_token}@github.com" > "${HOME_DIR}/.git-credentials"

# Make sure only you can read the credentials file (security)
chmod 600 "${HOME_DIR}/.git-credentials"

echo ""
echo "GitHub configured successfully!"
echo "You can now push/pull from GitHub repos without entering a password."
