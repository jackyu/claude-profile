# git-worktree.md — worktree 使用規範

一般走 `/spec` 最後一步建、`/finish` 收；下面是手動處理時的規範。

## 目錄與命名

- 有 orca-cli 優先用它建（worktree 掛進 Orca 追蹤），沒有才退回 `git worktree add`
- 路徑優先 `.claude/worktrees/<name>`，專案沒有 `.claude/` 才用 `.worktrees/<name>`；都要進 `.gitignore`
- 名稱 `<type>_<short_description>`，全 snake_case（type 與描述用底線連接，不用 slash），branch 名與 worktree 名同一個字串，type 三選一：`feat` 新功能、`bug` 修 bug、`fix` hotfix。例：`feat_auth_flow`
- 建立前先確認分支不存在：`git branch --list <name>`

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
