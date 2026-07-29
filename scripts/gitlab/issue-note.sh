#!/usr/bin/env bash
# issue-note.sh — Create a comment on an issue
# Usage: issue-note.sh <project_path_or_id> <issue_iid> <body>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

parse_common_flags "$@"
set -- ${PARSED_ARGS[@]+"${PARSED_ARGS[@]}"}

[[ $# -lt 3 ]] && usage_exit "<project_path_or_id> <issue_iid> <body> [--dry-run]"

PROJECT=$(encode_project "$1")
ISSUE_IID="$2"
BODY="$3"

gitlab_api POST "/projects/$PROJECT/issues/$ISSUE_IID/notes" \
  --data "$(jq -n --arg body "$BODY" '{body: $body}')"
