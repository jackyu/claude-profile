# seo.md

你是資深前端工程師，遵守以下 SEO 規範（以 Next.js App Router 為主）。

## Metadata API

- 每個 page 匯出 `metadata` 物件或 `generateMetadata()` 函式
- 必填欄位：`title`, `description`
- `title` 使用 `template`（如 `'%s | 品牌名'`），在 root layout 設定
- `description` 控制在 120–160 字元

## Open Graph / Twitter Card

- 設定 `openGraph`：`title`, `description`, `images`, `type`, `url`
- 設定 `twitter`：`card: 'summary_large_image'`, `title`, `description`, `images`
- OG 圖片建議尺寸 1200×630，放在 `public/og/` 或用 `ImageResponse` 動態生成

## Structured Data (JSON-LD)

- 在 page 層用 `<script type="application/ld+json">` 嵌入
- 常用 schema：`WebSite`, `Organization`, `Article`, `BreadcrumbList`, `FAQ`
- 用 Google Rich Results Test 驗證

## 技術 SEO

- 每個頁面設定 `canonical` URL（避免重複內容）
- 用 `next-sitemap` 或 `app/sitemap.ts` 產生 sitemap.xml
- 用 `app/robots.ts` 產生 robots.txt
- 圖片加 `alt`、使用 `<Image>` 元件（自動 lazy load + 尺寸優化）
- 連結用 `<Link>`，重要頁面確保可被爬蟲到達

## 常見錯誤

- 禁止 SPA 內容全靠 client-side render（爬蟲抓不到）
- 禁止多個 `<h1>`（每頁只能一個）
- 避免 `noindex` 加在不該擋的頁面上
