# ================================================================================
# HISTORY tuning
# --------------------------------------------------------------------------------
HISTSIZE=1000000
SAVEHIST=$HISTSIZE
HISTFILE="$HOME/.local/.zsh_history"

setopt EXTENDED_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY_TIME
# ================================================================================

# ================================================================================
# Set LOCALE 
# --------------------------------------------------------------------------------
LANG="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_CTYPE="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_ALL="en_US.UTF-8"
# ================================================================================

# ================================================================================
# PATH environment variable tweaks
# --------------------------------------------------------------------------------
export PATH=$PATH:"$HOME/.local/bin"
export PATH=$PATH:"$HOME/.local/cargo"
export PATH=$PATH:"$HOME/.cargo/bin"
# ================================================================================

# ================================================================================
# Exports
# --------------------------------------------------------------------------------
export EDITOR="nvim"

if bat -V 2> /dev/null 1>&2 ; then
	export MANROFFOPT='-c' 
	export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi
# ================================================================================

# ================================================================================
# Dynamic named directories
# --------------------------------------------------------------------------------
dotfiles="$HOME/.dotfiles"; : ~$dotfiles
zconfig="$dotfiles/.config/zsh"; : ~$zconfig
zplugins="$dotfiles/.config/zsh/plugins"; : ~$zplugins
# ================================================================================

# ================================================================================
# Options
# --------------------------------------------------------------------------------
setopt AUTO_CD
setopt NO_CASE_GLOB
setopt EXTENDED_GLOB
setopt MULTIOS
# ================================================================================

# ================================================================================
# Vim key bindings
# --------------------------------------------------------------------------------
bindkey -v
# ================================================================================

source "$ZDOTDIR/functions.zsh"
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/prompt.zsh"

# ================================================================================
# Apply PLUGINS
# --------------------------------------------------------------------------------
for plugin_dir in $(command ls "$ZDOTDIR/plugins"); do
	local plugin_name=$(basename "$plugin_dir")
	source_if_exists "$ZDOTDIR/plugins/$plugin_dir/$plugin_name.zsh"
	source_if_exists "$ZDOTDIR/plugins/$plugin_dir/$plugin_name.plugin.zsh"
done
# ================================================================================

source_if_exists ~/.fzf.zsh
