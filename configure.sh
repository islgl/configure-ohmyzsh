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

# 4. Update Plugins List (Cross-platform safe)
# Define the new plugins block using a variable to avoid syntax errors
NEW_PLUGINS="plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"

if grep -q "plugins=(" "$zshrc_file"; then
  echo "Updating plugins section..."
  # Use Perl to replace the plugins block (handles multi-line matching)
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

# 6. Update ZSH_THEME in .zshrc
# Using Perl here is safer than sed for macOS/Linux compatibility
if grep -q "^ZSH_THEME=" "$zshrc_file"; then
  echo "Found ZSH_THEME, updating to agnoster..."
  perl -i -pe 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$zshrc_file"
else
  echo "ZSH_THEME not found, adding setting..."
  echo 'ZSH_THEME="agnoster"' >> "$zshrc_file"
fi
echo "Theme configuration in .zshrc updated."

# 7. Modify the actual Agnoster Theme File (Your Custom Logic)
theme_file="$HOME/.oh-my-zsh/themes/agnoster.zsh-theme"

# Backup the theme file
if [ -f "$theme_file" ]; then
  cp "$theme_file" "${theme_file}.bak"
  echo "Backed up theme file to ${theme_file}.bak"
else
  echo "Error: Theme file $theme_file does not exist. Skipping modification."
  exit 0
fi

echo "Patching prompt_context in agnoster theme..."

# Define the new function using a Heredoc with single quotes 'EOF'
# This prevents the shell from trying to interpret $USERNAME or %F prematurely
new_prompt_context=$(cat <<'EOF'
prompt_context() {
  if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)%n🧸"
  fi
}
EOF
)

# Use awk to surgically replace the function in the file
# This logic works on both macOS and Linux
awk -v new_func="$new_prompt_context" '
BEGIN { found = 0 }
/prompt_context\(\)/ { found = 1; print new_func; next }
found && /^\}/ { found = 0; next }
!found { print }
' "$theme_file" > "${theme_file}.tmp" && mv "${theme_file}.tmp" "$theme_file" || { echo "Failed to update theme file"; exit 1; }

echo "--------------------------------------------------"
echo "✅ Setup completed successfully!"
echo "💡 Run 'source ~/.zshrc' to apply changes."
echo "Note: Ensure your terminal font is set to a Powerline font to see the 🧸 icon."
