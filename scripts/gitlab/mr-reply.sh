#!/usr/bin/env bash
# mr-reply.sh — Reply to an existing MR discussion thread
# Usage: mr-reply.sh <project_path_or_id> <mr_iid> <discussion_id> <body>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

parse_common_flags "$@"
set -- ${PARSED_ARGS[@]+"${PARSED_ARGS[@]}"}

[[ $# -lt 4 ]] && usage_exit "<project_path_or_id> <mr_iid> <discussion_id> <body> [--dry-run]"

PROJECT=$(encode_project "$1")
MR_IID="$2"
DISCUSSION_ID="$3"
BODY="$4"

gitlab_api POST "/projects/$PROJECT/merge_requests/$MR_IID/discussions/$DISCUSSION_ID/notes" \
  --data "$(jq -n --arg body "$BODY" '{body: $body}')"
