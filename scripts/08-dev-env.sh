#!/bin/bash
set -euo pipefail

# Source .env if vars aren't already exported (e.g. when running standalone)
if [ -z "${BOT_USER:-}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  ENV_FILE="${SCRIPT_DIR}/../.env"
  if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env not found. Copy .env.example to .env and edit it."
    exit 1
  fi
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${BOT_USER:?BOT_USER not set — source .env}"

# Ensure brew is on PATH
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

BOT_HOME=$(eval echo "~${BOT_USER}")

echo "Verifying dev environment for '$BOT_USER'..."

# Check Claude Code
if command -v claude &>/dev/null; then
  echo "  claude: $(claude --version 2>/dev/null || echo 'installed')"
else
  echo "  WARNING: claude command not found. Check Homebrew cask installation."
fi

# Check key tools
for tool in git gh tmux nvim rg fd jq rbenv; do
  if command -v "$tool" &>/dev/null; then
    echo "  $tool: OK"
  else
    echo "  WARNING: $tool not found"
  fi
done

# Check rbenv Ruby for bot user
RUBY_VERSION=$(sudo -u "$BOT_USER" -H bash -c "export PATH=\"$(brew --prefix)/bin:\$PATH\" && rbenv version-name 2>/dev/null" || true)
if [ -n "$RUBY_VERSION" ] && [ "$RUBY_VERSION" != "system" ]; then
  echo "  ruby (rbenv): $RUBY_VERSION"
else
  echo "  WARNING: No rbenv Ruby installed for $BOT_USER"
fi

# Check dotfiles (stowed from dotfiles submodule)
echo ""
echo "Checking dotfiles..."

DOTFILE_WARNINGS=0

check_dotfile() {
  local file="$1"
  local label="${2:-$file}"
  if [ -e "${BOT_HOME}/${file}" ]; then
    echo "  $label: OK"
  else
    echo "  WARNING: $label not found"
    DOTFILE_WARNINGS=$((DOTFILE_WARNINGS + 1))
  fi
}

# zsh
check_dotfile ".zshenv" "zsh: .zshenv"
check_dotfile ".zshrc" "zsh: .zshrc"

# git
check_dotfile ".gitconfig" "git: .gitconfig"
check_dotfile ".config/git/ignore" "git: .config/git/ignore"

# nvim
check_dotfile ".config/nvim/init.lua" "nvim: init.lua"
check_dotfile ".config/nvim/lua/plugins.lua" "nvim: plugins.lua"
check_dotfile ".config/nvim/lua/keybindings.lua" "nvim: keybindings.lua"

# tmux
check_dotfile ".tmux.conf" "tmux: .tmux.conf"

# claude
check_dotfile ".claude/settings.json" "claude: settings.json"
check_dotfile ".claude/CLAUDE.md" "claude: CLAUDE.md"

if [ "$DOTFILE_WARNINGS" -gt 0 ]; then
  echo "  $DOTFILE_WARNINGS dotfile(s) missing — run dotfiles/install.sh to stow"
fi

echo ""
echo "Dev environment check complete."
