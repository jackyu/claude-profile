# response-transform.md

API 回應資料轉換必須遵守 immutable 原則，禁止直接修改 response 物件。

## 禁止：直接修改 response

```ts
// BAD — 直接 mutate 原始物件
data.applicationReviewData.bankInfo = { ...rest, subAccount: sub_account };
app.submissionTime = toDateOrNull(app.submissionTime);
records.forEach((r) => { r.updateTime = new Date(r.updateTime); });
```

## 正確：產生新物件

```ts
// GOOD — 展開運算子建立新物件，巢狀資料逐層展開
const transformed = {
  ...data,
  submissionTime: toDateOrNull(data.submissionTime),
  applicationReviewData: data.applicationReviewData
    ? {
        ...data.applicationReviewData,
        updateRecords: data.applicationReviewData.updateRecords.map((r) => ({
          ...r,
          updateTime: toDateOrNull(r.updateTime) ?? new Date(0),
        })),
      }
    : undefined,
};
```

## 原則

- 陣列轉換用 `.map()` 回傳新陣列，禁止 `.forEach()` 內 mutate
- 巢狀物件逐層展開，每層都產生新 reference
- 轉換邏輯抽成純函式（input → output），不產生 side effect
