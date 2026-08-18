---
description: 定位 /spec 建立好的開發 worktree 並接續開發（拆票、TDD 實作）
---

# /start — 接續開發任務

任務描述：$ARGUMENTS

## 你的任務

依以下順序執行：

### 0. 載入 spec brief（決定實作依據）

開工前先把規格帶進 session，避免只拿到一句標題。依優先序：

1. **`$ARGUMENTS` 含 issue ID/URL** → 以 issue 全文為主。
   - URL：`~/.claude/skills/_shared/fe-mr-common/scripts/issue-get.sh <url>`
   - `#NNN`：從 `git remote get-url origin` 解析 project，再 `issue-get.sh <project> NNN`
   - issue 的 title/labels 拿去推導比對用的分支名稱（見步驟 1.2）。
2. **否則 → 找 `/spec` 的持久 spec 檔**（先 active 再 archive）：
   - 帶明確參照（`#NNN` 或 spec 檔路徑）→ 直接定位 `.claude/specs/spec-<NNN>-*.md`、`.claude/specs/archive/spec-<NNN>-*.md` 或該路徑。
   - **目前所在目錄已經是個 linked worktree**（`git rev-parse --show-toplevel` 不等於主 repo 根）→ 先用當前分支名去 `.claude/specs/archive/` 比對檔名（分支名去掉 type 前綴那段多半就是 spec 檔 slug 的一部分）；這個任務的 spec 早在 `/spec` 建 worktree 時就歸檔了，active 目錄這時候大機率是別的任務、**不要套下面「只有一份就直接用」的捷徑**去撿。
   - 無明確參照、也不在既有 worktree 內：先看 active 的 `.claude/specs/*.md`——只有一份 → 直接用；多份 → `AskUserQuestion` 讓使用者選。active 一份都沒有，再看 `.claude/specs/archive/*.md`（續作 session 要的規格書已在首跑時歸檔到這裡，撈得回來就不必重議 seams），同樣是一份直接用、多份就問。
   - **不做模糊文字比對**——認不出就往下一階。
3. **兩者都沒有** → 把 `$ARGUMENTS` 當任務描述；若連描述都沒有，請使用者補述要做什麼。

載入後，把 brief（AC、決議、API 相依）留在 session 當實作依據；**不寫進 worktree**（避免誤 commit）。

### 1. 定位開發用的 worktree

worktree 現在改由 `/spec` 最後一步建立；`/start` 不再建立，只負責找到它、接續開發。

**1.1 快速路徑**：先看目前所在目錄本身是不是一個 linked worktree（非主 repo）：

```bash
git rev-parse --show-toplevel
git worktree list
```

目前所在路徑就出現在 `git worktree list` 的非主 repo 那幾行 → 已經身處目標 worktree，直接取 `git branch --show-current` 當分支名，跳過 1.2–1.3，進第 2 步。

**1.2 否則，算出比對用名稱**（沿用 `/spec` 建立 worktree 當時同一套規則，只為了找、不是為了建）：

> 若步驟 0 的 brief 來自 issue：type 優先讀 issue labels（`# type::bug`→`bug`、`# type::feature`→`feat`…）；抓不到再退回下表關鍵字規則。

| 關鍵字（任一） | type |
|----------------|------|
| 修正、修復、bug、bugfix、錯誤 | `bug` |
| hotfix、緊急、熱修 | `fix` |
| 新增、建立、開發、實作、feat、feature、add | `feat` |

同時匹配 `修正` 與 `hotfix` → 以 `hotfix` 優先；都不匹配 → 預設 `feat`。

從任務描述移除觸發關鍵字，剩餘部分翻譯為英文、全小寫、snake_case，3–6 個單字：

```
name="<type>_<short_description>"   # 例：feat_cart_checkout_flow
```

**1.3 找既有 worktree**：

```bash
git worktree list | grep -- "$name"
```

有 orca-cli 可用時（`[ -f ~/.claude/skills/orca-cli/SKILL.md ] && command -v orca >/dev/null 2>&1 && orca status --json >/dev/null 2>&1`）優先用它查，資訊更完整：

```bash
orca worktree list --json
```

**1.4 判斷結果**：

