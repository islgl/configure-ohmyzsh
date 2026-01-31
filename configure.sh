#!/bin/bash

# PREREQUISITE: Ensure zsh and oh-my-zsh are installed before running this script!

set -e

echo "🚀 Starting ZSH configuration setup..."

# 0. OS Detection
OS="$(uname -s)"
echo "🖥️  Detected Operating System: $OS"

# 1. Environment Check
command -v git >/dev/null 2>&1 || { echo >&2 "Error: git is not installed. Please install git first."; exit 1; }
command -v zsh >/dev/null 2>&1 || { echo >&2 "Error: zsh is not installed."; exit 1; }

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Error: Oh My Zsh is not installed in $HOME/.oh-my-zsh"
    echo "Please install it via: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    exit 1
fi

# 2. Plugin Installation Function
install_plugin() {
  local repo_url=$1
  local target_dir=$2

  if [ ! -d "$target_dir" ]; then
    echo "⬇️  Installing plugin: $(basename "$target_dir")..."
    git clone "$repo_url" "$target_dir" || { echo "Failed to clone repository: $repo_url"; exit 1; }
  else
    echo "✅ Plugin directory $(basename "$target_dir") already exists; skipping clone."
  fi
}

# Install zsh plugins
install_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

# 3. Backup .zshrc Configuration
zshrc_file="$HOME/.zshrc"
if [ -f "$zshrc_file" ]; then
  cp "$zshrc_file" "$zshrc_file.bak"
  echo "📦 Backup created: $zshrc_file.bak"
else
  echo ".zshrc does not exist; creating a new one..."
  touch "$zshrc_file"
fi

# 4. Update Plugins List in .zshrc
# We use perl for cross-platform compatibility (sed -i behaves differently on Mac/Linux)
NEW_PLUGINS="plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"

if grep -q "plugins=(" "$zshrc_file"; then
  echo "⚙️  Updating plugins section in .zshrc..."
  # Use perl to replace multi-line plugins=(...) block
  perl -i -0777 -pe "s/plugins=\(.*?(\n\s*)*?\)/$NEW_PLUGINS/gs" "$zshrc_file"
else
  echo "⚙️  Plugins section not found in .zshrc; appending..."
  echo -e "\n$NEW_PLUGINS" >> "$zshrc_file"
fi

# 5. Install Meslo LG S Nerd Font (Cross-Platform)
echo "🅰️  Installing Meslo LG S Nerd Font..."

# Determine Font Directory based on OS
if [ "$OS" = "Darwin" ]; then
    FONT_DIR="$HOME/Library/Fonts"
else
    # Linux standard path
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
fi

font_names=(
    "MesloLGS NF Regular.ttf"
    "MesloLGS NF Bold.ttf"
    "MesloLGS NF Italic.ttf"
    "MesloLGS NF Bold Italic.ttf"
)
base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"

for font in "${font_names[@]}"; do
    # Encode URL spaces as %20
    encoded_name="${font// /%20}" 
    url="${base_url}/${encoded_name}"
    target_path="$FONT_DIR/$font"

    if [ ! -f "$target_path" ]; then
        echo "   Downloading $font..."
        curl -fL "$url" -o "$target_path" || { echo "Failed to download font: $font"; exit 1; }
    else
        echo "   Font $font already exists; skipping."
    fi
done

# Refresh font cache on Linux
if [ "$OS" != "Darwin" ]; then
    echo "🔄 Refreshing font cache (Linux)..."
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -fv "$FONT_DIR" >/dev/null
    else
        echo "⚠️  Warning: fc-cache not found. You might need to restart or install fontconfig."
    fi
fi
echo "✅ Fonts installed to $FONT_DIR"

# 6. Update ZSH_THEME to Agnoster
if grep -q "^ZSH_THEME=" "$zshrc_file"; then
  echo "🎨 Updating ZSH_THEME to 'agnoster' in .zshrc..."
  perl -i -pe 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$zshrc_file"
else
  echo "🎨 ZSH_THEME not found in .zshrc; adding setting..."
  echo 'ZSH_THEME="agnoster"' >> "$zshrc_file"
fi

# 7. Patch Agnoster Theme's prompt_context
theme_file="$HOME/.oh-my-zsh/themes/agnoster.zsh-theme"

if [ -f "$theme_file" ]; then
  # Only backup if backup doesn't exist to avoid overwriting original with patched version
  if [ ! -f "${theme_file}.bak" ]; then
      cp "$theme_file" "${theme_file}.bak"
      echo "📦 Backed up theme file: ${theme_file}.bak"
  fi
else
  echo "Error: Theme file $theme_file not found. Skipping theme modification."
  exit 0
fi

echo "🔧 Patching prompt_context in agnoster.zsh-theme..."

# Define the modified prompt_context function
# Note: Using printf to ensure clean variable content
new_prompt_context=$(cat <<'EOF'
prompt_context() {
  if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)%n🧸"
  fi
}
EOF
)

export AGNOSTER_PATCH="$new_prompt_context"

# Use awk to replace the function block
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
echo "  1. Open your Terminal Preferences/Settings."
echo "  2. Change the font to 'MesloLGS NF' (Look for this exact name)."
if [ "$OS" = "Darwin" ]; then
    echo "     (On macOS: Preferences > Profiles > Text > Change Font)"
fi
echo "  3. Run 'source ~/.zshrc' or restart your terminal to apply changes."
echo "--------------------------------------------------"
