---
description: 規格逼問到產出前端技術 issue 一條龍（意圖釐清 → grill → to-spec 規格書 → fe-issue）
argument-hint: "[PM issue URL | 需求描述 | 留空從對話起手]"
---

# /spec — 規格討論到產出開發 issue

附加參數：$ARGUMENTS

把實作前的手動流程收合成一條龍：探索意圖 → 逼問規格 → 產出規格書 → 產出前端技術 issue。
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
ls CONTEXT.md CONTEXT-MAP.md docs/adr/ 2>/dev/null
```

- 有 `CONTEXT.md`（或 `CONTEXT-MAP.md`，代表 multi-context repo）→ 呼叫 `mattpocock-skills:grilling`，並同時載入 `mattpocock-skills:domain-modeling`：訪談中挑戰與現有術語衝突的用詞、決議一確定就即時回寫 `CONTEXT.md`、符合「難反轉 + 沒背景會看不懂 + 真的權衡過」三條件才寫 ADR。
- 沒有 CONTEXT.md，或現有文件對本需求線索不足 → 只呼叫 `mattpocock-skills:grilling` 做純訪談。

> plugin 的 `grill-with-docs`／`grill-me` 標記為 user-only（`disable-model-invocation`），Skill 工具無法直接呼叫；它們本身是組合皮（前者 = grilling + domain-modeling、後者 = 只跑 grilling），故改用上述底層組合，行為等同。

逐題逼問、走完決策樹。**每解一題立即回寫 spec 檔**：

- 有結論 → 寫進「決議紀錄」
- 暫時無解 → 列進「未決問題帳本」（勾選框）

### 4. 產 issue 前驗收 gate

放行條件（全部滿足才繼續）：

- [ ] 「未決問題帳本」中所有項目已 resolved
- [ ] 驗收條件（AC）寫得出來且可測（不是「做好就好」這種無法驗證的描述）
- [ ] API 相依已盤點（哪些既有可複用、哪些需後端新開）

任一不滿足 → **退回第 3 步補逼問**，或向使用者點明缺口請其補答，不得放行。

### 5. 產規格書（to-spec）

gate 乾淨後，把對話與決議綜合成一份規格書。讀取 plugin 的 to-spec 指示照做（版本用 glob，不寫死版號）：

```bash
ls ~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/*/skills/engineering/to-spec/SKILL.md
```

讀到後依其流程走：**不重新訪談**，綜合本次對話 + spec 檔的「決議紀錄」→ 與使用者確認測試 seams（優先用既有 seam、取最高層、數量越少越好）→ 按其模板產出規格書（Problem Statement／Solution／User Stories／Implementation Decisions／Testing Decisions／Out of Scope／Further Notes）。

本流程對 to-spec 原文的兩處調整（以本節為準）：

- **User Stories 收斂**：只列行為真正不同的分支，同一行為的同義改寫合併成一條。篇幅以「嵌入 issue 後，整份 issue 仍符合 fe-issue 模板頂部的長度判準」為準（判準的實際數字以模板為單一來源），超標先砍重複敘述。
- **產出去向**：規格書只寫入 spec 檔，成為主體區段「## 規格書」（原有的「決議紀錄」「未決問題帳本」保留為附錄，供 `/start` 實作時查考）；GitLab 發佈由第 7 步的 fe-issue 負責，triage label 一併交給它處理。

fallback：glob 找不到 SKILL.md → 提示使用者確認 `mattpocock-skills` plugin 是否安裝，改以 spec 檔的「決議紀錄」作為規格輸入繼續往下走，**不阻斷**主流程。

### 6.（可選）codex 審規格書

用 `AskUserQuestion` 問使用者是否讓 codex 再審一輪完整規格書：

- 選項 a：`交給 codex 審`（Recommended）
- 選項 b：`跳過，直接產 issue`

若選擇審：

- 用 `Agent` 工具，`subagent_type: "codex:codex-rescue"`，prompt 指向 spec 檔絕對路徑，請它對「## 規格書」全文做 **adversarial review**：找漏掉的邊界情況、模糊或不可測的 AC、未處理的狀態與錯誤分支、遺漏的 API。
- **不要用** `/codex:review` —— 那支只審 git 工作區的程式碼 diff，無法審 spec 檔這類非 git diff 的 markdown 草稿。
- 若 codex 缺席/未認證（companion 報 missing 或 unauthenticated）→ 優雅略過並提示使用者可跑 `/codex:setup`，**不阻斷**主流程。
- 把 codex 回饋折回 spec 檔（新問題進帳本）→ 重跑第 4 步 gate，乾淨後才繼續。

### 7. 交給 fe-issue 產出

用 Skill 工具呼叫 `fe-issue`，並明確傳入：

- spec 檔（`.claude/specs/spec-<slug>.md`）的絕對路徑，告知：**「## 規格書」即為已澄清的規格，跳過 Phase 1.1 重複澄清**
- PM issue 來源（URL 或內容，若步驟 1 有抓到）
- **issue 正文只放四塊**（其餘一律省略，讓第一讀者能一眼掃完）：
  1. 關聯需求 ＋ 規格疑問警語
  2. `## 規格書`：只嵌入 Problem Statement／Solution／User Stories 三段
  3. `## 驗收條件（AC）`：覆寫模板的 4 小節結構，合併成**單一清單 5–7 條**——涵蓋功能完成定義、回歸保護、測試門檻（模板固定的測試品質 3 項壓縮成 1–2 條，例：「新增/修改元件附單元測試，覆蓋率（Statements & Branches）≥ 80%」）
  4. `## API 依賴` 表
- **不呈現的區塊**（模板有、但 `/spec` 流程一律省略）：規格書的 Implementation Decisions／Testing Decisions／Out of Scope／Further Notes，以及模板的實作範圍／預估工時／技術備註／功能描述——完整版都在 spec 檔，issue 不重複
- **實作規劃回寫 spec 檔**：fe-issue 照常做架構探索 (1.3) 與 API 盤點 (1.4)，但其產出的「實作範圍／預估工時／技術備註」寫進 spec 檔新增區段 `## 實作規劃`（放在「## 規格書」之後、附錄之前），不進 issue
- **去重規則**：同一資訊只出現一次——根因只在 Problem Statement 講、測試門檻只在 AC 講；發現重複以先出現者為準，刪後者
- Figma 欄位處理：本流程不收集設計稿，fe-issue 的 Phase 1.2 也已跳過。若第 1 步抓到的 PM issue 或對話中出現設計稿連結，就填進「關聯需求」的 Figma 欄位；沒有則整行刪除，不回頭向使用者索取

讓 `fe-issue` 直接走它的：架構探索 (1.3) → API 狀態 (1.4) → labels (1.5) → 產前端技術 issue 草稿。

沿用 `fe-issue` 既有行為，由它詢問是否用 `issue-create.sh` 建到 GitLab。

**若有建 GitLab issue**：把 spec 檔改名嵌入 issue iid → `.claude/specs/spec-<NNN>-<slug>.md`，讓 `/start #NNN` 之後能用 `NNN` 精準對上。沒建 issue 則維持 `spec-<slug>.md`。

### 8. 印出交接線索

明確印出下一步 `/start` 指令，讓接續實作不必手動回想：

- 有建 issue → `下一步：/start #NNN`
- 沒建 issue（只有 spec 檔）→ `下一步：/start .claude/specs/spec-<slug>.md`

順帶預告：`/start` 建好 worktree 後，會先依這份規格書拆成 tracer-bullet 票，再逐票 TDD 實作；實作範圍與工時預估在 spec 檔的「## 實作規劃」區段。

## 錯誤處理

| 情境 | 處理 |
|------|------|
| `issue-get.sh` 抓取失敗 | 告知使用者，請其改貼 issue 內容後繼續 |
| 需求仍模糊但使用者想直接產 | 提醒風險，仍可由使用者決定略過意圖釐清 |
| gate 未通過 | 列出未滿足項，退回逼問，不產 issue |
| codex 未設定 | 提示 `/codex:setup`，跳過審查步驟繼續 |
| 專案無 CONTEXT.md/ADR | 自動改用純 `mattpocock-skills:grilling` 訪談，不報錯 |
| to-spec SKILL.md 找不到 | 提示確認 `mattpocock-skills` plugin 已安裝，改以「決議紀錄」為規格輸入繼續 |
