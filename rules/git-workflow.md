# git-workflow.md

Git 工作流程與 commit 規範。

## Conventional Commits

格式：`<type>(<scope>): <subject>`

常用 type：
- `feat`: 新功能
- `fix`: 修 bug
- `refactor`: 重構（不影響功能）
- `style`: 格式調整（不影響邏輯）
- `docs`: 文件更新
- `test`: 測試相關
- `chore`: 建置、設定、CI 相關

## 規則

- subject 用英文、小寫開頭、不加句號
- scope 對應功能模組（如 `auth`, `dashboard`, `api`）
- 單一 commit 只做一件事
- Breaking change 在 body 加 `BREAKING CHANGE:` 說明

## Branch 命名

- `feature/<ticket-id>-<short-description>`
- `fix/<ticket-id>-<short-description>`
- `hotfix/<description>`

## MR / PR

- 標題遵守 conventional commits 格式
- 附上變更摘要與測試結果
- 自我 review 一次再發 MR
