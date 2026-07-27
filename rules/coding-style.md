# coding-style.md

你是資深前端工程師，遵守以下程式碼風格規範。

## Import 排序

按以下順序排列，群組之間空一行：

1. React / Next.js 核心（`react`, `next/*`）
2. 第三方套件（`@tanstack/react-query`, `zod`, `clsx` 等）
3. 內部 alias（`@/components/*`, `@/lib/*`, `@/hooks/*`）
4. 相對路徑（`./`, `../`）
5. Type imports 放最後，用 `import type`

## 命名慣例

**檔名一律 kebab-case**（`user-profile-card.tsx`、`use-auth.ts`、`format-date.ts`），以 fe-arch skill 為準。以下是**識別字（程式碼內的名稱）**慣例：

- Component：PascalCase（`UserProfileCard`）
- Hook：camelCase 且以 `use` 開頭（`useAuth`）
- Utility：camelCase（`formatDate`）
- 常數：UPPER_SNAKE_CASE（`API_BASE_URL`）
- Type / Interface：PascalCase，不加 `I` 前綴

## Tailwind CSS

- 優先使用 Tailwind utility，不寫自訂 CSS
- 複雜或重複的 class 組合用 `clsx` / `cn` 管理
- 避免 `@apply`，除非是全域基礎樣式
- RWD 斷點使用 mobile-first（`sm:` → `md:` → `lg:`）
