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
# PATH environment variable tweaks
# --------------------------------------------------------------------------------
export PATH=$PATH:"$HOME/.local/bin"
export PATH=$PATH:"$HOME/.local/cargo"
# ================================================================================

# ================================================================================
# MISC exports
# --------------------------------------------------------------------------------
export EDITOR="nvim"
# ================================================================================

# ================================================================================
# Vim key bindings
# --------------------------------------------------------------------------------
bindkey -v
# ================================================================================

source "$ZDOTDIR/functions.zsh"
source "$ZDOTDIR/aliases.zsh"

# ================================================================================
# Apply PLUGINS
for plugin_dir in $(command ls "$ZDOTDIR/plugins"); do
	local plugin_name=$(basename "$plugin_dir")
	source_if_exists "$ZDOTDIR/plugins/$plugin_dir/$plugin_name.zsh"
	source_if_exists "$ZDOTDIR/plugins/$plugin_dir/$plugin_name.plugin.zsh"
done
# ================================================================================

source_if_exists ~/.fzf.zsh
