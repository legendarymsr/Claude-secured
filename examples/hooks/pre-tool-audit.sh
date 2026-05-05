#!/usr/bin/env bash
# PreToolUse hook — writes every tool call to a structured audit log
# See: docs/04-hooks.md
#
# Install in settings.json:
#   "hooks": {
#     "PreToolUse": [{ "matcher": "*", "hooks": [{ "type": "command", "command": "/path/to/pre-tool-audit.sh" }] }]
#   }
#
# Log location: /tmp/claude-audit/YYYY-MM-DD.log (rotate daily)
# This hook always exits 0 (pass-through with logging — never blocks)

set -euo pipefail

LOG_DIR="/tmp/claude-audit"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"

mkdir -p "$LOG_DIR"

# Read the full JSON payload from stdin
INPUT=$(cat)

# Extract fields for the log line
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

# Build a compact JSON log entry
LOG_ENTRY=$(jq -n \
  --arg ts "$TIMESTAMP" \
  --arg session "$SESSION_ID" \
  --arg tool "$TOOL_NAME" \
  --argjson input "$INPUT" \
  '{
    timestamp: $ts,
    session_id: $session,
    tool_name: $tool,
    tool_input: $input.tool_input
  }')

# Append to daily log file (one JSON object per line)
echo "$LOG_ENTRY" >> "$LOG_FILE"

# Always allow — this hook only logs
exit 0
