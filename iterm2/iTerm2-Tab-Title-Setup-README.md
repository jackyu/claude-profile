# iTerm2 Tab Title 設定 - Git Worktree/Branch 顯示

讓 iTerm2 分頁標題自動顯示 `worktree:branch` 格式，方便多分頁工作時快速識別。

## 變更摘要

| 檔案 | 變更內容 |
|------|----------|
| `~/.zshrc` | 停用 Starship、啟用 DISABLE_AUTO_TITLE |
| `~/.p10k.zsh` | 新增 `set_iterm_tab_title` hook |

---

## 變更詳情

### 1. ~/.zshrc 變更

**停用 Starship** (line 186):
```zsh
# eval "$(starship init zsh)"  # Disabled - using Powerlevel10k instead
```

**啟用 DISABLE_AUTO_TITLE** (line 55):
```zsh
DISABLE_AUTO_TITLE="true"  # Using custom tab title in p10k.zsh instead
```

> 必須停用 oh-my-zsh 的 auto title，否則會覆蓋自訂的 tab title 並加上 `(zsh)` 後綴。

---

### 2. ~/.p10k.zsh 新增內容 (檔案末尾)

```zsh
# ============================================================================
# Custom iTerm2 Tab Title: worktree:branch
# Added for better multi-tab identification
# ============================================================================

function set_iterm_tab_title() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  local worktree_root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ -n "$branch" && -n "$worktree_root" ]]; then
    local worktree_name=$(basename "$worktree_root")
    # Format: worktree:branch (e.g., my-app:feature/auth)
    print -Pn "\e]1;${worktree_name}:${branch}\a"
  else
    # Fallback: show actual directory name
    local dir_name=$(basename "$PWD")
    [[ "$PWD" == "$HOME" ]] && dir_name="~"
    print -Pn "\e]1;${dir_name}\a"
  fi
}

# Register the hook to run before each prompt
autoload -Uz add-zsh-hook
add-zsh-hook precmd set_iterm_tab_title
```

---

## 效果

| 情境 | Tab 標題 |
|------|----------|
| `cd ~/Projects/my-app` (branch: main) | `my-app:main` |
| `git checkout feature/auth` | `my-app:feature/auth` |
| `cd ~` | `~` |
| `cd /tmp` | `tmp` |

---

## 套用方式

```bash
source ~/.zshrc
```

或開啟新的 iTerm2 分頁。

---

## 還原方式

如需還原：

1. **恢復 Starship**:
   ```zsh
   # 在 ~/.zshrc 取消註解
   eval "$(starship init zsh)"
   ```

2. **停用自訂 tab title**:
   ```zsh
   # 在 ~/.zshrc 註解掉
   # DISABLE_AUTO_TITLE="true"
   ```

3. **移除 p10k.zsh 的 hook**:
   刪除 `~/.p10k.zsh` 末尾的 `set_iterm_tab_title` 相關程式碼。

---

## 相關檔案

- `~/.zshrc` - Zsh 主設定檔
- `~/.p10k.zsh` - Powerlevel10k 設定檔
- `~/.oh-my-zsh/` - Oh My Zsh 安裝目錄

---

*設定日期: 2026-02-05*
