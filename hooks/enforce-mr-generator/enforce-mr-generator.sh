#!/usr/bin/env bash
# PreToolUse hook：攔截建立/更新 GitLab MR，驗證 description 是否帶 fe-mr-generator 標記。
# 缺標記 → deny，引導先用 fe-mr-generator skill 產生描述。
# ponytail: 驗產物（標記）不驗流程；hook 永遠只是 grep 一個固定字串，skill 格式怎麼改都不誤擋。
#
# 防線分工（2026-08-11 查證後補記，別以為這條沒作用就拿掉）
# ─────────────────────────────────────────────────────
# 這條只掛 mcp__gitLab__create/update_merge_request，所以走 MCP 建 MR 時由它擋。
# 但 /push 走的是 Bash 呼叫 scripts/gitlab/mr-create.sh，**不會觸發這條**——
# 主流程的防線在 mr-create.sh:45-50 與 mr-update.sh:53-57 的 in-script 檢查（缺 marker → exit 1）。
#
# 為什麼不改成 Bash matcher：marker 在 description 檔案裡、不在 command 字串裡，
# hook 得去解析參數再讀檔才驗得到，比 in-script 檢查脆弱又重複。
# 兩條路各自守各自的入口，這樣最省事。
set -euo pipefail

MARKER='<!-- mr:fe-mr-generator -->'

input="$(cat)"

# 用 python3（macOS 既有、免裝 jq）取出 tool_input.description
desc="$(printf '%s' "$input" | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("description", ""))
except Exception:
    pass' 2>/dev/null || true)"

# 有標記 → 放行
if printf '%s' "$desc" | grep -qF "$MARKER"; then
  exit 0
fi

# 缺標記 → deny（exit 0 + JSON 由 stdout 驅動決策）
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"MR 描述未經 fe-mr-generator 產生（缺少驗證標記）。請先用 fe-mr-generator skill 產生 title/description 再建立 MR，不要手寫。"}}
JSON
exit 0
