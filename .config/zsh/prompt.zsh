setopt PROMPT_SUBST

zmodload zsh/datetime
zmodload zsh/mathfunc


function __pwdlen_precmd_hook() {
	__PROMPT_PWDLEN=""
	local term_width=$(( COLUMNS - ${ZLE_RPROMPT_INDENT:-1} -1 ))
	local curr_dir_size=${#${(%):-%~}}
  local padding_template="--__  __"
  local padding_size=${#padding_template}
	if [[ "$curr_dir_size + $padding_size" -gt $term_width ]]; then
		(( __PROMPT_PWDLEN=$term_width - $padding_size ))
	fi
}


# Update pwdlen params on SIGWINCH
function TRAPWINCH() {
	__pwdlen_precmd_hook
	zle && { zle reset-prompt; zle -R }
}


function __print_with_slanted_bg() {
  local text="$1"
  local prev_bg_color="$2"
  local color="$3"
  local bg_color="$4"
  local with_right_slope="${5:-no}"

  local left="%{%F{${bg_color}}%K{${prev_bg_color}}%}█%{%f%k%}"
	local mid="%{%F{${color}}%K{${bg_color}}%}${text}%{%f%k%}"
  local right="%{%F{${bg_color}}%k%}█%{%f%}"
  if [[ "$with_right_slope" == "yes" ]]; then
    right="${right}%{%F{${bg_color}}%}%{%f%}"
  fi
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
	__print_with_slanted_bg "${branch_symbol} ${branch_name}" 227 black "${branch_color}" yes

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
	__VCS_INFO=""
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
add-zsh-hook precmd __pwdlen_precmd_hook
add-zsh-hook precmd __vcs_precmd_hook


function () {
	# ======================================================================
	# top-left info
	# ----------------------------------------------------------------------
	local curr_dir='%$__PROMPT_PWDLEN<...<%~%<<'
  local curr_dir_block="$(__print_with_slanted_bg "${curr_dir}" default black blue yes)"
	local top_left_info="─ ${exit_code_block}${curr_dir_block} "
	# ----------------------------------------------------------------------

	# ======================================================================
	# bottom-left info
	# ----------------------------------------------------------------------
  local input_sign="%{%F{%(?.green.red)}%}%(!.#.$(print '\u276f'))%{%f%}"
	local zle_info='${(e)__ZLE_INFO}'
	local bottom_left_info="─ ${zle_info} ${input_sign} "
	# ----------------------------------------------------------------------

	PROMPT="\
$(print '\u256D')${top_left_info}
$(print '\u2570')${bottom_left_info}"

	RPROMPT='${(e)__VCS_INFO}'
}

