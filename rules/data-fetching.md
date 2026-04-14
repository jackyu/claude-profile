# data-fetching.md

使用 TanStack React Query（v5）作為資料請求與快取管理方案。

## Query 規範

- 每個 API endpoint 封裝成獨立的 custom hook（如 `useGetUser`、`useGetOrders`）
- Query Key 使用陣列格式並保持一致：`['users', userId]`、`['orders', { status }]`
- Query Key 統一在 `services/queryKeys.ts` 集中管理
- 使用 `queryOptions()` helper 建立可重用的 query 設定

## Mutation 規範

- Mutation 成功後用 `queryClient.invalidateQueries` 更新相關快取
- 提供 `onError` 統一錯誤處理，搭配 toast 通知使用者
- 樂觀更新（Optimistic Update）僅用於使用者體驗敏感的操作

## API 層

- API 呼叫函式放在 `services/` 目錄，與 hook 分離
- 使用 `fetch` 或 `ky` / `axios`，統一 base URL 與 interceptor
- Response 用 Zod schema 驗證，確保型別安全
- 錯誤統一用自訂 `ApiError` class 包裝

## Query 資料同步至表單（可編輯場景）

當 `useQuery` 取得的資料需同步至 `useState` 供使用者編輯時，必須防止背景 refetch 覆蓋編輯中的值。

React Query 預設 `refetchOnWindowFocus: true`，閒置後切回視窗會觸發 refetch → `data` 更新 → `useEffect` 重新執行 → 覆蓋本地值。

**必做：**

1. hook 設定 `refetchOnWindowFocus: false`
2. `useEffect` 僅一次性同步，用 `useRef` 標記已初始化

```tsx
// ✅
const isInitialized = useRef(false);
useEffect(() => {
  if (data && !isInitialized.current) {
    setFormValue(data.value);
    isInitialized.current = true;
  }
}, [data]);

// ❌ data 變更時覆蓋編輯中的值
useEffect(() => {
  if (data) setFormValue(data.value);
}, [data]);
```

## Server Component 資料取得

- Server Component 直接用 `fetch` + Next.js cache 機制
- 不要在 Server Component 中使用 React Query
