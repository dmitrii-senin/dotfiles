#! /bin/zsh

setopt PROMPT_SUBST

function __fillbar_precmd_hook() {
	__PROMPT_FILLBAR=""
	__PROMPT_PWDLEN=""

	local term_width=$(( COLUMNS - ${ZLE_RPROMPT_INDENT:-1} ))

	local prompt_size=${#${(%):---()--(%n@%M)--}}
	local pwd_size=${#${(%):-%~}}

	if [[ "$prompt_size + $pwd_size" -gt $term_width ]]; then
		(( __PROMPT_PWDLEN=$term_width - $prompt_size ))
	else
		local fillbar_size
		(( fillbar_size = $term_width - ( $prompt_size + $pwd_size ) ))
		__PROMPT_FILLBAR="\${(l.$fillbar_size..─.)}"
	fi
}

function __hg_prompt_info() {
	local summary=$1

	local bookmark=$(command grep 'bookmarks:' <<< $summary | command grep -oP '(?<=\*)\S+')
	local commit_id=$(command grep 'parent:' <<< $summary | command awk '{print $2}' | tr '\n' ' ')
	local commit_info=$(command grep 'commit:' <<< $summary)

	local added=$(command grep -oP '\d+(?= added)' <<< $commit_info)
	local added_info=$([ -n "$added" ] && echo "%{%B%F{green}%}A${added}%{%f%b%}")
	local modified=$(command grep -oP '\d+(?= modified)' <<< $commit_info)
	local modified_info=$([ -n "$modified" ] && echo "%{%B%F{blue}%}M${modified}%{%f%b%}")
	local deleted=$(command grep -oP '\d+(?= deleted)' <<< $commit_info)
	local deleted_info=$([ -n "$deleted" ] && echo "%{%B%F{red}%}D${deleted}%{%f%b%}")
	local unknown=$(command grep -oP '\d+(?= unknown)' <<< $commit_info)
	local unknown_info=$([ -n "$unknown" ] && echo "%{%B%F{magenta}%}U${unknown}%{%f%b%}")
	local changes_info="${added_info}${modified_info}${deleted_info}${unknown_info}"
	if [ -n "$changes_info" ]; then
		changes_info=" $changes_info"
	fi

	local bookmark_color="%{%B%F{green}%}"
	if [ -n "$added" ] || [ -n "$deleted" ]  || [ -n "$modified" ] ; then
		local bookmark_color="%{%B%F{red}%}"
	fi
	local bookmark_info="${bookmark_color}${bookmark:-$commit_id}%{%f%b%}"

	local repo_name=$(command hg root 2> /dev/null | command xargs basename)
	local repo_info="%{%B%F{yellow}%}${repo_name}%{%f%b%}"

	echo "%{%F{cyan}%}(${repo_info} | ${bookmark_info}${changes_info}%{%F{cyan}%})%{%f%}"
}

function __hg_rprompt_info() {
	local summary=$1

	local commit_info=$(command grep 'commit:' <<< $summary)

	local color="%{%B%F{green}%}"
	if ! command grep 'clean' -q <<< $commit_info ; then
		local color="%{%B%F{red}%}"
	fi

	echo "${color}${bookmark}:${commit_id}%{%f%b%}"
}

function __vcs_precmd_hook() {
	__PROMPT_VCS_INFO=""
	__RPROMPT_VCS_INFO=""

	local summary
	summary=$(command hg summary 2> /dev/null)
	if [ $? -eq 0 ]; then
		__PROMPT_VCS_INFO=$(__hg_prompt_info $summary)
		__RPROMPT_VCS_INFO=$(__hg_rprompt_info $summary)
	fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd __fillbar_precmd_hook
add-zsh-hook precmd __vcs_precmd_hook

function () {
	local cyan="%{%F{cyan}%}"
	local yellow="%{%F{yellow}%}"

	local curr_dir='%{%B%F{blue}%}%$__PROMPT_PWDLEN<...<%~%<<%{%f%b%}'

	local retcode_ok="%{%B%F{green}%}✔%{%f%b%}"
	local retcode_error="%{%B%F{red}%}✗%{%f%b%}"
	local cmd_status="%(?.${retcode_ok}.${retcode_error})"
	local retcode_value="%(?..%{%B%F{red}%}(%? ↵%)%{%f%b%})"

	local user="%(!.%{%B%F{red}%}%n%{%f%b%}.%{%F{green}%}%n%{%f%})"
	if [[ -n "$SSH_CLIENT"  ||  -n "$SSH2_CLIENT" ]]; then
		local host="%{%B%F{red}%}@%M%{%f%b%}"
	else
		local host="%{%F{green}%}@%M%{%f%}"
	fi
	local user_info="${user}${host}"
	local fillbar='${(e)__PROMPT_FILLBAR}'
	local vcs_info='${(e)__PROMPT_VCS_INFO}'

	PROMPT="\
${cyan}┌─(${curr_dir}${cyan})─${fillbar}─(${user_info}${cyan}%)─┐
${cyan}└─${vcs_info} ${cmd_status} "
	RPROMPT="${retcode_value} ${cyan}(${yellow}%*${cyan}%)─┘"
}

