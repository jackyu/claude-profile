# component-patterns.md — React 元件撰寫規範

## 基本原則

- 用 function declaration（`function MyComponent()`），不用 arrow function export
- Props 用 interface 定義，命名 `{ComponentName}Props`
- 單一元件檔案不超過 200 行，超過就拆分

## 狀態管理

- 局部狀態用 `useState` / `useReducer`
- 跨元件共享用 Zustand 或 Context（僅限低頻更新場景）
- 表單用 React Hook Form + Zod resolver
- prop drilling 不要超過 3 層，改用 composition 或 context

## 效能

- 列表渲染必須給穩定的 `key`，不用 index
- 昂貴計算用 `useMemo`，callback 穩定性用 `useCallback`
- 不要過度優化——只在有明確效能問題時才加 memo
- 圖片用 `next/image`，設定適當 `sizes` 與 `priority`

## Server vs Client Component

- 預設用 Server Component
- 只在需要 hooks、事件處理、瀏覽器 API 時才用 `'use client'`
- 把 client 邏輯推到葉節點，保持父層是 server component
