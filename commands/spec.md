---
description: 規格逼問到開發環境就緒一條龍（意圖釐清 → grill → to-spec 規格書 → fe-issue → 建 worktree）
argument-hint: "[PM issue URL | 需求描述 | 留空從對話起手]"
---

# /spec — 規格討論到開發環境就緒

附加參數：$ARGUMENTS

把實作前的手動流程收合成一條龍：探索意圖 → 逼問規格 → 產出規格書 → 產出前端技術 issue → 詢問並建立開發 worktree。
過程中每個關卡都讀寫同一份 **spec 檔**，讓逼問的決議不會只活在對話記憶裡而流失。

## 你的任務

依以下順序執行。每一步的決議都要回寫 spec 檔，gate 未通過不得往下。

### 1. 解析輸入 + 建立 spec 檔

從 `$ARGUMENTS` 判斷起點：

| 輸入 | 動作 |
|------|------|
| 含 GitLab issue URL | 用 `~/.claude/skills/_shared/fe-mr-common/scripts/issue-get.sh <url>` 抓 PM issue 內容 |
| 既有 spec 檔路徑（`.claude/specs/` 或 `archive/` 下的 `spec-*.md`） | 讀入該檔，**不重建**。已有「## 規格書」區段且第 4 步 gate 條件都乾淨 → 直接跳第 8 步問要不要建 worktree；規格書還沒產出 → 續跑第 3 步；規格書有但還沒建 issue → 續跑第 7 步 |
| 一段需求描述 | 直接當作需求起手 |
| 留空 | 從當前對話上下文擷取需求 |

（這一列是「先不建 worktree」重跑時的入口——第 9 步會把 spec 檔路徑印給使用者，之後直接把該路徑當 `$ARGUMENTS` 帶進來就對得上，不必重新逼問一輪。）

**以下建檔骨架只適用前三種輸入**（issue URL／需求描述／留空）；帶既有 spec 檔路徑的直接讀入既有內容，跳過建檔。

在專案內建一份持久 spec 檔 **`.claude/specs/spec-<slug>.md`**（`<slug>` 由需求重點取 kebab-case），骨架如下：

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

**建到 GitLab 時的固定參數**（覆寫 fe-issue Phase 3 的 label 預設，只在 `/spec` 這條路徑生效，fe-issue skill 本體不動）：

- **適用範圍防呆**：這組固定值是照 <primary-project> 的慣例訂的。目標專案不是 <primary-project> → 停下來問使用者要掛哪些 label、指派給誰，不要照抄。
- **labels 就這四個**，逐字照抄——`# type::` 那個帶 `# ` 前綴，另外三個不帶。專案裡佈滿只差一點的相似項（`# type::Bug`、`# type::bugfix` 這類大小寫或縮寫只差一點的項目），抄錯不會報錯，會靜默建出一個新 label：
  `# type::<擇一>`、`FE`、`product::<product>`、`<team-label>`
  不掛 `workflow::*`；PM issue 的 `$ priority::*` 等其他 label 一律不繼承。
- **`# type::` 擇一**：PM issue 已有 `# type::*` → 沿用同一個；沒有 → 依規格性質判斷（修壞掉的行為→`# type::bug`、新能力→`# type::feature`、既有功能優化→`# type::improvement`、驗證任務→`# type::QA`）；還是判不出來 → `AskUserQuestion` 問使用者，不要猜。
- **assignee**：`~/.claude/scripts/gitlab/user-id.sh jackyu` 取數字 ID 餵給 `--assignee-ids`。

```bash
~/.claude/scripts/gitlab/issue-create.sh "<project>" "<title>" \
  --description "<issue 正文>" \
  --labels "# type::<擇一>,FE,product::<product>,<team-label>" \
  --assignee-ids "$(~/.claude/scripts/gitlab/user-id.sh jackyu)"
```

**建立成功後設狀態**：進度全程走 GitLab 原生 status，不再用 `workflow::*` label 表達。

```bash
~/.claude/scripts/gitlab/issue-status.sh "<project>" <NNN> "Ready to develop"
```

失敗不阻斷——issue 已經建起來了，印警告請使用者手動改即可。這是狀態接力的第一棒：`Ready to develop`（本步驟）→ `Developing`（第 8 步建 worktree 時）→ `Reviewing`（/push）。

**若有建 GitLab issue**：把 spec 檔改名嵌入 issue iid → `.claude/specs/spec-<NNN>-<slug>.md`，讓 `/start #NNN` 之後能用 `NNN` 精準對上。沒建 issue 則維持 `spec-<slug>.md`。

