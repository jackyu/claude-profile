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
echo "=== mr-discussion.sh ==="
{
  # 顯式 shas + new_line
  set_curl_response '{"id":900}' 201
  output=$(run_script mr-discussion.sh "group/project" 277 \
    --file "src/a.ts" --new-line 42 --body "測試註解" \
    --base-sha "aaa" --start-sha "bbb" --head-sha "ccc")
  curl_call=$(get_last_curl_call)
  assert_contains "posts to discussions endpoint" "merge_requests/277/discussions" "$curl_call"
  assert_contains "includes position_type text" "position_type" "$curl_call"
  assert_contains "includes base_sha" "aaa" "$curl_call"
  assert_contains "includes new_path" "src/a.ts" "$curl_call"
  assert_contains "includes new_line" "\"new_line\":42" "$curl_call"
  assert_not_contains "no old_line when new-line given" "old_line" "$curl_call"

  # --old-line 變體
  set_curl_response '{"id":901}' 201
  output=$(run_script mr-discussion.sh "group/project" 277 \
    --file "src/b.ts" --old-line 10 --body "刪除原因" \
    --base-sha "aaa" --start-sha "bbb" --head-sha "ccc")
  curl_call=$(get_last_curl_call)
  assert_contains "includes old_line" "\"old_line\":10" "$curl_call"
  assert_not_contains "no new_line when old-line given" "new_line" "$curl_call"

  # 省略 shas -> 先 GET 再 POST
  set_curl_response '{"iid":277,"diff_refs":{"base_sha":"gaa","start_sha":"gbb","head_sha":"gcc"}}' 200
  output=$(run_script mr-discussion.sh "group/project" 277 \
    --file "src/c.ts" --new-line 5 --body "取自 diff_refs")
  curl_call=$(get_last_curl_call)
  assert_contains "GET fetches MR for diff_refs" "GET" "$curl_call"
  assert_contains "GET endpoint correct" "merge_requests/277" "$curl_call"
  assert_contains "POST uses fetched base_sha" "gaa" "$curl_call"
  assert_contains "POST uses fetched start_sha" "gbb" "$curl_call"
  assert_contains "POST uses fetched head_sha" "gcc" "$curl_call"

  # HTTP 400 -> stderr 含 HTTP 400 與 diff hunk 提示（用顯式 shas 跳過 GET）
  set_curl_response '{"message":"400 Bad Request"}' 400
  output=$(run_script mr-discussion.sh "group/project" 277 \
    --file "src/d.ts" --new-line 999 --body "行號錯誤" \
    --base-sha "aaa" --start-sha "bbb" --head-sha "ccc" || true)
  stderr=$(get_stderr)
  assert_contains "stderr shows HTTP 400" "HTTP 400" "$stderr"
  assert_contains "stderr shows diff hunk hint" "diff hunk" "$stderr"

  # 參數驗證：缺兩個行號 flag
  output=$(run_script mr-discussion.sh "group/project" 277 --file "src/e.ts" --body "x" 2>/dev/null || true)
  stderr=$(get_stderr)
  assert_contains "errors when no line flag given" "new-line" "$stderr"

  # 參數驗證：同時給兩個行號 flag
  output=$(run_script mr-discussion.sh "group/project" 277 --file "src/e.ts" --new-line 1 --old-line 2 --body "x" 2>/dev/null || true)
  stderr=$(get_stderr)
  assert_contains "errors when both line flags given" "only one" "$stderr"

  # 參數驗證：缺 positional
  output=$(run_script mr-discussion.sh "group/project" 2>/dev/null || true)
  stderr=$(get_stderr)
  assert_contains "shows usage on missing args" "Usage:" "$stderr"

  # body 加工
  set_curl_response '{"id":902}' 201
  output=$(run_script mr-discussion.sh "group/project" 277 \
    --file "src/f.ts" --new-line 1 --body "純內容" \
    --base-sha "aaa" --start-sha "bbb" --head-sha "ccc")
  curl_call=$(get_last_curl_call)
  assert_contains "body kept as-is" "純內容" "$curl_call"
  assert_not_contains "no author-note prefix" "作者註" "$curl_call"
  assert_contains "body suffixed with self-annotation marker" "mr:self-annotation" "$curl_call"

  # 省略 shas，GET 失敗（如 404）-> 自訂錯誤訊息、exit 1
  set_curl_response '{"message":"404 Not Found"}' 404
  output=$(run_script mr-discussion.sh "group/project" 277 \
    --file "src/g.ts" --new-line 1 --body "取不到 diff_refs" || true)
  stderr=$(get_stderr)
  assert_contains "GET failure shows custom error" "failed to fetch MR" "$stderr"

  # 省略 shas，GET 成功但 diff_refs 缺欄位（// empty 避免拿到字面 "null"）-> 空值報錯
  set_curl_response '{"iid":277,"diff_refs":{"start_sha":"gbb","head_sha":"gcc"}}' 200
  output=$(run_script mr-discussion.sh "group/project" 277 \
    --file "src/h.ts" --new-line 1 --body "diff_refs 不完整" || true)
  stderr=$(get_stderr)
  assert_contains "missing diff_refs field errors out" "沒有 diff_refs" "$stderr"
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
