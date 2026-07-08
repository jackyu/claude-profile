#!/bin/bash
# 安裝 Claude Code 自訂狀態列腳本
# 用法: bash status-line/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/statusline.sh"
TARGET="$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"

# 檢查 jq
if ! command -v jq &>/dev/null; then
  echo "❌ 需要 jq，請先安裝："
  echo "   macOS:  brew install jq"
  echo "   Ubuntu: sudo apt install jq"
  exit 1
fi

# 建立目錄
mkdir -p "$HOME/.claude"

# 備份舊腳本
if [ -f "$TARGET" ]; then
  cp "$TARGET" "${TARGET}.bak"
  echo "📦 已備份舊腳本至 ${TARGET}.bak"
fi

# 複製腳本
cp "$SOURCE" "$TARGET"
chmod +x "$TARGET"
echo "✅ 已安裝 statusline.sh → $TARGET"

# 更新 settings.json 中的 statusLine 設定
if [ -f "$SETTINGS" ]; then
  if grep -q '"statusLine"' "$SETTINGS"; then
    echo "ℹ️  settings.json 已有 statusLine 設定，請確認指向："
    echo "   \"command\": \"~/.claude/statusline.sh\""
    echo "   建議加上 \"refreshInterval\": 5（idle 時每 5 秒重跑，分支/時間才會即時更新）"
  else
    echo ""
    echo "📝 請在 $SETTINGS 中加入："
    echo '  "statusLine": {'
    echo '    "type": "command",'
    echo '    "command": "~/.claude/statusline.sh",'
    echo '    "refreshInterval": 5'
    echo '  }'
  fi
else
  echo ""
  echo "📝 未偵測到 $SETTINGS，請建立並加入："
  echo '{'
  echo '  "statusLine": {'
  echo '    "type": "command",'
  echo '    "command": "~/.claude/statusline.sh",'
  echo '    "refreshInterval": 5'
  echo '  }'
  echo '}'
fi

echo ""
echo "🎉 安裝完成！重新啟動 Claude Code 即可生效。"
