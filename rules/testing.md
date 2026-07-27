# testing.md

React 元件測試規範（Jest 或 Vitest，依專案偵測）。

## 選型裁決（先做，禁止假設）

看 lockfile／`devDependencies` 偵測要用 Jest 還是 Vitest——出現 `vitest` 用 Vitest，出現 `jest` 用 Jest。`coverage-check.sh` 也依此自動選 runner，勿假設或硬套其一。

## 基本原則

- 每個元件至少要有基本 render 測試
- 測試行為（使用者看到什麼、點了什麼），不測實作細節
- 測試檔案放在被測檔案同層的 `__tests__/` 目錄：`__tests__/component-name.test.tsx`（檔名 kebab-case，與被測檔同名）
- 用 `describe` 分群組，`it` 描述用英文、以動詞開頭

## 設定

- **Vitest**：`vitest.config.ts` 繼承 `vite.config.ts`；全域 setup 放 `test/setup.ts`（在 `setupFiles` 引入）；mock 用 `vi.fn()`／`vi.mock()`／`vi.spyOn()`
- **Jest**：`jest.config.ts`（或 `package.json` 的 `jest` 欄位）；全域 setup 放 `test/setup.ts`（在 `setupFilesAfterFramework` 引入）；需 transform 時用 `ts-jest` 或 `@swc/jest`；mock 用 `jest.fn()`／`jest.mock()`／`jest.spyOn()`
- 兩者都用 `@testing-library/jest-dom` 擴充 matchers（透過 setup 引入）

## Mock 規範

- API 請求用 MSW（Mock Service Worker）
- 不要 mock React Query 本身，mock 底層的 fetch
- 全域 mock 放 `__mocks__/`（Jest 自動辨識）或 `test/setup.ts`

## 覆蓋率（一個事實，兩個層級）

- **hook 檢查**：`coverage-check.sh` 於 TaskCompleted 執行，預設 line 70／branch 60（可用 `LINE_THRESHOLD`／`BRANCH_THRESHOLD` env 覆寫）。實際行為：**僅提示、不阻擋**（測試失敗 exit 1、門檻不足 exit 0，皆非 hook 阻擋碼）——測試結果與覆蓋率都要自己核對輸出
- **目標**：核心業務邏輯 ≥ 80
- 新功能必須附帶對應測試；修 bug 時先寫失敗測試再修復（TDD 精神）
