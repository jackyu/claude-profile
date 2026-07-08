#!/usr/bin/env bash
# mr-note.sh — Create a comment on a merge request
# Usage: mr-note.sh <project_path_or_id> <mr_iid> <body>

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
  echo "Usage: $0 <project_path_or_id> <mr_iid> <body> [--dry-run]" >&2
  echo "Example: $0 'group/project' 277 'LGTM!'" >&2
  exit 1
fi

PROJECT=$(encode_project "$1")
MR_IID="$2"
BODY="$3"

gitlab_api POST "/projects/$PROJECT/merge_requests/$MR_IID/notes" \
  --data "$(jq -n --arg body "$BODY" '{body: $body}')"
