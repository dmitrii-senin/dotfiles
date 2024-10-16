# ================================================================================
# Zsh aliases
# --------------------------------------------------------------------------------
alias edit_zshrc="$EDITOR $ZDOTDIR/.zshrc"
alias edit_zsh_aliases="$EDITOR $ZDOTDIR/aliases.zsh"
alias edit_zsh_git_aliases="$EDITOR $ZDOTDIR/git_aliases.zsh"
alias edit_zsh_docker_aliases="$EDITOR $ZDOTDIR/docker_aliases.zsh"
alias edit_zsh_functions="$EDITOR $ZDOTDIR/functions.zsh"
alias edit_zsh_prompt="$EDITOR $ZDOTDIR/prompt.zsh"

# Reload zsh configuration
alias reload_zshrc="source $ZDOTDIR/.zshrc"
# ================================================================================

alias clr="clear"

# NeovVim aliases
if nvim -v 2> /dev/null 1>&2 ; then
	alias vim="nvim"
fi

# cd aliases
alias -g ...="../.."
alias -g ....="../../.."
alias -g .....="../../../.."

# sort aliases
alias -g S="| sort"
alias -g NS="| sort -n"
alias -g US="| sort -u"

# other pipe aliases
alias -g H="| head"
alias -g T="| tail"
alias -g G="| grep -E"
alias -g L="| less"
alias -g LL="2>&1 | less"
alias -g C="| wc -l"
alias -g X0="| xargs -0"

# redirection aliases
alias -g NUL="> /dev/null 2>&1"

# Colorize grep output
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='fgrep --color=auto'

# Easier to read disk
alias df='df -h'     # human-readable sizes
alias free='free -m' # show sizes in MB

# Get top process eating memory
alias psmem='ps auxf | sort -nr -k 4 | head -5'
# Get top process eating cpu cycles
alias pscpu='ps auxf | sort -nr -k 3 | head -5'

# Create parent directories (verbose)
alias mkdir="mkdir -pv"

# Glow aliases
if glow -v &> /dev/null ; then
	alias glow="glow -p"
fi

# LS aliases
if exa -v &> /dev/null ; then
	alias l="exa --color=auto --icons"
	alias ls="exa --color=auto --icons"
	alias la="exa --color=auto -la --icons"
	alias ll="exa --color=auto -l --icons"
	alias tree="exa --color=auto --icons --tree"
else
	alias l="ls --color=auto -h"
	alias ls="ls --color=auto -h"
	alias la="ls --color=auto -Al -h"
	alias ll="ls --color=auto -l -h"
fi

if bat -V 2> /dev/null 1>&2 ; then
	alias cat="bat --style=plain --paging=never"
fi


# Stop after 5 pings
alias ping="ping -c 5"

