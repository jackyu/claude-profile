# project-structure.md

Next.js App Router 專案結構規範。

## 目錄結構

```
src/
├── app/                  # App Router 路由與頁面
│   ├── (auth)/           # Route Group
│   ├── api/              # Route Handlers
│   └── layout.tsx
├── components/
│   ├── ui/               # 通用 UI 元件（Button, Modal, Input）
│   └── features/         # 業務功能元件（UserCard, OrderTable）
├── hooks/                # 自訂 Hooks
├── lib/                  # 工具函式、設定、第三方封裝
├── services/             # API 呼叫層（搭配 React Query）
├── stores/               # 全域狀態（Zustand 等）
├── types/                # 共用型別定義
└── constants/            # 常數與 enum
```

## 規則

- 頁面邏輯寫在 `app/` 內的 `page.tsx`，不在頁面檔放業務元件
- 共用元件放 `components/ui/`，功能元件放 `components/features/`
- 每個元件資料夾可包含 `index.tsx`、`*.test.tsx`、`*.stories.tsx`
- Server Component 為預設，需要互動時才加 `'use client'`
