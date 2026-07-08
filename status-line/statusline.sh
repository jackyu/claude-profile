#!/bin/bash
# Claude Code 狀態列腳本（v2 — aesthetic edition）
# Line 1: [Model] ver | 📁 project | 🌿 branch* | wt:name | +N -N
# Line 2: ▓▓▓░░░(gradient) PCT% | $X.XX | ⏱️ Xm Ys | 5h:XX% 7d:XX% | 📅 date
#
# 零值智慧隱藏：費用=0、時間=0、行數=0 時自動省略
# Git 狀態以 current_dir 為準（cd／進 worktree 後跟著變），project_dir 只用於專案名稱
# 需求: jq (https://jqlang.github.io/jq/)
# 安裝: bash status-line/install.sh

# ─── 顏色與符號 ─────────────────────────────────────
RST='\033[0m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
ORANGE='\033[38;5;208m'
RED='\033[31m'
DIM='\033[2m'
GRAY='\033[90m'

# 進度條漸層 RGB（10 格：綠 → 黃 → 橙 → 紅）
GRAD_R=(46 86 126 166 200 220 233 240 248 255)
GRAD_G=(204 200 190 180 170 150 120 90 60 30)
GRAD_B=(113 90 70 50 30 20 15 10 5 0)

# ─── 快取設定 ─────────────────────────────────────
CACHE_DIR="/tmp/claude-statusline-cache"
GIT_CACHE_TTL=2
VERSION_CACHE_TTL=300
mkdir -p "$CACHE_DIR" 2>/dev/null

cache_valid() {
  local file="$1" ttl="$2"
  [ -f "$file" ] || return 1
  local age=$(( $(date +%s) - $(stat -f %m "$file" 2>/dev/null || echo 0) ))
  [ "$age" -lt "$ttl" ]
}

# ─── 降級處理 ─────────────────────────────────────
fallback() {
  printf '%b\n' "${CYAN}[Claude Code]${RST} | $1"
  exit 0
}

command -v jq &>/dev/null || fallback "jq not found — brew install jq"

# ─── 讀取 JSON（單次 jq） ───────────────────────────
input=$(cat)

