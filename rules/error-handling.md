# error-handling.md

錯誤處理與使用者回饋規範。

## Next.js Error Boundary

- 每個路由段落提供 `error.tsx`，漏接的錯誤由全域 `global-error.tsx` 接住
- `not-found.tsx` 處理 404 頁面

## API 錯誤處理

- `ApiError` 攜帶後端 `message`／`errorCode`，不只 status code
- Toast 顯示後端訊息（如「庫存不足」），非通用「伺服器錯誤」
- 401 自動觸發重新登入；網路錯誤提供手動 retry 按鈕
- Sentry 回報時附帶完整 error response（status + message + errorCode）

## try..catch 規則

- API 呼叫、非同步操作必須用 try..catch 包裹
- catch 中區分 `ApiError`（已知）與未知錯誤，分別處理
- 不要空 catch，至少 log 或 re-throw
- 避免巢狀 try..catch，用 early return 或抽函式簡化

## 表單錯誤

- 欄位級別錯誤即時顯示（inline validation），送出失敗顯示具體訊息
- 成功操作給予明確回饋（toast / redirect）
- 前端錯誤透過 Sentry 回報，禁止 `console.log` 進 production
