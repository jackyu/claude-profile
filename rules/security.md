# security.md

前端安全規範。

## 環境變數

- 機敏資料（API Key、Secret）絕對不進版控
- 前端可見的環境變數用 `NEXT_PUBLIC_` 前綴，確認不含機敏資訊
- Server-only 的密鑰放在 `.env.local`，不加 `NEXT_PUBLIC_`
- `.env.example` 提供範本但不含真實值

## 資料處理

- 使用者輸入一律做驗證（Zod），前後端都要
- 渲染使用者內容時防範 XSS，避免 `dangerouslySetInnerHTML`
- URL 參數、query string 要做 sanitize 再使用
- 敏感資料不存 localStorage，改用 httpOnly cookie

## 認證與授權

- Token 存在 httpOnly cookie，不放 localStorage
- API Route 必須驗證 session / token
- 前端的權限檢查只是 UX 輔助，真正的授權在後端

## 依賴安全

- 定期執行 `npm audit`
- 不安裝來源不明的套件，優先選擇維護活躍的套件
