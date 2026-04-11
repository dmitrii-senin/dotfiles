#!/usr/bin/sh

sudo apt update

sudo apt install -y \
  build-essential   \
  curl              \
  fontconfig        \
  nala              \
  git               \
  gnome-tweak-tool  \
  neovim            \
  sed               \
  tar               \
  tmux              \
  zsh               \
  :


# ================================================================================
# WezTerm
# --------------------------------------------------------------------------------
# https://wezfurlong.org/wezterm/install/linux.html
echo "Installing WezTerm ..."

curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

sudo apt update
sudo apt install -y wezterm
# ================================================================================


# ================================================================================
# Install Nerd Fonts
# --------------------------------------------------------------------------------
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
FONT_NAME=$(basename $FONT_URL | cut -f1 -d.)
FONT_DIR=$XDG_DATA_HOME/fonts/$FONT_NAME
FONT_ARC=$FONT_DIR/$(basename $FONT_URL)

echo "Installing Nerd Font: $FONT_NAME ..."
mkdir -p $FONT_DIR
curl -LO --output-dir $FONT_DIR $FONT_URL
tar -C $FONT_DIR -xJf $FONT_ARC
fc-cache -fv $FONT_DIR

rm $FONT_ARC

# To check that the font is installed:
# fc-list | grep $FONT_NAME
# ================================================================================


# ================================================================================
# Install fzf
# --------------------------------------------------------------------------------
# TODO: Install fzf + symlinks from .local/bin
# ================================================================================


# ================================================================================
# Clone dotfiles and init zsh and tmux plugins
# --------------------------------------------------------------------------------
dotfiles_repo=$HOME/x/dotfiles
echo "Cloning dotfiles repo: $dotfiles_repo ..."
mkdir -p $(dirname $dotfiles_repo)
git clone https://github.com/dmitrii-senin/dotfiles.git $dotfiles_repo

echo "Initializing dotfiles submodules ..."
(cd $dotfiles_repo && git submodule update --init --recursive)

echo "Linking dotfiles ..."
(cd $dotfiles_repo && ./link_dotfiles.zsh)

echo "Initializing tmux plugins ..."
# TODO: init tmux plugins
# ================================================================================


# ================================================================================
# Make zsh a default shell
# --------------------------------------------------------------------------------
echo "Changing user's ($USER) shell to $(which zsh) ..."
chsh -s $(which zsh)
# ================================================================================


# ================================================================================
# Map Caps Lock => Esc:
# --------------------------------------------------------------------------------
# gnome-tweaks =>
#   Keyboard =>
#     Additional Layout Options =>
#       Caps Lock behavior =>
#         Make Caps Lock an additional Esc
# ================================================================================
