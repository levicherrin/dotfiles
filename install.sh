#!/bin/bash
# Automate symlinking dotfiles on new systems

ln -sf ~/repos/dotfiles/bashrc ~/.bashrc
ln -sf ~/repos/dotfiles/bash_aliases ~/.bash_aliases

echo "Dotfiles installed! Run 'source ~/.bashrc' to reload."
