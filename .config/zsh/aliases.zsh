# ================================================================================
# Zsh aliases
# --------------------------------------------------------------------------------
alias ez="$EDITOR $ZDOTDIR/.zshrc"
alias eza="$EDITOR $ZDOTDIR/aliases.zsh"
alias ezag="$EDITOR $ZDOTDIR/aliases_git.zsh"
alias ezf="$EDITOR $ZDOTDIR/functions.zsh"
alias ezp="$EDITOR $ZDOTDIR/prompt.zsh"

# Reload zsh configuration
alias rz="source $ZDOTDIR/.zshrc"
# ================================================================================

# NeovVim aliases
alias vim="nvim"

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
alias -g G="| egrep"
alias -g L="| less"
alias -g LL="2>&1 | less"
alias -g C="| wc -l"
alias -g X0="| xargs -0"

# redirection aliases
alias -g NUL="> /dev/null 2>&1"

# Colorize grep output
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
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

# LS aliases
if exa 2> /dev/null 1>&2 ; then
	alias l="exa --color=auto --icons"
	alias ls="exa --color=auto --icons"
	alias la="exa --color=auto -la --icons"
	alias ll="exa --color=auto -l --icons"
	alias tree="exa --color=auto --icons --tree"
else
	alias l="ls --color=auto -h"
	alias ls="ls --color=auto -h"
	alias la="ls --color=auto -al -h"
	alias ll="ls --color=auto -l -h"
fi

if bat -V 2> /dev/null 1>&2 ; then
	alias cat="bat --style=plain --paging=never"
fi


# Stop after 5 pings
alias ping="ping -c 5"

case "$(uname -s)" in
Darwin)
	# Mac OS X
	;;

Linux)
	;;

CYGWIN* | MINGW32* | MSYS* | MINGW*)
	# MS Windows
	;;
*)
	# Other OS
	;;
esac
