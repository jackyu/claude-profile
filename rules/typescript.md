# typescript.md

TypeScript 使用規範。

## 嚴格模式

- `tsconfig.json` 啟用 `"strict": true`，不可關閉
- 禁用 `any`，必要時用 `unknown` + type guard
- 啟用 `noUncheckedIndexedAccess` 確保陣列存取安全

## 型別定義

- 型別跟著它描述的資料走：feature 內的放 `features/{feature}/types/`，跨 feature 的領域型別放領域 feature 的 `types/`（位置以 fe-arch skill 為準）
- API Response 型別從 Zod schema 用 `z.infer<>` 推導
- 元件 Props 用 `interface`，其他場景 `type` 和 `interface` 皆可
- 善用 `as const`、`satisfies`、Discriminated Union

## 禁止事項

- 不使用 `@ts-ignore`，改用 `@ts-expect-error` 並附註原因
- 不使用 `!`（non-null assertion），做正確的 null check
- 不使用 `enum`，改用 `as const` object 或 union type
