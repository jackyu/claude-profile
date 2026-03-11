#!/bin/bash

# Claude Code 完成通知腳本
# 功能：發送通知 + 語音提示 + 根據結果顯示不同狀態

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

    # 跳轉腳本路徑（安裝時會一併複製）
    local script_dir="$(cd "$(dirname "$0")" && pwd)"
    local jump_script="$script_dir/jump-to-tab.scpt"

    # 根據結果決定通知內容
    local title
    local message
    local voice_message

    if check_for_errors "$transcript"; then
        # 成功
        title="✅ Claude Code 完成"
        message="專案: ${project_name}"
        voice_message="我完成了"
    else
        # 有錯誤
        title="❌ Claude Code 發生錯誤"
        message="專案: ${project_name} - 請檢查輸出"
        voice_message="發生錯誤，請檢查"
    fi

    # 發送通知
    if [[ -n "$window_id" && -n "$tab_index" && -f "$jump_script" ]]; then
        # 有 iTerm2 資訊，點擊可跳轉
        terminal-notifier \
            -title "$title" \
            -message "$message" \
            -group "claude-code-${session_id}" \
            -execute "osascript '$jump_script' '$window_id' '$tab_index'"
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