### 8. 詢問並建立開發 worktree

規格與 issue 都就緒了，這是啟動實際開發的時機。用 `AskUserQuestion` 問使用者：

- 選項 a：`現在建立 worktree`（Recommended）
- 選項 b：`先不建，之後再處理`

選 **b** → 跳過本步全部子步驟，直接進第 9 步；第 9 步的交接線索要改成告知使用者之後怎麼觸發（見第 9 步）。

選 **a** → 依序執行：

**8.1 推算分支／worktree 名稱**（全 snake_case，type 與描述用底線連接，不用 slash——見 `~/.claude/rules/git-worktree.md`）：

> 有建 GitLab issue（第 7 步）→ type 優先讀 issue labels（`# type::bug`→`bug`、`# type::feature`／`# type::improvement`→`feat`…）；抓不到再退回下表關鍵字規則，對需求標題／描述判斷。

| 關鍵字（任一） | type |
|----------------|------|
| 修正、修復、bug、bugfix、錯誤 | `bug` |
| hotfix、緊急、熱修 | `fix` |
| 新增、建立、開發、實作、feat、feature、add | `feat` |

同時匹配 `修正` 與 `hotfix` → 以 `hotfix` 優先；都不匹配 → 預設 `feat`。描述部分翻譯為英文、全小寫、snake_case，3–6 個單字：

```
name="<type>_<short_description>"   # 例：feat_landing_page_seo_copy
```

**8.2 同步遠端基底**（新分支一律以 `origin/<default>` 為起點，不從可能落後的本地 `<default>` 切）：

```bash
default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
default=${default:-main}
git fetch origin "$default"
git branch --list "$name"
```

`.claude/worktrees/`、`.claude/tickets/` 未進 `.gitignore` 就先補上：

```bash
grep -qxF '.claude/worktrees/' .gitignore || printf '.claude/worktrees/\n' >> .gitignore
grep -qxF '.claude/tickets/' .gitignore || printf '.claude/tickets/\n' >> .gitignore
```

**8.3 掃描既有 worktree／票，避免重複建立**（同一任務換句話說會生出不同名字，比不中舊 worktree 會讓舊票靜默變孤兒）：

```bash
git worktree list
ls .claude/tickets/ 2>/dev/null | grep -v '^archive$'
```

出現疑似同一任務的 worktree 或票目錄 → `AskUserQuestion` 請使用者確認是不是續作。確認是 → 沿用該分支與 worktree（`name` 改用舊分支名，worktree 與票目錄才對得上），**不建新的**，直接跳到 8.6；都對不上才繼續 8.4。

**8.4 偵測 orca-cli 是否可用，建立 worktree**（有的話優先用，worktree 會一併掛進 Orca 的追蹤——terminal、UI 狀態都連動；偵測不到或 Orca app 沒在跑，就退回 `git worktree add`，不阻斷 `/spec`）：

```bash
if [ -f ~/.claude/skills/orca-cli/SKILL.md ] && command -v orca >/dev/null 2>&1 && orca status --json >/dev/null 2>&1; then
  use_orca=true
else
  use_orca=false
fi
```

- **`use_orca=true`**：先確認 Orca 認得目前這個主 repo checkout（`orca worktree create` 沒帶 `--repo` 時靠 cwd 推斷，主 repo 沒註冊就會靜默失敗或建錯位置）：

  ```bash
  orca worktree current --json
  ```

  正常回傳（`result.worktree` 存在）→ 不必帶 `--repo`；報錯或查無 → 補 `--repo path:$(git rev-parse --show-toplevel)`（`orca repo add` 也會自動註冊）。接著建立，`--prompt` 給明確指令而不是單純的 brief 摘要——新 terminal 的 agent 要被告知「跑 `/start`」才會照票拆解流程走，不會自己即興開工；沒建 issue 時，因為 8.6 會把 spec 檔搬進 `archive/`，這裡先把歸檔後的路徑算出來、直接傳歸檔路徑（檔名不變，`/start` 步驟 0 本來就認 archive 路徑，不受 8.6 執行順序影響）：

  ```bash
  archived_spec=".claude/specs/archive/$(basename "<本次 spec 檔路徑>")"
  prompt="執行 /start #<NNN>"                    # 有建 GitLab issue 時
  # 沒建 issue 則改用：
  # prompt="執行 /start $archived_spec"

  orca worktree create --name "$name" --base-branch "origin/$default" --no-parent \
    [--repo path:<主 repo 絕對路徑，視上一步判斷加不加>] \
    --agent claude --prompt "$prompt" --json
  ```

  從回傳 JSON 讀出實際的 `worktree.path`（覆蓋掉上面推算的路徑）與實際分支名。若 Orca 沒有照 `$name` 原樣建立分支 → **只回報不自動改**：印出實際分支名與預期的 `$name` 不符，讓使用者決定要不要手動更名——在 Orca 背後跑 `git branch -m` 可能讓它的 metadata 對不上實際分支，不擅自處理。建立過程報錯（`orca status`／`orca worktree current` 過了但實際 `create` 失敗）→ 印警告，退回下面 `use_orca=false` 那條路徑，不中止 `/spec`。

