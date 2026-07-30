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
- `draft` = `true`（MR 一律先開草稿，等 CI 綠了再自己 mark as ready）

從 `$ARGUMENTS` 偵測覆寫：

- `--target <branch>` 或 `target=<branch>` 或中文「推到 rc/1.9.3」→ 覆寫 target
- `--ready` 或「直接開正式」「不要草稿」→ draft = false
- `--draft` 或「草稿」→ draft = true（已是預設，留著向後相容）

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

```bash
glab api "projects/:id/merge_requests?state=opened&source_branch=<current>"
```

（`:id` 會被 glab 換成當前 repo；不在 repo 內就填 url-encoded project path 或數字 id。）

- 有 → 顯示 MR URL，詢問使用者：
  - a) 僅推送（不動 MR）
  - b) 更新 description 與 inline 自註解（呼叫 fe-mr-generator 依目前 `origin/<target>...HEAD` three-dot diff 重新產生完整清單，`mr-update.sh` 更新 description，並對既有 inline 自註解執行「主動汰換」）：
    - **汰換原則**：用唯讀方式（`glab api` 或既有唯讀 script）讀取此 MR 既有 discussions，篩出 body 含 `<!-- mr:self-annotation -->` 且「無人回覆」的舊自註解 thread，逐一與新清單比對 `(file, line, body)`。
    - **比對前先 normalize 舊 body**（舊 body 帶著上一輪的導覽裝飾，不 normalize 會全部對不上）：
      1. 去掉 `<!-- mr:self-annotation -->` 尾行
      2. 去掉「接著看 → …」或「🏁 導覽結束…」尾行
      3. 去掉開頭的 `🤖💬 …` 首行
      4. **去掉前後空白行**（拿掉首行與尾行後會各留一個空行）再 trim
    - normalize 後與新 body 純內容比對：
      - **相同且無人回覆** → 保留該 thread、記下它的 `note_id` 與 `discussion_id`、從待發清單移除，並**併入 chain**（Phase B 會一律重 PUT 重新編號，因為順序可能已經變了）
      - **對不上**（行被改或內容更新）→ 呼叫 `mr-resolve.sh` 收掉該 thread，該項回到待發清單
      - **有人回覆過** → 一律不動，避免洗掉既有 review 對話；**不入 chain、不入閱讀地圖**，新清單中與其語意重複的項目也略過不重發
    - 待發清單處理完後，依步驟 9 相同流程（Phase A → B → C）處理：Phase A 只發待發清單，Phase B 對「保留的舊 note ＋ 新發的 note」整條 chain 重新補尾行，Phase C 因為 description 已有標記而走「整塊替換」。`diff_refs` 用 `glab api "projects/:id/merge_requests/<iid>"` 重新讀取此 MR 取得。

    ```bash
    ~/.claude/scripts/gitlab/mr-update.sh "<project>" <mr_iid> \
      --description "<skill 產出（含標記）>" \
      --labels "<步驟 6 解析出的單一 # type:: label>" \
      --assignee-ids "$(~/.claude/scripts/gitlab/user-id.sh jackyu)" \
      --draft   # draft=false（帶 --ready）時省略這行；亦可加 --title / --dry-run
    ```

    既有 MR 走這條也要補齊 Draft、assignee、label——新舊兩條路徑設定一致，才不會「第一次 /push 有、第二次沒有」。`--draft` 沒帶 `--title` 時腳本會先讀現有 title 再補前綴，已經是 `Draft: `／`WIP: ` 的不會被加第二次。
  - c) 取消
- 無 → 繼續步驟 6

無論走 b 或步驟 8 新建，MR 就緒後都要接步驟 8 之後的「回寫 issue 狀態」。

### 6. 解析 MR metadata

**Target branch：** 從步驟 1 的 `target`（預設 main）

**Assignee：** 當前使用者（自己）

```bash
~/.claude/scripts/gitlab/user-id.sh jackyu   # 印出數字 ID，直接餵給 --assignee-ids
```

**Label：** 只掛一個 `# type::*`，來源依序：

1. **有關聯 issue** → 讀 issue 自己的 `# type::*`（`~/.claude/skills/_shared/fe-mr-common/scripts/issue-get.sh <project> <NNN>`），沿用同一個，讓 issue 與 MR 對得上。
2. **沒有 issue** → 看分支前綴：

| 分支前綴 | Label |
|---------|-------|
| `feat/` | `# type::feature` |
| `fix/`、`bug/`、`hotfix/` | `# type::bug` |
| `refactor/`、`chore/`、`perf/` | `# type::improvement` |
| `qa/`、`test/` | `# type::QA` |

label 實名帶 `# ` 前綴，逐字照抄——專案裡另有 `# type::Bug`、`# type::bugfix` 這類相似項，抄錯會靜默建出新 label。建立 MR 前可用 `glab api "projects/:id/labels"` 驗證存在；若不存在，移除該 label 讓 MR 建立不失敗，並告知使用者。

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
- Inline 自註解清單（獨立 JSON code block，每則 `{file, new_line|old_line, order?, title?, body}`）

