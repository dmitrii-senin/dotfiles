setopt PROMPT_SUBST

function __fillbar_precmd_hook() {
	__PROMPT_FILLBAR=""
	__PROMPT_PWDLEN=""

	local term_width=$(( COLUMNS - ${ZLE_RPROMPT_INDENT:-1} ))

	local prompt_size=${#${(%):--__ %n / %m /  __--__ retcode / exec_time / %* C __--}}
	local pwd_size=${#${(%):-%~}}

	if [[ "$prompt_size + $pwd_size" -gt $term_width ]]; then
		(( __PROMPT_PWDLEN=$term_width - $prompt_size ))
	else
		local fillbar_size
		(( fillbar_size = $term_width - ( $prompt_size + $pwd_size ) ))
		__PROMPT_FILLBAR="\${(l.$fillbar_size..─.)}"
	fi
}

# Update fillbar params on SIGWINCH
function TRAPWINCH() {
	__fillbar_precmd_hook
	zle && { zle reset-prompt; zle -R }
}

function __set_timer() {
	__CMD_START_MS=$(( $(date +%s%0N) / 1000000 ))
}

function __build_exec_time() {
	if [[ -v __CMD_START_MS ]]; then
		local now_ms=$(( $(date +%s%0N) / 1000000 ))
		local elapsed_ms=$(( now_ms - __CMD_START_MS ))
		local sec=$(( elapsed_ms / 1000 ))
		local ms=$(( elapsed_ms % 1000 ))
		if [[ $sec -ge 100 ]]; then
			local exec_info=$(printf '% 5d s' $sec)
		elif [[ $sec -ge 10 ]]; then
			ms=$(( ms / 10 ))
			local exec_info=$(printf '%d.%02d s' $sec $ms)
		elif [[ $sec -ge 1 ]]; then
			local exec_info=$(printf '%d.%03d s' $sec $ms)
		else
			local exec_info=$(printf '% 4d ms' $ms)
		fi
		local hourglass=$(echo -e '\uf252')
		__CMD_EXEC_TIME="%{%F{227}%}${exec_info} ${hourglass}%{%f%}"
	fi
	unset __CMD_START_MS
}

function __hg_prompt_info() {
	local summary=$1

	local bookmark=$(command grep 'bookmarks:' <<< $summary | command grep -oP '(?<=\*)\S+')
	local commit_id=$(command grep 'parent:' <<< $summary | command awk '{print $2}')
	if [ $(command wc -l <<< $commit_ids) -eq 2 ]; then
		local commit_ids=(${(f)"$commit_id"})
		commit_id=$(echo -n "$commit_ids[1] -> $commit_ids[2]")
	fi
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
add-zsh-hook precmd __build_exec_time
add-zsh-hook preexec __set_timer

function () {
	local retcode_ok="%{%B%F{green}%}✔%{%f%b%}"
	local retcode_error="%{%B%F{red}%}✗%{%f%b%}"
	local cmd_status="%(?.${retcode_ok}.${retcode_error})%{ %}"

	local fillbar='${(e)__PROMPT_FILLBAR}'
	local vcs_info='${(e)__PROMPT_VCS_INFO}'

	local left_fade='%{%K{232}%}─%{%K{233}%} %{%K{235}%} %{%K{237}%}'
	local right_fade='%{%K{235}%} %{%K{233}%} %{%K{232}%}─%{%k%}'
	local sep='%{%F{241}%}/%{%f%}'

	# ======================================================================
	# top-left info
	# ======================================================================
	local curr_dir='%{%B%F{blue}%}%$__PROMPT_PWDLEN<...<%~%<<%{%f%b%}'
	local user="%(!.%{%B%F{red}%}%n%{%f%b%}.%{%F{green}%}%n%{%f%})"

	if [[ -n "$SSH_CLIENT"  ||  -n "$SSH2_CLIENT" ]]; then
		local host="%{%B%F{red}%}%m%{%f%b%}"
	else
		local host="%{%F{green}%}%m%{%f%}"
	fi

	local user_host="${user} ${sep} ${host}"
	local top_left_info="${left_fade} ${user_host} ${sep} ${curr_dir} ${right_fade}"
	# ----------------------------------------------------------------------

	# ======================================================================
	# top-right info
	# ======================================================================
	local exec_time='${(e)__CMD_EXEC_TIME}'
	local clock="%{%F{252}%}%* $(echo -e '\uf017')%{%f%}"
	local time_info="${exec_time} ${sep} ${clock}"

	local ok_status="%{%F{46}%}$(echo -e '\uf05d')   0 ↵%{%f%}"
	local err_status='%{%B%F{red}%}${(e)$(print -P -f "\uea87 %3d" %?)} ↵%{%f%b%}'
	local retcode="%(?.${ok_status}.${err_status})"

	local top_right_info="${left_fade} ${retcode} ${sep} ${time_info} ${right_fade}"
	# ----------------------------------------------------------------------

	PROMPT="\
┌${top_left_info}${fillbar}${top_right_info}┐
└─${vcs_info} ${cmd_status}"

	RPROMPT="─┘"
}