- **命中** → 若目前不在該路徑，`cd` 進去；進第 2 步。
- **沒命中** → 停下來，不自行代建。告知使用者：這個任務還沒有對應的 worktree，請先跑 `/spec`（它最後一步會問要不要建）；若已經跑過 `/spec` 但比對不中，列出 `git worktree list` 現況，請使用者確認正確的分支或路徑。

### 2. 基底狀態檢查（唯讀，僅回報不阻擋）

worktree 建立當下 `/spec` 已經驗過一次基底乾淨，這裡只是接續開發前的現況快照：

```bash
default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
default=${default:-main}
git log --oneline "origin/$default..HEAD"
```

輸出是自己先前的 commit（續作正常情況）→ 略過；輸出出現陌生 commit → 提醒使用者基底疑似被汙染，建議確認來源後視情況 `rebase --onto`，這裡只回報不自動處理。

### 3. 列出目前狀態

```bash
git worktree list
```

並於訊息中明確回報：

- 目前所在目錄（絕對路徑）
- 目前分支名稱
- 基底狀態：步驟 2 的檢查結果
- 其他所有 worktree 的路徑與分支（從 `git worktree list` 取得）
- 一行訊息：`實作依據：<issue #NNN｜spec 檔路徑（已歸檔）｜對話描述>`
- 一行訊息：`準備開發：<原始任務描述>`
- 一行訊息：`拆票：<N 張｜沿用既有 M 張（續作）｜已跳過（micro）>`
- 一行訊息：`下一張：<#NN 票名（in-progress 優先）>`

最後兩行要等第 5 步的結果，拆票完成後補印。

### 4. 品質護欄偵測（唯讀，只提示不安裝）

跑一次，看這專案的品質關卡齊不齊：

```bash
bash ~/.claude/skills/fe-guardrails/scripts/detect.sh
```

依結果處理：

- **不是 Node 專案** → 腳本會自己說明並正常結束，跳過本步，不必回報
- **全部齊備** → 一行帶過（`品質護欄：齊備`），不展開細節
- **有缺** → 列出缺的項目，問一句「要現在補嗎？」。**問完就繼續往下走**，不要停在這裡等回覆；使用者說要補，才載入 `fe-guardrails` skill 處理

**這步絕不阻擋流程。** 腳本不存在、跑不起來、輸出看不懂——一律跳過並記一行，不得中止 `/start`。

為什麼放在這個位置：worktree 已就緒、還沒開始寫 code，是唯一「補護欄不會跟功能變更混在同一批 diff」的時機。拖到 `/push` 才發現沒有關卡就太晚了。

### 5. 拆解 tracer-bullet 票（to-tickets）

把實作依據拆成一組 tracer-bullet 垂直切片票，落成本地票檔，讓實作有序、中斷可續。

**先判斷走哪條路：**

1. **續作**：主 repo 根的 `.claude/tickets/<name>/` 已存在（`<name>` 即步驟 1 定位到的 worktree 名）→ 這是中斷後重啟，沿用既有票、**不重拆**，直接進第 6 步依票檔狀態續作。
2. **micro**：明顯一張票內就做得完的單點改動（改一處文案、調一個常數、單檔小修）→ 跳過拆票，第 6 步以單票模式依 brief 直接開工。
3. **其餘** → 往下拆票。

讀 plugin 的 to-tickets 指示照做（版本用 glob，不寫死版號）：

```bash
ls ~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/*/skills/engineering/to-tickets/SKILL.md
```

依其流程走完；探索在**worktree 內**進行（基底最新、baseline 已於 `/spec` 建立時驗過綠），quiz 環節照走——使用者核可粒度與 blocking edges 之後才落檔。

本流程對 to-tickets 原文的兩處覆寫（以本節為準）：

- **落檔位置**：用 local files 模式，寫到**主 repo 根**的 `.claude/tickets/<name>/NN-<slug>.md`（不是 `.scratch/`，也不放進 worktree——比照 brief「不寫進 worktree 避免誤 commit」）。`<name>` 與分支、worktree 同名，三者互相對得上；該目錄已於 `/spec` 建立 worktree 時納入 `.gitignore`。
- **Status 初始值**：填 `ready`。本地用 `ready → in-progress → done` 三態，取代 `ready-for-agent` 這個 label 語意。票只落本地檔，GitLab 維持單一 issue、不發票。

