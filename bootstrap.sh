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

echo "==> [3/4] Personalizing username..."
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ -n "$FLAKE_USER" ] && [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "    Updating flake.nix user from \"$FLAKE_USER\" to \"$REAL_USER\"..."
  sed -i.bak -E "s/^([[:space:]]*user = \")[^\"]+(\";.*)/\1${REAL_USER}\2/" "$DIR/flake.nix"
  rm -f "$DIR/flake.nix.bak"
fi

echo "==> [4/4] Applying initial configuration..."
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  echo "    Detected macOS (Darwin). Running nix-darwin switch..."
  NIX_BIN="$(command -v nix)"
  sudo "$NIX_BIN" run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake ~/.dotfiles#mac
else
  echo "    Detected Linux (Debian/WSL2/Homelab). Running Home Manager switch..."
  nix run github:nix-community/home-manager -- switch --flake ~/.dotfiles#linux
fi

echo ""
echo "Bootstrap complete. Run './rebuild.sh' for future configuration changes."
