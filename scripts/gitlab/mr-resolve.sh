#!/usr/bin/env bash
# mr-resolve.sh — Resolve or unresolve an MR discussion thread
# Usage: mr-resolve.sh <project_path_or_id> <mr_iid> <discussion_id> [--unresolve]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

parse_common_flags "$@"
set -- ${PARSED_ARGS[@]+"${PARSED_ARGS[@]}"}

[[ $# -lt 3 ]] && usage_exit "<project_path_or_id> <mr_iid> <discussion_id> [--unresolve] [--dry-run]"

PROJECT=$(encode_project "$1")
MR_IID="$2"
DISCUSSION_ID="$3"
RESOLVED="true"

if [[ "${4:-}" == "--unresolve" ]]; then
  RESOLVED="false"
fi

gitlab_api PUT "/projects/$PROJECT/merge_requests/$MR_IID/discussions/$DISCUSSION_ID" \
  --data "$(jq -n --argjson resolved "$RESOLVED" '{resolved: $resolved}')"
