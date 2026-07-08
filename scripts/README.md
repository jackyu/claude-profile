# scripts

供 Claude Code command／skill 呼叫的輔助腳本，安裝後位於 `~/.claude/scripts/`。

## gitlab/

以 GitLab REST API 操作 MR 與 issue 的純 shell 腳本，被 `commands/push.md`、`commands/auto-review.md` 等使用。

- `_config.sh` — 共用設定與 `gitlab_api()` 封裝，`source` 用、不直接執行。憑證從 `.env` 或 `~/.claude.json` 讀取，不寫死在腳本內。
- `mr-*.sh`、`issue-*.sh` — 建立／更新／回覆 MR 與 issue 的動作腳本。
- `tests/` — 用 mock curl 與假 `~/.claude.json` 的自包含測試，不會打真實 API。跑法：`bash tests/run_tests.sh`。

## 設定憑證

腳本需要 GitLab token 才能運作，但 token **不進版控**：

```bash
cp gitlab/.env.example gitlab/.env
# 編輯 gitlab/.env 填入 GITLAB_PERSONAL_ACCESS_TOKEN 與 GITLAB_API_URL
```

`.env` 已被根目錄 `.gitignore` 排除。

## 安裝

從 repo 根目錄執行 `./install.sh`，選 `[3] Scripts` 會同步到 `~/.claude/scripts/`（不會覆蓋既有的 `.env`）。
