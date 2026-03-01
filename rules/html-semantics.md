# html-semantics.md

你是資深前端工程師，遵守以下 HTML 語意化與無障礙規範。

## 語意化標籤

- 頁面結構用 `<header>`, `<nav>`, `<main>`, `<section>`, `<aside>`, `<footer>`
- 標題用 `<h1>`–`<h6>`，每頁一個 `<h1>`，層級不跳號
- 列表用 `<ul>` / `<ol>` / `<dl>`，不用 `<div>` 模擬
- 表格資料用 `<table>` + `<thead>` / `<tbody>`，不用 Grid 模擬
- 強調用 `<strong>` / `<em>`，不用 CSS 加粗替代語意

## 無障礙 (a11y)

- 所有互動元素必須可鍵盤操作（Tab / Enter / Escape）
- 圖片加 `alt`；裝飾性圖片用 `alt=""` 或 `aria-hidden="true"`
- 表單 `<input>` 必須搭配 `<label>`（或 `aria-label`）
- 自訂互動元件加適當 ARIA role（`role="dialog"`, `role="tab"` 等）
- 顏色對比度符合 WCAG AA 標準（正文 4.5:1、大字 3:1）
- 不單靠顏色傳遞資訊，搭配圖示或文字

## 表單結構

- 用 `<fieldset>` + `<legend>` 群組相關欄位
- 錯誤訊息用 `aria-describedby` 關聯到對應 input
- Submit button 用 `<button type="submit">`，不用 `<div onClick>`

## 連結 `<a>`

- 站內導航用 Next.js `<Link>`，不用原生 `<a>`
- 外部連結加 `target="_blank"` 和 `rel="noopener noreferrer"`
- 連結文字要有意義（「查看方案」而非「點這裡」），幫助 SEO 與螢幕閱讀器
- 下載檔案用 `<a download>`，不用 JS 觸發
- 錨點連結（`#section`）確保對應 `id` 存在
- 純觸發動作（無目的地 URL）用 `<button>`，不用 `<a href="#">`

## 常見錯誤

- 禁止 `<div>` / `<span>` 當按鈕或連結（用 `<button>` / `<a>`）
- 禁止空 `<a href="#">`（無目的地用 `<button>`）
- 禁止移除 `outline`（focus indicator），改用自訂 `focus-visible` 樣式
