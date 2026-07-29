#!/usr/bin/env bash
# mr-note.sh — Create a comment on a merge request
# Usage: mr-note.sh <project_path_or_id> <mr_iid> <body>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

parse_common_flags "$@"
set -- ${PARSED_ARGS[@]+"${PARSED_ARGS[@]}"}

[[ $# -lt 3 ]] && usage_exit "<project_path_or_id> <mr_iid> <body> [--dry-run]" "Example: $0 'group/project' 277 'LGTM!'"

PROJECT=$(encode_project "$1")
MR_IID="$2"
BODY="$3"

gitlab_api POST "/projects/$PROJECT/merge_requests/$MR_IID/notes" \
  --data "$(jq -n --arg body "$BODY" '{body: $body}')"
