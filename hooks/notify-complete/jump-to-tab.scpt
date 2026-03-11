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
