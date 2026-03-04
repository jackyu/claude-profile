#!/bin/bash
# Claude Code 狀態列腳本
# Line 1: [Model Ver] | project (clickable) | 🌿 branch | wt:name
# Line 2: ▓░ PCT% | ⏱️ Xm Ys | YYYY/MM/DD HH:MM
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

REMOTE=$(git -C "$PROJECT_DIR" remote get-url origin 2>/dev/null \
  | sed 's|git@[^:]*:|https://github.com/|' \
  | sed 's|\.git$||')

if [ -n "$REMOTE" ]; then
  # OSC 8 clickable link
  PROJECT_LINK=$(printf '%b' "\e]8;;${REMOTE}\a${PROJECT_NAME}\e]8;;\a")
else
  PROJECT_LINK="$PROJECT_NAME"
fi

# === Git branch ===
BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)

# === Worktree detection ===
WT=""
GIT_FILE="$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)/.git"
if [ -f "$GIT_FILE" ]; then
  WT=" | wt:$(basename "$DIR")"
fi

# === Context window progress bar ===
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

# Pick bar color based on context usage
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')

# === Duration ===
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
MINS=$((DURATION_MS / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))

# === Date/Time ===
DATETIME=$(date '+%Y/%m/%d %H:%M')

# === Output ===
# Line 1
echo -e "${CYAN}[${MODEL}]${RESET} | ${PROJECT_LINK} | 🌿 ${BRANCH}${WT}"
# Line 2
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% | ⏱️  ${MINS}m ${SECS}s | ${DIM}${DATETIME}${RESET}"
