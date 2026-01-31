#!/bin/zsh

# Ensure zsh and oh-my-zsh are installed before running this script!

set -e

# 1. Environment Check
command -v git >/dev/null 2>&1 || { echo >&2 "Error: git is not installed. Please install git first."; exit 1; }

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

# 3. Configuration Backup
zshrc_file="$HOME/.zshrc"
if [ -f "$zshrc_file" ]; then
  cp "$zshrc_file" "$zshrc_file.bak"
  echo "Backup created: .zshrc.bak"
else
  echo ".zshrc does not exist, creating a new one..."
  touch "$zshrc_file"
fi

# 4. Update Plugins List
# Using a temp variable to hold the new block to avoid quoting hell
NEW_PLUGINS=$(cat <<EOF
plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
)
EOF
)

if grep -q "plugins=(" "$zshrc_file"; then
  echo "Updating plugins section in .zshrc..."
  # Perl handles the multi-line replacement reliably on both macOS and Linux
  perl -i -0777 -pe "s/plugins=\(.*?\)/$NEW_PLUGINS/gs" "$zshrc_file"
else
  echo "Plugins section not found, appending to file..."
  echo -e "\n$NEW_PLUGINS" >> "$zshrc_file"
fi

# 5. Install Powerline Fonts
if [ ! -d "fonts" ]; then
  echo "Cloning Powerline fonts..."
  git clone https://github.com/powerline/fonts.git --depth=1 || { echo "Failed to clone fonts"; exit 1; }
fi
./fonts/install.sh || { echo "Failed to install fonts"; exit 1; }
rm -rf fonts

# 6. Update ZSH_THEME
if grep -q "^ZSH_THEME=" "$zshrc_file"; then
  echo "Updating theme to 'agnoster'..."
  perl -i -pe 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$zshrc_file"
else
  echo "Adding ZSH_THEME setting..."
  echo 'ZSH_THEME="agnoster"' >> "$zshrc_file"
fi
