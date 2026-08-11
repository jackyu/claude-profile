# Claude Code 前端開發 Rules

一套給 Claude Code 使用的前端開發規範，讓 AI 在寫程式碼時自動遵守團隊約定。

## 技術棧

- **Framework**: Next.js (App Router)
- **Styling**: Tailwind CSS
- **Data Fetching**: React Query v5
- **Testing**: Vitest / Jest + React Testing Library
- **Language**: TypeScript (strict mode)

## 檔案總覽

| 檔案 | 涵蓋範圍 |
|------|----------|
| `typescript.md` | TypeScript 嚴格模式與型別使用規範 |
| `coding-style.md` | Import 排序與命名慣例（Tailwind 規範集中在 `tailwind.md`） |
| `comment-style.md` | 程式碼註解的句子表達 — 去翻譯腔與贅字、40 字拆句、口語但專業 |
| `tailwind.md` | Tailwind class 排序、design token、dark mode、responsive 策略 |
| `html-semantics.md` | 語意化 HTML 標籤、無障礙 (a11y)、表單結構 |
| `component-patterns.md` | React 元件撰寫、狀態管理、Server/Client Component |
| `data-fetching.md` | React Query v5 資料請求、快取管理、API 層設計 |
| `response-transform.md` | API 回應轉換的 immutable 原則，禁止 mutate 原始物件 |
| `error-handling.md` | Error Boundary、API 錯誤、表單驗證、日誌 |
| `testing.md` | 測試總則 — 依 lockfile 裁決 Jest / Vitest 選型，共通原則與兩者設定差異 |
| `security.md` | 環境變數、資料驗證、認證授權、依賴安全 |
| `seo.md` | Next.js Metadata API、Open Graph、Structured Data、技術 SEO |
| `git-workflow.md` | Conventional Commits、分支命名、MR/PR 流程 |
| `git-worktree.md` | Git Worktree 目錄配置、命名與清理規範 |

> 分支命名（`feat/` `bug/` `fix/` + snake_case、不帶 ticket id）在 `git-workflow.md` 與 `git-worktree.md` 兩處都有，且與 `commands/start.md` 產生的格式對齊。改其中一處要三份一起改，否則模型手動開分支時會照 rules 走、跟 `/start` 產出的不一致。

> 語氣與表達規範已遷移為 output style（`output-styles/communication-style.md`），直接進 system prompt、回應風格更穩定，不再放 rules。
> 專案目錄結構規範已由 fe-arch skill 接手（`claude-skills` repo）；rules 設計原則的完整版在 `~/.claude/playbooks/maintenance.md`。

## 設計原則

- **從痛點出發** — 你每次都要提醒 AI 的事情，就該變成 rule
- **40 行以內** — rules/ 每個 session 都自動載入，每多一行全年每次對話都在付費。太長就拆或抽走
- **一個檔案一個維度** — 每個檔案聚焦一件事，同一條規則不要在兩個檔案各講一次
- **不放範例程式碼** — 規則講清楚就好。判準寫得夠具體的話，模型不需要 BAD/GOOD 對照碼才知道怎麼做

> 2026-08 做過一次精簡：14 檔 485 → 354 行（-27%），手段是刪跨檔重複、移除範例碼、合併標題行。目前最大的 `html-semantics.md` 35 行。

## 使用方式

使用根目錄的安裝腳本，可互動選擇 user scope 或 project scope：

```bash
bash install.sh
```

或手動複製到專案的 `.claude/rules/` 下：

```bash
cp rules/*.md your-project/.claude/rules/
```

Claude Code 會在對話時自動載入 `.claude/rules/` 中的所有 `.md` 檔案作為指令。

## 推薦搭配：everything-claude-code

[everything-claude-code](https://github.com/affaan-m/everything-claude-code) 提供通用的 coding style、git workflow、testing、security 等 rules，適合作為基礎規範搭配本專案的前端專屬規範使用。

安裝方式：

```bash
git clone https://github.com/affaan-m/everything-claude-code.git
cd everything-claude-code
./install.sh typescript   # 依語言選擇：typescript / python / golang
```

規則會安裝到 `~/.claude/rules/`（user scope），與本專案的 project scope 規則互補、不衝突。
