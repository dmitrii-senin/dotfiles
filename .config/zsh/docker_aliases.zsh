alias dim="docker images"

alias dps="docker ps"
alias dpsa="docker ps --all"

alias dr="docker run -e 'TERM=xterm-256color'"
alias {drit,drti}="docker run --interactive --tty -e 'TERM=xterm-256color'"
alias {dritr,drtir,drrit,drrti}="docker run --interactive --tty --rm -e 'TERM=xterm-256color'"

alias dex="docker exec -it -e 'TERM=xterm-256color'"

alias dc="docker compose"
alias dcb="docker compose build"
alias dcu="docker compose up --detach"
alias dcd="docker compose down"
alias dcr="docker compose run"
alias dcls="docker compose ls"
alias dcps="docker compose ps"
