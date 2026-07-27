# project-structure.md

Next.js App Router 專案結構規範。

## 檔案放置一律以 fe-arch skill 為準

**「這個檔案該放哪」不在本檔定義**——建立任何新檔案（元件、hook、API 層、測試、types）前，載入 `fe-arch` skill 走其決策流程（Phase 1–6），完整目錄地圖見該 skill 的 `references/architecture-reference.md`。

本檔只保留與位置無關的通則，避免兩份規範打架。

## 通則

- 頁面邏輯寫在 `app/` 內的 `page.tsx`，`page.tsx` 只做組裝（薄殼），不放業務邏輯
- Server Component 為預設，需要互動時才加 `'use client'`
- 元件主檔用具名檔案（`user-card.tsx`），`index.ts` 只做 re-export，不拿 `index.tsx` 當主檔
- 測試檔放在被測檔案同層的 `__tests__/` 目錄；E2E 例外，放專案根 `e2e/`
- fe-arch 未涵蓋的兩類：全域狀態（Zustand 等）放 `src/stores/`、跨 feature 常數放 `src/constants/`；只有單一 feature 用的則留在該 feature 內
