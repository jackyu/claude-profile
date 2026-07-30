# claude-profile

此 repo 存放 Claude Code 的個人設定與前端開發規範。

## 專案結構

- `settings.json` — `~/.claude/settings.json` 的去敏範本（權限、hooks、plugins、狀態列、output style），換機重建的參照依據
- `commands/` — 自訂 slash commands（auto-review、push、spec、start）
- `rules/` — 前端開發規範集合
- `output-styles/` — 自訂 output style（回應語氣規範，進 system prompt）
- `hooks/` — Claude Code hooks 集合（coverage-check 等）
- `status-line/` — 自訂終端狀態列腳本與安裝工具
- `CLAUDE.md` — 本檔案，專案層級指令

## 編輯規則

- 修改 `rules/*.md` 時維持每檔 30 行以內
- 每個檔案聚焦一個維度，不混合主題
- 使用繁體中文撰寫規範內容
- `settings.json` 含註解說明，修改時保留註解
- 修改 `~/.claude/settings.json` 後同步回範本；機敏值（webhook、公司內部 URL）一律用佔位符，不入版控

## Commit 規範

遵守 Conventional Commits，type 使用：
`feat`, `fix`, `docs`, `style`, `refactor`, `add`, `chore`
