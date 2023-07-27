#!/bin/sh

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

apt update

# ==============================================================================
# Install Zsh and make it a default shell
# site: https://www.zsh.org/
# source: https://zsh.sourceforge.io/arc/source.html
# ------------------------------------------------------------------------------ 
apt install -y zsh
chsh -s "$(which zsh)"
# ==============================================================================


# ==============================================================================
# Install Git
# site: https://neovim.io/
# source: https://github.com/neovim/neovim
# ------------------------------------------------------------------------------ 
apt install -y git
# ==============================================================================


# ==============================================================================
# Install Stow
# site: https://www.gnu.org/software/stow/
# source: https://git.savannah.gnu.org/cgit/stow.git
# ------------------------------------------------------------------------------ 
apt install -y stow
# ==============================================================================


# ==============================================================================
# 1. Clone dotfiles repository
# 2. Deploy specified files using GNU Stow to $HOME
# ------------------------------------------------------------------------------ 
git -C "$HOME" clone https://github.com/dmitrii-senin/dotfiles.git .dotfiles
stow --dir="$HOME/.dotfiles" --target="$HOME" .
# ==============================================================================
