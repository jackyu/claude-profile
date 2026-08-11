# maintenance.md — 制度維護協議

> 讀者：未來任何 session 的模型。何時讀：想修改 rules/、playbooks/、CLAUDE.md、agents/ 或 settings 之前。

## 一、權限分級

**可自行改（改前備份到 `~/.claude/backups/`，改後在回覆中告知使用者改了什麼）**：
- 在 playbooks/ 新增教訓、修正錯字、更新失效的路徑或工具名
- 在 CLAUDE.md 路由表加一行指向新檔（不動鐵律）
- 新增 memory 檔與 MEMORY.md 索引行
- 更新本檔的量測數字（附量測日期）

**動之前必須先問使用者（AskUserQuestion 帶明確選項）**：
- 刪除或實質改寫任何既有規則（rules/、CLAUDE.md 鐵律、playbooks 的判準）
- 修改 `settings.json`（hooks、permissions、enabledPlugins、model）
- 修改 hooks 腳本或 agents/ 定義檔
- 任何「放寬」性質的改動（調低門檻、移除檢查、增加例外）

判斷原則：**加法（新增知識）可自行；減法與改法（刪規則、鬆綁）要問**。

## 二、踩坑教訓寫回哪裡

| 教訓類型 | 寫到 | 格式 |
|---|---|---|
| 使用者偏好、如何跟這位使用者工作 | memory（type: user/feedback） | memory frontmatter＋Why＋How to apply |
| 環境陷阱（hook 行為、CI 雷、工具怪癖） | memory（type: project/reference） | 同上；相對日期轉絕對日期 |
| 每個 session 都會踩、一行講得完的 | CLAUDE.md「環境事實」段 | 一行，含觸發條件 |
| 派工／驗證流程的新模式 | delegation.md 或 judgment.md 對應小節 | 沿用該檔既有格式（訊號清單＋正反例） |
| 只跟單一 repo 有關的 | 該 repo 自己的 CLAUDE.md | 不要寫進全域 |

寫之前先搜尋既有檔案是否已涵蓋——更新舊條目優於新增重複條目。錯了的記憶直接刪。

## 三、規則撰寫原則（原 rules/summary.md，遷移至此）

- **從痛點出發**：同一件事提醒過 AI 兩次，就該變成規則；沒痛過的不要預先立法。
- 用自然語言 Markdown，像跟同事交代工作規範。
- 每條規則要有**觸發條件＋具體動作＋判準**；「保持高品質」這種抽象句等於沒寫。
- 可能被誤讀的規則附一個正例一個反例（格式參考 judgment.md）。
- 每個 rules/ 檔案聚焦一個維度，目標 ≤40 行；超過就把範例碼抽到 playbooks/examples-*.md。

## 四、膨脹控制（觸發條件與做法）

**為什麼**：rules/ 頂層與 CLAUDE.md 每個 session 自動載入，每多一行全年每個 session 都付費。playbooks/ 按需載入，寬鬆得多。

觸發任一條件就執行精簡（精簡屬「減法」，方案要先給使用者過目）：
- CLAUDE.md 超過 100 行
- rules/ 頂層合計超過 500 行（量測：`wc -l ~/.claude/rules/*.md | tail -1`）
- 單一 playbook 超過 250 行
- MEMORY.md 索引超過 30 行

精簡做法：合併重複 → 把低頻內容從 rules/ 移到 playbooks/ 並在路由表登記 → 刪除超過半年沒被任何任務用到的條目（列清單問使用者）。

## 五、季度量測流程（照抄執行）

```bash
# 固定載入量（rules 頂層 + CLAUDE.md；子目錄不會自動載入）
wc -c ~/.claude/rules/*.md ~/CLAUDE.md | tail -1
# agents 定義大小（每次派工都載入該 agent 的 prompt）
wc -c ~/.claude/agents/*.md
# playbooks 健康度
wc -l ~/.claude/playbooks/*.md
```

把結果與日期記錄在本檔末尾的「量測記錄」，跟上一季比較；成長超過 20% 就走第四節的精簡流程。

## 六、已知事實（改動時不要違反）

- rules/ **只有頂層 .md** 會自動載入；放進子目錄＝實質停用。要停用一條規則，移進任一子目錄即可，不必刪；長期封存用 `rules-archive-<YYYYMMDD>/`（**要用時才建，平常不留空目錄**）。
- **custom subagent 會繼承主 session 的 CLAUDE.md 與 rules/ 內容**（2026-07-04 canary 實驗＋官方文件 sub-agents.md 證實；內建 Explore/Plan 例外，不載入）。所以 agent 定義檔不需要複製 rules 細則。注意：subagent 拿到的是 session 開始時的快照，session 中途改 rules 不會反映到新派的 subagent。
- agent frontmatter 設 `memory: user` 時，harness **自動注入** memory 使用說明與 MEMORY.md 前 200 行；不要把 memory 樣板寫進 agent 檔（官方文件 sub-agents.md「Enable persistent memory」證實）。
- CLAUDE.md 位於 `~/CLAUDE.md`，對 /Users/jackyu 底下所有專案生效（Claude Code 會向上層目錄找 CLAUDE.md）。
- claim-audit.sh（Stop hook）對帳 write-ledger.sh（PostToolUse hook）記錄的實際寫入路徑——寫入後被刪或清空會擋下 Stop；/tmp、/private/tmp、scratchpad 路徑不列管。攔截是**每路徑一次性**（2026-07-08 加入銷帳機制）：block 過一次且模型已回覆說明後，該路徑寫入 `.acked` 不再重複警告；同路徑被重新寫入會自動 un-ack 恢復列管。
- 備份目錄慣例：`~/.claude/backups/<用途>-<YYYYMMDD>/`。2026-07-04 制度建立前的完整備份在 `~/.claude/backups/pre-fable-20260704/`。

## 量測記錄

- 2026-07-04（制度建立日，整併前）：CLAUDE.md 195 行/6.4KB；rules/ 頂層 16 檔 ~20KB；code-implementer.md 22.4KB。
- 2026-07-04（整併後）：CLAUDE.md 44 行/4.1KB；rules/ 頂層 14 檔 456 行/17.1KB（summary、long-task-anchor、typescript/ 已封存至 rules-archive-2026-07-04）；agents 三檔合計 10.2KB（code-implementer 5.3KB）；playbooks 7 檔 ~460 行。
- 2026-08-11（預防性精簡，485 → 354 行 / 15.2KB，-27%）：CLAUDE.md 46 行/5.3KB；rules/ 14 檔全部落在 40 行以內（最大 html-semantics 35 行）；agents 三檔 11.9KB（deep-reasoner／fast-worker 各加了一段「何時寫 memory」）；playbooks 6 檔 467 行。手段：14 檔標題行合併、刪跨檔重複、範例碼直接移除（未抽 playbook，故路由表不動）。同時裁決分支命名三方衝突——以 `/start` 的實際格式為準（snake_case、不帶 ticket id、type 三選一 `feat`／`bug`／`fix`），並補上 git-worktree 缺漏的 `origin/main` 基底要求。
