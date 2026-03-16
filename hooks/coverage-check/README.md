# Coverage Check Hook

> Claude Code Stop hook，任務完成時自動檢查測試覆蓋率

## 功能

- 自動偵測 Vitest / Jest 測試工具
- 執行測試並產出覆蓋率報告
- 比對覆蓋率門檻（預設 Line >= 70%, Branch >= 60%）
- 未達標時列出低覆蓋率檔案
- 非 JS/TS 專案自動跳過

## 安裝

```bash
# 安裝至目標專案
./install.sh /path/to/your/project

# 安裝至當前專案
./install.sh .
```

安裝後，在專案的 `.claude/settings.json` 加入 hook 設定：

```json
{
  "hooks": {
    "Stop": [
      {
        "command": "bash .claude/hooks/coverage-check.sh",
        "description": "Auto-check test coverage on task completion"
      }
    ]
  }
}
```

## 自訂門檻

透過環境變數調整：

```bash
LINE_THRESHOLD=80 BRANCH_THRESHOLD=70 bash .claude/hooks/coverage-check.sh
```

## 前置條件

- 專案需有 `package.json` 且包含 `vitest` 或 `jest` 依賴
- 需安裝對應的 coverage provider（`@vitest/coverage-v8` 或 `istanbul`）

---

*Part of [claude-skills](../../README.md)*
