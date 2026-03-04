# Claude Code Status Line

自訂兩行狀態列腳本，顯示於 Claude Code 終端機底部。

## 預覽

```
[Opus 4.6] | my-project | 🌿 feature/auth | wt:confident-lalande
▓▓▓░░░░░░░ 30% | ⏱️ 5m 12s | 2026/03/04 14:30
```

## 顯示內容

**第一行**
- `[Model 版號]` — 目前使用的模型與版本（如 `[Opus 4.6]`）
- `專案名稱` — 可點擊連結至 git remote（支援 OSC 8 的終端）
- `🌿 分支` — 目前 git 分支
- `wt:名稱` — Git worktree 名稱（僅在 worktree 中顯示）

**第二行**
- `▓░ PCT%` — Context window 使用進度列（綠 → 黃 → 紅）
- `⏱️ Xm Ys` — 工作階段持續時間
- `YYYY/MM/DD HH:MM` — 目前日期時間

## 需求

- [jq](https://jqlang.github.io/jq/) — JSON 解析工具

## 安裝

```bash
bash status-line/install.sh
```

腳本會：
1. 檢查 jq 是否已安裝
2. 複製 `statusline.sh` 至 `~/.claude/statusline.sh`
3. 提示設定 `settings.json`

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

用模擬資料測試腳本輸出：

```bash
echo '{"model":{"id":"claude-opus-4-6","display_name":"Opus"},"workspace":{"current_dir":"/tmp","project_dir":"/tmp"},"context_window":{"used_percentage":42},"cost":{"total_duration_ms":300000}}' | ~/.claude/statusline.sh
```

## 自訂

直接編輯 `statusline.sh` 即可，常見調整：

- 修改 `BAR_WIDTH` 改變進度列寬度
- 修改顏色閾值（預設 70% 黃、90% 紅）
- 調整 `DATETIME` 格式
- 修改 git remote URL 轉換規則（預設支援 GitHub SSH → HTTPS）
