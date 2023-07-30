# Dotfiles

# Installation

## Ubuntu

```
sudo -i -- sh -c 'apt update && \
                  apt install -y wget && \
                  wget -O - https://raw.githubusercontent.com/dmitrii-senin/dotfiles/master/bootstrap.sh | sh'
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

# Fonts

TODO: How to install Nerd-Fonts

# Add a Zsh Plugin

Using zsh-autosuggestions plugin as an example:
```
cd .config/zsh/plugins
git submodule add https://github.com/zsh-users/zsh-autosuggestions
git commit -m "Add zsh-autosuggestions plugin"
```