fallback：glob 找不到 SKILL.md → 提示使用者確認 `mattpocock-skills` plugin 已安裝，改以 brief 直接開工，**不阻斷**主流程。

### 6. 逐票實作（implement）

讀 plugin 的 implement 指示照做（版本同樣用 glob）：

```bash
ls ~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/*/skills/engineering/implement/SKILL.md
```

它要求的 `/tdd` 直接用 Skill 工具呼叫 `mattpocock-skills:tdd`；seams 以規格書「Testing Decisions」中已與使用者確認者為準（沒有規格書時，開工前先跟使用者議定 seams）。

**選票規則**（首跑與續作同一套，只看票檔）：

1. 有 `Status: in-progress` 的票 → 先做完它。
2. 否則取 **frontier**——blocking edges 指向的票全為 `done` 的 `ready` 票——依編號取最小的一張。
3. 全部票都是 `done` → 進下面的收尾。

micro 模式沒有票檔，把 brief 當單張票走同一個迴圈，略過票檔標記。

**每張票的迴圈：**

1. 開工前先把該票 `Status` 改成 `in-progress`。
2. 用 `mattpocock-skills:tdd` 實作，過程中常跑 type-check 與該票相關的單檔測試。
3. 該票 AC 全數滿足、測試綠 → 勾選票檔的 AC checkbox。
4. `Status` 改成 `done`。
5. commit 到當前分支（conventional commits；一張票至少一個可編譯、測試通過的 commit）。

Status 與 AC **即時回寫票檔**，不留到最後批次補——這是中斷續作的唯一依據：新 session 重跑 `/start` 同任務，第 5 步偵測到既有票目錄後，本步驟只憑票檔就重建得出進度。

**全部票 `done` 後**：跑一次完整測試套件與 type-check，輸出乾淨才收工，接著提示使用者可走 `/code-review` 審這批變更、再走 `/finish` 收尾。

### 7. 若執行中發生錯誤

- 找不到對應 worktree → 已在步驟 1.4 處理並停下，不重複代建；使用者確認正確的分支或路徑後才繼續
- 基底疑似汙染（步驟 2）→ 只回報、列出陌生 commit 清單，交由使用者確認後再決定是否 `rebase --onto`
- `issue-get.sh` 抓取失敗（步驟 0）→ 提示改貼 issue 內容，或改用 `.claude/specs/` 的 spec 檔
- `.claude/specs/` 有多份 spec → `AskUserQuestion` 詢問用哪一份
- to-tickets／implement 的 SKILL.md 找不到（步驟 5／6）→ 提示確認 `mattpocock-skills` plugin 已安裝，退回依 brief 直接開工，不阻斷
- 票檔 Status 與實際進度矛盾（例如標了 `done` 但測試是紅的）→ 以實際驗證結果為準，修正票檔並告知使用者

## 範例

前提：`/spec` 已經在最後一步建好 `.claude/worktrees/bug_typo_of_page`（分支 `bug_typo_of_page`）。

輸入：`/start 修正畫面疊字錯誤`

執行流程：

1. 讀 brief：無 issue／spec 參照，直接用任務描述
2. 目前不在該 worktree 內 → 算比對名稱：關鍵字「修正」→ type = `bug`，翻譯「畫面疊字錯誤」→ `typo_of_page` → `name = bug_typo_of_page`
3. `git worktree list` 比對到 `.claude/worktrees/bug_typo_of_page` → `cd` 進去
4. 基底狀態檢查：`git log --oneline origin/main..HEAD` 沒有陌生 commit ✓
5. 列出：

```
目前目錄：/Users/.../myproject/.claude/worktrees/bug_typo_of_page
目前分支：bug_typo_of_page
基底：origin/main（無陌生 commit）
拆票：已跳過（micro）

所有 worktrees：
  /Users/.../myproject                                       [main]
  /Users/.../myproject/.claude/worktrees/bug_typo_of_page    [bug_typo_of_page]

準備開發：修正畫面疊字錯誤
```
