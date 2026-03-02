# claude-profile

我的 Claude Code 個人設定與前端開發規範，可快速套用到任何專案。

## 目錄結構

```
├── settings.json        # Claude Code 全域設定（權限、hooks、狀態列）
├── rules/               # 前端開發規範（15 個 .md 檔案）
│   ├── README.md        # Rules 檔案總覽與使用說明
│   └── *.md             # 各維度規範
└── CLAUDE.md            # 專案層級指令
```

## 內容總覽

### settings.json

| 設定 | 說明 |
|------|------|
| `language` | 繁體中文回應 |
| `permissions` | 自動允許 git / ls / test 等常用指令 |
| `hooks.Stop` | 對話結束時桌面通知 |
| `hooks.TaskCompleted` | 任務完成時檢查測試覆蓋率 |
| `statusLine` | 終端底部顯示分支名稱與時間 |

### rules/

15 個前端開發規範，針對 **Next.js App Router + Tailwind CSS + React Query v5 + Vitest / Jest** 技術棧。

詳見 [rules/README.md](rules/README.md)。

## 使用方式

### 套用 settings

```bash
cp settings.json ~/.claude/settings.json
```

### 套用 rules（推薦）

使用互動式安裝腳本，可選擇安裝到 user scope（全域）或 project scope（單一專案）：

```bash
bash install.sh
```

或手動複製：

```bash
# 全域（所有專案共用）
cp rules/*.md ~/.claude/rules/

# 專案（僅該專案生效）
cp rules/*.md your-project/.claude/rules/
```

### 套用 CLAUDE.md 到專案

```bash
cp CLAUDE.md your-project/CLAUDE.md
```

Claude Code 會自動載入 `~/.claude/settings.json`、`.claude/rules/*.md` 和 `CLAUDE.md`。

## 客製化

- 修改 `rules/` 中的檔案以符合你的團隊規範
- 設計原則：從痛點出發、30 行以內、一個檔案一個維度
- 詳見 [rules/summary.md](rules/summary.md)
