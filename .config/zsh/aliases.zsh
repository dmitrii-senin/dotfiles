# ================================================================================
# Zsh aliases
# --------------------------------------------------------------------------------
alias ezenv="$EDITOR $ZDOTDIR/.zshenv"
alias ez="$EDITOR $ZDOTDIR/.zshrc"
alias eza="$EDITOR $ZDOTDIR/aliases.zsh"
alias ezd="$EDITOR $ZDOTDIR/docker.zsh"
alias ezf="$EDITOR $ZDOTDIR/functions.zsh"
alias ezp="$EDITOR $ZDOTDIR/prompt.zsh"

# Reload zsh configuration
alias rz="source $ZDOTDIR/.zshrc"
# ================================================================================

# ================================================================================
# Kitty aliases
# --------------------------------------------------------------------------------
alias ekconf="$EDITOR ${XDG_CONFIG_HOME}/kitty/kitty.conf"
# ================================================================================

alias clr="clear"

# NeovVim aliases
if command -v nvim &> /dev/null; then
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
if comman -v glow &> /dev/null ; then
	alias glow="glow -p"
fi

# LS aliases
if command -v eza &> /dev/null ; then
	alias l="\eza --color=auto --icons"
	alias ls="\eza --color=auto --icons"
	alias la="\eza --color=auto -la --icons"
	alias ll="\eza --color=auto -l --icons"
	alias tree="\eza --color=auto --icons --tree"
else
	alias l="ls --color=auto -h"
	alias ls="ls --color=auto -h"
	alias la="ls --color=auto -Al -h"
	alias ll="ls --color=auto -l -h"
fi

if command -v bat &> /dev/null ; then
	alias cat="bat --style=plain --paging=never"
fi


# Stop after 5 pings
alias ping="ping -c 5"

