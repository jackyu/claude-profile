# .claude/ — 專案層級的 Claude Code 設定

這個 repo 會公開到 GitHub，所以 commit 前有一道 guard 把兩件事擋在前面。

## commit-guard 在做什麼

`hooks/commit-guard.sh` 掛在 PreToolUse（matcher `Bash`），只對 `git commit` 生效：

1. **作者身份** — 避免用公司帳號簽到公開 repo
2. **敏感詞** — 掃 staged diff 與 commit message，命中就擋

掃描範圍只有「這次要提交的東西」，不掃整個工作區，所以無關檔案不會誤報。

## 啟用（clone 後兩步）

沒做這兩步不會卡住任何操作，guard 只是不生效。

```bash
# 1. 敏感詞清單
cp .claude/commit-denylist.example.txt .claude/commit-denylist.txt
# 編輯它，填入實際要擋的詞

# 2. 允許的作者信箱
git config commitguard.email you@example.com
```

兩者都刻意留在本地：清單列著它要保護的東西，信箱是個人資料。

## 進版控 vs 本地

| 檔案 | 版控 | 說明 |
|------|------|------|
| `hooks/commit-guard.sh` | ✅ | 機制本身，跟著 repo 走 |
| `commit-denylist.example.txt` | ✅ | 範本與說明 |
| `settings.json` | ✅ | hook 接線 |
| `README.md` | ✅ | 本檔 |
| `commit-denylist.txt` | ❌ | 實際清單 |
| `settings.local.json` | ❌ | 個人偏好 |
| `worktrees/` | ❌ | 本地產物 |

## 失效模式（設計時的取捨）

| 狀況 | 行為 | 為什麼 |
|------|------|--------|
| 沒有 `commit-denylist.txt` | 放行 + 每次印提示 | clone 後還沒設定是正常狀態，不該卡死；印提示是為了讓「以為有防護但其實沒有」無所遁形 |
| 清單存在但讀不到 | **擋下** | 設定壞掉不等於沒設定 |
| 清單裡沒有任何有效詞 | 放行 + 印提示 | 同上，讓空清單無所遁形 |
| 沒設 `commitguard.email` | 跳過身份檢查 | 沒設定就不管 |
| hook 本身出錯 | 放行 | 不讓 guard 的 bug 癱瘓整個 session |

## 已知摩擦

分支名含 `commit` 字樣（例如 `chore/commit-guard`）會誤觸 fast path——`git merge --ff-only chore/commit-guard` 會被當成 commit 指令送進檢查。實際上會放行（作者對、無敏感詞），只是多繞一圈。**分支命名避開 `commit` 這個字就沒事。**

## 它擋不住什麼

guard 掃的是字面比對，擋得住「寫錯字」，擋不住刻意規避（改寫、縮寫、拼音）。它是防手滑的網子，不是資安機制。
