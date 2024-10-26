# How to Install

To install dotfiles on a new instance:
```
curl https://raw.githubusercontent.com/dmitrii-senin/dotfiles/master/dotsync | zsh &&
exec zsh
```

# Installation

## MacOS

```
setopt interactive_comments

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install CLI tools
brew install \
    fzf      \ # a command-line fuzzy finder
    git      \ # a distributed version control system
    neovim   \ # a hyperextensible Vim-based text editor
    tmux     \ # a terminal multiplexer
    go       \ # a Go programming language
    :

# Install GUI tools
brew install --cask               \
    font-jetbrains-mono-nerd-font \
    kitty                         \
    :
```

## Linux: Ubuntu

```
setopt interactive_comments

# Install Kitty: https://sw.kovidgoyal.net/kitty/binary/
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
```

```
setopt interactive_comments

sudo apt install -y \
    golang-go       \ # a Go programming language
    :
```

### Install Nerd Fonts
```
mkdir -p ${XDG_DATA_HOME}/fonts
cd ${XDG_DATA_HOME}/fonts
curl -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz | tar xJf -
fc-cache -fv
fc-list | grep JetBrainsMono
```

## Common

```
setopt interactive_comments

# Install Cargo
curl https://sh.rustup.rs -sSf | sh

cargo install \
    bat       \ # a cat(1) clone with wings.
    exa       \ # a modern replacement for ls
    git-delta \ # a syntax-highlighting pager for git
    ripgrep   \ # a line-oriented search tool that recursively searches the current directory for a regex pattern
    :
```

```
setopt interactive_comments

# Install Go binaries
# NB! Go must be already installed
go install                               \
    github.com/charmbracelet/glow@latest \ # Render Markdown on the CLI
    :
```

# Customization

## Add New Zsh Plugin

```
cd ${DOTFILES:-$HOME/dotfiles}/.config/zsh/plugins
git submodule add <https link to git repo>
git commit -m "Add <plugin name>"
```

