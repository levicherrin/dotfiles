#!/bin/bash
# Automate symlinking dotfiles on new systems

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create ~/.config directory if it doesn't exist
mkdir -p ~/.config

ln -sf "$DOTFILES_DIR/bashrc" ~/.bashrc
ln -sf "$DOTFILES_DIR/bash_aliases" ~/.bash_aliases
ln -sf "$DOTFILES_DIR/tmux.conf" ~/.tmux.conf
ln -sfn "$DOTFILES_DIR/.config/nvim" ~/.config/nvim

# If tmux is running, reload configuration live
if command -v tmux >/dev/null 2>&1 && tmux ls >/dev/null 2>&1; then
    tmux source-file ~/.tmux.conf
fi

echo "Dotfiles installed! Run 'source ~/.bashrc' to reload."
