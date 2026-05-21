# ================================================================================
# PATH
# --------------------------------------------------------------------------------
path+=("$HOME/.local/bin")

path+=("$CARGO_HOME/bin")

path+=("$GOPATH/bin")

case "$(uname -s)" in
	Darwin)
		for brew_prefix in /opt/homebrew /usr/local; do
			if [[ -x "$brew_prefix/bin/brew" ]]; then
				eval "$("$brew_prefix/bin/brew" shellenv zsh)"
				break
			fi
		done
		if command -v brew >/dev/null 2>&1; then
			if go_prefix=$(brew --prefix go 2>/dev/null); then
				path+=("$go_prefix/bin")
			fi
		fi
		;;
esac

export PATH


# ================================================================================
# FPATH
# --------------------------------------------------------------------------------
fpath+=("$ZDOTDIR/functions")
export FPATH


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
case "$(uname -o)" in
    "Linux")
        export DOCKER_HOST=unix:///run/user/${UID}/docker.sock
        ;;
esac
