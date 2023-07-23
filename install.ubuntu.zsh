#!/bin/sh


# ==============================================================================
# Install Eternal Terminal
# site: https://eternalterminal.dev/
# source: https://github.com/MisterTea/EternalTerminal
# ------------------------------------------------------------------------------ 
apt install -y software-properties-common
add-apt-repository -y ppa:jgmath2000/et
apt update
apt install -y et
# ==============================================================================


# ==============================================================================
# Install NeoVim
# site: https://neovim.io/
# source: https://github.com/neovim/neovim
# ------------------------------------------------------------------------------ 
apt install -y neovim
# ==============================================================================
