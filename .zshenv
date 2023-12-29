[ -z "$XDG_CONFIG_HOME" ] && export XDG_CONFIG_HOME="$HOME/.config/"

ZDOTDIR=$XDG_CONFIG_HOME/zsh
[ -f "$ZDOTDIR/.zshenv" ] && source "$ZDOTDIR/.zshenv"
