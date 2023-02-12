setopt PROMPT_SUBST

function __fillbar_precmd_hook() {
	__PROMPT_FILLBAR=""
	__PROMPT_PWDLEN=""

	local term_width=$(( COLUMNS - ${ZLE_RPROMPT_INDENT:-1} -1 ))

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
	else
		__CMD_EXEC_TIME="%{%F{227}%}    0 ms ${hourglass}%{%f%}"
	fi
	unset __CMD_START_MS
}

function __hg_prompt_info() {
	local left_fade='%{%K{232}%} %{%K{233}%} %{%K{235}%} %{%K{237}%}'
	local right_fade='%{%K{235}%} %{%K{233}%} %{%K{232}%}─%{%k%}'
	local sep='%{%F{241}%}/%{%f%}'

	local summary=$1

	local bookmark=$(\grep 'bookmarks:' <<< $summary | \grep -oP '(?<=\*)\S+')
	local commit_id=$(\grep 'parent:' <<< $summary | \awk '{print $2}')
	if [ $(\wc -l <<< $commit_ids) -eq 2 ]; then
		local commit_ids=(${(f)"$commit_id"})
		commit_id=$(echo -n "$commit_ids[1] -> $commit_ids[2]")
	fi
	local commit_info=$(\grep 'commit:' <<< $summary)

	local added=$(\grep -oP '\d+(?= added)' <<< $commit_info)
	local modified=$(\grep -oP '\d+(?= modified)' <<< $commit_info)
	local deleted=$(\grep -oP '\d+(?= deleted)' <<< $commit_info)
	local unknown=$(\grep -oP '\d+(?= unknown)' <<< $commit_info)

	local bookmark_color="%{%B%F{green}%}"
	if [ -n "$added" ] || [ -n "$deleted" ]  || [ -n "$modified" ] ; then
		local bookmark_color="%{%B%F{red}%}"
	fi
	local bookmark_info="${bookmark_color}${bookmark:-$commit_id}%{%f%b%}"

	local repo_name=$(\hg root 2> /dev/null | \xargs basename)
	local repo_info="%{%B%F{227}%}${repo_name}%{%f%b%}"

	echo -n "${left_fade}"
	echo -n "${repo_info} ${sep} ${bookmark_info} "

	local added_info=$([ -n "$added" ] && echo "%{%B%F{green}%}A${added}%{%f%b%}")
	local modified_info=$([ -n "$modified" ] && echo "%{%B%F{blue}%}M${modified}%{%f%b%}")
	local deleted_info=$([ -n "$deleted" ] && echo "%{%B%F{red}%}D${deleted}%{%f%b%}")
	local unknown_info=$([ -n "$unknown" ] && echo "%{%B%F{magenta}%}U${unknown}%{%f%b%}")

	local changes_info="${added_info}${modified_info}${deleted_info}${unknown_info}"
	if [ -n "$changes_info" ]; then
		echo -n "${sep} ${changes_info} "
	fi

	echo "${right_fade}"
}

function __vcs_precmd_hook() {
	__PROMPT_VCS_INFO="─"

	local summary
	summary=$(\hg summary 2> /dev/null)
	if [ $? -eq 0 ]; then
		__PROMPT_VCS_INFO=$(__hg_prompt_info $summary)
	fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd __fillbar_precmd_hook
add-zsh-hook precmd __vcs_precmd_hook
add-zsh-hook precmd __build_exec_time
add-zsh-hook preexec __set_timer

function () {
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

	local ok_status="%{%F{green}%}$(echo -e '\uf05d')   0 ↵%{%f%}"
	local err_status='%{%B%F{red}%}${(e)$(print -P -f "\uea87 %3d" %?)} ↵%{%f%b%}'
	local retcode="%(?.${ok_status}.${err_status})"

	local top_right_info="${left_fade} ${retcode} ${sep} ${time_info} ${right_fade}"
	# ----------------------------------------------------------------------

	# ======================================================================
	# bottom-left info
	# ======================================================================
	local retcode_ok="%{%B%F{green}%}✔%{%f%b%}"
	local retcode_error="%{%B%F{red}%}✗%{%f%b%}"
	local short_status="%(?.${retcode_ok}.${retcode_error}) "
	local bottom_left_info="─ ${short_status}"
	# ----------------------------------------------------------------------

	# ======================================================================
	# bottom-right info
	# ======================================================================
	local vcs_info='${(e)__PROMPT_VCS_INFO}'
	local bottom_right_info="${vcs_info}"
	# ----------------------------------------------------------------------

	local fillbar='${(e)__PROMPT_FILLBAR}'

	PROMPT="\
$(print '\u256D')${top_left_info}${fillbar}${top_right_info}$(print '\u256E')
$(print '\u2570')${bottom_left_info}"

	RPROMPT="${bottom_right_info}$(print '\u256F')"
}