parsed=$(printf '%s' "$input" | jq -r '[
  (.model.display_name // "Unknown" | gsub(" *\\(.*"; "")),
  (.workspace.current_dir // ""),
  (.workspace.project_dir // .workspace.current_dir // ""),
  (.context_window.used_percentage // 0 | floor | tostring),
  (.cost.total_duration_ms // 0 | tostring),
  (.cost.total_cost_usd // 0 | tostring),
  (.rate_limits.five_hour.used_percentage // 0 | floor | tostring),
  (.rate_limits.seven_day.used_percentage // 0 | floor | tostring),
  (.workspace.git_worktree // "")
] | join("\t")' 2>/dev/null) || fallback "parse error"

IFS=$'\t' read -r MODEL DIR PROJECT_DIR PCT DURATION_MS COST_USD PCT_5H PCT_7D GIT_WORKTREE <<< "$parsed"

[ -z "$DIR" ] && DIR="$PROJECT_DIR"

PCT=${PCT:-0};         [ "$PCT" = "null" ] && PCT=0
DURATION_MS=${DURATION_MS:-0}; [ "$DURATION_MS" = "null" ] && DURATION_MS=0
COST_USD=${COST_USD:-0};       [ "$COST_USD" = "null" ] && COST_USD=0
PCT_5H=${PCT_5H:-0};   [ "$PCT_5H" = "null" ] && PCT_5H=0
PCT_7D=${PCT_7D:-0};   [ "$PCT_7D" = "null" ] && PCT_7D=0

PROJECT_NAME=$(basename "$PROJECT_DIR")

# ─── Claude Code 版號（快取 5 分鐘）────────────────
VERSION_CACHE="$CACHE_DIR/cc_version"
if cache_valid "$VERSION_CACHE" "$VERSION_CACHE_TTL"; then
  CC_VER=$(cat "$VERSION_CACHE")
else
  CC_VER=$(claude --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  [ -n "$CC_VER" ] && printf '%s' "$CC_VER" > "$VERSION_CACHE"
fi
CC_VER_DISPLAY=""
[ -n "$CC_VER" ] && CC_VER_DISPLAY=" ${DIM}${CC_VER}${RST}"

# ─── 專案連結（OSC 8 clickable）────────────────────
REMOTE_RAW=$(git -C "$DIR" remote get-url origin 2>/dev/null)
if [ -n "$REMOTE_RAW" ]; then
  REMOTE=$(printf '%s' "$REMOTE_RAW" \
    | sed 's|^git@\([^:]*\):|https://\1/|' \
    | sed 's|\.git$||')
  PROJECT_LINK="\033]8;;${REMOTE}\a${PROJECT_NAME}\033]8;;\a"
else
  PROJECT_LINK="$PROJECT_NAME"
fi

# ─── Git 狀態（以 current_dir 為準，快取 2 秒）──────
CACHE_KEY=$(printf '%s' "$DIR" | md5 2>/dev/null || printf '%s' "$DIR" | md5sum 2>/dev/null | cut -d' ' -f1)
GIT_CACHE_FILE="$CACHE_DIR/git_${CACHE_KEY}"

# 快取逐行儲存：tab 分隔遇空欄位（clean 時 DIRTY 為空）會被 read 摺疊造成欄位位移
if cache_valid "$GIT_CACHE_FILE" "$GIT_CACHE_TTL"; then
  { read -r BRANCH; read -r DIRTY; read -r ADDITIONS; read -r DELETIONS; } < "$GIT_CACHE_FILE"
else
  BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
  DIRTY=""
  if git -C "$DIR" rev-parse --git-dir &>/dev/null; then
    if ! git -C "$DIR" diff --quiet HEAD 2>/dev/null || \
       ! git -C "$DIR" diff --cached --quiet 2>/dev/null; then
      DIRTY="*"
    fi
  fi
  # diff HEAD 已涵蓋 staged＋未 staged，再加 --cached 會把 staged 算兩次
  GIT_STAT=$(git -C "$DIR" diff --numstat HEAD 2>/dev/null)
  if [ -n "$GIT_STAT" ]; then
    ADDITIONS=$(printf '%s\n' "$GIT_STAT" | awk '{s+=$1} END {print s+0}')
    DELETIONS=$(printf '%s\n' "$GIT_STAT" | awk '{s+=$2} END {print s+0}')
  else
    ADDITIONS=0
    DELETIONS=0
  fi
  printf '%s\n%s\n%s\n%s\n' "$BRANCH" "$DIRTY" "$ADDITIONS" "$DELETIONS" > "$GIT_CACHE_FILE"
fi

# Worktree 偵測（payload 的 git_worktree 只有新版 Claude Code 才有，缺欄位時自行偵測）
WT=""
if [ -n "$GIT_WORKTREE" ]; then
  WT=" | wt:$(basename "$GIT_WORKTREE")"
else
  GIT_FILE="$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)/.git"
  [ -f "$GIT_FILE" ] && WT=" | wt:$(basename "$DIR")"
fi

# ─── 漸層進度條 ─────────────────────────────────────
[ "$PCT" -gt 100 ] 2>/dev/null && PCT=100
[ "$PCT" -lt 0 ] 2>/dev/null && PCT=0
FILLED=$((PCT / 10))
[ "$FILLED" -gt 10 ] && FILLED=10

BAR=""
i=0
while [ "$i" -lt 10 ]; do
  if [ "$i" -lt "$FILLED" ]; then
    BAR="${BAR}\033[38;2;${GRAD_R[$i]};${GRAD_G[$i]};${GRAD_B[$i]}m█"
  else
    BAR="${BAR}${DIM}░"
  fi
  i=$((i + 1))
done
BAR="${BAR}${RST}"

# 百分比文字顏色
if [ "$PCT" -ge 90 ]; then PCT_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then PCT_COLOR="$YELLOW"
else PCT_COLOR="$GREEN"; fi

# ─── 費用（零值隱藏）──────────────────────────────
COST_DISPLAY=""
COST_FMT=$(printf '%.2f' "$COST_USD" 2>/dev/null || echo "0.00")
if [ "$COST_FMT" != "0.00" ]; then
  COST_INT=${COST_USD%.*}; COST_INT=${COST_INT:-0}
  if [ "$COST_INT" -ge 10 ] 2>/dev/null; then COST_C="$RED"
  elif [ "$COST_INT" -ge 5 ] 2>/dev/null; then COST_C="$YELLOW"
  else COST_C="$GRAY"; fi
  COST_DISPLAY=" | ${COST_C}\$${COST_FMT}${RST}"
fi

# ─── 時間（零值隱藏）──────────────────────────────
DURATION_DISPLAY=""
if [ "$DURATION_MS" -gt 0 ] 2>/dev/null; then
  MINS=$((DURATION_MS / 60000))
  SECS=$(((DURATION_MS % 60000) / 1000))
  if [ "$MINS" -gt 0 ] || [ "$SECS" -gt 0 ]; then
    DURATION_DISPLAY=" | ⏱️  ${MINS}m ${SECS}s"
  fi
fi

# ─── Rate Limits ─────────────────────────────────────
rate_color() {
  local pct=$1
  if [ "$pct" -ge 90 ] 2>/dev/null; then printf '%s' "$RED"
  elif [ "$pct" -ge 75 ] 2>/dev/null; then printf '%s' "$ORANGE"
  elif [ "$pct" -ge 50 ] 2>/dev/null; then printf '%s' "$YELLOW"
  else printf '%s' "$GRAY"; fi
}
C5=$(rate_color "$PCT_5H")
C7=$(rate_color "$PCT_7D")
RATE_LIMITS="${C5}5h:${PCT_5H}%${RST} ${C7}7d:${PCT_7D}%${RST}"

# ─── Git 變動（零值隱藏）──────────────────────────
GIT_CHANGES=""
if [ "$ADDITIONS" -gt 0 ] 2>/dev/null || [ "$DELETIONS" -gt 0 ] 2>/dev/null; then
  [ "$ADDITIONS" -gt 0 ] 2>/dev/null && GIT_CHANGES="${GREEN}+${ADDITIONS}${RST}"
  [ "$DELETIONS" -gt 0 ] 2>/dev/null && GIT_CHANGES="${GIT_CHANGES} ${RED}-${DELETIONS}${RST}"
  GIT_CHANGES=" | ${GIT_CHANGES}"
fi

# ─── 輸出 ────────────────────────────────────────────
DATETIME=$(date '+%Y/%m/%d %H:%M')

printf '%b\n' "${CYAN}[${MODEL}]${RST}${CC_VER_DISPLAY} | 📁 ${PROJECT_LINK} | 🌿 ${BRANCH}${DIRTY}${WT}${GIT_CHANGES}"
printf '%b\n' "${BAR} ${PCT_COLOR}${PCT}%${RST}${COST_DISPLAY}${DURATION_DISPLAY} | ${RATE_LIMITS} | 📅 ${RST}${DATETIME}"
