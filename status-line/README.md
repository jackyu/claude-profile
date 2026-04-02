# Claude Code Status Line

自訂兩行狀態列腳本，顯示於 Claude Code 終端機底部。

## 預覽

```
[Opus 4.6] 2.1.90 | 📁 my-project | 🌿 feature/auth* | wt:name | +42 -10
▓▓▓▓░░░░░░ 42% | $1.23 | ⏱️ 5m 12s | 5h:28% 7d:7% | 📅 2026/04/02 14:30
```

## 顯示內容

**第一行**
- `[Model]` ver — 模型名稱與 Claude Code 版號
- `📁 專案` — 可點擊連結至 git remote（OSC 8）
- `🌿 branch*` — 分支名稱，`*` 表示有未提交變更
- `wt:name` — Worktree 名稱（僅在 worktree 中顯示）
- `+N -N` — 新增/刪除行數（零值隱藏）

**第二行**
- `▓░ PCT%` — Context window 漸層進度條（綠→黃→橙→紅，每格獨立 RGB）
- `$X.XX` — 累計費用（零值隱藏；≥$5 黃色、≥$10 紅色）
- `⏱️ Xm Ys` — 工作階段持續時間（零值隱藏）
- `5h:XX% 7d:XX%` — Rate limit 使用比例（≥50% 黃、≥75% 橙、≥90% 紅）
- `📅 日期時間` — 目前日期與時間

## 效能特性

- **單次 jq** — 所有 JSON 欄位一次解析，避免多次 fork
- **Git 快取** — 分支、dirty、diff stats 快取 5 秒（`/tmp/claude-statusline-cache/`）
- **版號快取** — `claude --version` 快取 5 分鐘
- **降級處理** — `jq` 不存在或解析失敗時顯示提示而非報錯

## 需求

- [jq](https://jqlang.github.io/jq/) — JSON 解析工具（缺少時會降級顯示）

## 安裝

```bash
bash status-line/install.sh
```

## 手動安裝

```bash
cp status-line/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

在 `~/.claude/settings.json` 中加入：

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## 測試

```bash
echo '{"model":{"display_name":"Opus 4.6"},"workspace":{"current_dir":"/tmp","project_dir":"/tmp"},"context_window":{"used_percentage":42},"cost":{"total_duration_ms":312000,"total_cost_usd":1.23},"rate_limits":{"five_hour":{"used_percentage":28},"seven_day":{"used_percentage":7}}}' | ~/.claude/statusline.sh
```

## 自訂

直接編輯 `statusline.sh`，常見調整：

- `GRAD_R/G/B` 陣列 — 進度條漸層 RGB 值
- `GIT_CACHE_TTL` / `VERSION_CACHE_TTL` — 快取有效期
- 顏色閾值 — 百分比（70%/90%）、費用（$5/$10）
- `DATETIME` 格式
