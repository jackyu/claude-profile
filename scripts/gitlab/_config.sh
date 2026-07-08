#!/usr/bin/env bash
# _config.sh — Shared GitLab API configuration
# Source this file; do not execute directly.

set -euo pipefail

# Credentials: prefer ~/.claude/scripts/gitlab/.env, fallback to ~/.claude.json (mcpServers.gitLab.env)
GITLAB_ENV_FILE="$HOME/.claude/scripts/gitlab/.env"
CLAUDE_CONFIG="$HOME/.claude.json"

GITLAB_TOKEN=""
GITLAB_API_URL=""

if [[ -f "$GITLAB_ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$GITLAB_ENV_FILE"
  GITLAB_TOKEN="${GITLAB_PERSONAL_ACCESS_TOKEN:-}"
  GITLAB_API_URL="${GITLAB_API_URL:-}"
fi

if [[ -z "$GITLAB_TOKEN" || -z "$GITLAB_API_URL" ]]; then
  if [[ -f "$CLAUDE_CONFIG" ]]; then
    GITLAB_TOKEN=$(jq -r '.mcpServers.gitLab.env.GITLAB_PERSONAL_ACCESS_TOKEN // empty' "$CLAUDE_CONFIG")
    GITLAB_API_URL=$(jq -r '.mcpServers.gitLab.env.GITLAB_API_URL // empty' "$CLAUDE_CONFIG")
  fi
fi

if [[ -z "$GITLAB_TOKEN" || "$GITLAB_TOKEN" == "null" ]]; then
  echo "ERROR: GITLAB_PERSONAL_ACCESS_TOKEN not found in $GITLAB_ENV_FILE or ~/.claude.json" >&2
  exit 1
fi

if [[ -z "$GITLAB_API_URL" || "$GITLAB_API_URL" == "null" ]]; then
  echo "ERROR: GITLAB_API_URL not found in $GITLAB_ENV_FILE or ~/.claude.json" >&2
  exit 1
fi

# URL-encode a project path (e.g., "group/project" -> "group%2Fproject")
# If input is numeric, pass through as-is
encode_project() {
  local input="$1"
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    echo "$input"
  else
    echo "$input" | sed 's/\//%2F/g'
  fi
}

# Make authenticated GitLab API call
# Usage: gitlab_api <METHOD> <endpoint> [curl_args...]
# Returns: response body + newline + http_code
gitlab_api() {
  local method="$1"
  local endpoint="$2"
  shift 2

  # Dry-run: print method/endpoint/body and return without sending the request.
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    local dr_body="" dr_prev=""
    for dr_arg in "$@"; do
      [[ "$dr_prev" == "--data" ]] && dr_body="$dr_arg"
      dr_prev="$dr_arg"
    done
    echo "[DRY-RUN] $method ${GITLAB_API_URL}${endpoint}"
    echo "[DRY-RUN] body: ${dr_body:-<none>}"
    return 0
  fi

  local response
  response=$(curl -s -w "\n%{http_code}" \
    --request "$method" \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    "$@" \
    "${GITLAB_API_URL}${endpoint}")

  local http_code body
  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')

  if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    echo "$body"
  else
    echo "ERROR (HTTP $http_code): $body" >&2
    return 1
  fi
}
