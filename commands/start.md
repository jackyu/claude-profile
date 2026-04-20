---
description: 依任務描述自動建立 git worktree 與分支，並切換進入開發環境
---

# /start — 啟動新開發任務

任務描述：$ARGUMENTS

## 你的任務

依以下順序執行：

### 1. 解析分支類型（type）

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

### 3. 呼叫 using-git-worktrees skill

使用 Skill 工具呼叫 `superpowers:using-git-worktrees`，並告知：

- 預期分支名稱：`<type>/<short-description>`
- 預期目錄：`.claude/worktrees/<short-description>`（skill 會自動依優先順序選定路徑；
  若不存在且 CLAUDE.md 無偏好，依 skill 規則詢問使用者）

Skill 會負責：

- `.gitignore` 驗證（專案內目錄）
- `git branch --list` 確認分支不存在
- `git worktree add <path> -b <branch>`
- 自動偵測 `package.json` / `Cargo.toml` / `requirements.txt` / `go.mod` 並執行 setup
- 執行 baseline 測試

### 4. 切換至新 worktree

Skill 完成後，使用 Bash 工具執行：

```bash
cd <worktree-path>
```

### 5. 列出所有 worktree 與當前狀態

```bash
git worktree list
```

並於訊息中明確回報：

- 目前所在目錄（絕對路徑）
- 目前分支名稱
- 其他所有 worktree 的路徑與分支（從 `git worktree list` 取得）
- 一行訊息：`準備開發：<原始任務描述>`

### 6. 若 skill 執行中發生錯誤

- 分支已存在 → 詢問是否使用既有分支或改名
- 目錄未在 .gitignore → 遵循 skill 指引加入並 commit
- baseline 測試失敗 → 回報具體錯誤，詢問是否繼續

## 範例

輸入：`/start 修正畫面疊字錯誤`

執行流程：

1. 關鍵字 `修正` → type = `bug`
2. 翻譯「畫面疊字錯誤」→ `typo_of_page`
3. 最終分支名：`bug/typo_of_page`
4. 呼叫 skill 建立 `.claude/worktrees/typo_of_page`
5. `cd` 進入
6. 列出：

```
目前目錄：/Users/.../myproject/.claude/worktrees/typo_of_page
目前分支：bug/typo_of_page

所有 worktrees：
  /Users/.../myproject                                  [main]
  /Users/.../myproject/.claude/worktrees/typo_of_page   [bug/typo_of_page]

準備開發：修正畫面疊字錯誤
```
