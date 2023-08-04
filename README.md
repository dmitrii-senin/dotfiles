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

# Fonts

Nerd-Fonts are used to have a nice prompt.

To install Nerd-Fonts please check the link below:
https://github.com/ryanoasis/nerd-fonts#font-installation

* MacOS
```
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font
```

* Linux
```
git clone https://github.com/ryanoasis/nerd-fonts.git
cd ./nerd-fonts && ./install.sh Hack
```


# Add a Zsh Plugin

Using zsh-autosuggestions plugin as an example:
```
cd .config/zsh/plugins
git submodule add https://github.com/zsh-users/zsh-autosuggestions
git commit -m "Add zsh-autosuggestions plugin"
```
