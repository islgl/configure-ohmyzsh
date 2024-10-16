#!/bin/zsh

set -e

# Check if necessary commands exist
command -v git >/dev/null 2>&1 || { echo >&2 "git is not installed. Please install git first."; exit 1; }

# Install plugins
install_plugin() {
  local repo_url=$1
  local target_dir=$2

  if [ ! -d "$target_dir" ]; then
    git clone "$repo_url" "$target_dir" || { echo "Failed to clone $repo_url"; exit 1; }
  else
    echo "Plugin directory $target_dir already exists, skipping clone"
  fi
}

install_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

# Define .zshrc file path
zshrc_file="$HOME/.zshrc"

# Backup .zshrc file
if [ -f "$zshrc_file" ]; then
  cp "$zshrc_file" "$zshrc_file.bak" || { echo "Failed to backup $zshrc_file"; exit 1; }
else
  echo "$zshrc_file does not exist, creating a new one"
  touch "$zshrc_file"
fi

# Check and update plugins section
if grep -q "plugins=(" "$zshrc_file"; then
  echo "Found plugins section, updating plugin list..."
  sed -i '/plugins=(/,/)/c\plugins=(\n\tgit\n\tzsh-autosuggestions\n\tzsh-syntax-highlighting\n)' "$zshrc_file" || { echo "Failed to update plugin list"; exit 1; }
else
  echo "Plugins section not found, adding plugin list..."
  echo -e "\nplugins=(\n\tgit\n\tzsh-autosuggestions\n\tzsh-syntax-highlighting\n)" >> "$zshrc_file" || { echo "Failed to add plugin list"; exit 1; }
fi

echo "Plugin update completed"

# Install powerline fonts
if [ ! -d "fonts" ]; then
  git clone https://github.com/powerline/fonts.git --depth=1 || { echo "Failed to clone powerline/fonts"; exit 1; }
fi
./fonts/install.sh || { echo "Failed to install powerline fonts"; exit 1; }
rm -rf fonts

# Update ZSH_THEME
if grep -q "^ZSH_THEME=" "$zshrc_file"; then
  echo "Found ZSH_THEME line, updating theme to agnoster..."
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$zshrc_file" || { echo "Failed to update ZSH_THEME"; exit 1; }
else
  echo "ZSH_THEME line not found, adding theme setting..."
  echo 'ZSH_THEME="agnoster"' >> "$zshrc_file" || { echo "Failed to add ZSH_THEME"; exit 1; }
fi

echo "Theme update completed"

# Define agnoster theme file path
theme_file="$HOME/.oh-my-zsh/themes/agnoster.zsh-theme"

# Backup agnoster theme file
if [ -f "$theme_file" ]; then
  cp "$theme_file" "$theme_file.bak" || { echo "Failed to backup $theme_file"; exit 1; }
else
  echo "$theme_file does not exist, skipping backup"
fi

# New prompt_context function content
new_prompt_context='prompt_context() {
  if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)%n🧸"
  fi
}'

# Update prompt_context function using awk
awk -v new_func="$new_prompt_context" '
BEGIN { found = 0 }
/prompt_context\(\)/ { found = 1; print new_func; next }
found && /^\}/ { found = 0; next }
!found { print }
' "$theme_file" > "${theme_file}.tmp" && mv "${theme_file}.tmp" "$theme_file" || { echo "Failed to update $theme_file"; exit 1; }

echo "prompt_context update completed"
echo "Script execution completed, please manually run source ~/.zshrc to apply the configuration"
