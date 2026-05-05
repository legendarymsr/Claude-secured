#!/usr/bin/env bash
# PostToolUse hook — desktop notification after file edits
# See: docs/04-hooks.md
#
# Install in settings.json:
#   "hooks": {
#     "PostToolUse": [{ "matcher": "Edit", "hooks": [{ "type": "command", "command": "/path/to/post-tool-notify.sh" }] }]
#   }
#
# Supports Linux (notify-send) and macOS (osascript)
# Silently exits on unsupported platforms

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // "a file"')
SHORT_PATH=$(basename "$FILE_PATH")

TITLE="Claude Code"
MESSAGE="Edited: $SHORT_PATH"

OS="$(uname -s)"

case "$OS" in
  Linux)
    if command -v notify-send &>/dev/null; then
      notify-send "$TITLE" "$MESSAGE" --urgency=low --expire-time=3000
    fi
    ;;
  Darwin)
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
    ;;
esac

exit 0
