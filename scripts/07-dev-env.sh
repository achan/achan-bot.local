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

echo "Verifying dev environment for '$BOT_USER'..."

# Check Claude Code
if command -v claude &>/dev/null; then
  echo "  claude: $(claude --version 2>/dev/null || echo 'installed')"
else
  echo "  WARNING: claude command not found. Check Homebrew cask installation."
fi

# Check key tools
for tool in git gh tmux nvim rg fd jq; do
  if command -v "$tool" &>/dev/null; then
    echo "  $tool: OK"
  else
    echo "  WARNING: $tool not found"
  fi
done

echo "Dev environment check complete."
