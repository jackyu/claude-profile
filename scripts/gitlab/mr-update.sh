#!/usr/bin/env bash
# mr-update.sh — Update a merge request's title/description
# Usage: mr-update.sh <project_path_or_id> <mr_iid> [options]
#   --title <text>
#   --description <text>   (if given, must contain the fe-mr-generator marker)
#   --draft                (prefix title with "Draft: ")
#   --dry-run

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

MARKER='<!-- mr:fe-mr-generator -->'

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <project_path_or_id> <mr_iid> [--title <t>] [--description <d>] [--draft] [--dry-run]" >&2
  exit 1
fi

PROJECT=$(encode_project "$1")
MR_IID="$2"
shift 2

DRY_RUN=0
DRAFT=0
TITLE=""
DESCRIPTION=""
HAS_TITLE=0
HAS_DESC=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)        TITLE="$2"; HAS_TITLE=1; shift 2 ;;
    --description)  DESCRIPTION="$2"; HAS_DESC=1; shift 2 ;;
    --draft)        DRAFT=1; shift ;;
    --dry-run)      DRY_RUN=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ "$HAS_TITLE" == "0" && "$HAS_DESC" == "0" ]]; then
  echo "ERROR: nothing to update (provide --title and/or --description)." >&2
  exit 1
fi

# If description provided, enforce fe-mr-generator marker.
if [[ "$HAS_DESC" == "1" ]]; then
  if ! printf '%s' "$DESCRIPTION" | grep -qF "$MARKER"; then
    echo "ERROR: MR description is missing the fe-mr-generator marker." >&2
    echo "先執行 fe-mr-generator skill 產生描述，不要手寫。" >&2
    exit 1
  fi
fi

if [[ "$DRAFT" == "1" && "$HAS_TITLE" == "1" ]]; then
  TITLE="Draft: $TITLE"
fi

JSON='{}'
if [[ "$HAS_TITLE" == "1" ]]; then
  JSON=$(echo "$JSON" | jq --arg v "$TITLE" '. + {title: $v}')
fi
if [[ "$HAS_DESC" == "1" ]]; then
  JSON=$(echo "$JSON" | jq --arg v "$DESCRIPTION" '. + {description: $v}')
fi

gitlab_api PUT "/projects/$PROJECT/merge_requests/$MR_IID" --data "$JSON"
