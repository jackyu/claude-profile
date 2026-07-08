#!/usr/bin/env bash
# run_tests.sh — Run all GitLab script tests
set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$TEST_DIR/setup.sh"

echo "=== _config.sh: encode_project ==="
{
  # Test: numeric project ID passes through
  result=$(HOME="$FAKE_HOME" bash -c "source '$SCRIPT_DIR/_config.sh'; encode_project 499")
  assert_equals "numeric ID passes through" "499" "$result"

  # Test: path with slashes gets encoded
  result=$(HOME="$FAKE_HOME" bash -c "source '$SCRIPT_DIR/_config.sh'; encode_project 'group/subgroup/project'")
  assert_equals "path slashes encoded to %2F" "group%2Fsubgroup%2Fproject" "$result"

  # Test: simple path
  result=$(HOME="$FAKE_HOME" bash -c "source '$SCRIPT_DIR/_config.sh'; encode_project 'my-group/my-project'")
  assert_equals "simple path encoded" "my-group%2Fmy-project" "$result"
}

echo ""
echo "=== _config.sh: missing config ==="
{
  # Test: missing ~/.claude.json
  BAD_HOME="$TEST_TMP/no-home"
  mkdir -p "$BAD_HOME"
  HOME="$BAD_HOME" bash "$SCRIPT_DIR/mr-note.sh" "proj" 1 "body" 2>"$TEST_TMP/stderr" || true
  stderr=$(cat "$TEST_TMP/stderr")
  assert_contains "error on missing config" "GITLAB_PERSONAL_ACCESS_TOKEN not found" "$stderr"
}

echo ""
echo "=== _config.sh: missing token ==="
{
  # Test: config exists but no token
  NO_TOKEN_HOME="$TEST_TMP/no-token-home"
  mkdir -p "$NO_TOKEN_HOME"
  echo '{"mcpServers":{"gitLab":{"env":{"GITLAB_API_URL":"https://example.com/api/v4"}}}}' > "$NO_TOKEN_HOME/.claude.json"
  HOME="$NO_TOKEN_HOME" bash "$SCRIPT_DIR/mr-note.sh" "proj" 1 "body" 2>"$TEST_TMP/stderr" || true
  stderr=$(cat "$TEST_TMP/stderr")
  assert_contains "error on missing token" "GITLAB_PERSONAL_ACCESS_TOKEN not found" "$stderr"
}

echo ""
echo "=== mr-note.sh ==="
{
  # Test: correct API endpoint and method
  set_curl_response '{"id":100,"body":"test"}' 201
  output=$(run_script mr-note.sh "group/project" 277 "LGTM!")
  curl_call=$(get_last_curl_call)
  assert_contains "uses POST method" "POST" "$curl_call"
  assert_contains "correct endpoint with encoded path" "projects/group%2Fproject/merge_requests/277/notes" "$curl_call"
  assert_contains "includes auth header" "PRIVATE-TOKEN" "$curl_call"
  assert_contains "body in JSON" "LGTM!" "$curl_call"

  # Test: missing args shows usage
  run_script mr-note.sh "group/project" 2>/dev/null || true
  stderr=$(get_stderr)
  assert_contains "shows usage on missing args" "Usage:" "$stderr"
}

echo ""
echo "=== mr-reply.sh ==="
{
  set_curl_response '{"id":200,"type":"DiscussionNote"}' 201
  output=$(run_script mr-reply.sh "group/project" 277 "abc123def" "Fixed in commit")
  curl_call=$(get_last_curl_call)
  assert_contains "correct discussion reply endpoint" "discussions/abc123def/notes" "$curl_call"
  assert_contains "includes body" "Fixed in commit" "$curl_call"

  # Test: missing args
  run_script mr-reply.sh "group/project" 277 2>/dev/null || true
  stderr=$(get_stderr)
  assert_contains "shows usage on missing args" "Usage:" "$stderr"
}

echo ""
echo "=== mr-resolve.sh ==="
{
  # Test: resolve (default)
  set_curl_response '{"id":"abc123","resolved":true}' 200
  output=$(run_script mr-resolve.sh "group/project" 277 "abc123def")
  curl_call=$(get_last_curl_call)
  assert_contains "uses PUT method" "PUT" "$curl_call"
  assert_contains "correct discussion endpoint" "discussions/abc123def" "$curl_call"
  assert_contains "resolved true" "true" "$curl_call"

  # Test: unresolve
  set_curl_response '{"id":"abc123","resolved":false}' 200
  output=$(run_script mr-resolve.sh "group/project" 277 "abc123def" --unresolve)
  curl_call=$(get_last_curl_call)
  assert_contains "resolved false on unresolve" "false" "$curl_call"
}

echo ""
echo "=== mr-approve.sh ==="
{
  set_curl_response '{"id":277,"approved":true}' 201
  output=$(run_script mr-approve.sh 499 277)
  curl_call=$(get_last_curl_call)
  assert_contains "uses POST method" "POST" "$curl_call"
  assert_contains "correct approve endpoint" "projects/499/merge_requests/277/approve" "$curl_call"

  # Test: numeric project ID not encoded
  assert_not_contains "no %2F for numeric ID" "%2F" "$curl_call"
}

echo ""
echo "=== issue-note.sh ==="
{
  set_curl_response '{"id":300}' 201
  output=$(run_script issue-note.sh "group/project" 42 "This is a comment")
  curl_call=$(get_last_curl_call)
  assert_contains "correct issue notes endpoint" "projects/group%2Fproject/issues/42/notes" "$curl_call"
  assert_contains "includes body" "This is a comment" "$curl_call"
}

echo ""
echo "=== issue-create.sh ==="
{
  # Test: basic create
  set_curl_response '{"id":50,"iid":42}' 201
  output=$(run_script issue-create.sh "group/project" "Fix login bug")
  curl_call=$(get_last_curl_call)
  assert_contains "uses POST method" "POST" "$curl_call"
  assert_contains "correct issues endpoint" "projects/group%2Fproject/issues" "$curl_call"
  assert_contains "includes title" "Fix login bug" "$curl_call"

  # Test: with optional flags
  set_curl_response '{"id":51,"iid":43}' 201
  output=$(run_script issue-create.sh "group/project" "New feature" --description "Details here" --labels "bug,frontend")
  curl_call=$(get_last_curl_call)
  assert_contains "includes description" "Details here" "$curl_call"
  assert_contains "includes labels" "bug,frontend" "$curl_call"
}

echo ""
echo "=== error handling ==="
{
  # Test: API error (HTTP 403)
  set_curl_response '{"message":"403 Forbidden"}' 403
  output=$(run_script mr-note.sh "group/project" 277 "test" || true)
  stderr=$(get_stderr)
  assert_contains "stderr shows HTTP error" "ERROR (HTTP 403)" "$stderr"
}

echo ""
echo "=== special characters in body ==="
{
  set_curl_response '{"id":400}' 201
  # Body with quotes and newlines — jq should handle escaping
  output=$(run_script mr-note.sh "group/project" 277 'Line with "quotes" and special <chars> & ampersand')
  curl_call=$(get_last_curl_call)
  assert_contains "body passed to curl" "quotes" "$curl_call"
}

print_summary
