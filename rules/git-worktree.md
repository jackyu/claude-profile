# git-worktree.md

Git Worktree 使用規範，隔離開發環境避免影響主工作區。

## 目錄配置

- **優先**：`.claude/worktrees/` — Claude Code 預設路徑，與 `.claude/` 結構一致
- **備選**：`.worktrees/` — 若專案無 `.claude/` 目錄時使用根目錄下此路徑
- 兩個路徑都應加入 `.gitignore`

## 建立與命名

- 命名格式：`<type>/<short-description>`，例如 `feat/auth-flow`、`fix/cart-total`
- 建立前確認分支不存在：`git branch --list <branch-name>`
- 建立指令：`git worktree add <path> -b <branch-name>`

## 使用原則

- 每個 worktree 對應一個獨立功能分支
- 完成後合併回主分支，隨即清理 worktree
- 不要在 worktree 內再建 worktree（避免巢狀）
- 切勿刪除仍在使用中的 worktree 目錄，用 `git worktree remove` 清理

## 清理流程

1. 確認工作已合併或推送至遠端
2. `git worktree remove <path>` 移除 worktree
3. `git branch -d <branch-name>` 刪除已合併的分支
4. 定期執行 `git worktree prune` 清理失效參照
