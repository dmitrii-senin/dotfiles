setopt PROMPT_SUBST

zmodload zsh/datetime
zmodload zsh/mathfunc

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
	__CMD_START_MS=$(( int( EPOCHREALTIME * 1000 ) ))
}

function __build_exec_time() {
	if [[ -v __CMD_START_MS ]]; then
		local now_ms=$(( int( EPOCHREALTIME * 1000 ) ))
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
		__CMD_EXEC_TIME="%{%F{227}%}$(print '\uf253') ${exec_info}%{%f%}"
	else
		__CMD_EXEC_TIME="%{%F{227}%}$(print '\uf253')    0 ms%{%f%}"
	fi
	unset __CMD_START_MS
}

function __print_with_slanted_bg() {
  local text="$1"
  local prev_bg_color="$2"
  local color="$3"
  local bg_color="$4"

  local left="%{%F{${bg_color}}%K{${prev_bg_color}}%}█%{%f%k%}"
	local mid="%{%F{${color}}%K{${bg_color}}%}${text}%{%f%k%}"
  local right="%{%F{${bg_color}}%k%}█%{%f%}"
  # local right="%{%F{${bg_color}}%K{${next_bg_color}}%}█%{%f%k%}"
  echo -n "${left}${mid}${right}"
}

function __git_prompt_info() {
	local changes=$(\git status --short)

	local branch_color="green"
	if [[ -n "${changes}" ]]; then
		branch_color="red"
	fi

	local repo_path="$1"
  local repo_name="$(\basename $repo_path)"
  __print_with_slanted_bg "$repo_name" default black 227

	local branch_symbol=$(print '\ue725')
	local branch_name=$(\git rev-parse --abbrev-ref HEAD)
	__print_with_slanted_bg "${branch_symbol} ${branch_name}" 227 black "${branch_color}"
  echo -n "%{%F{${branch_color}}%}%{%f%}"

	local A=$(\grep -E '^A' <<< $changes | \wc -l | tr -d ' ')
	local M=$(\grep -E '^M' <<< $changes | \wc -l | tr -d ' ')
	local D=$(\grep -E '^D' <<< $changes | \wc -l | tr -d ' ')
	local R=$(\grep -E '^R' <<< $changes | \wc -l | tr -d ' ')

	A=$([[ $A -gt 0 ]] && echo "%{%B%F{green}%}A${A}%{%f%b%}")
	M=$([[ $M -gt 0 ]] && echo "%{%B%F{blue}%}M${M}%{%f%b%}")
	D=$([[ $D -gt 0 ]] && echo "%{%B%F{red}%}D${D}%{%f%b%}")
	R=$([[ $R -gt 0 ]] && echo "%{%B%F{teal}%}R${R}%{%f%b%}")

	local index_info="${A}${M}${D}${R}"
	if [[ -n "$index_info" ]]; then
		echo -n " $(print '\uf1c0') ${index_info}"
  else
		echo -n " $(print '\uf1c0') -"
	fi

	local U
	A=$(\grep -E '^.A' <<< $changes | \wc -l | tr -d ' ')
	M=$(\grep -E '^.M' <<< $changes | \wc -l | tr -d ' ')
	D=$(\grep -E '^.D' <<< $changes | \wc -l | tr -d ' ')
	R=$(\grep -E '^.R' <<< $changes | \wc -l | tr -d ' ')
	U=$(\grep -E '^.\?' <<< $changes | \wc -l | tr -d ' ')

	A=$([[ $A -gt 0 ]] && echo "%{%B%F{green}%}A${A}%{%f%b%}")
	M=$([[ $M -gt 0 ]] && echo "%{%B%F{blue}%}M${M}%{%f%b%}")
	D=$([[ $D -gt 0 ]] && echo "%{%B%F{red}%}D${D}%{%f%b%}")
	R=$([[ $R -gt 0 ]] && echo "%{%B%F{teal}%}R${R}%{%f%b%}")
	U=$([[ $R -gt 0 ]] && echo "%{%B%F{magenta}%}U${U}%{%f%b%}")

	local work_info="${A}${M}${D}${R}${U}"
	if [[ -n "$work_info" ]]; then
		echo -n " $(print '\uea83') ${work_info} "
  else
		echo -n " $(print '\uea83') - "
	fi
}

function __vcs_precmd_hook() {
	__VCS_INFO="─"
	repo_path=$(\git rev-parse --show-toplevel 2> /dev/null)
	if [[ $? -eq 0 ]]; then
		__VCS_INFO=$(__git_prompt_info "$repo_path")
		return
	fi
}

function zle-line-init zle-keymap-select {
    case ${KEYMAP} in
        (vicmd)      __ZLE_INFO='CMD' ;;
        (main|viins) __ZLE_INFO='INS' ;;
        (*)          __ZLE_INFO='' ;;
    esac
    zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select

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
	local clock="%{%F{252}%}$(print '\uf017') %*%{%f%}"
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
	local zle_info='${(e)__ZLE_INFO}'
	local bottom_left_info="─ ${zle_info} ${short_status}"
	# ----------------------------------------------------------------------

	# ======================================================================
	# bottom-right info
	# ======================================================================
	local vcs_info='${(e)__VCS_INFO}'
	local bottom_right_info="${vcs_info}"
	# ----------------------------------------------------------------------

	local fillbar='${(e)__PROMPT_FILLBAR}'

	PROMPT="\
$(print '\u256D')${top_left_info}${fillbar}${top_right_info}$(print '\u256E')
$(print '\u2570')${bottom_left_info}"

	RPROMPT="${bottom_right_info}$(print '\u256F')"
}

