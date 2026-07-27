#!/usr/bin/env bash
# mr-discussion.sh — Create a positioned (inline) discussion on a merge request diff line
# Usage: mr-discussion.sh <project_path_or_id> <mr_iid> --file <path> (--new-line N | --old-line N) \
#   --body <text> [--old-path <p>] [--base-sha <s> --start-sha <s> --head-sha <s>] [--dry-run]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

# --dry-run: strip flag, set DRY_RUN so _config.sh's gitlab_api prints instead of sending
DRY_RUN=0
_args=()
for _a in "$@"; do
  [[ "$_a" == "--dry-run" ]] && { DRY_RUN=1; continue; }
  _args+=("$_a")
done
set -- ${_args[@]+"${_args[@]}"}

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <project_path_or_id> <mr_iid> --file <path> (--new-line N | --old-line N) --body <text> [--old-path <p>] [--base-sha <s> --start-sha <s> --head-sha <s>] [--dry-run]" >&2
  exit 1
fi

PROJECT_RAW="$1"
MR_IID="$2"
shift 2

FILE=""
OLD_PATH=""
NEW_LINE=""
OLD_LINE=""
BODY=""
BASE_SHA=""
START_SHA=""
HEAD_SHA=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)       FILE="$2"; shift 2 ;;
    --old-path)   OLD_PATH="$2"; shift 2 ;;
    --new-line)   NEW_LINE="$2"; shift 2 ;;
    --old-line)   OLD_LINE="$2"; shift 2 ;;
    --body)       BODY="$2"; shift 2 ;;
    --base-sha)   BASE_SHA="$2"; shift 2 ;;
    --start-sha)  START_SHA="$2"; shift 2 ;;
    --head-sha)   HEAD_SHA="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$FILE" ]]; then
  echo "ERROR: --file is required." >&2
  exit 1
fi
if [[ -z "$BODY" ]]; then
  echo "ERROR: --body is required." >&2
  exit 1
fi
if [[ -n "$NEW_LINE" && -n "$OLD_LINE" ]]; then
  echo "ERROR: specify only one of --new-line / --old-line, not both." >&2
  exit 1
fi
if [[ -z "$NEW_LINE" && -z "$OLD_LINE" ]]; then
  echo "ERROR: one of --new-line / --old-line is required." >&2
  exit 1
fi
if [[ -n "$NEW_LINE" && ! "$NEW_LINE" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --new-line must be numeric." >&2
  exit 1
fi
if [[ -n "$OLD_LINE" && ! "$OLD_LINE" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --old-line must be numeric." >&2
  exit 1
fi

PROJECT=$(encode_project "$PROJECT_RAW")

if [[ -z "$OLD_PATH" ]]; then
  OLD_PATH="$FILE"
fi

if [[ -z "$BASE_SHA" || -z "$START_SHA" || -z "$HEAD_SHA" ]]; then
  # 陷阱：GET 要在 command substitution 的 subshell 內覆寫 DRY_RUN=0，
  # 讓 --dry-run 時 GET 仍照跑，且 DRY_RUN=0 不會外洩到下面的 POST。
  if ! MR_JSON=$(DRY_RUN=0; gitlab_api GET "/projects/$PROJECT/merge_requests/$MR_IID"); then
    echo "ERROR: failed to fetch MR $MR_IID for diff_refs." >&2
    exit 1
  fi
  BASE_SHA=$(echo "$MR_JSON" | jq -r '.diff_refs.base_sha // empty')
  START_SHA=$(echo "$MR_JSON" | jq -r '.diff_refs.start_sha // empty')
  HEAD_SHA=$(echo "$MR_JSON" | jq -r '.diff_refs.head_sha // empty')
  if [[ -z "$BASE_SHA" || -z "$START_SHA" || -z "$HEAD_SHA" ]]; then
    echo "ERROR: MR $MR_IID 回應沒有 diff_refs（MR 可能尚無 diff）。" >&2
    exit 1
  fi
fi

# Body 加工（統一強制點）：附隱形標記，供 /push 重推時辨識舊自註解。
# body 直接用 skill 產出的純內容，不加可見前綴。
FULL_BODY="${BODY}
<!-- mr:self-annotation -->"

if [[ -n "$NEW_LINE" ]]; then
  POSITION=$(jq -cn \
    --arg base "$BASE_SHA" --arg start "$START_SHA" --arg head "$HEAD_SHA" \
    --arg new_path "$FILE" --arg old_path "$OLD_PATH" --argjson new_line "$NEW_LINE" \
    '{position_type:"text", base_sha:$base, start_sha:$start, head_sha:$head, new_path:$new_path, old_path:$old_path, new_line:$new_line}')
else
  POSITION=$(jq -cn \
    --arg base "$BASE_SHA" --arg start "$START_SHA" --arg head "$HEAD_SHA" \
    --arg new_path "$FILE" --arg old_path "$OLD_PATH" --argjson old_line "$OLD_LINE" \
    '{position_type:"text", base_sha:$base, start_sha:$start, head_sha:$head, new_path:$new_path, old_path:$old_path, old_line:$old_line}')
fi

PAYLOAD=$(jq -cn --arg body "$FULL_BODY" --argjson position "$POSITION" '{body:$body, position:$position}')

if ! gitlab_api POST "/projects/$PROJECT/merge_requests/$MR_IID/discussions" --data "$PAYLOAD"; then
  echo "HINT: 行號可能不在 MR diff hunk 內（只能註解變更行，行號以 three-dot diff 為準），可改用 mr-note.sh 發整體留言。" >&2
  exit 1
fi
