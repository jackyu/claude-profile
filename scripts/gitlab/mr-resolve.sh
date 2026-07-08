#!/usr/bin/env bash
# mr-resolve.sh — Resolve or unresolve an MR discussion thread
# Usage: mr-resolve.sh <project_path_or_id> <mr_iid> <discussion_id> [--unresolve]

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

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <project_path_or_id> <mr_iid> <discussion_id> [--unresolve] [--dry-run]" >&2
  exit 1
fi

PROJECT=$(encode_project "$1")
MR_IID="$2"
DISCUSSION_ID="$3"
RESOLVED="true"

if [[ "${4:-}" == "--unresolve" ]]; then
  RESOLVED="false"
fi

gitlab_api PUT "/projects/$PROJECT/merge_requests/$MR_IID/discussions/$DISCUSSION_ID" \
  --data "$(jq -n --argjson resolved "$RESOLVED" '{resolved: $resolved}')"
