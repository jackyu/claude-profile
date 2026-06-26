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
   - 無明確參照：`.claude/specs/*.md` 只有一份 → 直接用；多份 → `AskUserQuestion` 讓使用者選。
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

**問題背景**：直接從本地 `main` 切分支時，若本地 `main` 落後或分歧於 `origin/main`，
新分支會夾帶一堆「本地 main 有、origin/main 沒有」的無關 commit。MR 的 target 是
`origin/main`，diff 就會把那些不相干變更全算進來（例如把 rc 版號合併、別人的功能
commit 混進你的 feature MR），reviewer 會質疑「是不是混了兩個東西」。

因此在建立 worktree 前，先把基底對齊到最新的遠端預設分支：

```bash
# 偵測遠端預設分支（通常是 main，少數 repo 為 master）
default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
default=${default:-main}

# 同步遠端最新狀態
git fetch origin "$default"

# 檢查本地 default 是否落後/分歧於 origin/default（純資訊，不必須對齊本地）
git log --oneline "$default..origin/$default" | head   # 有輸出 = 本地落後
git log --oneline "origin/$default..$default" | head   # 有輸出 = 本地領先（潛在汙染來源）
```

**關鍵原則：新分支一律以 `origin/<default>` 為起點，不要從可能過期的本地 `<default>` 切。**

### 4. 呼叫 using-git-worktrees skill

使用 Skill 工具呼叫 `superpowers:using-git-worktrees`，並告知：

- 預期分支名稱：`<type>/<short-description>`
- 預期目錄：`.claude/worktrees/<short-description>`（skill 會自動依優先順序選定路徑；
  若不存在且 CLAUDE.md 無偏好，依 skill 規則詢問使用者）
- **分支起點：`origin/<default>`**（務必明確指定，見步驟 3）

Skill 會負責：

- `.gitignore` 驗證（專案內目錄）
- `git branch --list` 確認分支不存在
- 建立 worktree —— **務必帶上遠端起點**：`git worktree add <path> -b <branch> origin/<default>`
  （skill 預設指令 `git worktree add <path> -b <branch>` 會從本地 HEAD 切，**不要照用**，
  要補上 `origin/<default>` 起點）
- 自動偵測 `package.json` / `Cargo.toml` / `requirements.txt` / `go.mod` 並執行 setup
- 執行 baseline 測試

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

Skill 完成後，使用 Bash 工具執行：

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

### 8. 若 skill 執行中發生錯誤

- 分支已存在 → 詢問是否使用既有分支或改名
- 目錄未在 .gitignore → 遵循 skill 指引加入並 commit
- 基底汙染（步驟 5 檢查到多餘 commit）→ 列出多餘 commit，建議 `git rebase --onto origin/<default> <base>` 後再開發
- baseline 測試失敗 → 回報具體錯誤，詢問是否繼續
- `issue-get.sh` 抓取失敗（步驟 0）→ 提示改貼 issue 內容，或改用 `.claude/specs/` 的 spec 檔
- `.claude/specs/` 有多份 spec → `AskUserQuestion` 詢問用哪一份

## 範例

輸入：`/start 修正畫面疊字錯誤`

執行流程：

1. 關鍵字 `修正` → type = `bug`
2. 翻譯「畫面疊字錯誤」→ `typo_of_page`
3. `git fetch origin main`，確認以 `origin/main` 為分支起點
4. 最終分支名：`bug/typo_of_page`
5. 呼叫 skill 建立 `.claude/worktrees/typo_of_page`（`git worktree add ... -b bug/typo_of_page origin/main`）
6. 基底乾淨檢查：`git log --oneline origin/main..HEAD` 為空 ✓
7. `cd` 進入
8. 列出：

```
目前目錄：/Users/.../myproject/.claude/worktrees/typo_of_page
目前分支：bug/typo_of_page
基底：origin/main（無多餘 commit）

所有 worktrees：
  /Users/.../myproject                                  [main]
  /Users/.../myproject/.claude/worktrees/typo_of_page   [bug/typo_of_page]

準備開發：修正畫面疊字錯誤
```
