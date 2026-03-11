#!/bin/bash
# Install notify-complete hook into ~/.claude/hooks/
# Usage: ./install.sh

set -e

HOOK_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create hooks directory
mkdir -p "$HOOK_DIR"

# Copy hook files
cp "$SCRIPT_DIR/notify-complete.sh" "$HOOK_DIR/notify-complete.sh"
cp "$SCRIPT_DIR/jump-to-tab.scpt" "$HOOK_DIR/jump-to-tab.scpt"
chmod +x "$HOOK_DIR/notify-complete.sh"

echo "✅ Hook installed to $HOOK_DIR/notify-complete.sh"
echo "✅ AppleScript installed to $HOOK_DIR/jump-to-tab.scpt"

# Check dependency
if ! command -v terminal-notifier &>/dev/null; then
  echo ""
  echo "⚠️  terminal-notifier 未安裝，請執行："
  echo "  brew install terminal-notifier"
fi

# Check settings.json
if [ -f "$SETTINGS_FILE" ]; then
  if grep -q "notify-complete" "$SETTINGS_FILE" 2>/dev/null; then
    echo ""
    echo "ℹ️  Hook already configured in $SETTINGS_FILE"
    exit 0
  fi
fi

echo ""
echo "📝 Add this to your $SETTINGS_FILE:"
echo ""
cat <<'CONFIG'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/notify-complete.sh"
          }
        ]
      }
    ]
  }
}
CONFIG
