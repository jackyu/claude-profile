# git-worktree.md — worktree 使用規範

一般走 `/start` 建、`/finish` 收；下面是手動處理時的規範。

## 目錄與命名

- 路徑優先 `.claude/worktrees/`，專案沒有 `.claude/` 才用 `.worktrees/`；都要進 `.gitignore`
- 分支命名 `<type>/<short_description>`（snake_case、不帶 ticket id），type 三選一：`feat/` 新功能、`bug/` 修 bug、`fix/` hotfix。例：`feat/auth_flow`
- 建立前先確認分支不存在：`git branch --list <branch>`

## 建立

**一律以 `origin/<default>` 為基底**，不從可能落後的本地分支切：

```bash
git fetch origin
git worktree add <path> -b <branch> origin/main
```

建完立刻驗基底乾淨：`git log --oneline origin/main..HEAD` 應為空。

## 使用與清理

- 一個 worktree 一個功能分支，不在 worktree 裡再開 worktree
- 還在用的目錄不要直接刪，用 `git worktree remove <path>`
- 分支合併後 `git branch -d <branch>`；定期 `git worktree prune` 清失效參照
