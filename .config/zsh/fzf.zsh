if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
fi


function _fzf_compgen_path() {
  if command -v fd &> /dev/null; then
    fd --hidden --exclude .git . "$1"
  fi
}


function _fzf_compgen_dir() {
  if command -v fd &> /dev/null; then
    fd --type=d --hidden --exclude .git . "$1"
  fi
}


function __fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}


function __set_fzf_command() {
  if ! command -v fd &> /dev/null; then
    return
  fi

  export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
}


function __set_fzf_options() {
  if ! command -v eza &> /dev/null && ! command -v bat &> /dev/null; then
    return
  fi

  local show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
  export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
}


if command -v fzf &> /dev/null; then
  __set_fzf_command
  __set_fzf_options
fi
