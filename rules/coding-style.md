# coding-style.md — import 排序與命名慣例

## Import 排序

群組之間空一行，順序：React／Next 核心 → 第三方套件 → 內部 alias（`@/*`）→ 相對路徑。`import type` 放最後。

## 命名慣例

檔名與檔案位置以 fe-arch 為準（檔名一律 kebab-case）。以下是**識別字**慣例：

- Component：PascalCase（`UserProfileCard`）
- Hook：camelCase 且以 `use` 開頭（`useAuth`）
- Utility：camelCase（`formatDate`）
- 常數：UPPER_SNAKE_CASE（`API_BASE_URL`）
- Type / Interface：PascalCase，不加 `I` 前綴

Tailwind 相關規範見 tailwind.md。
