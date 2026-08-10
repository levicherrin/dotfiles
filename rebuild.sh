#!/usr/bin/env bash
# Re-applies your dotfiles configuration on any machine (Linux, WSL2, macOS).
set -euo pipefail

# Source Nix profile if nix is not yet in PATH in the current session
if ! command -v nix >/dev/null 2>&1; then
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
fi

OS="$(uname -s)"
REAL_USER="$(whoami)"

if [ "$OS" = "Darwin" ]; then
  FLAKE_PATH="${HOME}/.dotfiles"
  if command -v darwin-rebuild >/dev/null 2>&1; then
    sudo -H USER="$REAL_USER" darwin-rebuild switch --impure --flake "${FLAKE_PATH}#mac"
  else
    NIX_BIN="$(command -v nix)"
    sudo -H USER="$REAL_USER" "$NIX_BIN" run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --impure --flake "${FLAKE_PATH}#mac"
  fi
else
  if command -v home-manager >/dev/null 2>&1; then
    home-manager switch --impure --flake ~/.dotfiles#linux
  else
    nix run github:nix-community/home-manager -- switch --impure --flake ~/.dotfiles#linux
  fi
fi
