# claude-profile

我的 Claude Code 個人設定與前端開發規範，可快速套用到任何專案。

## 目錄結構

```
├── settings.json        # Claude Code 全域設定（權限、hooks、狀態列）
├── commands/            # 自訂 slash 指令
│   ├── start.md         # /start 啟動新開發任務
│   ├── push.md          # /push 推送並開立 MR
│   └── auto-review.md   # /auto-review 監聽 MR 自動審查
├── rules/               # 前端開發規範（15 個 .md 檔案）
│   ├── README.md        # Rules 檔案總覽與使用說明
│   └── *.md             # 各維度規範
├── hooks/               # Claude Code hooks 集合
│   ├── coverage-check/  # 任務完成時自動檢查測試覆蓋率
│   └── notify-complete/ # 對話結束時桌面通知與語音提示
├── status-line/         # 自訂終端狀態列
│   ├── statusline.sh
│   └── install.sh
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

### commands/

自訂 slash 指令，安裝後可在任意專案以 `/指令名` 觸發。

| 指令 | 功能 |
|------|------|
| `/start` | 依任務描述自動建立 git worktree 與分支，並切換進入開發環境 |
| `/push` | 推送當前分支至遠端並建立 GitLab MR（含 title、description、label、assignee） |
| `/auto-review` | 監聽目前 repo 對應的 GitLab 專案新/更新 MR，自動產出 HTML review 並推 Mattermost 通知（自帶迴圈） |

> 指令會引用 `~/.claude/scripts/`、`~/.claude/schedules/` 等外部腳本與 skills，本 repo 僅保存指令定義本身。

### rules/

15 個前端開發規範，針對 **Next.js App Router + Tailwind CSS + React Query v5 + Vitest / Jest** 技術棧。

詳見 [rules/README.md](rules/README.md)。

### hooks/

Claude Code hooks 集合，可安裝到任意專案。

| Hook | 觸發時機 | 功能 |
|------|----------|------|
| `coverage-check` | TaskCompleted | 自動執行測試覆蓋率檢查，未達門檻時提示改善 |
| `notify-complete` | Stop | 桌面通知 + 語音提示，支援 iTerm2 Tab 跳轉 |

### status-line/

自訂終端狀態列腳本，顯示 Git 分支名稱與當前時間。

## 使用方式

### 套用 settings

```bash
cp settings.json ~/.claude/settings.json
```

### 安裝自訂指令

```bash
cp commands/*.md ~/.claude/commands/
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

### 安裝 hooks

```bash
# 安裝 coverage-check hook 到目標專案
bash hooks/coverage-check/install.sh /path/to/project

# 安裝 notify-complete hook（全域，安裝至 ~/.claude/hooks/）
bash hooks/notify-complete/install.sh
```

### 安裝 status-line

```bash
bash status-line/install.sh
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
