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

## 韌性原則（保命，務必遵守）

這條迴圈最大的風險不是「某筆 review 失敗」，而是**整條迴圈靜默死亡**：步驟 2–6 任何未處理的
錯誤若讓本 turn 中止，就到不了步驟 7 的自排程 → 迴圈永久停擺，且因為通知在步驟 6 才發，你不會
收到任何告警。因此：

1. **心跳必活**：除了「步驟 1 的設定／目錄錯誤」（見步驟 1，刻意不排程），**步驟 2–6 的任何失敗
   都不得中止整條迴圈**。失敗時降級為「**本輪跳過、仍照常排下一輪**」（直接跳到步驟 7），絕不讓迴圈死掉。
2. **瞬時錯誤先重試**：所有外部呼叫（GitLab API / shell script / notify）失敗時，以
   **retry-with-backoff** 重試最多 3 次（間隔 2s → 4s）。多數瞬斷（`ConnectionRefused`、
   `FailedToOpenSocket`、短暫 5xx）重試一次就過，不會升級成整輪失敗。
3. **單筆隔離**：步驟 5–6 逐一處理多個 MR 時，**某一個 MR 失敗只跳過那一個**，不影響其他 MR
   與排程。失敗的 MR**不要更新狀態檔**（下一輪自動重審）。

下方每個 shell script 呼叫都用這個 `retry` 包起來。Bash 工具的 shell state 不會跨呼叫保留，
**每次 Bash 指令都要連同函式定義一起貼進同一行**：

```bash
retry() { local n=1 d=2; until "$@"; do [ $n -ge 3 ] && return 1; sleep $d; n=$((n+1)); d=$((d*2)); done; }
retry <原本的指令>
```

> 邊界：retry 只能救「session 還活著、但某次呼叫瞬斷」。若整個 session／container 被 OS 資源
> 耗盡（`EAGAIN`、`fork failed`）殺死，in-session 自排程無從自救——那屬於外部 cron／headless
> 的範疇，不在本檔處理。

## 你的任務（執行「一輪」，最後自排程）

### 0. 解析參數（消歧，避免把 interval 當成 repo）

`$ARGUMENTS` 可能是 `[repo] [interval]`、`[repo]`、`[interval]` 或空，**順序不拘**。
對每個 token 判斷：

- 符合 `^[0-9]+(m|h|s)?$`（如 `20m`、`1h`、`90s`、`1200`）→ 視為 **interval**。
- 其餘 → 視為 **repo**（短名，如 `masterlink`、`fugle-web`；repo 名永遠不長得像 interval，故零誤判）。

得到兩個變數：

- `{repo_arg}`：解析出的 repo 短名（可能為空 → 純靠 cwd 自動判定）。
- `{interval}`：解析出的間隔字串，**預設 `20m`**。

> 這條規則修掉「`/auto-review 20m` 把 `20m` 當 repo 名丟給 resolve-project.sh」的歷史 bug。

### 1. 依「目前目錄」判定專案（cwd 比對）

執行（傳入步驟 0 解析出的 `{repo_arg}`，**不是原始 `$1`**）：

```bash
~/.claude/schedules/mr-review-by-loop/resolve-project.sh "{repo_arg}"
```

（`{repo_arg}` 選用：若有給就當作「預期 repo name」做交叉驗證；沒給則純靠 cwd 自動判定。）

- 成功 → 輸出 JSON `{repo, project_path, display_name, repo_root}`，記下這些值往下走。
- **失敗（exit 1）→ 把它印出的錯誤訊息原樣呈現給使用者，然後停止本輪、且不要排程**
  （例如「目前目錄不對應任何專案，請切換到正確的 repo checkout」或「指定 repo 與目前目錄不符」）。
  這是刻意設計：避免在錯誤的目錄產出沒有 diff 的空洞 review。

把步驟 0 的 `{interval}` 轉成秒數 `INTERVAL_SECONDS`
（`20m`→1200、`30m`→1800、`1h`→3600、純數字視為秒；夾在 [60, 3600]）。

向使用者明確顯示：目前監聽的專案 `display_name`、對應目錄 `repo_root`。

> 下方所有 `{repo}`、`{project_path}`、`{display_name}` 都用 **步驟 1 解析出的值**，
> 不要用 `{repo_arg}`（它只是選用的交叉驗證參數，可能沒給）。

### 2. 取得「指派給我」的 open MR 清單

執行（`{project_path}` 用步驟 1 的值；用韌性原則的 `retry` 包起來）：

```bash
retry() { local n=1 d=2; until "$@"; do [ $n -ge 3 ] && return 1; sleep $d; n=$((n+1)); d=$((d*2)); done; }
retry ~/.claude/scripts/gitlab/mr-list-for-review.sh "{project_path}"
```

輸出 JSON：`{ "reviewer": "<我的 username>", "mrs": [ {iid,title,author,draft,sha,web_url}, ... ] }`。
記住 `reviewer`（即「我自己」）。

**若重試 3 次仍失敗** → 視為本輪瞬時故障，**直接跳到步驟 7（仍排下一輪）**，不要中止迴圈。

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

**單筆隔離**：若某個 MR 審查過程拋錯（skill 失敗、API 取 diff 失敗等），重試該步驟最多 3 次仍
不行就**跳過這個 MR**（不更新其狀態、下一輪重審），繼續處理其餘 MR，**不可中止本輪**。

### 6. 通知 Mattermost + 更新狀態

對每個剛產出的 MR，組一段 Markdown 並推送（用韌性原則的 `retry` 包起來）：

```bash
retry() { local n=1 d=2; until "$@"; do [ $n -ge 3 ] && return 1; sleep $d; n=$((n+1)); d=$((d*2)); done; }
retry ~/.claude/schedules/mr-review-by-loop/notify-mattermost.sh "<markdown>"
```

Markdown 內容建議：
- 開頭標明 `**[{display_name}]** 🆕 新的待審 MR` 或 `🔄 有新 commit，已重審`
- MR 標題 + `web_url`（可點進 GitLab）
- 合併建議結論 + severity 計數（如 🔴1 🟠2 🟡3 🔵0 ⚪0）
- **HTML 報告路徑**，用 `file://` 開頭的絕對路徑（讓我點開即用 browser 閱讀），
  例如 `file:///Users/.../reports/masterlink/mr-review-123-ab12cd34.html`

通知成功後，更新狀態檔（用 helper，immutable 合併、不破壞其他條目；同樣用 `retry` 包起來）：

```bash
retry() { local n=1 d=2; until "$@"; do [ $n -ge 3 ] && return 1; sleep $d; n=$((n+1)); d=$((d*2)); done; }
retry ~/.claude/schedules/mr-review-by-loop/update-state.sh {repo} <iid> <head_sha>
```

**若通知重試後仍失敗** → **不要更新該 MR 的狀態檔**（讓它下一輪重新通知），跳過此 MR 繼續處理
其餘 MR，最後仍照常走到步驟 7。

> 不要自動在 MR 上發 comment。是否回覆 review 一律由我人工決定後，另用
> `~/.claude/scripts/gitlab/mr-note.sh` / `mr-reply.sh` 處理。

### 7. 自排程下一輪

**這是迴圈的命脈**。不論本輪有無待審 MR、也**不論本輪步驟 2–6 是否發生過瞬時錯誤**（重試耗盡、
某些 MR 被跳過），最後都**務必**呼叫 `ScheduleWakeup`，把下一輪排上去：
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
