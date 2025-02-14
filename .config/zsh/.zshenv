# ================================================================================
# LOCALE and TZ
# --------------------------------------------------------------------------------
function () {
	local locale=$(locale -a | grep -Ei '^en_US\.UTF-?8$' | head -n1)
	if [ -z "$locale" ]; then
		locale=$(locale -a | grep -Ei '^C\.UTF-?8$' | head -n1)
	fi

	export LANG="$locale"
	export LANGUAGE="$locale"
	export LC_COLLATE="$locale"
	export LC_CTYPE="$locale"
	export LC_MESSAGES="$locale"
	export LC_MONETARY="$locale"
	export LC_NUMERIC="$locale"
	export LC_TIME="$locale"
	export LC_ALL="$locale"
	export LC_CTYPE="$locale"
}

export TZ="Europe/London"


# ================================================================================
# Dev Environment
# --------------------------------------------------------------------------------
export CARGO_HOME="$HOME/.local/cargo"

export GOROOT=/usr/local/go
export GOPATH=$HOME/.local/go


# ================================================================================
# PATH
# --------------------------------------------------------------------------------
path+=("$HOME/.local/bin")

path+=("$CARGO_HOME/bin")

path+=("$GOPATH/bin")
path+=("$GOROOT/bin")

case "$(uname -o)" in
	"Darwin")
		path+=("$HOME/homebrew/bin")
		path+=("$HOME/homebrew/sbin")
		;;
	"Linux")
		;;
esac

export PATH


# ================================================================================
# FPATH
# --------------------------------------------------------------------------------
fpath+=("$ZDOTDIR/functions")
export FPATH


# ================================================================================
# EDITOR
# --------------------------------------------------------------------------------
export EDITOR="vim"
if command -v nvim &> /dev/null ; then
	export EDITOR="nvim"
fi


# ================================================================================
# PAGER
# --------------------------------------------------------------------------------
if command -v bat &> /dev/null ; then
	export MANROFFOPT='-c'
	export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export BAT_THEME="Dracula"
fi


# ================================================================================
# MISC
# --------------------------------------------------------------------------------
export TMUX_PLUGIN_MANAGER_PATH="${XDG_STATE_HOME}/tmux/plugins"
export DOCKER_HOST=unix:///run/user/${UID}/docker.sock
