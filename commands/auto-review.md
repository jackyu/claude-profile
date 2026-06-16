---
description: 監聽「目前目錄對應的」GitLab 專案中指派給我 review 的新/更新 MR，自動產出 HTML review 並推 Mattermost 通知（自帶迴圈）
argument-hint: [repo-short-name] [interval. 預設 20m]
---

# /auto-review — 多專案 MR 自動監聽與 HTML review

附加參數：$ARGUMENTS

這個 command 是「自帶迴圈」的監聽器：跑完一輪後會用 `ScheduleWakeup` 自排程下一輪。
**它只審「你目前所在 repo checkout」對應的那個專案**（這樣才能用本機 `git diff` 取得變更）。
要監聽多個專案，就在各專案的 checkout 目錄各開一個 Claude session 跑 `/auto-review`。

設定根目錄（下稱 `$ROOT`）：`~/.claude/schedules/mr-review-by-loop`

## 你的任務（執行「一輪」，最後自排程）

### 1. 依「目前目錄」判定專案（cwd 比對）

執行：

```bash
~/.claude/schedules/mr-review-by-loop/resolve-project.sh "$1"
```

（`$1` 選用：若有給就當作「預期 repo name」做交叉驗證；沒給則純靠 cwd 自動判定。）

- 成功 → 輸出 JSON `{repo, project_path, display_name, repo_root}`，記下這些值往下走。
- **失敗（exit 1）→ 把它印出的錯誤訊息原樣呈現給使用者，然後停止本輪、且不要排程**
  （例如「目前目錄不對應任何專案，請切換到正確的 repo checkout」或「指定 repo 與目前目錄不符」）。
  這是刻意設計：避免在錯誤的目錄產出沒有 diff 的空洞 review。

解析間隔：`$2` = 輪詢間隔，預設 `20m`，轉成秒數 `INTERVAL_SECONDS`
（`20m`→1200、`30m`→1800、`1h`→3600、純數字視為秒；夾在 [60, 3600]）。

向使用者明確顯示：目前監聽的專案 `display_name`、對應目錄 `repo_root`。

> 下方所有 `{repo}`、`{project_path}`、`{display_name}` 都用 **步驟 1 解析出的值**，
> 不要用 `$1`（`$1` 只是選用的交叉驗證參數，可能沒給）。

### 2. 取得「指派給我」的 open MR 清單

執行（`{project_path}` 用步驟 1 的值）：

```bash
~/.claude/scripts/gitlab/mr-list-for-review.sh "{project_path}"
```

輸出 JSON：`{ "reviewer": "<我的 username>", "mrs": [ {iid,title,author,draft,sha,web_url}, ... ] }`。
記住 `reviewer`（即「我自己」）。

### 3. 過濾

從 `mrs` 丟掉：
- `draft == true`（Draft/WIP 先不審）
- `author == reviewer`（自己開的不審）

### 4. 比對狀態，挑出待審 MR

讀狀態檔 `$ROOT/state/seen-{repo}.json`（不存在視為 `{}`）。結構：`{ "<iid>": "<已審過的 head sha>" }`。

對每個過濾後的 MR，符合下列任一即「待審」：
- `iid` 不在狀態檔（新 MR）
- 狀態檔中該 `iid` 的 sha 與目前 `sha` 不同（有新 commit → 重審）

若無待審 MR → 跳到步驟 7（安靜略過，不發通知）。

### 5. 逐一產出 HTML review

對每個待審 MR：

- 使用 **`fe-mr-review-html`** skill 對 `{project_path}` 的 MR `!<iid>` 進行審查。
  diff 用本機 git（cwd 已是該 repo）；若 `mr-context.sh` 回報「unable to compute local diff」，
  改用 GitLab API `merge_requests/<iid>/changes` 取 diff。
- **覆寫輸出路徑**為 `$ROOT/reports/{repo}/mr-review-{iid}-{short_sha}.html`
  （`short_sha` = sha 前 8 碼；先 `mkdir -p` 該 reports 子目錄）。
- **跳過該 skill 的互動式 Step 9**：不要用 `SendUserFile`、不要詢問後續行動。
  我們只需要把 HTML 檔寫到上述路徑。
- 從審查結果記下：合併建議結論（同意 / 有條件 / 不同意）與各 severity 計數。

### 6. 通知 Mattermost + 更新狀態

對每個剛產出的 MR，組一段 Markdown 並推送：

```bash
~/.claude/schedules/mr-review-by-loop/notify-mattermost.sh "<markdown>"
```

Markdown 內容建議：
- 開頭標明 `**[{display_name}]** 🆕 新的待審 MR` 或 `🔄 有新 commit，已重審`
- MR 標題 + `web_url`（可點進 GitLab）
- 合併建議結論 + severity 計數（如 🔴1 🟠2 🟡3 🔵0 ⚪0）
- **HTML 報告路徑**，用 `file://` 開頭的絕對路徑（讓我點開即用 browser 閱讀），
  例如 `file:///Users/.../reports/masterlink/mr-review-123-ab12cd34.html`

通知成功後，更新狀態檔（用 helper，immutable 合併、不破壞其他條目）：

```bash
~/.claude/schedules/mr-review-by-loop/update-state.sh {repo} <iid> <head_sha>
```

> 不要自動在 MR 上發 comment。是否回覆 review 一律由我人工決定後，另用
> `~/.claude/scripts/gitlab/mr-note.sh` / `mr-reply.sh` 處理。

### 7. 自排程下一輪

不論本輪有無待審 MR，最後都要呼叫 `ScheduleWakeup`：
- `delaySeconds` = 步驟 1 算出的 `INTERVAL_SECONDS`
- `prompt` = `/auto-review {repo} {interval}`（帶上解析出的 repo，讓下一輪先驗證 cwd 仍相符）
- `reason` = 例如 `auto-review 監聽 {display_name}，每 {interval} 一輪`

（步驟 1 的「找不到 / 參數不符」情況例外：報錯後不排程，避免無限失敗迴圈。）

## 畫面回報

每輪結束在畫面上呈現：
- 目前監聽的專案 `display_name`（與 `repo_root`）
- 本輪掃到幾個 open MR、其中幾個待審
- 對每個本輪審查的 MR，列出 **MR title + MR link（web_url）+ HTML 報告路徑**
- 下一輪排程時間
- 若 cwd 不對應任何專案 / 與指定不符：只呈現錯誤訊息，提示確認是否已切換到正確的執行目錄。
