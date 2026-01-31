#!/bin/zsh

# PREREQUISITE: Ensure zsh and oh-my-zsh are installed before running this script!

set -e

# 1. Environment Check
command -v git >/dev/null 2>&1 || { echo >&2 "Error: git is not installed. Please install git first."; exit 1; }

# 2. Plugin Installation Function
install_plugin() {
  local repo_url=$1
  local target_dir=$2

  if [ ! -d "$target_dir" ]; then
    echo "Installing plugin: $(basename "$target_dir")..."
    git clone "$repo_url" "$target_dir" || { echo "Failed to clone repository: $repo_url"; exit 1; }
  else
    echo "Plugin directory $target_dir already exists; skipping clone."
  fi
}

# Install zsh plugins
install_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

# 3. Backup .zshrc Configuration
zshrc_file="$HOME/.zshrc"
if [ -f "$zshrc_file" ]; then
  cp "$zshrc_file" "$zshrc_file.bak"
  echo "Backup created: $zshrc_file.bak"
else
  echo ".zshrc does not exist; creating a new one..."
  touch "$zshrc_file"
fi

# 4. Update Plugins List in .zshrc
NEW_PLUGINS="plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"

if grep -q "plugins=(" "$zshrc_file"; then
  echo "Updating plugins section in .zshrc..."
  perl -i -0777 -pe "s/plugins=\(.*?(\n\s*)*?\)/$NEW_PLUGINS/gs" "$zshrc_file"
else
  echo "Plugins section not found in .zshrc; appending..."
  echo -e "\n$NEW_PLUGINS" >> "$zshrc_file"
fi

# 5. Install Meslo LG M Nerd Font
echo "Installing Meslo LG M Nerd Font..."
mkdir -p "$HOME/.fonts_temp"
cd "$HOME/.fonts_temp" || exit 1

# Download 4 styles of Meslo LG M Nerd Font (Regular/Bold/Italic/BoldItalic)
font_urls=(
  "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Regular/MesloLGMNerdFont-Regular.ttf"
  "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Bold/MesloLGMNerdFont-Bold.ttf"
  "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Italic/MesloLGMNerdFont-Italic.ttf"
  "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Bold-Italic/MesloLGMNerdFont-BoldItalic.ttf"
)

for url in "${font_urls[@]}"; do
  font_name=$(basename "$url")
  if [ ! -f "$font_name" ]; then
    curl -fL "$url" -o "$font_name" || { echo "Failed to download font: $font_name"; exit 1; }
  else
    echo "Font $font_name already exists; skipping download."
  fi
done

# Register fonts with macOS Font Book
echo "Opening fonts in Font Book (click 'Install' when prompted)..."
for font in *.ttf; do
  open -a "Font Book" "$font" 2>/dev/null || { echo "Failed to open $font in Font Book"; }
done

# Refresh font cache (optional for macOS; terminal restart may still be needed)
fc-cache -fv 2>/dev/null || true
cd - || exit 1
rm -rf "$HOME/.fonts_temp"  # Clean up temporary directory
echo "Meslo LG M Nerd Font installed successfully."

# 6. Update ZSH_THEME to Agnoster
if grep -q "^ZSH_THEME=" "$zshrc_file"; then
  echo "Updating ZSH_THEME to 'agnoster' in .zshrc..."
  perl -i -pe 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$zshrc_file"
else
  echo "ZSH_THEME not found in .zshrc; adding setting..."
  echo 'ZSH_THEME="agnoster"' >> "$zshrc_file"
fi

# 7. Patch Agnoster Theme's prompt_context
theme_file="$HOME/.oh-my-zsh/themes/agnoster.zsh-theme"

if [ -f "$theme_file" ]; then
  cp "$theme_file" "${theme_file}.bak"
  echo "Backed up theme file: ${theme_file}.bak"
else
  echo "Error: Theme file $theme_file not found. Skipping theme modification."
  exit 0
fi

echo "Patching prompt_context in agnoster.zsh-theme..."

# Define the modified prompt_context function
new_prompt_context=$(cat <<'EOF'
prompt_context() {
  if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)%n🧸"
  fi
}
EOF
)

# Export function for awk (avoids newline errors on macOS)
export AGNOSTER_PATCH="$new_prompt_context"

awk '
BEGIN { 
    found = 0 
    new_func = ENVIRON["AGNOSTER_PATCH"]
}
/prompt_context\(\)/ { found = 1; print new_func; next }
found && /^\}/ { found = 0; next }
!found { print }
' "$theme_file" > "${theme_file}.tmp" && mv "${theme_file}.tmp" "$theme_file" || { echo "Failed to update theme file"; exit 1; }

# 8. Final Completion Message
echo "--------------------------------------------------"
echo "✅ Setup completed successfully!"
echo "💡 Next steps:"
echo "  1. Open Mac Terminal > Preferences > Profiles > Text"
echo "  2. Change the font to 'Meslo LG M Nerd Font'"
echo "  3. Run 'source ~/.zshrc' to apply all changes."
