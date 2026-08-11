# testing.md — React 元件測試

## 選型裁決（先做，禁止假設）

看 lockfile／`devDependencies` 決定用 Jest 還是 Vitest——出現 `vitest` 用 Vitest，出現 `jest` 用 Jest。`coverage-check.sh` 也依此自動選 runner，不要假設或硬套其一。

## 基本原則

- 每個元件至少要有基本 render 測試
- 測試行為（使用者看到什麼、點了什麼），不測實作細節
- 測試檔放同層 `__tests__/`、檔名與被測檔同名（位置以 fe-arch 為準）
- 用 `describe` 分群組，`it` 描述用英文、以動詞開頭

## 設定

- 全域 setup 都放 `test/setup.ts`：Vitest 從 `setupFiles` 引入、Jest 從 `setupFilesAfterFramework`
- mock 前綴跟著 runner 走：`vi.fn()`／`vi.mock()` 對 `jest.fn()`／`jest.mock()`
- 兩者都用 `@testing-library/jest-dom` 擴充 matchers

## Mock 規範

- API 請求用 MSW（Mock Service Worker）
- 不要 mock React Query 本身，mock 底層的 fetch
- 全域 mock 放 `__mocks__/`（Jest 自動辨識）或 `test/setup.ts`

## 覆蓋率

門檻與 hook 實際行為見 CLAUDE.md 鐵律 6（`coverage-check.sh` 僅提示不阻擋，要自己核對輸出）。核心業務邏輯目標 ≥ 80。