- **`use_orca=false`**：

  ```bash
  path=".claude/worktrees/$name"   # 專案無 .claude/ 目錄時改用 .worktrees/
  git worktree add "$path" -b "$name" "origin/$default"
  ```

建立後（無論哪條路徑）：偵測 `package.json` / `Cargo.toml` / `requirements.txt` / `go.mod`，執行對應的相依安裝，並跑 baseline 測試確認起點是綠的；baseline 測試失敗 → 回報具體錯誤，詢問使用者是否仍要繼續。

**8.5 基底乾淨檢查**：

```bash
git log --oneline "origin/$default..HEAD"
```

輸出為空 → 基底乾淨。有非空輸出（陌生 commit）→ ⚠️ 基底已汙染，列出多餘 commit 清單，讓使用者確認後再 `git rebase --onto "origin/$default" <base>`，避免帶髒進後續 MR。

**8.6 消費即歸檔**：把第 1 步建立、本次流程一路寫到現在的 spec 檔從 `.claude/specs/` 移到 `.claude/specs/archive/`（不刪、留痕），讓 active 目錄只剩「尚未開工」的 spec。

**8.7 設定 issue 狀態**：只有第 7 步有建 GitLab issue 才做，`<project>` 沿用同一個來源：

```bash
~/.claude/scripts/gitlab/issue-status.sh "<project>" <NNN> "Developing"
```

失敗不阻斷，印警告請使用者手動改即可。

**8.8 列出目錄路徑**：明確印出新 worktree 的絕對路徑、分支名，以及（若 8.4 用了 orca）新開的 terminal 資訊，讓使用者知道要去哪裡接續。

### 9. 印出交接線索

- 第 8 步建了 worktree → 印出目錄路徑（若 orca 開了新 agent terminal，提示「新 terminal 已在該路徑接續開發」；沒有的話印 `下一步：cd <path> 後執行 /start`）
- 第 8 步使用者選了先不建 → 印出如何之後觸發：`下一步：準備好時重新執行 /spec`，並附上本次的 spec 檔路徑（`.claude/specs/spec-<NNN 或 slug>.md`），讓使用者知道重跑時能直接對上、不必重新逼問一輪

順帶預告：`/start` 進到 worktree 後，會先依這份規格書拆成 tracer-bullet 票，再逐票 TDD 實作；實作範圍與工時預估在 spec 檔的「## 實作規劃」區段。

## 錯誤處理

| 情境 | 處理 |
|------|------|
| `issue-get.sh` 抓取失敗 | 告知使用者，請其改貼 issue 內容後繼續 |
| 需求仍模糊但使用者想直接產 | 提醒風險，仍可由使用者決定略過意圖釐清 |
| gate 未通過 | 列出未滿足項，退回逼問，不產 issue |
| codex 未設定 | 提示 `/codex:setup`，跳過審查步驟繼續 |
| 專案無 CONTEXT.md/ADR | 自動改用純 `mattpocock-skills:grilling` 訪談，不報錯 |
| to-spec SKILL.md 找不到 | 提示確認 `mattpocock-skills` plugin 已安裝，改以「決議紀錄」為規格輸入繼續 |
| issue 建好但 status 設定失敗（第 7、8.7 步） | 不阻斷，印警告請使用者手動改狀態 |
| 目標專案不是 <primary-project>（第 7 步） | 停下來問使用者要掛的 label 與 assignee，不套用固定組 |
| 分支已存在（第 8.2 步） | 詢問是否使用既有分支或改名；使用既有分支時走 8.3 的續作路徑，跳過 8.4 建立 |
| orca 偵測到但實際建立失敗（第 8.4 步） | 印警告，退回 `git worktree add`，不中止 |
| baseline 測試失敗（第 8.4 步） | 回報具體錯誤，詢問使用者是否仍要繼續 |
| 基底汙染（第 8.5 步） | 列出多餘 commit，交由使用者確認後再決定是否 rebase |