清單欄位語意：

| 欄位 | 說明 |
|------|------|
| `order` | 導覽順序。主要點 `"1"`、`"2"`…（連續字串）；次要點 `"2.1"`（掛在該主要點下，每個主要點最多 3 個）。**省略＝補充項**，不佔導覽順位、最後才發 |
| `title` | 有 `order` 者必填，≤16 全形字、不含路徑。供「接著看」連結文字與閱讀地圖使用 |
| `body` | 純內容。**不含** `🤖💬`、編號、「接著看」尾行、`<!-- mr:self-annotation -->` 標記——這些裝飾全部由步驟 9 組裝，skill 不預先寫入（否則重推時步驟 5b 的汰換比對會全部對不上） |

`order` 只表達相對順序；實際顯示的 `[i/M]` 編號由步驟 9 依最終發佈清單重算，**分母 M ＝主要點總數**（次要點與補充項不計入）。

### 8. 建立 MR

使用 `mr-create.sh`（走 script 層：強制驗證 fe-mr-generator 標記、支援 `--dry-run`、互動時觸發 ask 確認）：

```bash
~/.claude/scripts/gitlab/mr-create.sh \
  "<project path 或 id（git remote 解析）>" \
  "<current>" \
  "<target>" \
  --title "<skill 產出的 title（勿手動加 Draft: 前綴）>" \
  --description "<skill 產出的 description（必含標記 <!-- mr:fe-mr-generator -->）>" \
  --assignee-ids "$(~/.claude/scripts/gitlab/user-id.sh jackyu)" \
  --labels "<步驟 6 解析出的單一 # type:: label>" \
  --draft   # 預設就要帶；只有 draft=false（--ready）才省略
```

- **description 必須來自步驟 7 的 fe-mr-generator**（含隱形標記）；缺標記腳本會 `exit 1`，需先跑 skill。
- `--draft` → 腳本自動為 title 加 `Draft: ` 前綴，勿手動加。
- `remove_source_branch: true`、`squash: false` 已內建於腳本。
- 送出前可先加 `--dry-run` 檢視 payload（印出、不發射）。
- 讀取類（列 MR／查 user id／列 label）走 `glab api` 與 `user-id.sh`；只有「建立/更新 MR」下沉到 script 層。

### 8b. 回寫 issue 狀態

MR 建立或更新成功後，若步驟 6 有解析到關聯 issue：

```bash
~/.claude/scripts/gitlab/issue-status.sh "<project>" <NNN> "Reviewing"
```

失敗不阻斷——MR 已經開好了，印警告請使用者手動改即可。狀態接力的最後一棒：`Ready to develop`（/spec）→ `Developing`（/start）→ `Reviewing`（/push）。

### 9. 發佈 inline 自註解與導覽（自動，二段式）

從步驟 8 `mr-create.sh` 的回應中取出 `iid`、`web_url` 與 `diff_refs`（`base_sha` / `start_sha` / `head_sha`）。

為什麼要二段式：**note id 只有發文成功後才拿得到**，而「接著看 → 下一則」的連結需要下一則的 id。所以先把全部 note 發完收齊 id（Phase A），再回頭補導引尾行（Phase B），最後把閱讀地圖 patch 進 description（Phase C）。

註解清單為空 → 整個步驟跳過。

#### Phase A：正序發文並收集 id

先把清單分成兩組並排序：

- **導引項**＝有 `order` 者，依 `order` 排序，主要點與其次要點交錯：`1` → `1.1` → `1.2` → `2` → `2.1` → `3`…
- **補充項**＝無 `order` 者，排在導引項全部之後

依這個順序逐則發文。body 這一輪先送**首行＋純內容**（尾行等 Phase B 補）：

```
🤖💬 [2/5] <title>

<body 純內容>
```

- 主要點首行 `🤖💬 [i/M] <title>`，`i` 為該主要點在導引項中的序號、`M` 為主要點總數
- 次要點首行 `🤖💬 [2.1] <title>`
- 補充項首行 `🤖💬 [補充] <title 或省略>`

```bash
out=$(~/.claude/scripts/gitlab/mr-discussion.sh \
  "<project>" <iid> \
  --file "<file>" --new-line <n> \
  --body "<組裝後的首行＋body>" \
  --base-sha "<diff_refs.base_sha>" --start-sha "<diff_refs.start_sha>" --head-sha "<diff_refs.head_sha>")

# discussion 回應：.id 是 discussion_id、.notes[0].id 是 note_id
note_id=$(jq -r '.notes[0].id // .id' <<<"$out")
discussion_id=$(jq -r 'if .notes then .id else empty end' <<<"$out")
```

- 每則記下 `(order, title, note_id, discussion_id)`；單則失敗（例如行號不在 diff hunk）記錄失敗，**不中止**，繼續下一則
- **Phase A 必須全部跑完才能開始 Phase B**——不要發一則就馬上補一則的尾行，因為第 i 則的尾行需要第 i+1 則的 id

#### Phase B：補導引尾行

