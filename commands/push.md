---
description: 推送當前分支至遠端並建立 GitLab MR（含 title、description、label、assignee）
---

# /push — 完成開發並開立 MR

附加參數：$ARGUMENTS

## 你的任務

依以下順序執行。任何一步失敗都應阻擋後續流程，讓使用者先處理問題。

### 1. 解析參數

預設：
- `target` = `main`
- `draft` = `false`

從 `$ARGUMENTS` 偵測覆寫：

- `--target <branch>` 或 `target=<branch>` 或中文「推到 rc/1.9.3」→ 覆寫 target
- `--draft` 或「草稿」→ draft = true

### 2. 前置檢查（任一失敗即中止）

```bash
# 當前分支
current=$(git branch --show-current)

# 檢查 1：非 main / master
# 檢查 2：working tree 乾淨
git status --porcelain
# 檢查 3：相對於 target 有 commit 差異
git log --oneline origin/<target>..HEAD
```

- 若分支為 `main` / `master` → 中止並提示
- 若 working tree 不乾淨 → 列出未提交檔案，詢問是否 commit 後再推
- 若無 commit 差異 → 中止並告知

### 3. 品質閘（有 `package.json` 才檢查，失敗阻擋）

讀取 `package.json`，偵測以下 scripts 並依序執行：

| Script | 指令 |
|--------|------|
| `lint` | `npm run lint` |
| `typecheck` 或 `type-check` | `npm run <script>` |
| `test`（僅當存在且非 `jest --watch` 類型） | 視情況，可由使用者以參數 `--skip-test` 跳過 |

任何一項失敗即中止，輸出錯誤摘要並回報：「先修正上述錯誤再 push」。

若無 `package.json` 或無對應 script，跳過此步。

### 4. Push 到遠端

```bash
# 偵測是否已有 upstream
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

- 沒有 upstream → `git push -u origin <current>`
- 有 upstream → `git push`

失敗時回報原因（權限、protected branch 等）並中止。

### 5. 檢查是否已有開啟中的 MR

使用 MCP 工具：

```
mcp__gitLab__list_merge_requests
  project_id: <從 git remote get-url origin 解析>
  source_branch: <current>
  state: opened
```

- 有 → 顯示 MR URL，詢問使用者：
  - a) 僅推送（不動 MR）
  - b) 更新 description（呼叫 skill 重新產生並 `update_merge_request`）
  - c) 取消
- 無 → 繼續步驟 6

### 6. 解析 MR metadata

**Target branch：** 從步驟 1 的 `target`（預設 main）

**Assignee：** 當前使用者（自己）
- 用 `mcp__gitLab__get_users` 以 username 查詢取得 ID（從 git remote 或 git config 解析 username）

**Label：** 依分支前綴
| 分支前綴 | Label |
|---------|-------|
| `feat/` | `feature` |
| `bug/`  | `bug` |
| `fix/`  | `bug` |

建立 MR 前可用 `mcp__gitLab__list_labels` 驗證 label 存在；若不存在，移除該 label 讓 MR 建立不失敗，並告知使用者。

**Issue ID 來源（依序）：**
1. 分支名稱中的數字 — 例如 `feat/269_user_list` → `#269`
2. 對話上下文中使用者明確提到的 Issue 編號
3. 以上都沒有 → AskUserQuestion 詢問「此 MR 關聯的 Issue ID？」（允許留空）

**Remove source branch：** `true`
**Squash：** `false`
**Draft：** 步驟 1 解析結果

### 7. 呼叫 fe-mr-generator skill 產生 Title 與 Description

使用 Skill 工具呼叫 `fe-mr-generator`，並傳入：

- 當前分支、target branch
- 已解析的 Issue ID（若有）
- `main..HEAD` 的 commits 與 diff

Skill 會產出：
- MR Title（依 Issue 狀況帶格式）
- MR Description（五個區塊：關聯、為什麼、做了什麼、測試、截圖）

### 8. 建立 MR

使用 MCP：

```
mcp__gitLab__create_merge_request
  project_id: <解析結果>
  source_branch: <current>
  target_branch: <target>
  title: <skill 產出，若 draft 則前綴 "Draft: ">
  description: <skill 產出>
  assignee_ids: [<self user id>]
  labels: [<依分支前綴解析>]
  remove_source_branch: true
  squash: false
```

### 9. 回報結果

成功後在訊息中明確顯示：

```
MR 已建立：<MR URL>

Title:    <title>
Target:   <target>
Source:   <current>
Assignee: <username>
Labels:   <labels>
Draft:    <true/false>

下一步建議：
- 補上截圖（前端 UI 變更必附前後對比）
- 指定 reviewer
- 等 CI 通過後 mark as ready（若為 draft）
```

## 錯誤處理

| 情境 | 處理 |
|------|------|
| 當前在 main/master | 中止，提示先 `/start` 開 worktree |
| Working tree 不乾淨 | 列出檔案、詢問 commit 或 stash |
| 無 commit 差異 | 中止，告知使用者無變更 |
| 品質閘失敗 | 中止，輸出錯誤摘要 |
| Push 被拒 | 顯示 git 錯誤訊息，中止 |
| MR 已存在 | 詢問動作（僅推送 / 更新描述 / 取消） |
| Label 不存在於專案 | 移除該 label 並告知使用者 |
| 無法解析 Issue ID | 透過 AskUserQuestion 詢問（可留空） |
| GitLab API 失敗 | 顯示錯誤訊息，告知使用者可手動開 MR |

## 範例

輸入：`/push`

流程：
1. 解析：target=main、draft=false
2. 當前分支 `bug/typo_of_page`、working tree 乾淨、相對 main 有 3 個 commit
3. 跑 `npm run lint` + `npm run typecheck` 全部通過
4. `git push -u origin bug/typo_of_page`
5. 檢查 MR：無開啟中的 MR
6. 解析 metadata：
   - Label: `bug`
   - Assignee: `jackyu`
   - Issue ID: 從分支名抓不到 → 詢問使用者 → 使用者回 `#42`
7. 呼叫 `fe-mr-generator` 產 title + description
8. 建立 MR
9. 回報 URL
