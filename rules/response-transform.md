# response-transform.md — API 回應轉換

API 回應一律 immutable 處理。禁止直接改 response 物件——`data.a.b = c`、`app.time = toDate(app.time)`、`forEach` 內 mutate 都不行，一律用展開運算子產生新物件。

## 原則

- 陣列轉換用 `.map()` 回傳新陣列，禁止 `.forEach()` 內 mutate
- 巢狀物件逐層展開，每層都產生新 reference
- 轉換邏輯抽成純函式（input → output），不產生 side effect
