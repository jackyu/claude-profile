# Claude Rules 設計原則摘要

## 核心理念

**從痛點出發** — 如果你每次都要提醒 AI 的同一件事，那它就該變成 rule。

## 設計方法

問自己：「我最常提醒 AI 的事情是什麼？」然後針對每個痛點建立對應的 rule 檔案。

## 範例對照

| 你常說的話 | 對應 Rule 檔 |
|---|---|
| 用 conventional commits | `git-workflow.md` |
| import 要排序 | `coding-style.md` |
| 寫完跑測試 | `testing.md` |
| 不要把 API key commit 進去 | `security.md` |
| 改完 code 用 code-reviewer 審 | `agents.md` |

## 撰寫原則

1. **格式**：用 Markdown 撰寫，自然語言即可，不需特殊語法
2. **語氣**：像在跟同事交代工作規範一樣寫
3. **長度**：每個 rule 檔控制在 30 行以內
4. **拆分**：太長就拆成多個檔案，每個檔案聚焦一個維度
