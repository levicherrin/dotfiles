#!/usr/bin/env bash
# Re-applies your dotfiles configuration on any machine (Linux, WSL2, macOS).
set -euo pipefail

OS="$(uname -s)"

if [ "$OS" = "Darwin" ]; then
  darwin-rebuild switch --flake ~/.dotfiles#mac
else
  home-manager switch --flake ~/.dotfiles#linux
fi
