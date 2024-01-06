# Dotfiles

# Installation

## Ubuntu

```
sh -c '
  apt update &&
  apt install -y wget &&
  wget -O - https://raw.githubusercontent.com/dmitrii-senin/dotfiles/master/bootstrap.sh | sh &&
  exec zsh'
```

The same with `sudo`:
```
sudo -i -- sh -c '
  apt update &&
  apt install -y wget &&
  wget -O - https://raw.githubusercontent.com/dmitrii-senin/dotfiles/master/bootstrap.sh | sh
  exec zsh'
```

## Centos / Fedora

Must have packages
```
sudo dnf install -y zsh git stow
```

Nice to have packages
```
TODO: Rust / Cargo
TODO: exa, bat
TODO: delta
TODO: riggrep
```

## MacOS

Must have packages
```
brew install zsh git stow
```

# Nerd Fonts

Nerd-Fonts are used to have nice prompt and tmux status bar.

To install Nerd-Fonts please check the link below:
https://github.com/ryanoasis/nerd-fonts#font-installation

## MacOS
```
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font
```

## Linux
```
git clone https://github.com/ryanoasis/nerd-fonts.git
cd ./nerd-fonts && ./install.sh Hack
```

# Terminal

As a terminal I use Alacrity:
https://github.com/alacritty/alacritty/blob/master/INSTALL.md

To install Alacritty you need Cargo:
https://doc.rust-lang.org/cargo/getting-started/installation.html
```
curl https://sh.rustup.rs -sSf | sh
```

## Ubuntu
```
cat <<EOF > ~/.local/share/applications/alacritty.desktop
    [Desktop Entry]
    Type=Application
    Exec=$HOME/.local/.cargo/bin/alacritty
    Icon=alacritty
    Terminal=false
    Categories=System;TerminalEmulator;
    Name=Alacritty
    Comment=A fast, cross-platform, OpenGL terminal emulator
    StartupNotify=true
    StartupWMClass=Alacritty
    Actions=New;

    [Desktop Action New]
    Name=Alacritty
    Exec=$HOME/.local/.cargo/bin/alacritty
EOF

wget https://raw.githubusercontent.com/alacritty/alacritty/master/extra/logo/compat/alacritty-term.png -O ~/.local/share/icons/alacritty.png

sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/alacritty 50
sudo update-alternatives --config x-terminal-emulator
```

# Utilities

## Cargo Utilities

To install these utilities you need Cargo:
https://doc.rust-lang.org/cargo/getting-started/installation.html
```
curl https://sh.rustup.rs -sSf | sh
```

### Delta
A syntax-highlighting pager for git, diff, and grep output.
https://github.com/dandavison/delta
```
cargo install git-delta
```

### Exa
A modern replacement for ‘ls’.
https://github.com/ogham/exa
```
cargo install exa
```

### [Bat](https://github.com/sharkdp/bat)
A _cat(1)_ clone with syntax highlighting and Git integration.
```
cargo install bat
```

### Ripgrep
Ripgrep recursively searches directories for a regex pattern while respecting your gitignore.
https://github.com/BurntSushi/ripgrep
```
cargo install ripgrep
```

## Other Utilities

### Glow
Render markdown on the CLI.
https://github.com/charmbracelet/glow


# Add New Zsh Plugins

All zsh plugins are located in `.config/zsh/plugins` dir as a git submodules:
```
cd .config/zsh/plugins
git submodule add <https link to git repo>
git commit -m "Add <plugin name>"
```
