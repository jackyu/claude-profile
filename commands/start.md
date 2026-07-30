---
description: 依任務描述自動建立 git worktree 與分支，並切換進入開發環境
---

# /start — 啟動新開發任務

任務描述：$ARGUMENTS

## 你的任務

依以下順序執行：

### 0. 載入 spec brief（決定實作依據）

開工前先把規格帶進 session，避免只拿到一句標題。依優先序：

1. **`$ARGUMENTS` 含 issue ID/URL** → 以 issue 全文為主。
   - URL：`~/.claude/skills/_shared/fe-mr-common/scripts/issue-get.sh <url>`
   - `#NNN`：從 `git remote get-url origin` 解析 project，再 `issue-get.sh <project> NNN`
   - issue 的 title/labels 拿去推導分支 type 與名稱（見步驟 1–2）。
2. **否則 → 找 `/spec` 的持久 spec 檔**（先 active 再 archive）：
   - 帶明確參照（`#NNN` 或 spec 檔路徑）→ 直接定位 `.claude/specs/spec-<NNN>-*.md`、`.claude/specs/archive/spec-<NNN>-*.md` 或該路徑。
   - 無明確參照：先看 active 的 `.claude/specs/*.md`——只有一份 → 直接用；多份 → `AskUserQuestion` 讓使用者選。active 一份都沒有，再看 `.claude/specs/archive/*.md`（續作 session 要的規格書已在首跑時歸檔到這裡，撈得回來就不必重議 seams），同樣是一份直接用、多份就問。
   - **不做模糊文字比對**——認不出就往下一階。
3. **兩者都沒有** → 把 `$ARGUMENTS` 當任務描述；若連描述都沒有，請使用者補述要做什麼。

載入後，把 brief（AC、決議、API 相依）留在 session 當實作依據；**不寫進 worktree**（避免誤 commit）。

**消費即歸檔**：若依據來自 `.claude/specs/` 的 active spec 檔，建立 worktree 後把該檔移到 `.claude/specs/archive/`（不刪、留痕），讓 active 目錄只剩「尚未開工」的 spec。

### 1. 解析分支類型（type）

> 若步驟 0 的 brief 來自 issue：type 優先讀 issue labels（`# type::bug`→`bug/`、`# type::feature`→`feat/`…），分支名用 issue title 推導；抓不到再退回下表關鍵字規則。

從任務描述中偵測關鍵字：

| 關鍵字（任一） | type | 分支前綴 |
|----------------|------|----------|
| 修正、修復、bug、bugfix、錯誤 | `bug` | `bug/` |
| hotfix、緊急、熱修 | `fix` | `fix/` |
| 新增、建立、開發、實作、feat、feature、add | `feat` | `feat/` |

**規則：**
- 若同時匹配 `修正` 與 `hotfix`，以 `hotfix` 為優先（緊急程度高）
- 若無任何關鍵字匹配，預設為 `feat`

### 2. 產生英文分支名稱

- 從任務描述移除觸發關鍵字，剩餘部分翻譯為英文
- 格式：全小寫、snake_case、以底線連接，不含中文或標點
- 長度控制在 3–6 個單字之內，抓核心意圖即可
- 範例：
  - `修正畫面疊字錯誤` → `typo_of_page` → `bug/typo_of_page`
  - `新增購物車結帳流程` → `cart_checkout_flow` → `feat/cart_checkout_flow`
  - `hotfix 登入頁 token 過期` → `login_token_expired` → `fix/login_token_expired`

### 3. 同步遠端基底（避免分支基底汙染）⚠️ 必做

**原則：新分支一律以 `origin/<default>` 為起點，不要從可能過期的本地 `<default>` 切。**
本地 `<default>` 落後或分歧時，從它切出的分支會把不相干 commit 夾進 MR diff。

```bash
# 偵測遠端預設分支（通常是 main），並同步最新狀態
default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
default=${default:-main}
git fetch origin "$default"
```

### 4. 建立 worktree

