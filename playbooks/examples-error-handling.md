# examples-error-handling.md — 錯誤處理完整範例

> 本檔是 `~/.claude/rules/error-handling.md` 的範例附錄。判準在 rules 檔（自動載入）；需要完整範例碼時才讀本檔。

## fetch / 非同步錯誤分流：完整對照

```ts
// BAD — 一個 catch 概括，HTTP 錯誤接不到、讀檔失敗被誤標網路錯誤、空檔靜默成功
try {
  const data = await fileToBase64(file);          // 空檔回 "" → 靜默成功
  const res = await fetch(url, { body: data });   // 500 不會 throw，漏判
  onSuccess();
} catch {
  toast.error("網路錯誤");                          // 讀檔/解析錯誤也跳這句
}

// GOOD — 分流：驗證→讀檔→HTTP 非 ok→網路 throw，各給對的訊息
try {
  let payload: string;
  try {
    payload = await fileToBase64(file);            // 空 payload 內部 reject
  } catch (readErr) {
    Sentry.captureException(readErr);
    toast.error(readErr instanceof Error ? readErr.message : "檔案讀取失敗");
    return;                                        // 不送出
  }
  const res = await fetch(url, { body: payload });
  if (!res.ok) {                                   // HTTP 錯誤靠 !res.ok
    const body = await res.json().catch(() => ({}));
    const msg = typeof body?.message === "string" ? body.message : "";
    Sentry.captureMessage("submit failed", { level: "error", extra: { status: res.status, body } });
    toast.error(msg || "上傳失敗，請稍後再試");      // 後端訊息優先、fallback 自然
    return;
  }
  toast.success("已送出"); onSuccess();
} catch (err) {
  Sentry.captureException(err);
  toast.error("網路連線異常，請稍後再試");           // 此處才是真正網路層失敗
}
```

## 分流各層的訊息原則（對照上例）

- **前置驗證**（缺欄位／格式／大小／空檔）→ 就地即時呈現（欄位或區塊紅框），不只 toast、不拖到送出才報。
- **資料準備失敗**（FileReader、parse）→ 顯示該層訊息，且**不送出請求**（early return）。
- **HTTP 非 ok** → 優先顯示後端 `message`；無則用貼合當前操作的自然 fallback（「上傳失敗，請稍後再試」，不要沿用彆扭字串如「處理完成失敗」）。
- **真正網路層失敗**（fetch 本身 throw）→ 才顯示「網路連線異常」；外層 catch 不可武斷標成網路錯誤（它可能接到讀檔／parse／程式錯誤）。
- **禁止靜默成功**：空／部分 payload（如 base64 為空字串）視為失敗 reject，不可當成功送出或顯示成功 toast。
- **Sentry 不只在 throw**：HTTP 非 ok 也要回報（附 status + body），否則持續 5xx 對維運不可見。
