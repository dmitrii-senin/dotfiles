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