```bash
branch="<type>/<short-description>"
path=".claude/worktrees/<short-description>"   # 專案無 .claude/ 目錄時改用 .worktrees/

# worktree 與票目錄必須被 ignore（未列入則補上並 commit）
grep -qxF '.claude/worktrees/' .gitignore || printf '.claude/worktrees/\n' >> .gitignore
grep -qxF '.claude/tickets/' .gitignore || printf '.claude/tickets/\n' >> .gitignore

# 分支已存在？有輸出就停在這裡，走步驟 10 詢問，別往下建
git branch --list "$branch"
```

**比不中也先別急著建。** 分支名是「任務描述翻成 3–6 個英文字」生出來的，同一個任務換句話說就生出不同名字；續作 session 若比不中舊分支，舊票會靜默變成孤兒。先掃一眼既有的 worktree 與票目錄（`archive` 不算）：

```bash
git worktree list
ls .claude/tickets/ 2>/dev/null | grep -v '^archive$'
```

- 出現疑似同一任務的 worktree 或票目錄 → `AskUserQuestion` 請使用者確認是不是續作。確認是 → 沿用該分支與 worktree，改走步驟 10「分支已存在」那列的續作路徑，不建新的（`<short-description>` 一併改用舊分支名去掉 type 前綴的那段，worktree 與票目錄才對得上）。
- 都對不上 → 確定是新任務，這時才建：

```bash
# 變數當場重宣告：上面那個 block 的 shell state 不會留到這一次呼叫
branch="<type>/<short-description>"
path=".claude/worktrees/<short-description>"
default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
default=${default:-main}

git worktree add "$path" -b "$branch" "origin/$default"
```

建立後進入新 worktree：偵測 `package.json` / `Cargo.toml` / `requirements.txt` / `go.mod`，
執行對應的相依安裝，並跑 baseline 測試確認起點是綠的。

### 5. 基底乾淨檢查（建立後立即驗證）⚠️ 必做

worktree 建好後，確認新分支的基底乾淨——除了尚未有自己的 commit，
相對 `origin/<default>` 不應該有任何多餘 commit：

```bash
git log --oneline "origin/$default..HEAD"
```

- **輸出為空** → 基底乾淨，可開始開發。
- **有非空輸出**（出現你沒寫的 commit）→ ⚠️ 基底已汙染。明確告知使用者，並建議補救：

  ```bash
  # 把分支重新接到乾淨的遠端基底（<base> = 新分支第一個 commit 的 parent，
  # 初始無 commit 時即目前 HEAD 的多餘起點）
  git rebase --onto "origin/$default" <base>
  ```

  列出多餘的 commit 清單，讓使用者確認後再 rebase，避免帶髒進後續 MR。

### 6. 切換至新 worktree

```bash
cd <worktree-path>
```

### 7. 列出所有 worktree 與當前狀態

```bash
git worktree list
```

並於訊息中明確回報：

- 目前所在目錄（絕對路徑）
- 目前分支名稱
- 基底狀態：相對 `origin/<default>` 無多餘 commit（步驟 5 的檢查結果）
- 其他所有 worktree 的路徑與分支（從 `git worktree list` 取得）
- 一行訊息：`實作依據：<issue #NNN｜spec 檔路徑（已歸檔）｜對話描述>`
- 一行訊息：`準備開發：<原始任務描述>`
- 一行訊息：`拆票：<N 張｜沿用既有 M 張（續作）｜已跳過（micro）>`
- 一行訊息：`下一張：<#NN 票名（in-progress 優先）>`

最後兩行要等第 8 步的結果，拆票完成後補印。

### 8. 拆解 tracer-bullet 票（to-tickets）

把實作依據拆成一組 tracer-bullet 垂直切片票，落成本地票檔，讓實作有序、中斷可續。

**先判斷走哪條路：**

1. **續作**：主 repo 根的 `.claude/tickets/<short-description>/` 已存在 → 這是中斷後重啟，沿用既有票、**不重拆**，直接進第 9 步依票檔狀態續作。
2. **micro**：明顯一張票內就做得完的單點改動（改一處文案、調一個常數、單檔小修）→ 跳過拆票，第 9 步以單票模式依 brief 直接開工。
3. **其餘** → 往下拆票。

讀 plugin 的 to-tickets 指示照做（版本用 glob，不寫死版號）：

