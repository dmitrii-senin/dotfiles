#!/usr/bin/env bash
# Claude Code statusLine command
# Inspired by starship Catppuccin Macchiato prompt

input=$(cat)

# Catppuccin Macchiato palette (ANSI 24-bit)
RED='\033[38;2;237;135;150m'
PEACH='\033[38;2;245;169;127m'
YELLOW='\033[38;2;238;212;159m'
GREEN='\033[38;2;166;218;149m'
SAPPHIRE='\033[38;2;125;196;228m'
LAVENDER='\033[38;2;183;189;248m'
OVERLAY2='\033[38;2;147;154;183m'
CRUST_BG='\033[48;2;24;25;38m'
RESET='\033[0m'
BOLD='\033[1m'

pct_color() {
    local pct=${1%%.*}
    if   [ "$pct" -lt 50 ]; then printf '%s' "$GREEN"
    elif [ "$pct" -lt 80 ]; then printf '%s' "$YELLOW"
    else                         printf '%s' "$RED"
    fi
}

relative_time() {
    local target=$1
    local now=$(date +%s)
    local diff=$(( target - now ))
    [ "$diff" -lt 0 ] && diff=0
    if   [ "$diff" -lt 3600 ];  then printf '%dm' $(( diff / 60 ))
    elif [ "$diff" -lt 86400 ]; then printf '%dh' $(( diff / 3600 ))
    else                             printf '%dd' $(( diff / 86400 ))
    fi
}

# Extract fields from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
repo_owner=$(echo "$input" | jq -r '.workspace.repo.owner // empty')
repo_name=$(echo "$input" | jq -r '.workspace.repo.name // empty')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
branch=""
git_status_str=""

# Truncate cwd: show up to 3 path components, replace home with ~
home="$HOME"
if [ -n "$cwd" ]; then
    display_path="${cwd/#$home/~}"
    # Truncate to last 3 components
    depth=$(echo "$display_path" | tr -cd '/' | wc -c)
    if [ "$depth" -gt 3 ]; then
        display_path="…/$(echo "$display_path" | rev | cut -d'/' -f1-3 | rev)"
    fi
else
    display_path="$(pwd | sed "s|^$HOME|~|")"
fi

# Git branch (from repo info or git command)
if [ -n "$git_worktree" ]; then
    branch="$git_worktree"
elif [ -n "$repo_name" ]; then
    branch=$(git -C "${cwd:-.}" --no-optional-locks branch --show-current 2>/dev/null)
fi

# Git status indicators
if [ -n "$cwd" ] && git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    if [ -z "$branch" ]; then
        branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    fi
    ahead=$(git -C "$cwd" --no-optional-locks rev-list --count @{u}..HEAD 2>/dev/null)
    behind=$(git -C "$cwd" --no-optional-locks rev-list --count HEAD..@{u} 2>/dev/null)
    dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -1)
    [ -n "$dirty" ] && git_status_str="*"
    [ -n "$ahead" ] && [ "$ahead" -gt 0 ] 2>/dev/null && git_status_str="${git_status_str}⇡${ahead}"
    [ -n "$behind" ] && [ "$behind" -gt 0 ] 2>/dev/null && git_status_str="${git_status_str}⇣${behind}"
fi

# Context window usage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Rate limits (Pro/Max only — may be absent)
five_pct=$(echo "$input"   | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at       // empty')
week_pct=$(echo "$input"   | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at       // empty')

# Build output
printf "${RED}${BOLD} $(whoami)${RESET}"
printf " ${PEACH}${display_path}${RESET}"

if [ -n "$branch" ]; then
    printf " ${YELLOW} ${branch}${RESET}"
    [ -n "$git_status_str" ] && printf "${YELLOW}${git_status_str}${RESET}"
fi

if [ -n "$repo_owner" ] && [ -n "$repo_name" ]; then
    printf " ${OVERLAY2}${repo_owner}/${repo_name}${RESET}"
fi

if [ -n "$model" ]; then
    printf " ${SAPPHIRE}${model}${RESET}"
fi

if [ -n "$used_pct" ]; then
    printf " ${LAVENDER}ctx:$(printf '%.0f' "$used_pct")%%${RESET}"
fi

if [ -n "$five_pct" ]; then
    color=$(pct_color "$five_pct")
    reset_str=""
    [ -n "$five_reset" ] && reset_str="↻$(relative_time "$five_reset")"
    printf " ${color}5h:$(printf '%.0f' "$five_pct")%%${reset_str}${RESET}"
fi

if [ -n "$week_pct" ]; then
    color=$(pct_color "$week_pct")
    reset_str=""
    [ -n "$week_reset" ] && reset_str="↻$(relative_time "$week_reset")"
    printf " ${color}7d:$(printf '%.0f' "$week_pct")%%${reset_str}${RESET}"
fi

printf "\n"
