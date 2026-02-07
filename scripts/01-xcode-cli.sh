#!/bin/bash
set -euo pipefail

echo "Checking Xcode Command Line Tools..."

if xcode-select -p &>/dev/null; then
  echo "Xcode CLI tools already installed."
else
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install

  # Wait for installation to complete
  echo "Waiting for Xcode CLI tools installation..."
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  echo "Xcode CLI tools installed."
fi
