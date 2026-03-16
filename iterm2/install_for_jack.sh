#!/bin/bash

# ============================================
# Claude Code 完成通知 - Jack 個人化安裝腳本
# ============================================
# 功能：
#   - 系統通知（前景/背景都會顯示）
#   - 語音提示（成功：我做完了喔 / 失敗：喔喔，GG / 等待：是要等多久）
#   - 點擊通知跳轉到對應 iTerm2 分頁
#
# 使用方式：
#   curl -fsSL <url> | bash
#   或
#   bash install_for_jack.sh
# ============================================

set -e

echo "🚀 開始安裝 Claude Code 完成通知..."

# 1. 安裝 terminal-notifier
echo "📦 檢查 terminal-notifier..."
if ! command -v terminal-notifier &> /dev/null; then
    echo "   安裝 terminal-notifier..."
    brew install terminal-notifier
else
    echo "   ✅ terminal-notifier 已安裝"
fi

# 2. 建立目錄
echo "📁 建立 hooks 目錄..."
mkdir -p ~/.claude/hooks

# 3. 建立跳轉腳本
echo "📝 建立 jump-to-tab.scpt..."
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

# 4. 建立通知腳本
echo "📝 建立 notify-complete.sh..."
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

# 5. 更新 settings.json
echo "⚙️  設定 Claude Code hooks..."

SETTINGS_FILE="$HOME/.claude/settings.json"

if [[ -f "$SETTINGS_FILE" ]]; then
    # 檢查是否已有 hooks 設定
    if grep -q '"hooks"' "$SETTINGS_FILE"; then
        echo "   ⚠️  settings.json 已有 hooks 設定，請手動合併以下內容："
        echo '   "hooks": {'
        echo '     "Stop": ['
        echo '       {'
        echo '         "hooks": ['
        echo '           {'
        echo '             "type": "command",'
        echo '             "command": "$HOME/.claude/hooks/notify-complete.sh stop"'
        echo '           }'
        echo '         ]'
        echo '       }'
        echo '     ],'
        echo '     "Notification": ['
        echo '       {'
        echo '         "hooks": ['
        echo '           {'
        echo '             "type": "command",'
        echo '             "command": "$HOME/.claude/hooks/notify-complete.sh notification"'
        echo '           }'
        echo '         ]'
        echo '       }'
        echo '     ]'
        echo '   }'
    else
        # 使用 jq 合併設定（如果有 jq）
        if command -v jq &> /dev/null; then
            jq '. + {
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
            }' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
            echo "   ✅ 已更新 settings.json"
        else
            echo "   ⚠️  請手動將 hooks 設定加入 settings.json"
        fi
    fi
else
    # 建立新的 settings.json
    cat > "$SETTINGS_FILE" << 'EOF'
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
EOF
    echo "   ✅ 已建立 settings.json"
fi

# 6. 測試
echo ""
echo "🧪 測試通知..."
~/.claude/hooks/notify-complete.sh

echo ""
echo "============================================"
echo "✅ 安裝完成！"
echo ""
echo "📋 已安裝："
echo "   • terminal-notifier"
echo "   • ~/.claude/hooks/notify-complete.sh"
echo "   • ~/.claude/hooks/jump-to-tab.scpt"
echo "   • ~/.claude/settings.json (hooks 設定)"
echo ""
echo "🔔 功能："
echo "   • 任務完成時顯示系統通知"
echo "   • 語音提示：成功「我做完了喔」/ 失敗「喔喔，GG」/ 等待「是要等多久」"
echo "   • 點擊通知跳轉到對應 iTerm2 分頁"
echo ""
echo "⚠️  首次使用請確認："
echo "   1. 系統設定 > 通知 > terminal-notifier > 允許通知"
echo "   2. 關閉專注模式（如果有開啟）"
echo "============================================"
