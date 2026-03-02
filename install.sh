#!/usr/bin/env bash
set -euo pipefail

# 取得腳本所在目錄（支援 symlink）
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
RULES_DIR="$SCRIPT_DIR/rules"

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Claude Code Rules 安裝工具         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# 檢查 rules 目錄是否存在
if [[ ! -d "$RULES_DIR" ]]; then
  echo -e "${RED}錯誤：找不到 rules/ 目錄（$RULES_DIR）${NC}"
  exit 1
fi

# 選擇安裝範圍
echo "請選擇安裝範圍："
echo ""
echo "  [1] User（全域）  → ~/.claude/rules/"
echo "  [2] Project（專案）→ <project>/.claude/rules/"
echo ""
read -rp "輸入選項 (1/2): " scope_choice

case "$scope_choice" in
  1)
    TARGET_DIR="$HOME/.claude/rules"
    echo ""
    echo -e "安裝目標：${GREEN}$TARGET_DIR${NC}"
    ;;
  2)
    echo ""
    read -rp "請輸入專案路徑（預設為 $PWD）: " project_path
    project_path="${project_path:-$PWD}"
    # 展開 ~ 為 $HOME
    project_path="${project_path/#\~/$HOME}"
    if [[ ! -d "$project_path" ]]; then
      echo -e "${RED}錯誤：目錄不存在 — $project_path${NC}"
      exit 1
    fi
    TARGET_DIR="$project_path/.claude/rules"
    echo ""
    echo -e "安裝目標：${GREEN}$TARGET_DIR${NC}"
    ;;
  *)
    echo -e "${RED}無效選項，請輸入 1 或 2${NC}"
    exit 1
    ;;
esac

# 衝突處理：目標目錄已有檔案
if [[ -d "$TARGET_DIR" ]] && ls "$TARGET_DIR"/*.md &>/dev/null; then
  echo ""
  echo -e "${YELLOW}⚠ 目標目錄已存在 rule 檔案${NC}"
  read -rp "要覆蓋現有檔案嗎？(y/N): " overwrite
  if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
    echo "已取消安裝。"
    exit 0
  fi
fi

# 建立目標目錄
mkdir -p "$TARGET_DIR"

# 複製 rules/*.md（排除 README.md）
count=0
for file in "$RULES_DIR"/*.md; do
  filename="$(basename "$file")"
  if [[ "$filename" == "README.md" ]]; then
    continue
  fi
  cp "$file" "$TARGET_DIR/$filename"
  count=$((count + 1))
done

# 結果摘要
echo ""
echo -e "${GREEN}✔ 安裝完成！${NC}"
echo ""
echo "  已安裝 ${count} 個 rule 檔案"
echo "  目標路徑：$TARGET_DIR"
echo ""