把 Phase A 成功發出的**導引項**依順序串成 chain。chain 長度 < 2 → 跳過 Phase B 與 Phase C（只有一則就保留 `[1/1]`、不加尾行、不插閱讀地圖）。

chain 中每一則重新組裝完整 body 後整體 PUT：

```
🤖💬 [2/5] <title>

<body 純內容>

接著看 → [[2.1] <下則 title>](<web_url>#note_<下則 note_id>)
```

- 連結文字＝下一則的顯示標籤＋title（主要點 `[3/5] xxx`、次要點 `[2.1] xxx`）
- chain 最後一則尾行改成 `🏁 導覽結束（共 <M> 個重點）`
- 補充項永不掛尾行，也不進 chain

```bash
~/.claude/scripts/gitlab/mr-note-update.sh \
  "<project>" <iid> <note_id> \
  --body "<重新組裝的完整 body>" \
  --discussion "<discussion_id>"
```

- **body 一律從 skill 的原始純內容重新組裝**，不要把線上既有 body 讀回來再改——script 會自己補 `<!-- mr:self-annotation -->` 標記，讀回來改會變成兩個標記，下次重推時步驟 5b 的比對就會失準
- `--discussion` 必帶（positioned diff note 的正式端點是 discussion-scoped 那支）
- 單則失敗 → 記錄「該則缺導引」，不中止

#### Phase C：把閱讀地圖 patch 進 description

用 `<!-- mr:reading-map:start -->` / `<!-- mr:reading-map:end -->` 包夾一塊索引，章＝有序清單（主要點）、節＝內縮子清單（次要點）：

```markdown
<!-- mr:reading-map:start -->
**閱讀地圖**

1. [入口點在哪被呼叫](<web_url>#note_101)
2. [篩選條件組裝](<web_url>#note_102)
   - [快取鍵設計](<web_url>#note_103)
3. [錯誤分流](<web_url>#note_104)
<!-- mr:reading-map:end -->
```

插入規則（冪等）：

| 情況 | 處理 |
|------|------|
| description 已有 `<!-- mr:reading-map:start -->`…`:end` | 整塊替換 |
| 沒有標記、找得到 `## 💡 為什麼要這樣做` | 插在該標題行**之後** |
| 連標題也找不到 | 插在 description 最頂 |

- 發佈失敗的項目仍列入地圖，但不帶連結（純文字 title），讓 reviewer 知道有這個重點
- 補充項不列入地圖
- 組好新 description 後用 `mr-update.sh --description` 寫回（description 已含 `<!-- mr:fe-mr-generator -->`，可過 marker 閘）

```bash
~/.claude/scripts/gitlab/mr-update.sh "<project>" <iid> --description "<patch 後的 description>"
```

#### 收尾

- 全部跑完後，若有發佈失敗項目 → 彙整為一則整體留言（格式：`<file>:<line> — <body>` 逐行列出），呼叫 `mr-note.sh` 發佈作為 fallback
- 回報「inline 自註解：成功 N 則／失敗 M 則」、「導引補寫 N 則」、「閱讀地圖：已插入｜已更新｜跳過」
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
Issue 狀態：<已改為 Reviewing｜略過（無關聯 issue）｜失敗（原因）>
Inline 自註解：成功 <N> 則／失敗 <M> 則
導引補寫：<N> 則
閱讀地圖：<已插入|已更新|跳過（導引項不足 2 則）>

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
| inline 自註解發佈失敗（單則，Phase A） | 記錄失敗不中止，最後彙整成整體留言 fallback，見步驟 9 |
| 導引尾行補寫失敗（單則，Phase B） | 記錄「該則缺導引」不中止；該 note 內容仍在，只是動線斷一環，回報時列出斷點 |
| 閱讀地圖 patch 失敗（Phase C） | 不中止也不重試整段流程；回報「閱讀地圖：跳過（更新失敗）」並附 `mr-update.sh` 的錯誤訊息，note 本身與導引不受影響 |
| issue 狀態回寫失敗（步驟 8b） | 不阻斷，印警告請使用者手動改 |
| GitLab 寫入被 write-gate 擋下（專案不在 allowlist） | 受 gate 檢查的是 `mr-discussion.sh`、`issue-status.sh` 這類腳本（`mr-create.sh`／`mr-update.sh` 豁免，改由 fe-mr-generator 標記把關）。顯示 hook 的 deny 訊息，提示將專案加入 `~/.claude/schedules/mr-review-by-loop/projects.json`，或改用 `--dry-run` 先驗證 |

## 範例

輸入 `/push`，目前在 `bug/typo_of_page`（乾淨、相對 main 領先 3 個 commit）：品質閘全過 → push
→ 無既有 MR → 解析 metadata（Label `bug`；Issue ID 從分支名抓不到，詢問使用者後回 `#42`）
→ `fe-mr-generator` 產出 title/description/inline 自註解清單 → 建立 MR → 逐則發佈 inline 自註解、補上「接著看」導引尾行、把閱讀地圖插進 description → 回報 URL。
