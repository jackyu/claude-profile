---
description: 前端程式碼審查——Spec／Standards 兩軸主幹，加爆炸半徑與無害區對抗挑戰
argument-hint: "[fixed-point，預設 origin/main] [spec 檔路徑，可省略]"
---

# /cr — 程式碼審查

附加參數：$ARGUMENTS

## 你的任務

1. 解析 `$ARGUMENTS`：
   - 第一個看起來像 commit SHA / branch / tag 的字串 → **fixed point**；沒給就用 `origin/main`。
   - 剩下的字串中，看起來像檔案路徑（以 `.md` 結尾或指向存在的檔案）者 → **spec 檔路徑**；已判為 fixed point 的字串不再參與。沒給就留空，讓 skill 自行定位。
   - 兩者都沒給 → fixed point 用 `origin/main`、spec 路徑留空。

2. 用 `Skill` tool 呼叫 `fe-code-review`，在 `args` 中明確傳入：
   - `模式：審查模式`
   - `fixed point：<解析結果>`
   - `spec 路徑：<解析結果，或「未指定，依 Step 1c 自行定位」>`

3. 後續流程一律以 `fe-code-review` skill 為準，本命令不重述流程。
