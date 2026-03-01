# testing.md

測試規範，使用 Vitest + React Testing Library。

## 基本原則

- 每個元件至少要有基本 render 測試
- 測試行為（使用者看到什麼、點了什麼），不測實作細節
- 測試檔案放在同層目錄：`ComponentName.test.tsx`
- 用 `describe` 分群組，`it` 描述用英文、以動詞開頭

## 測試範圍

- **Unit Test**：工具函式、custom hooks、pure function
- **Integration Test**：元件互動、表單送出、API mock 整合
- **E2E**（Playwright）：關鍵使用者流程（登入、結帳等）

## Mock 規範

- API 請求用 MSW（Mock Service Worker）
- 不要 mock React Query 本身，mock 底層的 fetch
- 全域 mock 放 `__mocks__/` 或 `test/setup.ts`

## 覆蓋率

- 目標：核心業務邏輯 ≥ 80%
- 新功能必須附帶對應測試
- 修 bug 時先寫失敗測試再修復（TDD 精神）
