# Zsh aliases
alias ez="$EDITOR $ZDOTDIR/.zshrc"
alias eza="$EDITOR $ZDOTDIR/aliases.zsh"
alias ezf="$EDITOR $ZDOTDIR/functions.zsh"
alias ezp="$EDITOR $ZDOTDIR/prompt.zsh"
alias ezpm="$EDITOR $ZDOTDIR/plugins/zsh-meta-platforms/zsh-meta-platforms.zsh"

alias sz="source $ZDOTDIR/.zshrc"

# dotfiles aliases
alias dotpull="${DOTFILES:-$HOME/.dotfiles}/manager pull"
alias dotdeploy="${DOTFILES:-$HOME/.dotfiles}/manager deploy"
alias dotsync="${DOTFILES:-$HOME/.dotfiles}/manager sync"
alias dotpush="${DOTFILES:-$HOME/.dotfiles}/manager push"

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
alias grep='grep -n --color=auto'
alias egrep='egrep -n --color=auto'
alias fgrep='fgrep -n --color=auto'

# Confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

# Easier to read disk
alias df='df -h'     # human-readable sizes
alias free='free -m' # show sizes in MB

# Get top process eating memory
alias psmem='ps auxf | sort -nr -k 4 | head -5'
# Get top process eating cpu cycles
alias pscpu='ps auxf | sort -nr -k 3 | head -5'

# Git aliases
alias g="git"

alias gco="git checkout"
alias gcom="git checkout master"
alias gcos="git checkout stable"

alias gst="git status"

alias ga="git add"
alias gaa="git add --all"

alias gcg="git config --edit --global"
alias gcl="git config --edit --local"

alias gr="git reset -- "
alias guc="git reset --hard HEAD"
alias gcc="git clean -f -d -x"

alias gc="git commit --verbose"
alias gc!="git commit --verbose --amend"
alias gcn!="git commit --verbose --no-edit --amend"
alias gca="git commit --verbose --all"
alias gcm="git commit -m"
alias gcam="git commit --all --message"

alias gd="git diff"
alias gds="git diff --staged"

# Create parent directories (verbose)
alias mkdir="mkdir -pv"

# Stop after 5 pings
alias ping="ping -c 5"

case "$(uname -s)" in
Darwin)
	# Mac OS X
	alias ls='ls -G -h'
	alias ll='ls -G -l -h'
	;;

Linux)
	alias ls="ls --color=auto -h"
	alias ll='ls --color=auto -l -h'
	;;

CYGWIN* | MINGW32* | MSYS* | MINGW*)
	# MS Windows
	;;
*)
	# Other OS
	;;
esac
