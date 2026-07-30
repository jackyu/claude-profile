#!/usr/bin/env bash
# PreToolUse hook (matcher Bash): gate GitLab review/issue *write* scripts under ~/.claude/scripts/gitlab/.
#   - deny if project not in the mr-review allowlist (projects.json: project_path / project_id)
#   - deny if the iid positional arg is not purely numeric
#   - --dry-run bypasses (prints payload, sends nothing)
#   - non-write commands and read scripts pass through
# NOTE: mr-create.sh / mr-update.sh are intentionally EXEMPT from the allowlist
#   (/push builds MRs across arbitrary projects). Their guard is the fe-mr-generator
#   marker check (in-script) + permissions.ask confirmation + --dry-run.
# Fail-open by design: any parse failure allows (this is a safety net, not the only guard).
# ponytail: grep raw stdin first so 99% of Bash calls never spawn python.
set -euo pipefail

input="$(cat)"

# Fast path: command doesn't reference a gitlab script at all -> allow without python.
if ! printf '%s' "$input" | grep -q 'scripts/gitlab/'; then
  exit 0
fi

printf '%s' "$input" | python3 -c '
import sys, json, shlex, re, os

WRITE_SCRIPTS = {"mr-note.sh","mr-reply.sh","mr-resolve.sh","mr-approve.sh","issue-note.sh","issue-create.sh","mr-discussion.sh","mr-note-update.sh","issue-status.sh"}
IID_SCRIPTS   = {"mr-note.sh","mr-reply.sh","mr-resolve.sh","mr-approve.sh","issue-note.sh","mr-discussion.sh","mr-note-update.sh","issue-status.sh"}

def allow():
    sys.exit(0)

def deny(reason):
    out = {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":reason}}
    print(json.dumps(out, ensure_ascii=False))
    sys.exit(0)

def main():
    data = json.load(sys.stdin)
    cmd = data.get("tool_input", {}).get("command", "")
    if "scripts/gitlab/" not in cmd:
        allow()
    try:
        tokens = shlex.split(cmd)
    except Exception:
        tokens = cmd.split()

    idx = None
    name = None
    for i, tok in enumerate(tokens):
        base = os.path.basename(tok)
        if base in WRITE_SCRIPTS and "gitlab/" in tok:
            idx = i
            name = base
            break
    if idx is None:
        allow()  # references gitlab/ but not a write script (read script, comment, etc.)

    tail = tokens[idx+1:]
    if "--dry-run" in tail:
        allow()

    if not tail:
        deny("GitLab 寫入被擋：缺少 project 參數。")
    project = tail[0]

    projects_path = os.path.expanduser("~/.claude/schedules/mr-review-by-loop/projects.json")
    allowed_paths, allowed_ids = set(), set()
    try:
        with open(projects_path) as f:
            pj = json.load(f)
        for v in pj.values():
            if isinstance(v, dict):
                if v.get("project_path"): allowed_paths.add(v["project_path"])
                if v.get("project_id") is not None: allowed_ids.add(str(v["project_id"]))
    except Exception:
        deny("GitLab 寫入被擋：無法讀取 allowlist（projects.json），保守拒絕。")

    if project not in allowed_paths and project not in allowed_ids:
        listing = "\n".join("  - " + p for p in sorted(allowed_paths))
        deny("GitLab 寫入被擋：專案 \"{}\" 不在 allowlist。合法專案：\n{}\n若確定要對此專案寫入，先加進 projects.json，或用 --dry-run 驗證 payload。".format(project, listing))

    if name in IID_SCRIPTS:
        if len(tail) < 2:
            deny("GitLab 寫入被擋：缺少 iid 參數。")
        iid = tail[1]
        if not re.fullmatch(r"[0-9]+", iid):
            deny("GitLab 寫入被擋：iid 必須為純數字，收到 \"{}\"。".format(iid))

    allow()

try:
    main()
except Exception:
    sys.exit(0)  # fail open on any unexpected error
'
exit 0
