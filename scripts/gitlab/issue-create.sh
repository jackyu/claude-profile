#!/usr/bin/env bash
# issue-create.sh — Create a new issue
# Usage: issue-create.sh <project_path_or_id> <title> [options]
#   --description <text>
#   --labels <label1,label2>
#   --assignee-ids <id1,id2>
#   --milestone-id <id>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <project_path_or_id> <title> [--description <text>] [--labels <l1,l2>] [--assignee-ids <id1,id2>] [--milestone-id <id>] [--dry-run]" >&2
  exit 1
fi

PROJECT=$(encode_project "$1")
TITLE="$2"
shift 2

# Build JSON with jq, starting with title
JSON=$(jq -n --arg title "$TITLE" '{title: $title}')

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --description)
      JSON=$(echo "$JSON" | jq --arg v "$2" '. + {description: $v}')
      shift 2
      ;;
    --labels)
      JSON=$(echo "$JSON" | jq --arg v "$2" '. + {labels: $v}')
      shift 2
      ;;
    --assignee-ids)
      JSON=$(echo "$JSON" | jq --arg v "$2" '. + {assignee_ids: ($v | split(",") | map(tonumber))}')
      shift 2
      ;;
    --milestone-id)
      JSON=$(echo "$JSON" | jq --arg v "$2" '. + {milestone_id: ($v | tonumber)}')
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

gitlab_api POST "/projects/$PROJECT/issues" --data "$JSON"
