function source_if_exists() {
	[[ -f "$1" ]] && source "$1"
}

function namedir () {
	local short_name=${1:-$(command basename "$PWD")}
	typeset -g $short_name="$PWD"
	: ~$short_name
}
