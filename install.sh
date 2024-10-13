#!/bin/bash

set -e

# Function: Log
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - \$1"
}

# Check if necessary commands exist
command -v curl >/dev/null 2>&1 || { log "curl is not installed. Please install curl first."; exit 1; }
command -v git >/dev/null 2>&1 || { log "git is not installed. Please install git first."; exit 1; }

# Install zsh
if ! command -v zsh >/dev/null 2>&1; then
  log "Starting zsh installation..."
  sudo apt update || { log "Failed to update package list"; exit 1; }
  sudo apt install -y zsh || { log "Failed to install zsh"; exit 1; }
  log "zsh installation completed"
else
  log "zsh is already installed, skipping installation"
fi

# Change default shell to zsh
if [ "$SHELL" != "/bin/zsh" ]; then
  log "Changing default shell to zsh..."
  chsh -s /bin/zsh || { log "Failed to change default shell"; exit 1; }
  log "Default shell changed to zsh"
else
  log "Default shell is already zsh, skipping change"
fi

# Install oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Starting oh-my-zsh installation..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || { log "Failed to install oh-my-zsh"; exit 1; }
  log "oh-my-zsh installation completed"
else
  log "oh-my-zsh is already installed, skipping installation"
fi

log "Script execution completed"
