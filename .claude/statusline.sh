#!/usr/bin/env bash
# Claude Code statusLine command — Catppuccin Macchiato + Nerd Font powerline.
# Tip: add "refreshInterval": 5 to settings.json statusLine block for live cost updates.

input=$(cat)

# ── Catppuccin Macchiato palette (ANSI 24-bit) ─────────────────────────────
RED='\033[38;2;237;135;150m';      RED_BG='\033[48;2;237;135;150m'
PEACH='\033[38;2;245;169;127m';    PEACH_BG='\033[48;2;245;169;127m'
YELLOW='\033[38;2;238;212;159m';   YELLOW_BG='\033[48;2;238;212;159m'
GREEN='\033[38;2;166;218;149m';    GREEN_BG='\033[48;2;166;218;149m'
SAPPHIRE='\033[38;2;125;196;228m'; SAPPHIRE_BG='\033[48;2;125;196;228m'
LAVENDER='\033[38;2;183;189;248m'; LAVENDER_BG='\033[48;2;183;189;248m'
OVERLAY2='\033[38;2;147;154;183m'; OVERLAY2_BG='\033[48;2;147;154;183m'
CRUST_FG='\033[38;2;24;25;38m';    CRUST_BG='\033[48;2;24;25;38m'
RESET='\033[0m'

# Powerline + glyphs (Nerd Font required). Encoded as raw UTF-8 byte triples
# because BMP private-use chars get stripped when the file is written via the
# harness; the $'\xHH' form keeps the source plain ASCII and lets bash assemble
# the bytes at parse time.
SEP=$'\xee\x82\xb0'        # U+E0B0 powerline right solid
SEP_THIN=$'\xee\x82\xb1'   # U+E0B1 powerline right thin
ICON_USER=$'\xef\x80\x87'  # U+F007 nf-fa-user
ICON_DIR=$'\xef\x81\xbc'   # U+F07C nf-fa-folder_open
ICON_BRANCH=$'\xee\x9c\xa5' # U+E725 nf-dev-git_branch
ICON_REPO=$'\xef\x82\x9b'  # U+F09B nf-fa-github
ICON_MODEL=$'\xef\x82\x85' # U+F085 nf-fa-cogs
ICON_CTX=$'\xef\x83\xa7'   # U+F0E7 nf-fa-bolt
ICON_COST=$'\xef\x85\x95'  # U+F155 nf-fa-dollar
ICON_5H=$'\xef\x89\x92'    # U+F252 nf-fa-hourglass_half
ICON_7D=$'\xef\x81\xb3'    # U+F073 nf-fa-calendar
ICON_MCP=$'\xf3\xb0\x92\x8b' # U+F048B nf-md-server_network_outline

