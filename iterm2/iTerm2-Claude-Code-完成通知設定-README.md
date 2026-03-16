# iTerm2 + Claude Code 完成通知設定

當 Claude Code 任務完成時，發送 macOS 系統通知，點擊通知可直接跳轉到對應的 iTerm2 Tab。

## 功能

| 功能 | 說明 |
|------|------|
| 系統通知 | 前景/背景都會顯示通知 |
| 語音提示 | 成功：「我做完了喔」/ 失敗：「喔喔，GG」/ 等待：「是要等多久」 |
| 結果判斷 | 自動檢查 transcript 中的錯誤關鍵字 |
| 等待通知 | Claude 需要使用者操作時語音提醒 |
| 點擊跳轉 | 點擊通知跳轉到對應 iTerm2 分頁 |

## 前置需求

- macOS
- [Homebrew](https://brew.sh/)
- [iTerm2](https://iterm2.com/)
- [Claude Code](https://claude.ai/code)

---

## 一鍵安裝

```bash
bash install_for_jack.sh
```

腳本會自動：
1. 安裝 `terminal-notifier`（透過 Homebrew）
2. 建立 `~/.claude/hooks/` 目錄
3. 建立通知腳本和跳轉腳本
4. 更新 `~/.claude/settings.json`（智慧合併，不覆蓋現有設定）
5. 執行測試通知

---

## 安裝後設定

### 1. 允許通知權限

首次執行後，請確認：

1. 打開 **系統設定** → **通知**
2. 找到 **terminal-notifier**
3. 設定：
   - 允許通知：✅ 開啟
   - 通知樣式：**橫幅** 或 **提示**

### 2. 關閉專注模式

如果開啟了專注模式，通知可能會被攔截。

---

## 檔案結構

安裝完成後會建立以下檔案：

```
~/.claude/
├── settings.json              # Claude Code hook 設定
└── hooks/
    ├── notify-complete.sh     # 通知腳本（主程式）
    └── jump-to-tab.scpt       # AppleScript 跳轉腳本
```

---

## 自訂設定

### 更換語音

編輯 `~/.claude/hooks/notify-complete.sh`，修改語音設定：

```bash
# 目前使用 Meijia（美佳，台灣中文女聲）
say -v Meijia "$voice_message" &

# 可選其他中文語音：
# say -v Tingting "$voice_message" &  # 婷婷，大陸中文
# say -v Sinji "$voice_message" &     # 善怡，香港粵語
```

查看所有可用語音：

```bash
say -v '?' | grep zh
```

### 更換語音內容

編輯 `~/.claude/hooks/notify-complete.sh`，修改：

```bash
voice_message="我做完了喔"    # 成功時的語音
voice_message="喔喔，GG"     # 失敗時的語音
voice_message="是要等多久"    # 等待使用者操作時的語音
```

### 只在背景時通知

如果只想在 iTerm2 不在前景時才發送通知，在 `notify-complete.sh` 的 `main()` 函數開頭加入：

```bash
# 檢查 iTerm2 是否在前景
is_iterm_active() {
    local active_app=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true')
    [[ "$active_app" == "iTerm2" ]]
}

main() {
    # 如果 iTerm2 在前景，不發送通知
    if is_iterm_active; then
        return 0
    fi

    # ... 其餘邏輯
}
```

---

## 疑難排解

### 通知沒有出現

1. 檢查通知權限：系統設定 → 通知 → terminal-notifier
2. 確認專注模式已關閉
3. 測試 terminal-notifier：
   ```bash
   terminal-notifier -title "測試" -message "這是測試"
   ```

### 點擊通知沒反應

測試 AppleScript：

```bash
osascript -e 'tell application "iTerm2" to activate'
```

### Hook 沒有觸發

1. 確認 settings.json 語法正確：
   ```bash
   cat ~/.claude/settings.json | jq .
   ```
2. 確認腳本有執行權限：
   ```bash
   chmod +x ~/.claude/hooks/notify-complete.sh
   ```

---

## 手動安裝

如果一鍵安裝失敗，可以手動執行以下步驟：

### Step 1: 安裝 terminal-notifier

```bash
brew install terminal-notifier
```

### Step 2: 建立目錄

```bash
mkdir -p ~/.claude/hooks
```

### Step 3: 建立 AppleScript 跳轉腳本

```bash
cat > ~/.claude/hooks/jump-to-tab.scpt << 'EOF'
on run argv
    if (count of argv) < 2 then
        tell application "iTerm2" to activate
        return
    end if

    set targetWindowId to item 1 of argv
    set targetTabIndex to item 2 of argv as integer

    tell application "iTerm2"
        activate

        -- 遍歷所有視窗找到目標
        repeat with w in windows
            try
                set wId to id of w as string
                if wId = targetWindowId then
                    -- 選擇對應的 tab
                    set targetTab to item targetTabIndex of tabs of w
                    select targetTab
                    return
                end if
            end try
        end repeat

        -- 如果找不到特定視窗，至少把 iTerm2 帶到前景
    end tell
end run
EOF
```

### Step 4: 建立通知腳本

```bash
cat > ~/.claude/hooks/notify-complete.sh << 'EOF'
#!/bin/bash

# Claude Code 完成通知腳本
# 功能：發送通知 + 語音提示 + 根據結果顯示不同狀態
# 用法：notify-complete.sh [stop|notification]

EVENT_TYPE="${1:-stop}"

# 取得當前 iTerm2 視窗和 Tab 資訊
get_iterm_info() {
    osascript << 'APPLESCRIPT'
tell application "iTerm2"
    set currentWindow to current window
    set windowId to id of currentWindow
    set currentTab to current tab of currentWindow
    set tabList to tabs of currentWindow
    set tabIndex to 1
    repeat with i from 1 to count of tabList
        if item i of tabList is currentTab then
            set tabIndex to i
            exit repeat
        end if
    end repeat
    return (windowId as string) & "|" & (tabIndex as string)
end tell
APPLESCRIPT
}

# 檢查是否有錯誤
check_for_errors() {
    local transcript="$1"

    # 如果 transcript 檔案存在，檢查是否有錯誤關鍵字
    if [[ -f "$transcript" ]]; then
        # 檢查常見的錯誤模式
        if grep -qiE "(error|failed|exception|fatal|panic)" "$transcript" 2>/dev/null; then
            return 1  # 有錯誤
        fi
    fi
    return 0  # 沒有錯誤
}

# 主邏輯
main() {
    local session_id="${CLAUDE_SESSION_ID:-unknown}"
    local transcript="${CLAUDE_TRANSCRIPT:-}"
    local cwd="${PWD:-}"
    local project_name=$(basename "$cwd")

    # 取得 iTerm2 資訊
    local iterm_info=$(get_iterm_info 2>/dev/null)
    local window_id=$(echo "$iterm_info" | cut -d'|' -f1)
    local tab_index=$(echo "$iterm_info" | cut -d'|' -f2)

    # 根據事件類型和結果決定通知內容
    local title
    local message
    local voice_message

    if [[ "$EVENT_TYPE" == "notification" ]]; then
        # 等待使用者操作
        title="⏳ Claude Code 等待中"
        message="專案: ${project_name} - 需要你的操作"
        voice_message="是要等多久"
    elif check_for_errors "$transcript"; then
        # 成功
        title="✅ Claude Code 完成"
        message="專案: ${project_name}"
        voice_message="我做完了喔"
    else
        # 有錯誤
        title="❌ Claude Code 發生錯誤"
        message="專案: ${project_name} - 請檢查輸出"
        voice_message="喔喔，GG"
    fi

    # 發送通知
    if [[ -n "$window_id" && -n "$tab_index" ]]; then
        # 有 iTerm2 資訊，點擊可跳轉
        terminal-notifier \
            -title "$title" \
            -message "$message" \
            -group "claude-code-${session_id}" \
            -execute "osascript '$HOME/.claude/hooks/jump-to-tab.scpt' '$window_id' '$tab_index'"
    else
        # 沒有 iTerm2 資訊，點擊只啟動 iTerm2
        terminal-notifier \
            -title "$title" \
            -message "$message" \
            -group "claude-code-${session_id}" \
            -activate "com.googlecode.iterm2"
    fi

    # 語音提示
    say -v Meijia "$voice_message" &
}

main "$@"
EOF

chmod +x ~/.claude/hooks/notify-complete.sh
```

### Step 5: 設定 Claude Code Hook

編輯 `~/.claude/settings.json`，加入 hooks 設定：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/notify-complete.sh stop"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/notify-complete.sh notification"
          }
        ]
      }
    ]
  }
}
```

**如果已有 settings.json**，請手動合併 hooks 區塊。

### Step 6: 測試

```bash
~/.claude/hooks/notify-complete.sh
```

---

## 解除安裝

```bash
# 刪除腳本
rm -f ~/.claude/hooks/notify-complete.sh
rm -f ~/.claude/hooks/jump-to-tab.scpt

# 從 settings.json 移除 hooks 設定（手動編輯）
```

---

## License

MIT
