# Dotfiles

Personal dotfiles with [Catppuccin Macchiato](https://github.com/catppuccin/catppuccin) theme
and [JetBrainsMono Nerd Font](https://www.nerdfonts.com/) across all tools.

## What's Included

| Tool | Description |
|------|-------------|
| [zsh](https://www.zsh.org/) | Shell with vi-mode, syntax highlighting, autosuggestions |
| [neovim](https://neovim.io/) | Editor with LSP, DAP, linting, formatting (lazy.nvim) |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer with TPM plugins |
| [WezTerm](https://wezfurlong.org/wezterm/) | GPU-accelerated terminal emulator |
| [starship](https://starship.rs/) | Cross-shell prompt |
| [git](https://git-scm.com/) | Version control with [delta](https://github.com/dandavella/delta) as pager |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder (integrated with fd, bat, eza) |
| [bat](https://github.com/sharkdp/bat) | cat with syntax highlighting |
| [eza](https://github.com/eza-community/eza) | Modern ls replacement |
| [fd](https://github.com/sharkdp/fd) | Fast find alternative |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast grep alternative |
| [yazi](https://github.com/sxyazi/yazi) | Terminal file manager |

## Quick Start

```sh
# 1. Clone
git clone https://github.com/dmitrii-senin/dotfiles.git ~/x/dotfiles
cd ~/x/dotfiles

# 2. Install system packages (see OS-specific sections below)

# 3. Install Rust/Go CLI tools (see Common section below)

# 4. Link dotfiles & init plugins
git submodule update --init --recursive
./link_dotfiles.zsh

# 5. Set zsh as default shell
chsh -s $(which zsh)
exec zsh
```

## Installation

### 1. Clone & Link

```sh
git clone https://github.com/dmitrii-senin/dotfiles.git ~/x/dotfiles
cd ~/x/dotfiles
git submodule update --init --recursive
./link_dotfiles.zsh
```

### 2. System Packages

<details>
<summary><b>macOS (Homebrew)</b></summary>

Install [Homebrew](https://brew.sh/) if not already installed:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Install packages:

```sh
brew install \
    fzf \
    git \
    go \
    neovim \
    starship \
    tmux \
    zsh
```

Install GUI apps and fonts:

```sh
brew install --cask \
    font-jetbrains-mono-nerd-font \
    wezterm
```

</details>

<details>
<summary><b>Ubuntu (apt)</b></summary>

Install system packages:

```sh
sudo apt update
sudo apt install -y \
    build-essential \
    curl \
    fontconfig \
    git \
    neovim \
    tmux \
    zsh
```

Install WezTerm:

```sh
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo apt update
sudo apt install -y wezterm
```

Install JetBrainsMono Nerd Font:

```sh
FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMono"
mkdir -p "$FONT_DIR"
curl -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
    | tar xJf - -C "$FONT_DIR"
fc-cache -fv "$FONT_DIR"
```

Install starship:

```sh
curl -sS https://starship.rs/install.sh | sh
```

Install fzf:

```sh
sudo apt install -y fzf
```

</details>

<details>
<summary><b>CentOS / RHEL (dnf)</b></summary>

Install system packages:

```sh
sudo dnf install -y \
    curl \
    gcc \
    git \
    make \
    neovim \
    tmux \
    zsh
```

Install WezTerm:

```sh
sudo dnf copr enable -y wezfurlong/wezterm-nightly
sudo dnf install -y wezterm
```

Install JetBrainsMono Nerd Font:

```sh
FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMono"
mkdir -p "$FONT_DIR"
curl -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
    | tar xJf - -C "$FONT_DIR"
fc-cache -fv "$FONT_DIR"
```

Install starship:

```sh
curl -sS https://starship.rs/install.sh | sh
```

Install fzf:

```sh
sudo dnf install -y fzf
```

</details>

### 3. Rust CLI Tools (all platforms)

Install [Rust](https://www.rust-lang.org/tools/install):

```sh
curl https://sh.rustup.rs -sSf | sh
```

Install CLI tools:

```sh
cargo install \
    bat \
    eza \
    fd-find \
    git-delta \
    ripgrep \
    yazi-fm
```

### 4. Go Tools (all platforms)

> Go must be installed first (`brew install go` on macOS, or see [go.dev](https://go.dev/dl/)).

```sh
go install github.com/charmbracelet/glow@latest
```

### 5. Post-Install

```sh
# Init zsh plugins
cd ~/x/dotfiles
git submodule update --init --recursive

# Set zsh as default shell
chsh -s $(which zsh)

# Init tmux plugins: open tmux, then press
#   Ctrl+Space, Shift+I
```

## Customization

### Add a New Zsh Plugin

```sh
cd ~/x/dotfiles/.config/zsh/plugins
git submodule add <https-link-to-git-repo>
git commit -m "Add <plugin-name>"
```
