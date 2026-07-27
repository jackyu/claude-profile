# testing-vitest.md

使用 Vitest + React Testing Library 的測試規範。

## 基本原則

- 每個元件至少要有基本 render 測試
- 測試行為（使用者看到什麼、點了什麼），不測實作細節
- 測試檔案放在被測檔案同層的 `__tests__/` 目錄：`__tests__/component-name.test.tsx`（檔名 kebab-case，與被測檔同名）
- 用 `describe` 分群組，`it` 描述用英文、以動詞開頭

## Vitest 設定

- 設定檔用 `vitest.config.ts`，繼承 `vite.config.ts`
- 全域 setup 放 `test/setup.ts`，在 `setupFiles` 中引入
- 使用 `@testing-library/jest-dom` 的 matchers（透過 setup 引入）
- 善用 `vi.fn()`、`vi.mock()`、`vi.spyOn()` 進行 mock

## Mock 規範

- API 請求用 MSW（Mock Service Worker）
- 不要 mock React Query 本身，mock 底層的 fetch
- 全域 mock 放 `__mocks__/` 或 `test/setup.ts`

## 覆蓋率

- 目標：核心業務邏輯 ≥ 80%
- 新功能必須附帶對應測試
- 修 bug 時先寫失敗測試再修復（TDD 精神）