# ── Helpers ─────────────────────────────────────────────────────────────────
pct_color() {
    local pct=${1%%.*}
    local kind=${2:-fg}
    if [ "$kind" = bg ]; then
        if   [ "$pct" -lt 50 ]; then printf '%s' "$GREEN_BG"
        elif [ "$pct" -lt 80 ]; then printf '%s' "$YELLOW_BG"
        else                         printf '%s' "$RED_BG"
        fi
    else
        if   [ "$pct" -lt 50 ]; then printf '%s' "$GREEN"
        elif [ "$pct" -lt 80 ]; then printf '%s' "$YELLOW"
        else                         printf '%s' "$RED"
        fi
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

# Convert a 48; (bg) ANSI sequence into its 38; (fg) equivalent.
bg_to_fg() {
    printf '%s' "${1/48;/38;}"
}

# powerline_seg <bg_seq> <fg_seq> <prev_bg_seq|""> <content>
powerline_seg() {
    local bg=$1 fg=$2 prev=$3 content=$4
    local out
    if [ -n "$prev" ]; then
        if [ "$prev" = "$bg" ]; then
            # Same-color neighbours — solid arrow would be invisible; use thin separator.
            out="${bg}${fg}${SEP_THIN} ${content} ${RESET}"
        else
            out="${bg}$(bg_to_fg "$prev")${SEP}${fg} ${content} ${RESET}"
        fi
    else
        out="${bg}${fg} ${content} ${RESET}"
    fi
    printf '%b' "$out"
}

# powerline_end <last_bg_seq>
powerline_end() {
    local last=$1
    [ -z "$last" ] && return
    printf '%b' "$(bg_to_fg "$last")${SEP}${RESET}"
}

# render_bar <width> <pct>
render_bar() {
    local width=$1
    local pct=${2%%.*}
    [ -z "$pct" ] && pct=0
    [ "$pct" -lt 0 ] && pct=0
    [ "$pct" -gt 100 ] && pct=100
    local filled=$(( width * pct / 100 ))
    [ "$filled" -gt "$width" ] && filled=$width
    local empty=$(( width - filled ))
    local out="" i
    for ((i=0; i<filled; i++)); do out+="▰"; done
    for ((i=0; i<empty;  i++)); do out+="▱"; done
    printf '%s' "$out"
}

# session_cost <session_cost_usd> — prints "session\tdaily" (either may be empty).
session_cost() {
    local sess=$1
    local sess_fmt=""
    if [ -n "$sess" ]; then
        sess_fmt=$(printf '$%.2f' "$sess" 2>/dev/null)
    fi

    local cutoff
    cutoff=$(date -u +%Y-%m-%dT00:00:00)
    local daily=""
    daily=$(
        {
            find "$HOME/.claude/projects" -type f -name '*.jsonl' -mtime -1 -print0 2>/dev/null \
            | xargs -0 cat 2>/dev/null \
            | jq -sR --arg c "$cutoff" '
                [ split("\n")[] | select(length > 0) | fromjson?
                  | select(.timestamp >= $c)
                  | select(.message.usage? and .message.model?)
                  | (.message.model) as $m
                  | (.message.usage) as $u
                  | ({
                      "claude-opus-4-7":           {"i":15, "o":75, "w":18.75, "r":1.50},
                      "claude-sonnet-4-6":         {"i":3,  "o":15, "w":3.75,  "r":0.30},
                      "claude-haiku-4-5-20251001": {"i":1,  "o":5,  "w":1.25,  "r":0.10}
                    } | to_entries | map(select($m | startswith(.key))) | .[0].value) as $p
                  | select($p != null)
                  | ( ($u.input_tokens // 0)               * $p.i
                    + ($u.output_tokens // 0)              * $p.o
                    + ($u.cache_creation_input_tokens // 0) * $p.w
                    + ($u.cache_read_input_tokens // 0)     * $p.r ) / 1000000
                ] | add // 0
            ' 2>/dev/null
        }
    )
    local daily_fmt=""
    if [ -n "$daily" ] && [ "$daily" != "null" ]; then
        # Only emit when meaningfully > 0 to avoid showing "$0.00" before any usage today.
        local nonzero
        nonzero=$(awk -v d="$daily" 'BEGIN { print (d+0 >= 0.005) ? 1 : 0 }')
        [ "$nonzero" = "1" ] && daily_fmt=$(printf '$%.2f' "$daily" 2>/dev/null)
    fi

    printf '%s\t%s' "$sess_fmt" "$daily_fmt"
}

# mcp_health <cwd> — prints "N/N" when servers configured, else empty.
mcp_health() {
    local cwd=$1
    [ ! -f "$HOME/.claude.json" ] && return
    local total
    total=$(jq -r --arg cwd "$cwd" '
        ((.mcpServers // {}) + ((.projects[$cwd].mcpServers) // {})) | length
    ' "$HOME/.claude.json" 2>/dev/null)
    if [ -z "$total" ] || [ "$total" = "0" ] || [ "$total" = "null" ]; then
        return
    fi
    printf '%s/%s' "$total" "$total"
}

# ── Extract fields from stdin JSON ──────────────────────────────────────────
cwd=$(echo "$input"          | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input"        | jq -r '.model.display_name // empty')
model="${model#Claude }"
repo_owner=$(echo "$input"   | jq -r '.workspace.repo.owner // empty')
repo_name=$(echo "$input"    | jq -r '.workspace.repo.name // empty')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
total_cost=$(echo "$input"   | jq -r '.total_cost_usd // empty')
used_pct=$(echo "$input"     | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input"     | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input"   | jq -r '.rate_limits.five_hour.resets_at       // empty')
week_pct=$(echo "$input"     | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input"   | jq -r '.rate_limits.seven_day.resets_at       // empty')

branch=""
git_status_str=""

# Truncate cwd: show up to 3 path components, replace home with ~
home="$HOME"
if [ -n "$cwd" ]; then
    display_path="${cwd/#$home/~}"
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
    [ -n "$dirty" ] && git_status_str=" *"
    [ -n "$ahead" ]  && [ "$ahead"  -gt 0 ] 2>/dev/null && git_status_str="${git_status_str} ⇡${ahead}"
    [ -n "$behind" ] && [ "$behind" -gt 0 ] 2>/dev/null && git_status_str="${git_status_str} ⇣${behind}"
fi

# Derived signals
IFS=$'\t' read -r sess_cost_fmt daily_cost_fmt <<<"$(session_cost "$total_cost")"
mcp_str=$(mcp_health "$cwd")

# ── Build line 1: identity / location / git ─────────────────────────────────
prev=""
line1=""
line1+=$(powerline_seg "$RED_BG"   "$CRUST_FG" "$prev" "$ICON_USER $(whoami)");        prev=$RED_BG
line1+=$(powerline_seg "$PEACH_BG" "$CRUST_FG" "$prev" "$ICON_DIR $display_path");     prev=$PEACH_BG
if [ -n "$branch" ]; then
    line1+=$(powerline_seg "$YELLOW_BG" "$CRUST_FG" "$prev" "$ICON_BRANCH $branch$git_status_str")
    prev=$YELLOW_BG
fi
if [ -n "$repo_owner" ] && [ -n "$repo_name" ]; then
    line1+=$(powerline_seg "$OVERLAY2_BG" "$CRUST_FG" "$prev" "$ICON_REPO $repo_owner/$repo_name")
    prev=$OVERLAY2_BG
fi
line1+=$(powerline_end "$prev")
printf '%s\n' "$line1"

# ── Build line 2: model / ctx / cost / limits / mcp ─────────────────────────
prev=""
line2=""
if [ -n "$model" ]; then
    line2+=$(powerline_seg "$SAPPHIRE_BG" "$CRUST_FG" "$prev" "$ICON_MODEL $model")
    prev=$SAPPHIRE_BG
fi
if [ -n "$used_pct" ]; then
    bar=$(render_bar 5 "$used_pct")
    line2+=$(powerline_seg "$LAVENDER_BG" "$CRUST_FG" "$prev" "$ICON_CTX $bar $(printf '%.0f' "$used_pct")%")
    prev=$LAVENDER_BG
fi
if [ -n "$sess_cost_fmt" ]; then
    cost_content="$ICON_COST $sess_cost_fmt"
    [ -n "$daily_cost_fmt" ] && cost_content="$ICON_COST $sess_cost_fmt / $daily_cost_fmt"
    line2+=$(powerline_seg "$GREEN_BG" "$CRUST_FG" "$prev" "$cost_content")
    prev=$GREEN_BG
fi
if [ -n "$five_pct" ]; then
    bar=$(render_bar 5 "$five_pct")
    reset_str=""
    [ -n "$five_reset" ] && reset_str=" ↻$(relative_time "$five_reset")"
    bg=$(pct_color "$five_pct" bg)
    line2+=$(powerline_seg "$bg" "$CRUST_FG" "$prev" "$ICON_5H 5h $bar $(printf '%.0f' "$five_pct")%$reset_str")
    prev=$bg
fi
if [ -n "$week_pct" ]; then
    bar=$(render_bar 5 "$week_pct")
    reset_str=""
    [ -n "$week_reset" ] && reset_str=" ↻$(relative_time "$week_reset")"
    bg=$(pct_color "$week_pct" bg)
    line2+=$(powerline_seg "$bg" "$CRUST_FG" "$prev" "$ICON_7D 7d $bar $(printf '%.0f' "$week_pct")%$reset_str")
    prev=$bg
fi
if [ -n "$mcp_str" ]; then
    line2+=$(powerline_seg "$OVERLAY2_BG" "$CRUST_FG" "$prev" "$ICON_MCP $mcp_str")
    prev=$OVERLAY2_BG
fi
line2+=$(powerline_end "$prev")
[ -n "$line2" ] && printf '%s\n' "$line2"
