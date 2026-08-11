# seo.md — Next.js App Router SEO

## Metadata API

- 每個 page 匯出 `metadata` 或 `generateMetadata()`
- 必填 `title`、`description`；`description` 控制在 120–160 字元
- `title` 在 root layout 設 `template`（如 `'%s | 品牌名'`）

## 分享卡片與結構化資料

- `openGraph` 給 `title`／`description`／`images`／`type`／`url`；OG 圖 1200×630，放 `public/og/` 或用 `ImageResponse` 動態生成
- `twitter` 用 `card: 'summary_large_image'`
- JSON-LD 在 page 層用 `<script type="application/ld+json">` 嵌入；常用 schema `WebSite`、`Organization`、`Article`、`BreadcrumbList`、`FAQ`，用 Google Rich Results Test 驗

## 技術 SEO

- 每頁設 `canonical` URL，避免重複內容
- `app/sitemap.ts` 產 sitemap.xml、`app/robots.ts` 產 robots.txt
- 重要頁面確保爬蟲走得到（連結與圖片的規則見 html-semantics.md）

## 常見錯誤

- 內容全靠 client-side render，爬蟲抓不到
- `noindex` 加在不該擋的頁面上
