# How to Install

To install dotfiles on a new instance:
```
curl https://raw.githubusercontent.com/dmitrii-senin/dotfiles/master/dotsync | zsh &&
exec zsh
```

# Common

```
setopt interactive_comments

# Install Cargo
curl https://sh.rustup.rs -sSf | sh

cargo install     \
	bat       \ # a cat(1) clone with wings.
	exa       \ # a modern replacement for ls
	git-delta \ # a syntax-highlighting pager for git
	:
```

# MacOS

```
setopt interactive_comments

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install CLI tools
brew install   \
  fzf    \
	git    \
	neovim \
	tmux   \
	:

# Install GUI tools
brew install --cask                   \
	font-jetbrains-mono-nerd-font \
	kitty                         \
	:
```

# How to Sync

# Terminal: Alacritty

As a terminal I use [Alacritty](https://github.com/alacritty/alacritty):
A cross-platform, OpenGL terminal emulator.
Here is an [instruction](https://github.com/alacritty/alacritty/blob/master/INSTALL.md)
on how to build the latest version.

To support nice fonts and icons I use Nerd-Fonts.
Here is an [instruction](https://github.com/ryanoasis/nerd-fonts#font-installation)
on how to install Nerd-Fonts.

Example:
```
mkdir -p ${XDG_DATA_HOME}/fonts
cd ${XDG_DATA_HOME}/fonts
curl -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz | tar xJf -
fc-cache -fv
fc-list | grep JetBrainsMono
```

# Shell: Zsh

As a shell I use [Zsh](https://www.zsh.org/).
To read more about Zsh please check its [documentation](https://zsh.sourceforge.io/Doc/Release/zsh_toc.html).

To add new Zsh plugin to dotfiles:
```
cd ${DOTFILES:-$HOME/dotfiles}/.config/zsh/plugins
git submodule add <https link to git repo>
git commit -m "Add <plugin name>"
```

# Terminal Multiplexer: Tmux

# IDE: NeoVim

# Utilities

## Cargo Utilities

To install these utilities you need
[Cargo](https://doc.rust-lang.org/cargo/getting-started/installation.html):
```
curl https://sh.rustup.rs -sSf | sh
```

* [delta](https://github.com/dandavison/delta): A syntax-highlighting pager for git, diff, and grep output.
* [bat](https://github.com/sharkdp/bat): A _cat(1)_ clone with syntax highlighting and Git integration.
* [exa](https://github.com/ogham/exa): A modern replacement for ‘ls’.
* [ripgrep](https://github.com/BurntSushi/ripgrep): Ripgrep recursively searches directories for a regex pattern while respecting your gitignore.

```
cargo install \
    git-delta \
    bat       \
    exa       \
    ripgrep
```


## Go Utilities

To install these utilities you need Go:
https://go.dev/doc/install

```
sudo apt install -y golang-go
go version
```

* [Glow](https://github.com/charmbracelet/glow): Render markdown on the CLI.

```
go install \
    github.com/charmbracelet/glow@latest
```
