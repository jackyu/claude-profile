#!/bin/bash
# Install coverage-check hook into a project's .claude/hooks/ directory
# Usage: ./install.sh [project-path]

set -e

PROJECT_DIR="${1:-.}"
HOOK_DIR="$PROJECT_DIR/.claude/hooks"
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SRC="$SCRIPT_DIR/coverage-check.sh"

# Create hooks directory
mkdir -p "$HOOK_DIR"

# Copy hook script
cp "$HOOK_SRC" "$HOOK_DIR/coverage-check.sh"
chmod +x "$HOOK_DIR/coverage-check.sh"

echo "✅ Hook installed to $HOOK_DIR/coverage-check.sh"

# Update settings.json
if [ -f "$SETTINGS_FILE" ]; then
  # Check if hook already exists
  if grep -q "coverage-check" "$SETTINGS_FILE" 2>/dev/null; then
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
        "command": "bash .claude/hooks/coverage-check.sh",
        "description": "Auto-check test coverage on task completion"
      }
    ]
  }
}
CONFIG
echo ""
echo "Or set custom thresholds with environment variables:"
echo "  LINE_THRESHOLD=80 BRANCH_THRESHOLD=70 bash .claude/hooks/coverage-check.sh"
