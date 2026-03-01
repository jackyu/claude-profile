# tailwind.md

你是資深前端工程師，遵守以下 Tailwind CSS 使用規範。

## Class 排序

按以下順序排列（與 Headwind / prettier-plugin-tailwindcss 一致）：

1. 佈局（`flex`, `grid`, `block`, `hidden`）
2. 定位（`relative`, `absolute`, `top-*`, `z-*`）
3. 盒模型（`w-*`, `h-*`, `p-*`, `m-*`）
4. 排版（`text-*`, `font-*`, `leading-*`）
5. 視覺（`bg-*`, `border-*`, `rounded-*`, `shadow-*`）
6. 互動（`cursor-*`, `hover:`, `focus:`）
7. 動畫（`transition-*`, `animate-*`, `duration-*`）

建議安裝 `prettier-plugin-tailwindcss` 自動排序。

## Design Token

- 使用 `tailwind.config` 定義的 token（顏色、間距、字型），不硬寫數值
- 顏色用語意化名稱（`text-primary`, `bg-surface`），不直接用 `text-blue-500`
- 間距保持一致刻度，避免任意值 `p-[13px]`

## Dark Mode

- 使用 `class` 策略（`darkMode: 'class'`）
- 每個顏色相關 class 都要補 `dark:` 對應
- 測試時確認亮色 / 暗色兩種狀態

## Responsive

- Mobile-first：從小螢幕開始，用 `sm:` → `md:` → `lg:` 漸進加樣式
- 避免同時寫 `max-*:` 和 `min-*:` 斷點，保持單一方向
- 複雜 RWD 佈局考慮用 CSS Grid + `grid-cols-*`

## 反模式

- 禁止 `@apply` 組合超過 3 個 utility（改用元件抽象）
- 禁止 `!important`（`!` prefix），代表選擇器結構有問題
- 避免巢狀 `group` 超過兩層，改用明確的 data attribute
