[ -z "$XDG_CONFIG_HOME" ] && export XDG_CONFIG_HOME="$HOME/.config"
[ -z "$XDG_DATA_HOME" ] && export XDG_DATA_HOME="$HOME/.local/share"
[ -z "$XDG_STATE_HOME" ] && export XDG_STATE_HOME="$HOME/.local/state"

ZDOTDIR=$XDG_CONFIG_HOME/zsh
[ -f "$ZDOTDIR/.zshenv" ] && source "$ZDOTDIR/.zshenv"
