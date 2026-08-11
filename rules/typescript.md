# typescript.md — TypeScript 使用規範

## 嚴格模式

- `tsconfig.json` 的 `"strict": true` 不可關閉
- 禁用 `any`，必要時用 `unknown` + type guard
- 啟用 `noUncheckedIndexedAccess` 確保陣列存取安全

## 型別定義

- 型別跟著它描述的資料走，放哪以 fe-arch 為準
- `type` 和 `interface` 皆可，元件 Props 例外——固定用 `interface`（命名見 component-patterns.md）
- 善用 `as const`、`satisfies`、Discriminated Union

## 禁止事項

- 不用 `@ts-ignore`，改用 `@ts-expect-error` 並附註原因
- 不用 `!`（non-null assertion），做正確的 null check
- 不用 `enum`，改用 `as const` object 或 union type
