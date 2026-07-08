#!/usr/bin/env bash
# setup.sh — Test harness for GitLab scripts
# Creates a fake ~/.claude.json and a mock curl to intercept API calls.

set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_DIR="$(dirname "$TEST_DIR")"

# --- Test counters ---
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# --- Temp directory for test fixtures ---
TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

# --- Create fake ~/.claude.json ---
FAKE_HOME="$TEST_TMP/fakehome"
mkdir -p "$FAKE_HOME"
cat > "$FAKE_HOME/.claude.json" <<'FAKEJSON'
{
  "mcpServers": {
    "gitLab": {
      "env": {
        "GITLAB_PERSONAL_ACCESS_TOKEN": "glpat-test-token-12345",
        "GITLAB_API_URL": "https://gitlab.example.com/api/v4"
      }
    }
  }
}
FAKEJSON

# --- Mock curl ---
# Captures all arguments to a log file and returns a configurable response.
CURL_LOG="$TEST_TMP/curl_calls.log"
CURL_RESPONSE_BODY='{"id": 1, "status": "ok"}'
CURL_RESPONSE_CODE="201"

mock_curl_bin="$TEST_TMP/bin"
mkdir -p "$mock_curl_bin"
cat > "$mock_curl_bin/curl" <<'MOCKCURL'
#!/usr/bin/env bash
# Mock curl: logs args and returns configured response
LOG_FILE="__CURL_LOG__"
RESPONSE_BODY_FILE="__TEST_TMP__/curl_response_body"
RESPONSE_CODE_FILE="__TEST_TMP__/curl_response_code"

echo "$@" >> "$LOG_FILE"

body="${MOCK_CURL_BODY:-$(cat "$RESPONSE_BODY_FILE" 2>/dev/null || echo '{"id":1}')}"
code="${MOCK_CURL_CODE:-$(cat "$RESPONSE_CODE_FILE" 2>/dev/null || echo '201')}"

# Check if -w flag is present (for format string)
has_write_out=false
for arg in "$@"; do
  if [[ "$arg" == *"%{http_code}"* ]]; then
    has_write_out=true
    break
  fi
done

if $has_write_out; then
  printf '%s\n%s' "$body" "$code"
else
  echo "$body"
fi
MOCKCURL

# Replace placeholders in mock curl
sed -i '' "s|__CURL_LOG__|$CURL_LOG|g" "$mock_curl_bin/curl"
sed -i '' "s|__TEST_TMP__|$TEST_TMP|g" "$mock_curl_bin/curl"
chmod +x "$mock_curl_bin/curl"

# Set default response
echo "$CURL_RESPONSE_BODY" > "$TEST_TMP/curl_response_body"
echo "$CURL_RESPONSE_CODE" > "$TEST_TMP/curl_response_code"

# --- Helper: set mock curl response ---
set_curl_response() {
  local body="$1"
  local code="${2:-201}"
  echo "$body" > "$TEST_TMP/curl_response_body"
  echo "$code" > "$TEST_TMP/curl_response_code"
}

# --- Helper: get last curl call ---
# run_script clears the log before each call, so the whole log is the last call.
# (--data bodies built by jq are multi-line, so tail -n1 would truncate them.)
get_last_curl_call() {
  cat "$CURL_LOG" 2>/dev/null || echo ""
}

# --- Helper: clear curl log ---
clear_curl_log() {
  > "$CURL_LOG"
}

# --- Helper: run a script with mocked environment ---
run_script() {
  local script_name="$1"
  shift
  clear_curl_log
  HOME="$FAKE_HOME" PATH="$mock_curl_bin:$PATH" \
    bash "$SCRIPT_DIR/$script_name" "$@" 2>"$TEST_TMP/stderr"
}

# --- Helper: get stderr output ---
get_stderr() {
  cat "$TEST_TMP/stderr" 2>/dev/null || echo ""
}

# --- Assertion helpers ---
assert_equals() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $description"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  FAIL: $description"
    echo "    expected: $expected"
    echo "    actual:   $actual"
  fi
}

assert_contains() {
  local description="$1"
  local needle="$2"
  local haystack="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$haystack" == *"$needle"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $description"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  FAIL: $description"
    echo "    expected to contain: $needle"
    echo "    actual: $haystack"
  fi
}

assert_not_contains() {
  local description="$1"
  local needle="$2"
  local haystack="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$haystack" != *"$needle"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $description"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  FAIL: $description"
    echo "    expected NOT to contain: $needle"
    echo "    actual: $haystack"
  fi
}

assert_exit_code() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $description"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  FAIL: $description (expected exit $expected, got $actual)"
  fi
}

# --- Summary ---
print_summary() {
  echo ""
  echo "================================"
  echo "Tests: $TESTS_RUN | Passed: $TESTS_PASSED | Failed: $TESTS_FAILED"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "STATUS: FAILED"
    exit 1
  else
    echo "STATUS: ALL PASSED"
    exit 0
  fi
}
