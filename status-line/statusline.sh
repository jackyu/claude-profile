#!/bin/bash
# Claude Code 狀態列腳本
# Line 1: [Model Ver] | project (clickable) | 🌿 branch | wt:name | 📅 date
# Line 2: ▓░ PCT% | ⏱️ Xm Ys | 5h ████████ XX% | 7d ████████ XX%
#
# 需求: jq (https://jqlang.github.io/jq/)
# 安裝: ./install.sh 或手動複製到 ~/.claude/statusline.sh

input=$(cat)

# === Model ===
DISPLAY_NAME=$(echo "$input" | jq -r '.model.display_name')
MODEL_ID=$(echo "$input" | jq -r '.model.id')
VERSION=$(echo "$MODEL_ID" | sed 's/.*-\([0-9]*-[0-9]*\)$/\1/' | tr '-' '.')
MODEL="${DISPLAY_NAME} ${VERSION}"

# === Project (clickable link) ===
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir')
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Parse git remote: git@host:path.git → https://host/path
REMOTE_RAW=$(git -C "$PROJECT_DIR" remote get-url origin 2>/dev/null)
if [ -n "$REMOTE_RAW" ]; then
  REMOTE=$(echo "$REMOTE_RAW" \
    | sed 's|^git@\([^:]*\):|https://\1/|' \
    | sed 's|\.git$||')
else
  REMOTE=""
fi

if [ -n "$REMOTE" ]; then
  PROJECT_LINK=$(printf '%b' "\e]8;;${REMOTE}\a${PROJECT_NAME}\e]8;;\a")
else
  PROJECT_LINK="$PROJECT_NAME"
fi

# === Git branch & worktree ===
BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
WT=""
GIT_FILE="$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)/.git"
[ -f "$GIT_FILE" ] && WT=" | wt:$(basename "$DIR")"

# === Context window bar ===
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
ORANGE='\033[38;5;208m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')

# === Duration ===
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
MINS=$((DURATION_MS / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))

# === Token usage (async cache — never blocks) ===
# Claude Code Max 5x: 5h=1M, 7d=5M
LIMIT_5H=1000000
LIMIT_7D=5000000
CACHE_FILE="/tmp/.claude-token-cache"
LOCK_FILE="/tmp/.claude-token-cache.lock"
CACHE_TTL=60

build_token_bar() {
  local tokens=$1 limit=$2
  local pct=$((tokens * 100 / (limit > 0 ? limit : 1)))
  [ "$pct" -gt 100 ] && pct=100

  local color
  if [ "$pct" -ge 90 ]; then color="$RED"
  elif [ "$pct" -ge 75 ]; then color="$ORANGE"
  elif [ "$pct" -ge 50 ]; then color="$YELLOW"
  else color="$GREEN"; fi

  local filled=$((pct * 8 / 100)); local empty=$((8 - filled))
  local bar=$(printf "%${filled}s" | tr ' ' '█')$(printf "%${empty}s" | tr ' ' '░')
  printf "${color}${bar}${RESET} %d%%" "$pct"
}

NOW_S=$(date +%s)
NEED_REFRESH=true
if [ -f "$CACHE_FILE" ]; then
  CACHE_AGE=$((NOW_S - $(stat -f '%m' "$CACHE_FILE" 2>/dev/null || echo 0)))
  [ "$CACHE_AGE" -lt "$CACHE_TTL" ] && NEED_REFRESH=false
fi

if $NEED_REFRESH && ! [ -f "$LOCK_FILE" ]; then
  (
    touch "$LOCK_FILE"
    H5_ISO=$(date -u -r $((NOW_S - 5 * 3600)) '+%Y-%m-%dT%H:%M:%SZ')
    D7_ISO=$(date -u -r $((NOW_S - 7 * 86400)) '+%Y-%m-%dT%H:%M:%SZ')

    find ~/.claude/projects -name '*.jsonl' -mtime -7 -exec \
      jq -c 'select(.requestId and .message.usage.input_tokens) |
        {rid: .requestId, ts: .timestamp,
         tok: ((.message.usage.input_tokens // 0) + (.message.usage.output_tokens // 0)
             + (.message.usage.cache_creation_input_tokens // 0)
             + (.message.usage.cache_read_input_tokens // 0))}' {} + 2>/dev/null \
      | sort -t'"' -k4,4 -u \
      | jq -s --arg h5 "$H5_ISO" --arg d7 "$D7_ISO" \
        'def st(c): [.[] | select(.ts >= c) | .tok] | add;
         {h5: (st($h5) // 0), d7: (st($d7) // 0)}' > "$CACHE_FILE" 2>/dev/null

    rm -f "$LOCK_FILE"
  ) &
  disown
fi

# Read from cache (instant)
TOK_5H=0; TOK_7D=0
if [ -f "$CACHE_FILE" ] && [ -s "$CACHE_FILE" ]; then
  TOK_5H=$(jq -r '.h5' "$CACHE_FILE" 2>/dev/null || echo 0)
  TOK_7D=$(jq -r '.d7' "$CACHE_FILE" 2>/dev/null || echo 0)
fi

BAR_5H=$(build_token_bar "$TOK_5H" "$LIMIT_5H")
BAR_7D=$(build_token_bar "$TOK_7D" "$LIMIT_7D")

# === Output ===
DATETIME=$(date '+%Y/%m/%d %H:%M')
echo -e "${CYAN}[${MODEL}]${RESET} | ${PROJECT_LINK} | 🌿 ${BRANCH}${WT} | 📅 ${DIM}${DATETIME}${RESET}"
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% | ⏱️  ${MINS}m ${SECS}s | 5h ${BAR_5H} | 7d ${BAR_7D}"
