# testing-jest.md

使用 Jest + React Testing Library 的測試規範。

## 基本原則

- 每個元件至少要有基本 render 測試
- 測試行為（使用者看到什麼、點了什麼），不測實作細節
- 測試檔案放在同層目錄：`ComponentName.test.tsx`
- 用 `describe` 分群組，`it` 描述用英文、以動詞開頭

## Jest 設定

- 設定檔用 `jest.config.ts`（或 `package.json` 中的 `jest` 欄位）
- 全域 setup 放 `test/setup.ts`，在 `setupFilesAfterFramework` 中引入
- 使用 `@testing-library/jest-dom` 擴充 matchers
- 善用 `jest.fn()`、`jest.mock()`、`jest.spyOn()` 進行 mock
- 需要 transform 時用 `ts-jest` 或 `@swc/jest`

## Mock 規範

- API 請求用 MSW（Mock Service Worker）
- 不要 mock React Query 本身，mock 底層的 fetch
- 全域 mock 放 `__mocks__/` 目錄（Jest 自動辨識）
- 手動 mock 模組時用 `jest.mock('module-name')`

## 覆蓋率

- 目標：核心業務邏輯 ≥ 80%
- 新功能必須附帶對應測試
- 修 bug 時先寫失敗測試再修復（TDD 精神）
