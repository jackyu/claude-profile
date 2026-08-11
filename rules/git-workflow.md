# git-workflow.md — commit 與分支規範

## Conventional Commits

格式 `<type>(<scope>): <subject>`。常用 type：`feat` 新功能、`fix` 修 bug、`refactor` 重構、`style` 格式、`docs` 文件、`test` 測試、`chore` 建置設定。

- subject 用英文、小寫開頭、不加句號
- scope 對應功能模組（`auth`、`dashboard`、`api`）
- 單一 commit 只做一件事
- Breaking change 在 body 加 `BREAKING CHANGE:` 說明

## Branch 命名

`<type>/<short_description>`，snake_case、不帶 ticket id，與 `/start` 產生的格式一致。

分支的 type 只有三種，**跟上面的 commit type 清單不一樣**：`feat/` 新功能、`bug/` 修 bug、`fix/` 專指 hotfix。例：`feat/cart_checkout_flow`、`bug/typo_of_page`、`fix/login_token_expired`。

功能開發在獨立 worktree 分支進行，**絕不直接 commit 到 main 或 release 分支（rc/*）**。

## MR / PR

- MR 標題與描述一律用 fe-mr-generator skill 產，不手寫
- 自我 review 一次再發
- 開 MR 前跑完整品質關卡（lint、type-check、test、build）；既有失敗另開 infra 修復 MR，不混進功能 MR
- rebase 優先於 merge，保持線性歷史；分支已分歧時，改寫歷史前先問過
- 未經使用者明確確認，絕不 force-push、也不推共用分支
