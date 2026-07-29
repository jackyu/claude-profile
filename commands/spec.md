---
description: 規格逼問到產出前端技術 issue 一條龍（意圖釐清 → grill → fe-issue）
argument-hint: "[PM issue URL | 需求描述 | 留空從對話起手]"
---

# /spec — 規格討論到產出開發 issue

附加參數：$ARGUMENTS

把實作前的三步手動流程收合成一條龍：探索意圖 → 逼問規格 → 產出前端技術 issue。
過程中每個關卡都讀寫同一份 **spec 檔**，讓逼問的決議不會只活在對話記憶裡而流失。

## 你的任務

依以下順序執行。每一步的決議都要回寫 spec 檔，gate 未通過不得往下。

### 1. 解析輸入 + 建立 spec 檔

從 `$ARGUMENTS` 判斷起點：

| 輸入 | 動作 |
|------|------|
| 含 GitLab issue URL | 用 `~/.claude/skills/_shared/fe-mr-common/scripts/issue-get.sh <url>` 抓 PM issue 內容 |
| 一段需求描述 | 直接當作需求起手 |
| 留空 | 從當前對話上下文擷取需求 |

接著在專案內建一份持久 spec 檔 **`.claude/specs/spec-<slug>.md`**（`<slug>` 由需求重點取 kebab-case），骨架如下：

```markdown
# Spec: <需求標題>

## 來源
<PM issue URL / 對話 / 描述原文>

## 決議紀錄
（每解一題就追加一條，格式：問題 → 結論 + 理由）

## 未決問題帳本
（open question → resolution，全部 resolved 才放行產 issue）
- [ ] <尚未解決的問題>
```

放 `.claude/specs/` 而非 scratchpad，是為了讓它**跨 session 持久、可被 `/start` 撈到**當實作 brief（scratchpad 帶 session UUID，換 session 就找不到）。

比照 `.claude/worktrees/` 慣例，確保 `.claude/specs/`（含 `archive/`）已在 `.gitignore`：

```bash
grep -qxF '.claude/specs/' .gitignore || printf '.claude/specs/\n' >> .gitignore
```

後續每個關卡都讀寫這份檔，它就是 grill ↔ fe-issue 之間的正式介面。

### 2. 模糊就先釐清意圖

判斷需求是否成形（有明確目標與範圍）：

- **過於模糊**（只有一句話、無範圍/無目標）→ 先探索意圖：以開放式問題一次一題釐清「要解什麼問題、給誰用、成功長什麼樣、範圍邊界在哪」，提出 2–3 個可行方向讓使用者選，把選定方向與捨棄選項寫進 spec 檔的「決議紀錄」，再進第 3 步。
- **已具體** → 略過，直接逼問。

> grill 適合壓測「已有的計畫」，意圖釐清負責「生出計畫」——次序不要顛倒。

### 3. 逼問規格（自動選模式）

偵測專案根目錄：

```bash
ls CONTEXT.md docs/adr/ 2>/dev/null
```

- 有 `CONTEXT.md` 或 `docs/adr/` → 呼叫 `grill-with-docs`（順手對齊術語、把難反轉的決策寫進 ADR）
- 否則 → 呼叫 `grill-me`

逐題逼問、走完決策樹。**每解一題立即回寫 spec 檔**：

- 有結論 → 寫進「決議紀錄」
- 暫時無解 → 列進「未決問題帳本」（勾選框）

### 4. 產 issue 前驗收 gate

放行條件（全部滿足才繼續）：

- [ ] 「未決問題帳本」中所有項目已 resolved
- [ ] 驗收條件（AC）寫得出來且可測（不是「做好就好」這種無法驗證的描述）
- [ ] API 相依已盤點（哪些既有可複用、哪些需後端新開）

任一不滿足 → **退回第 3 步補逼問**，或向使用者點明缺口請其補答，不得放行。

### 5.（可選）codex 審草稿

用 `AskUserQuestion` 問使用者是否讓 codex 再審一輪規格：

- 選項 a：`交給 codex 審`（Recommended）
- 選項 b：`跳過，直接產 issue`

若選擇審：

- 用 `Agent` 工具，`subagent_type: "codex:codex-rescue"`，prompt 指向 spec 檔絕對路徑，請它對規格做 **adversarial review**：找漏掉的邊界情況、模糊或不可測的 AC、未處理的狀態與錯誤分支、遺漏的 API。
- **不要用** `/codex:review` —— 那支只審 git 工作區的程式碼 diff，無法審 scratchpad 的 markdown 草稿。
- 若 codex 缺席/未認證（companion 報 missing 或 unauthenticated）→ 優雅略過並提示使用者可跑 `/codex:setup`，**不阻斷**主流程。
- 把 codex 回饋折回 spec 檔（新問題進帳本）→ 重跑第 4 步 gate，乾淨後才繼續。

### 6. 交給 fe-issue 產出

用 Skill 工具呼叫 `fe-issue`，並明確傳入：

- spec 檔（`.claude/specs/spec-<slug>.md`）的絕對路徑，告知：**「決議紀錄」即為已澄清的規格，跳過 Phase 1.1 重複澄清**
- PM issue 來源（URL 或內容，若步驟 1 有抓到）

讓 `fe-issue` 直接走它的：架構探索 (1.3) → API 狀態 (1.4) → labels (1.5) → 產前端技術 issue 草稿。

沿用 `fe-issue` 既有行為，由它詢問是否用 `issue-create.sh` 建到 GitLab。

**若有建 GitLab issue**：把 spec 檔改名嵌入 issue iid → `.claude/specs/spec-<NNN>-<slug>.md`，讓 `/start #NNN` 之後能用 `NNN` 精準對上。沒建 issue 則維持 `spec-<slug>.md`。

### 7. 印出交接線索

明確印出下一步 `/start` 指令，讓接續實作不必手動回想：

- 有建 issue → `下一步：/start #NNN`
- 沒建 issue（只有 spec 檔）→ `下一步：/start .claude/specs/spec-<slug>.md`

## 錯誤處理

| 情境 | 處理 |
|------|------|
| `issue-get.sh` 抓取失敗 | 告知使用者，請其改貼 issue 內容後繼續 |
| 需求仍模糊但使用者想直接產 | 提醒風險，仍可由使用者決定略過意圖釐清 |
| gate 未通過 | 列出未滿足項，退回逼問，不產 issue |
| codex 未設定 | 提示 `/codex:setup`，跳過審查步驟繼續 |
| 專案無 CONTEXT.md/ADR | 自動改用 `grill-me`，不報錯 |
