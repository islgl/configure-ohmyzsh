#!/bin/zsh

# PREREQUISITE: Ensure zsh and oh-my-zsh are installed before running this!

set -e

# 1. Environment Check
command -v git >/dev/null 2>&1 || { echo >&2 "Error: git is not installed."; exit 1; }

# 2. Plugin Installation Function
install_plugin() {
  local repo_url=$1
  local target_dir=$2

  if [ ! -d "$target_dir" ]; then
    echo "Installing plugin: $(basename "$target_dir")..."
    git clone "$repo_url" "$target_dir" || { echo "Failed to clone $repo_url"; exit 1; }
  else
    echo "Plugin directory $target_dir already exists, skipping clone."
  fi
}

install_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

# 3. Configuration Backup (.zshrc)
zshrc_file="$HOME/.zshrc"
if [ -f "$zshrc_file" ]; then
  cp "$zshrc_file" "$zshrc_file.bak"
  echo "Backup created: .zshrc.bak"
else
  echo ".zshrc does not exist, creating a new one..."
  touch "$zshrc_file"
fi

# 4. Update Plugins List
# Define the new plugins block
NEW_PLUGINS="plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"

if grep -q "plugins=(" "$zshrc_file"; then
  echo "Updating plugins section..."
  perl -i -0777 -pe "s/plugins=\(.*?(\n\s*)*?\)/$NEW_PLUGINS/gs" "$zshrc_file"
else
  echo "Plugins section not found, appending..."
  echo -e "\n$NEW_PLUGINS" >> "$zshrc_file"
fi

# 5. Install Powerline Fonts
if [ ! -d "fonts" ]; then
  echo "Cloning Powerline fonts..."
  git clone https://github.com/powerline/fonts.git --depth=1 || { echo "Failed to clone fonts"; exit 1; }
fi
./fonts/install.sh || { echo "Failed to install fonts"; exit 1; }
rm -rf fonts
echo "Font installation directory cleaned up."

# 6. Update ZSH_THEME
if grep -q "^ZSH_THEME=" "$zshrc_file"; then
  echo "Found ZSH_THEME, updating to agnoster..."
  perl -i -pe 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$zshrc_file"
else
  echo "ZSH_THEME not found, adding setting..."
  echo 'ZSH_THEME="agnoster"' >> "$zshrc_file"
fi

# 7. Modify the Agnoster Theme File
theme_file="$HOME/.oh-my-zsh/themes/agnoster.zsh-theme"

if [ -f "$theme_file" ]; then
  cp "$theme_file" "${theme_file}.bak"
  echo "Backed up theme file to ${theme_file}.bak"
else
  echo "Error: Theme file $theme_file does not exist. Skipping modification."
  exit 0
fi

echo "Patching prompt_context in agnoster theme..."

# capture the new function logic
new_prompt_context=$(cat <<'EOF'
prompt_context() {
  if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)%n🧸"
  fi
}
EOF
)

# Export the variable so awk can read it from the Environment
# This fixes the "newline in string" error on macOS
export AGNOSTER_PATCH="$new_prompt_context"

awk '
BEGIN { 
    found = 0 
    # Read variable from environment instead of -v flag
    new_func = ENVIRON["AGNOSTER_PATCH"]
}
/prompt_context\(\)/ { found = 1; print new_func; next }
found && /^\}/ { found = 0; next }
!found { print }
' "$theme_file" > "${theme_file}.tmp" && mv "${theme_file}.tmp" "$theme_file" || { echo "Failed to update theme file"; exit 1; }

# 8. Final Cleanup
if [ -d "fonts" ]; then
  rm -rf fonts
fi

echo "--------------------------------------------------"
echo "✅ Setup completed successfully!"
echo "💡 Run 'source ~/.zshrc' to apply changes."
