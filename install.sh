#!/usr/bin/env bash
set -euo pipefail

# 取得腳本所在目錄（支援 symlink）
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
RULES_DIR="$SCRIPT_DIR/rules"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
OUTPUT_STYLES_DIR="$SCRIPT_DIR/output-styles"

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Claude Code 設定安裝工具           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# 安裝 rules/*.md（排除 README.md）到指定目錄
install_rules() {
  local target_dir="$1"

  if [[ ! -d "$RULES_DIR" ]]; then
    echo -e "${RED}錯誤：找不到 rules/ 目錄（$RULES_DIR）${NC}"
    exit 1
  fi

  echo ""
  echo -e "安裝目標：${GREEN}$target_dir${NC}"

  # 衝突處理：目標目錄已有 rule 檔案
  if [[ -d "$target_dir" ]] && ls "$target_dir"/*.md &>/dev/null; then
    echo ""
    echo -e "${YELLOW}⚠ 目標目錄已存在 rule 檔案${NC}"
    read -rp "要覆蓋現有檔案嗎？(y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      echo "已取消安裝。"
      exit 0
    fi
  fi

  mkdir -p "$target_dir"

  local count=0
  local file filename
  for file in "$RULES_DIR"/*.md; do
    filename="$(basename "$file")"
    [[ "$filename" == "README.md" ]] && continue
    cp "$file" "$target_dir/$filename"
    count=$((count + 1))
  done

  echo ""
  echo -e "${GREEN}✔ 已安裝 ${count} 個 rule 檔案${NC}"
  echo "  目標路徑：$target_dir"
}

# 同步 scripts/ 下的 .sh 與 .env.example 到 ~/.claude/scripts/
# 保留目錄結構、自動 chmod +x；絕不覆蓋既有的 .env（含真實憑證）
install_scripts() {
  local target_dir="$HOME/.claude/scripts"

  if [[ ! -d "$SCRIPTS_DIR" ]]; then
    echo -e "${RED}錯誤：找不到 scripts/ 目錄（$SCRIPTS_DIR）${NC}"
    exit 1
  fi

  echo ""
  echo -e "安裝目標：${GREEN}$target_dir${NC}"
  echo -e "${YELLOW}註：僅同步 .sh 與 .env.example；既有的 .env（含真實憑證）不會被覆蓋。${NC}"

  # 衝突處理：目標目錄已有腳本
  if [[ -d "$target_dir" ]] && [[ -n "$(find "$target_dir" -name '*.sh' -print -quit 2>/dev/null)" ]]; then
    echo ""
    echo -e "${YELLOW}⚠ 目標目錄已存在腳本${NC}"
    read -rp "要覆蓋現有腳本嗎？(y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      echo "已取消安裝。"
      exit 0
    fi
  fi

  mkdir -p "$target_dir"

  local count=0
  local file rel dest
  while IFS= read -r -d '' file; do
    rel="${file#"$SCRIPTS_DIR"/}"
    dest="$target_dir/$rel"
    mkdir -p "$(dirname "$dest")"
    cp "$file" "$dest"
    [[ "$file" == *.sh ]] && chmod +x "$dest"
    count=$((count + 1))
  done < <(find "$SCRIPTS_DIR" -type f \( -name '*.sh' -o -name '.env.example' \) -print0)

  echo ""
  echo -e "${GREEN}✔ 已安裝 ${count} 個腳本檔案${NC}"
  echo "  目標路徑：$target_dir"
  echo ""
  echo -e "${YELLOW}下一步：建立 GitLab 憑證檔（腳本需要）${NC}"
  echo "  cp $target_dir/gitlab/.env.example $target_dir/gitlab/.env"
  echo "  # 編輯 .env 填入你的 GITLAB_PERSONAL_ACCESS_TOKEN 與 GITLAB_API_URL"
}

# 安裝 output-styles/*.md 到 ~/.claude/output-styles/
# 注意：安裝後需在 settings 設定 "outputStyle": "<style name>" 並重啟 session 才生效
install_output_styles() {
  local target_dir="$HOME/.claude/output-styles"

  if [[ ! -d "$OUTPUT_STYLES_DIR" ]]; then
    echo -e "${RED}錯誤：找不到 output-styles/ 目錄（$OUTPUT_STYLES_DIR）${NC}"
    exit 1
  fi

  echo ""
  echo -e "安裝目標：${GREEN}$target_dir${NC}"

  # 衝突處理：目標目錄已有 output style 檔案
  if [[ -d "$target_dir" ]] && ls "$target_dir"/*.md &>/dev/null; then
    echo ""
    echo -e "${YELLOW}⚠ 目標目錄已存在 output style 檔案${NC}"
    read -rp "要覆蓋現有檔案嗎？(y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      echo "已取消安裝。"
      exit 0
    fi
  fi

  mkdir -p "$target_dir"

  local count=0
  local file
  for file in "$OUTPUT_STYLES_DIR"/*.md; do
    cp "$file" "$target_dir/$(basename "$file")"
    count=$((count + 1))
  done

  echo ""
  echo -e "${GREEN}✔ 已安裝 ${count} 個 output style 檔案${NC}"
  echo "  目標路徑：$target_dir"
  echo ""
  echo -e "${YELLOW}下一步：在 ~/.claude/settings.json 設定 \"outputStyle\": \"communication-style\"${NC}"
  echo "  （或在 Claude Code 內用 /output-style 選擇；需重啟 session 或 /clear 才生效）"
}

# 選擇安裝項目
echo "請選擇安裝項目："
echo ""
echo "  [1] Rules（規範）        → User 全域    ~/.claude/rules/"
echo "  [2] Rules（規範）        → Project 專案  <project>/.claude/rules/"
echo "  [3] Scripts（腳本）      → ~/.claude/scripts/"
echo "  [4] Output Styles（語氣）→ ~/.claude/output-styles/"
echo ""
read -rp "輸入選項 (1/2/3/4): " choice

case "$choice" in
  1)
    install_rules "$HOME/.claude/rules"
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
    install_rules "$project_path/.claude/rules"
    ;;
  3)
    install_scripts
    ;;
  4)
    install_output_styles
    ;;
  *)
    echo -e "${RED}無效選項，請輸入 1、2、3 或 4${NC}"
    exit 1
    ;;
esac

echo ""
