#!/bin/bash
# Automate symlinking dotfiles on new systems

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ln -sf "$DOTFILES_DIR/bashrc" ~/.bashrc
ln -sf "$DOTFILES_DIR/bash_aliases" ~/.bash_aliases

echo "Dotfiles installed! Run 'source ~/.bashrc' to reload."
