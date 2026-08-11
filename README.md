# claude-profile

我的 Claude Code 個人設定與前端開發規範，可快速套用到任何專案。

## 目錄結構

```
├── settings.json        # Claude Code 全域設定（權限、hooks、狀態列）
├── commands/            # 自訂 slash 指令
│   ├── start.md         # /start 啟動新開發任務
│   ├── spec.md          # /spec 規格逼問到產出開發 issue
│   ├── cr.md            # /cr 前端 code review（兩軸主幹）
│   ├── push.md          # /push 推送並開立 MR
│   └── auto-review.md   # /auto-review 監聽 MR 自動審查
├── rules/               # 前端開發規範（14 個規範檔 + README）
│   ├── README.md        # Rules 檔案總覽與使用說明
│   └── *.md             # 各維度規範
├── agents/              # 子代理定義（3 個，派工用）
├── playbooks/           # 派工與判斷手冊（按需載入，不佔每次對話的 token）
├── hooks/               # Claude Code hooks 集合
│   ├── coverage-check/         # 任務完成時檢查測試覆蓋率（僅提示、不阻擋）
│   ├── enforce-mr-generator/   # 建 MR 前驗描述是否由 fe-mr-generator 產生
│   ├── gitlab-write-gate/      # GitLab 寫入腳本的 project allowlist 防護
│   └── notify-complete/        # 對話結束時桌面通知與語音提示
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
| `/spec` | 規格逼問到產出前端技術 issue 一條龍（brainstorming → grill → fe-issue），決議寫進 spec 檔、附驗收 gate 與可選 codex 審查 |
| `/cr` | 前端程式碼審查——Spec／Standards 兩軸主幹，加爆炸半徑與無害區對抗挑戰（薄殼，實際流程在 fe-code-review skill） |
| `/push` | 推送當前分支至遠端並建立 GitLab MR（含 title、description、label、assignee） |
| `/auto-review` | 監聽目前 repo 對應的 GitLab 專案新/更新 MR，自動產出 HTML review 並推 Mattermost 通知（自帶迴圈） |

> 指令會引用 `~/.claude/scripts/`、`~/.claude/schedules/` 等外部腳本與 skills，本 repo 僅保存指令定義本身。

### rules/

14 個前端開發規範，針對 **Next.js App Router + Tailwind CSS + React Query v5 + Vitest / Jest** 技術棧。合計 354 行，每檔控制在 40 行以內——這些檔案每個 session 都自動載入，篇幅就是成本。

詳見 [rules/README.md](rules/README.md)。

### agents/

三個子代理定義，用來把工作派出去、讓主對話只收結論。

| Agent | Model | 用途 |
|-------|-------|------|
| `deep-reasoner` | opus | 架構決策、間歇性 bug 根因、演算法設計、trade-off 分析 |
| `code-implementer` | sonnet | 實作與重構，走 TDD 流程 |
| `fast-worker` | sonnet | 樣板、測試、rename、格式化等低模糊度任務 |

三者都開了 `memory: user`，各自寫明「什麼情況該寫 memory」——只有開關沒有觸發條件的話，memory 目錄會一直是空的。

### playbooks/

按需載入的手冊，**不會自動進 context**，所以可以寫得比 rules 詳細。

| 檔案 | 內容 |
|------|------|
| `delegation.md` | 派工對照表、派工三件套、模型名冊、升降級路徑 |
| `judgment.md` | 五條判斷 rubric：何時升級模型、何時算完成、何時該問人、方向錯了的訊號、品質底線 |
| `templates.md` | 五型派工 prompt 模板（搜尋／實作／重構／研究／審查） |
| `maintenance.md` | 規則撰寫原則、膨脹控制觸發條件、季度量測流程 |
| `examples-error-handling.md` | 錯誤處理的完整範例碼（從 rules 抽出來的） |

> 這裡不含 `letter.md` 與 `00-diagnosis.md`——那兩份是本機環境的診斷與個人脈絡紀錄，對別人沒有參考價值。

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

### 套用 rules / agents / playbooks（推薦）

用互動式安裝腳本，選單有六項：

```bash
bash install.sh
```

| 選項 | 安裝到 |
|------|--------|
| `[1]` Rules → user scope | `~/.claude/rules/` |
| `[2]` Rules → project scope | `<project>/.claude/rules/` |
| `[3]` Scripts | `~/.claude/scripts/` |
| `[4]` Output Styles | `~/.claude/output-styles/` |
| `[5]` Agents | `~/.claude/agents/` |
| `[6]` Playbooks | `~/.claude/playbooks/` |

目標目錄已有同類檔案時會先問要不要覆蓋，不會直接蓋掉。

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
- 設計原則：從痛點出發、30 行以內、一個檔案一個維度（完整版見 `~/.claude/playbooks/maintenance.md`）
