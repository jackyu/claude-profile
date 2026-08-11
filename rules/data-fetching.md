# data-fetching.md — React Query 資料請求與快取

用 TanStack React Query（v5）。

## Query

- 每個 API endpoint 包成獨立 hook（`useGetUser`、`useGetOrders`）
- Query Key 一律陣列格式，由各 feature 的 key factory 產出（`features/{feature}/api/keys.ts`）；跨 feature invalidate 就 import owner 的 factory，不准手拼字串
- 用 `queryOptions()` 建立可重用的設定

## Mutation

- 成功後用 `queryClient.invalidateQueries` 更新相關快取
- **`invalidateQueries` 不會因重抓失敗而 reject**（內部對每個 refetch 套 `.catch(noop)`，除非傳 `throwOnError`）。所以 `await` 它只代表「試過了」，不代表快取是新的——**禁止把畫面正確性建立在那次重抓成功之上**。有舊資料時重抓失敗會是 `isError` 但 `data` 仍在，畫面必須明示「可能不是最新」並給手動重抓
- 一定要給 `onError`；錯誤訊息怎麼呈現看 error-handling.md
- 樂觀更新（Optimistic Update）用於使用者體驗敏感的操作，**或當畫面正確性不該依賴重抓成功時**（樂觀值＝送出去的值，寫入成功即等於後端狀態；反而是「等重抓才更新畫面」在重抓失敗時會無聲停在舊值）。採用時 `onMutate`（`cancelQueries` + 快照 + 寫入）／`onError`（回滾）／`onSettled`（背景校正）三段缺一不可

## API 層

- 一操作一檔，fetch + `queryOptions` + hook 三層；放哪以 fe-arch 為準
- 用 `fetch` 或 `ky` / `axios`，統一 base URL 與 interceptor
- Response 過 Zod `parse()`，型別用 `z.infer<>` 推導，不手寫

## Query 資料同步至表單

`useQuery` 的資料要餵進 `useState` 給人編輯時，切回視窗觸發的自動 refetch 會蓋掉編輯到一半的值。兩件事必做：

1. hook 設 `refetchOnWindowFocus: false`
2. `useEffect` 只同步一次，用 `useRef` 標記已初始化

## Server Component

直接用 `fetch` + Next.js cache，不要用 React Query。
