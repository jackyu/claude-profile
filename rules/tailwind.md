# tailwind.md — Tailwind CSS 使用規範

- 優先用 utility，不寫自訂 CSS
- 複雜或重複的 class 組合用 `clsx` / `cn` 管理

## Class 排序

裝 `prettier-plugin-tailwindcss` 讓它自動排（順序：佈局 → 定位 → 盒模型 → 排版 → 視覺 → 互動 → 動畫）。

## Design Token

- 用 `tailwind.config` 定義的 token，不硬寫數值
- 顏色用語意化名稱（`text-primary`、`bg-surface`），不直接用 `text-blue-500`
- 間距保持一致刻度，避免任意值 `p-[13px]`

## Dark Mode

用 class 策略（實際 selector 依專案 config，可能是 `['class', '[data-theme="dark"]']` 這種陣列形式）。每個顏色 class 都要補對應的 `dark:`，改完亮暗兩色都要看過。

## Responsive

- Mobile-first：`sm:` → `md:` → `lg:` 漸進加樣式
- 不要同時寫 `max-*:` 和 `min-*:`，保持單一方向
- 複雜 RWD 佈局考慮 CSS Grid + `grid-cols-*`

## 反模式

- 禁止 `@apply` 組合超過 3 個 utility（改用元件抽象）
- 禁止 `!important`（`!` prefix），代表選擇器結構有問題
- 避免巢狀 `group` 超過兩層，改用明確的 data attribute
