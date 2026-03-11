# Notify Complete Hook

> Claude Code Stop hook，對話結束時發送桌面通知與語音提示

## 功能

- 對話結束時發送 macOS 桌面通知（透過 terminal-notifier）
- 語音提示完成狀態（透過 `say` 指令，使用 Meijia 語音）
- 自動偵測 transcript 中的錯誤，顯示成功/失敗狀態
- 點擊通知可跳轉至對應的 iTerm2 視窗與 Tab

## 前置條件

- macOS（使用 AppleScript 與 `say` 指令）
- iTerm2（用於視窗跳轉，非必要）
- terminal-notifier：`brew install terminal-notifier`

## 安裝

```bash
# 安裝至 ~/.claude/hooks/
./install.sh
```

安裝後，在 `~/.claude/settings.json` 加入 hook 設定：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/notify-complete.sh"
          }
        ]
      }
    ]
  }
}
```

## 檔案說明

| 檔案 | 用途 |
|------|------|
| `notify-complete.sh` | 主要 hook 腳本 |
| `jump-to-tab.scpt` | AppleScript，點擊通知時跳轉 iTerm2 Tab |
| `install.sh` | 安裝腳本 |

---

*Part of [claude-profile](../../README.md)*
