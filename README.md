# Dotfiles

# Installation

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

## Ubuntu

Must have packages
```
sudo apt install -y zsh git stow
```

## MacOS

Must have packages
```
brew install zsh git stow
```

# Fonts

TODO: How to install Nerd-Fonts

# Add a Zsh Plugin

Using zsh-autosuggestions plugin as an example:
```
cd .config/zsh/plugins
git submodule add https://github.com/zsh-users/zsh-autosuggestions
git commit -m "Add zsh-autosuggestions plugin"
```
