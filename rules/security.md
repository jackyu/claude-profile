# security.md — 前端安全規範

## 環境變數

- 機敏資料（API Key、Secret）絕對不進版控
- 前端可見的環境變數用 `NEXT_PUBLIC_` 前綴，確認不含機敏資訊
- Server-only 的密鑰放 `.env.local`，不加 `NEXT_PUBLIC_`
- `.env.example` 提供範本但不含真實值

## 資料處理

- 使用者輸入一律驗證（Zod），前後端都要
- 渲染使用者內容時防 XSS，避免 `dangerouslySetInnerHTML`
- URL 參數、query string 先 sanitize 再用

## 認證與授權

- Token 與敏感資料存 httpOnly cookie，不放 localStorage
- API Route 必須驗證 session / token
- 前端的權限檢查只是 UX 輔助，真正的授權在後端

## 機敏資訊與依賴

- 專案文件出現帳號密碼就主動問是不是真的要留，能換成環境變數或密鑰工具就換；review 時盯 hardcoded credentials
- 定期跑 audit（看專案用 `pnpm audit` 還是 `npm audit`）；不裝來源不明的套件，優先選維護活躍的
