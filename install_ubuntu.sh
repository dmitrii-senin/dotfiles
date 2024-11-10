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
# Kitty
# --------------------------------------------------------------------------------
echo "Installing Kitty binary: https://sw.kovidgoyal.net/kitty/binary/ ..."
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# An assumption is that ~/.local/bin is in your system-wide PATH
echo "Creating symbolic links to add kitty and kitten in ~/.local/bin/ ..."
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/

echo "Placing the kitty.desktop file to ~/.local/share/applications/ ..."
cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/

# To open text files and images in kitty via your file manager
echo "Adding kitty-open.desktop file to ~/.local/share/applications/ ..."
cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/

# Update the paths to the kitty and its icon in the kitty desktop file(s)
sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop

# Make xdg-terminal-exec (and hence desktop environments that support it use kitty)
echo 'kitty.desktop' > ~/.config/xdg-terminals.list

echo "Adding kitty as an alternative for x-terminal-emulator with priority 50 ..."
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/kitty 50
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
# TODO: Intall fzf + symlinks from .local/bin
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
