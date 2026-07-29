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

### 2. 前置檢查（任一失敗即中止，處理方式見下方「錯誤處理」表）

```bash
# 當前分支
current=$(git branch --show-current)

# 檢查 1：非 main / master
# 檢查 2：working tree 乾淨
git status --porcelain
# 檢查 3：相對於 target 有 commit 差異
git log --oneline origin/<target>..HEAD
```

### 3. 品質閘（有 `package.json` 才檢查，失敗阻擋）

讀取 `package.json`，偵測以下 scripts 並依序執行：

| Script | 指令 |
|--------|------|
| `lint` | `npm run lint` |
| `typecheck` 或 `type-check` | `npm run <script>` |
| `test`（僅當存在且非 `jest --watch` 類型） | 視情況，可由使用者以參數 `--skip-test` 跳過 |

任何一項失敗即中止（處理方式見下方「錯誤處理」表）。若無 `package.json` 或無對應 script，跳過此步。

### 4. Push 到遠端

```bash
# 偵測是否已有 upstream
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

- 沒有 upstream → `git push -u origin <current>`
- 有 upstream → `git push`

失敗時中止（處理方式見下方「錯誤處理」表）。

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
  - b) 更新 description 與 inline 自註解（呼叫 fe-mr-generator 依目前 `origin/<target>...HEAD` three-dot diff 重新產生完整清單，`mr-update.sh` 更新 description，並對既有 inline 自註解執行「主動汰換」）：
    - **汰換原則**：用唯讀方式（MCP 或既有唯讀 script）讀取此 MR 既有 discussions，篩出 body 含 `<!-- mr:self-annotation -->` 且「無人回覆」的舊自註解 thread，逐一與新清單比對 `(file, line, body)`——完全相同就保留、從待發清單移除；對不上（行被改或內容更新）就呼叫 `mr-resolve.sh` 收掉該 thread。
    - 「有人回覆過」的 thread 一律不動，避免洗掉既有 review 對話；新清單中與其語意重複的項目也略過不重發。
    - 待發清單處理完後，依步驟 9 相同流程發佈剩餘的新註解（`diff_refs` 從 MCP 重新讀取此 MR 取得）。

    ```bash
    ~/.claude/scripts/gitlab/mr-update.sh "<project>" <mr_iid> \
      --description "<skill 產出（含標記）>"   # 亦可帶 --title / --draft / --dry-run
    ```
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
- MR Description（四個區塊：關聯、為什麼要這樣做、概念地圖、截圖或錄影）
- Inline 自註解清單（獨立 JSON code block，每則 `{file, new_line|old_line, body}`）

### 8. 建立 MR

使用 `mr-create.sh`（走 script 層：強制驗證 fe-mr-generator 標記、支援 `--dry-run`、互動時觸發 ask 確認）：

```bash
~/.claude/scripts/gitlab/mr-create.sh \
  "<project path 或 id（git remote 解析）>" \
  "<current>" \
  "<target>" \
  --title "<skill 產出的 title（勿手動加 Draft: 前綴）>" \
  --description "<skill 產出的 description（必含標記 <!-- mr:fe-mr-generator -->）>" \
  --assignee-ids "<self user id>" \
  --labels "<依分支前綴解析，可省略>" \
  # draft 時再加：--draft
```

- **description 必須來自步驟 7 的 fe-mr-generator**（含隱形標記）；缺標記腳本會 `exit 1`，需先跑 skill。
- `--draft` → 腳本自動為 title 加 `Draft: ` 前綴，勿手動加。
- `remove_source_branch: true`、`squash: false` 已內建於腳本。
- 送出前可先加 `--dry-run` 檢視 payload（印出、不發射）。
- 讀取類（list MR / users / labels）仍走 `mcp__gitLab__*`；只有「建立/更新 MR」下沉到 script 層。

### 9. 發佈 inline 自註解（自動）

從步驟 8 `mr-create.sh` 的回應中取出 `iid` 與 `diff_refs`（`base_sha` / `start_sha` / `head_sha`）。

對步驟 7 skill 產出的 inline 註解清單（JSON，每則 `{file, new_line|old_line, body}`）逐則呼叫：

```bash
~/.claude/scripts/gitlab/mr-discussion.sh \
  "<project>" <iid> \
  --file "<file>" --new-line <n>   # 或改 --old-line <n>
  --body "<body>" \
  --base-sha "<diff_refs.base_sha>" --start-sha "<diff_refs.start_sha>" --head-sha "<diff_refs.head_sha>"
```

規則：
- 註解清單為空 → 跳過本步驟
- 單則呼叫失敗（例如行號不在 diff hunk）→ 記錄失敗，不中止，繼續下一則
- 全部跑完後，若有失敗項目 → 彙整為一則整體留言（格式：`<file>:<line> — <body>` 逐行列出），呼叫 `mr-note.sh` 發佈作為 fallback
- 回報「inline 自註解：成功 N 則／失敗 M 則」
- 固定提醒：「自註解為 resolvable thread，若專案要求討論全部 resolve 才能 merge，請 review 完自行 resolve」

### 10. 回報結果

成功後在訊息中明確顯示：

```
MR 已建立：<MR URL>

Title:    <title>
Target:   <target>
Source:   <current>
Assignee: <username>
Labels:   <labels>
Draft:    <true/false>
Inline 自註解：成功 <N> 則／失敗 <M> 則

下一步建議：
- 補上截圖（前端 UI 變更必附前後對比）
- 指定 reviewer
- 若專案要求討論全部 resolve 才能 merge，review 完自行 resolve inline 自註解
- 等 CI 通過後 mark as ready（若為 draft）
```

## 錯誤處理

| 情境 | 處理 |
|------|------|
| 當前在 main/master（步驟 2） | 中止，提示先 `/start` 開 worktree |
| Working tree 不乾淨（步驟 2） | 列出檔案，詢問 commit 或 stash |
| 無 commit 差異（步驟 2） | 中止，告知使用者無變更 |
| 品質閘失敗（步驟 3） | 中止，輸出錯誤摘要，提示「先修正上述錯誤再 push」 |
| Push 被拒（步驟 4） | 顯示 git 錯誤訊息（權限、protected branch 等），中止 |
| MR 已存在（步驟 5） | 三選一，見步驟 5 |
| Label 不存在於專案（步驟 6） | 見步驟 6 |
| 無法解析 Issue ID（步驟 6） | 見步驟 6 |
| GitLab API 失敗 | 顯示錯誤訊息，告知使用者可手動開 MR |
| inline 自註解發佈失敗（單則，步驟 9） | 見步驟 9 |
| GitLab 寫入被 write-gate 擋下（專案不在 allowlist） | 顯示 hook 的 deny 訊息，提示將專案加入 `~/.claude/schedules/mr-review-by-loop/projects.json`，或改用 `--dry-run` 先驗證 |

## 範例

輸入 `/push`，目前在 `bug/typo_of_page`（乾淨、相對 main 領先 3 個 commit）：品質閘全過 → push
→ 無既有 MR → 解析 metadata（Label `bug`；Issue ID 從分支名抓不到，詢問使用者後回 `#42`）
→ `fe-mr-generator` 產出 title/description/inline 自註解清單 → 建立 MR → 逐則發佈 inline 自註解 → 回報 URL。
