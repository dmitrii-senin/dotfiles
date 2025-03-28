source "$ZDOTDIR/functions.zsh"
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/git.zsh"
source "$ZDOTDIR/docker.zsh"
source "$ZDOTDIR/prompt.zsh"
source "$ZDOTDIR/fzf.zsh"

# ================================================================================
# HISTORY
# --------------------------------------------------------------------------------
HISTSIZE=1000000
SAVEHIST=$HISTSIZE
HISTFILE="$HOME/.local/.zsh_history"

setopt EXTENDED_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY_TIME

unsetopt HIST_BEEP
# ================================================================================

# ================================================================================
# Dynamic named directories
# --------------------------------------------------------------------------------
zconf="${XDG_CONFIG_HOME}/zsh"; : ~$zconf
tconf="${XDG_CONFIG_HOME}/tmux"; : ~$tconf
kconf="${XDG_CONFIG_HOME}/kitty"; : ~$kconf
vconf="${XDG_CONFIG_HOME}/nvim"; : ~$vconf

name_if_exists "/usr/bin" "ubin"
name_if_exists "/usr/local/bin" "ulbin"
# ================================================================================

# ================================================================================
# OPTIONS
#
# To read more about each option use the link below:
# https://zsh.sourceforge.io/Doc/Release/Options.html
# --------------------------------------------------------------------------------
setopt AUTO_CD
setopt EQUALS
setopt EXTENDED_GLOB
setopt MULTIOS
setopt NULL_GLOB
setopt NUMERIC_GLOB_SORT
setopt RC_EXPAND_PARAM
setopt RC_QUOTES

unsetopt BEEP
unsetopt CASE_GLOB
unsetopt FLOW_CONTROL
unsetopt LIST_BEEP
# ================================================================================

# ================================================================================
# key bindings
# --------------------------------------------------------------------------------
bindkey -v
# ================================================================================

# ================================================================================
# Apply PLUGINS
# --------------------------------------------------------------------------------
for plugin_dir in $(\ls "$ZDOTDIR/plugins"); do
	local plugin_name=$(basename "$plugin_dir")
	source_if_exists "$ZDOTDIR/plugins/$plugin_dir/$plugin_name.zsh"
	source_if_exists "$ZDOTDIR/plugins/$plugin_dir/$plugin_name.plugin.zsh"
done
# ================================================================================
