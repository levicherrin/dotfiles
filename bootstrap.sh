#!/usr/bin/env bash
# Takes a fresh machine (Linux, WSL2, or macOS) from nothing to a built Nix and Home Manager environment.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> [1/4] Ensuring Determinate Nix is installed..."
if command -v nix >/dev/null 2>&1; then
  echo "    Nix is already installed, skipping."
else
  echo "    Installing Determinate Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # Source nix daemon profile for the current shell session
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
fi

echo "==> [2/4] Symlinking this repository to ~/.dotfiles..."
ln -sfn "$DIR" ~/.dotfiles

echo "==> [3/4] Personalizing environment..."
REAL_USER="$(whoami)"
echo "    Target user: $REAL_USER (dynamically resolved)"

# Safely preserve any pre-existing shell symlinks before initial activation
for f in "$HOME/.bashrc" "$HOME/.bash_aliases" "$HOME/.profile"; do
  if [ -L "$f" ]; then
    echo "    Found pre-existing symlink $f, backing up to ${f}.pre-nix-backup"
    mv "$f" "${f}.pre-nix-backup"
  fi
done

echo "==> [4/4] Applying initial configuration..."
OS="$(uname -s)"

if [ "$OS" = "Darwin" ]; then
  echo "    Detected macOS (Darwin). Running nix-darwin switch..."
  NIX_BIN="$(command -v nix)"
  sudo -H USER="$REAL_USER" "$NIX_BIN" run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --impure --flake "${DIR}#mac"

  # Ensure user login shell is switched to modern Nix Bash
  NIX_BASH="/run/current-system/sw/bin/bash"
  if [ -x "$NIX_BASH" ] && [ "${SHELL:-}" != "$NIX_BASH" ]; then
    echo "    Configuring modern Bash as default login shell..."
    sudo chsh -s "$NIX_BASH" "$REAL_USER" 2>/dev/null || chsh -s "$NIX_BASH" 2>/dev/null || true
  fi
else

  echo "    Detected Linux (Debian/WSL2/Homelab). Running Home Manager switch..."
  nix run github:nix-community/home-manager -- switch -b backup --impure --flake ~/.dotfiles#linux
fi

echo ""
echo "Bootstrap complete. Run './rebuild.sh' for future configuration changes."
