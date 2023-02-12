alias g="git"

alias gco="git checkout"
alias gcom="git checkout master"
alias gcos="git checkout stable"

alias gst="git status"

alias ga="git add"
alias gaa="git add --all"

alias gcg="git config --edit --global"
alias gcl="git config --edit --local"

alias gr="git reset -- "
alias guc="git reset --hard HEAD"
alias gcc="git clean -f -d -x"

alias gc="git commit --verbose"
alias gc!="git commit --verbose --amend"
alias gcn!="git commit --verbose --no-edit --amend"
alias gca="git commit --verbose --all"
alias gca!="git commit --verbose --all --amend"
alias {gcan!,gcna!}="git commit --verbose --all --amend"
alias gcm="git commit -m"
alias gcam="git commit --all --message"

alias gd="git diff"
alias gds="git diff --staged"

