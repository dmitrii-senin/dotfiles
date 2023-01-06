#! /bin/zsh

setopt PROMPT_SUBST

function __prompt_precmd_hook() {
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

autoload -Uz add-zsh-hook
add-zsh-hook precmd __prompt_precmd_hook

function () {
	local cyan="%{%F{cyan}%}"
	local yellow="%{%F{yellow}%}"

	local curr_dir='%{%B%F{blue}%}%$__PROMPT_PWDLEN<...<%~%<<%{%f%b%}'

	local retcode_ok="%{%B%F{green}%}✔%{%f%b%}"
	local retcode_error="%{%B%F{red}%}✗%{%f%b%}"
	local cmd_status="%(?.${retcode_ok}.${retcode_error})"
	local retcode_value="%(?..%{%B%F{red}%}(%? ↵%)%{%f%b%})"

	local user="%(!.%{%F{red}%}%n%{%f%}.%{%F{green}%}%n%{%f%})"
	if [[ -n "$SSH_CLIENT"  ||  -n "$SSH2_CLIENT" ]]; then
		local host="%{%F{red}%}@%M%{%f%}"
	else
		local host="%{%F{green}%}@%M%{%f%}"
	fi
	local user_info="${user}${host}"
	local fillbar='${(e)__PROMPT_FILLBAR}'

	PROMPT="\
${cyan}┌─(${curr_dir}${cyan})─${fillbar}─(${user_info}${cyan}%)─┐
${cyan}└─ ${cmd_status} "
	RPROMPT="${retcode_value} ${cyan}(${yellow}%*${cyan}%)─┘"
}

