#!/usr/bin/env bash
# mr-list-for-review.sh — List open MRs in a project where the current user
#   (the token owner) is requested as reviewer (fallback: assignee).
#   Used by the /auto-review command to detect MRs that need reviewing.
#
# Usage: mr-list-for-review.sh <project_path_or_id> [reviewer_username]
#
# Output (stdout, JSON):
#   { "reviewer": "<username>",
#     "mrs": [ { "iid", "title", "author", "draft", "sha", "web_url" }, ... ] }
#
# Notes:
#   - reviewer defaults to the token owner (GET /user).
#   - "sha" is the source-branch head SHA — compare against state to detect new commits.
#   - Filtering (draft / self-authored) is left to the caller so it can report what it skipped.

set -euo pipefail

source "$HOME/.claude/scripts/gitlab/_config.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project_path_or_id> [reviewer_username]" >&2
  exit 1
fi

PROJECT=$(encode_project "$1")
REVIEWER="${2:-}"

if [[ -z "$REVIEWER" ]]; then
  REVIEWER=$(gitlab_api GET "/user" | jq -r '.username')
fi

fetch_mrs() {
  # $1 = filter field (reviewer_username | assignee_username)
  gitlab_api GET "/projects/$PROJECT/merge_requests?state=opened&$1=$REVIEWER&per_page=100"
}

mrs=$(fetch_mrs "reviewer_username")
if [[ "$(jq 'length' <<< "$mrs")" -eq 0 ]]; then
  mrs=$(fetch_mrs "assignee_username")
fi

jq -n --arg reviewer "$REVIEWER" --argjson mrs "$mrs" '
  {
    reviewer: $reviewer,
    mrs: [ $mrs[] | {
        iid,
        title,
        author: (.author.username // .author.name // "unknown"),
        draft: (.draft // .work_in_progress // false),
        sha: (.sha // .diff_refs.head_sha // ""),
        web_url
    } ]
  }
'