```bash
ls ~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/*/skills/engineering/to-tickets/SKILL.md
```

依其流程走完；探索在**新 worktree 內**進行（此時基底最新、baseline 已綠），quiz 環節照走——使用者核可粒度與 blocking edges 之後才落檔。

本流程對 to-tickets 原文的兩處覆寫（以本節為準）：

- **落檔位置**：用 local files 模式，寫到**主 repo 根**的 `.claude/tickets/<short-description>/NN-<slug>.md`（不是 `.scratch/`，也不放進 worktree——比照 brief「不寫進 worktree 避免誤 commit」）。`<short-description>` 與分支、worktree 同名，三者互相對得上；該目錄已於第 4 步納入 `.gitignore`。
- **Status 初始值**：填 `ready`。本地用 `ready → in-progress → done` 三態，取代 `ready-for-agent` 這個 label 語意。票只落本地檔，GitLab 維持單一 issue、不發票。

fallback：glob 找不到 SKILL.md → 提示使用者確認 `mattpocock-skills` plugin 已安裝，改以 brief 直接開工，**不阻斷**主流程。

### 9. 逐票實作（implement）

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

Status 與 AC **即時回寫票檔**，不留到最後批次補——這是中斷續作的唯一依據：新 session 重跑 `/start` 同任務，第 8 步偵測到既有票目錄後，本步驟只憑票檔就重建得出進度。

**全部票 `done` 後**：跑一次完整測試套件與 type-check，輸出乾淨才收工，接著提示使用者可走 `/code-review` 審這批變更、再走 `/finish` 收尾。

### 10. 若執行中發生錯誤

- 分支已存在 → 詢問是否使用既有分支或改名。選用既有分支通常代表這是中斷後重啟：`git worktree list` 中還有對應該分支的 worktree → `cd` 進去，跳過步驟 5–6（基底首跑時已檢查過，人也已經在樹裡）；worktree 不見了 → 用 `git worktree add "$path" "$branch"` 重掛（**既有分支不帶 `-b`**，帶了必 fatal），重掛後補跑步驟 5–6 再繼續。無論哪條，都**仍照步驟 7 回報**——拆票行寫「沿用既有 M 張（續作）」，下一張行讀票目錄、依步驟 9 的選票規則印出，這正是續作者最需要看到的一行；回報完進步驟 8，由它偵測既有票目錄後接步驟 9 續作
- 基底汙染 → 依步驟 5 的補救流程處理
- baseline 測試失敗 → 回報具體錯誤，詢問是否繼續
- `issue-get.sh` 抓取失敗（步驟 0）→ 提示改貼 issue 內容，或改用 `.claude/specs/` 的 spec 檔
- `.claude/specs/` 有多份 spec → `AskUserQuestion` 詢問用哪一份
- to-tickets／implement 的 SKILL.md 找不到（步驟 8／9）→ 提示確認 `mattpocock-skills` plugin 已安裝，退回依 brief 直接開工，不阻斷
- 票檔 Status 與實際進度矛盾（例如標了 `done` 但測試是紅的）→ 以實際驗證結果為準，修正票檔並告知使用者

## 範例

輸入：`/start 修正畫面疊字錯誤`

執行流程：

1. 關鍵字 `修正` → type = `bug`
2. 翻譯「畫面疊字錯誤」→ `typo_of_page`
3. `git fetch origin main`，確認以 `origin/main` 為分支起點
4. 最終分支名：`bug/typo_of_page`
5. 建立 worktree：`git worktree add .claude/worktrees/typo_of_page -b bug/typo_of_page origin/main`
6. 基底乾淨檢查：`git log --oneline origin/main..HEAD` 為空 ✓
7. `cd` 進入
8. 列出：

```
目前目錄：/Users/.../myproject/.claude/worktrees/typo_of_page
目前分支：bug/typo_of_page
基底：origin/main（無多餘 commit）
拆票：已跳過（micro）

所有 worktrees：
  /Users/.../myproject                                  [main]
  /Users/.../myproject/.claude/worktrees/typo_of_page   [bug/typo_of_page]

準備開發：修正畫面疊字錯誤
```
