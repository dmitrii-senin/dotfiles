#!/bin/zsh

loglevels=(dbg inf wrn err)
loglevel=$loglevels[(i)${LOGLEVEL:-inf}]

function crt() { [ $loglevel -le $loglevels[(i)crt] ] && print -P "%{%B%F{magenta}%}[CRT] $* %{%f%b%}"; exit 1; }
function err() { [ $loglevel -le $loglevels[(i)err] ] && print -P "%{%B%F{red    }%}[ERR] $* %{%f%b%}"; }
function wrn() { [ $loglevel -le $loglevels[(i)wrn] ] && print -P "%{%B%F{yellow }%}[WRN] $* %{%f%b%}"; }
function inf() { [ $loglevel -le $loglevels[(i)inf] ] && print -P "%{%B%F{default}%}[INF] $* %{%f%b%}"; }
function dbg() { [ $loglevel -le $loglevels[(i)dbg] ] && print -P "%{%B%F{250    }%}[DBG] $* %{%f%b%}"; }

repo=${0:A:h}

sync_paths=(
	.config/git
	.config/nvim
	.config/tmux
	.config/zsh
	.zshenv
)


function make_xdg_dirs() {
	local xdg_dir
	local xdg_dirs=("$HOME/.config" "$HOME/.local/state" "$HOME/.local/share")
	for xdg_dir in $xdg_dirs; do
		if [ ! -d "$xdg_dir" ]; then
			inf "Creating dir '$xdg_dir' ..."
			mkdir -p "$xdg_dir" || err "Cannot create dir '$xdg_dir'"
		else
			dbg "Dir '$xdg_dir' exists"
		fi
	done
}

function make_links() {
	local sync_path
	for sync_path in ${sync_paths[@]}; do
		make_link "$sync_path"
	done
}

function make_link() {
	local sync_path="$1"
	local src_path="$repo/$sync_path"
	local dst_path="$HOME/$sync_path"

	if [ -L "$dst_path" -a "$dst_path" -ef "$src_path" ]; then
		dbg "Link exists: '$dst_path' => '$src_path'"
	elif [ -L "$dst_path" -a ! "$dst_path" -ef "$src_path" ]; then
		wrn "Incorrect link: '$dst_path' => '$(ls -ld $dst_path | rev | cut -d' ' -f1 | rev)' (expected: '$src_path')"
		ln -si "$src_path" "$dst_path" || err "Cannot create link '$dst_path' => 'src_path'"
	elif [ ! -e "$dst_path" ]; then
		inf "Creating link '$dst_path' => '$src_path' ..."
		ln -s "$src_path" "$dst_path" || err "Cannot create link '$dst_path' => '$src_path'"
	else
		err "Path '$dst_path' exists and is not a symlink"
	fi
}

function main() {
	make_xdg_dirs
	make_links
}

main "$@"
