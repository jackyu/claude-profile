# error-handling.md

錯誤處理與使用者回饋規範。

## Next.js Error Boundary

- 每個路由段落提供 `error.tsx` 處理未預期錯誤
- 全域提供 `global-error.tsx` 作為最終兜底
- `not-found.tsx` 處理 404 頁面
- `loading.tsx` 搭配 Suspense 處理載入狀態

## API 錯誤處理

- 統一用 `ApiError` class 區分錯誤類型（400/401/403/404/500）
- React Query 的 `onError` 統一用 toast 通知使用者
- 401 自動觸發重新登入流程
- 網路錯誤顯示重試提示，提供手動 retry 按鈕

## 表單錯誤

- 欄位級別錯誤即時顯示（inline validation）
- 表單送出失敗顯示具體錯誤訊息，不用通用提示
- 成功操作給予明確回饋（toast / redirect）

## 日誌

- 前端錯誤透過 Sentry 或類似服務回報
- `console.log` 不進 production，用 lint rule 攔截
