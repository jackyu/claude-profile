#!/usr/bin/env bash
# mr-approve.sh — Approve a merge request
# Usage: mr-approve.sh <project_path_or_id> <mr_iid>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

parse_common_flags "$@"
set -- ${PARSED_ARGS[@]+"${PARSED_ARGS[@]}"}

[[ $# -lt 2 ]] && usage_exit "<project_path_or_id> <mr_iid> [--dry-run]"

PROJECT=$(encode_project "$1")
MR_IID="$2"

gitlab_api POST "/projects/$PROJECT/merge_requests/$MR_IID/approve"
