#!/bin/bash
# Claude Code 狀態列腳本
# Line 1: [Model Ver] | project (clickable) | 🌿 branch | wt:name | 📅 date
# Line 2: ▓░ PCT% | ⏱️ Xm Ys | 5h ████████ XX% | 7d ████████ XX%
#
# 需求: jq (https://jqlang.github.io/jq/)
# 安裝: ./install.sh 或手動複製到 ~/.claude/statusline.sh

input=$(cat)

# === Model ===
MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"' | sed 's/ *(.*//')

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
PCT=${PCT:-0}; [ "$PCT" = "null" ] && PCT=0

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
DURATION_MS=${DURATION_MS:-0}; [ "$DURATION_MS" = "null" ] && DURATION_MS=0
MINS=$((DURATION_MS / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))

# === Rate limits (from Claude Code 2.1.80+ JSON input) ===
PCT_5H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0' | cut -d. -f1)
PCT_7D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0' | cut -d. -f1)
PCT_5H=${PCT_5H:-0}; [ "$PCT_5H" = "null" ] && PCT_5H=0
PCT_7D=${PCT_7D:-0}; [ "$PCT_7D" = "null" ] && PCT_7D=0

build_pct_bar() {
  local pct=${1:-0}
  [ "$pct" = "null" ] && pct=0
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

BAR_5H=$(build_pct_bar "$PCT_5H")
BAR_7D=$(build_pct_bar "$PCT_7D")

# === Output ===
DATETIME=$(date '+%Y/%m/%d %H:%M')
echo -e "${CYAN}[${MODEL}]${RESET} | ${PROJECT_LINK} | 🌿 ${BRANCH}${WT} | 📅 ${DIM}${DATETIME}${RESET}"
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% | ⏱️  ${MINS}m ${SECS}s | 5h ${BAR_5H} | 7d ${BAR_7D}"
