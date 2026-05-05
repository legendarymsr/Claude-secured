#!/usr/bin/env bash
# PermissionRequest hook — logs every permission dialog and optionally auto-denies patterns
# See: docs/04-hooks.md
#
# Install in settings.json:
#   "hooks": {
#     "PermissionRequest": [{ "matcher": "*", "hooks": [{ "type": "command", "command": "/path/to/permission-request-logger.sh" }] }]
#   }

set -euo pipefail

LOG_DIR="/tmp/claude-audit"
LOG_FILE="$LOG_DIR/permissions-$(date +%Y-%m-%d).log"

mkdir -p "$LOG_DIR"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
PERMISSION_TYPE=$(echo "$INPUT" | jq -r '.permission_type // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Log the request
LOG_ENTRY=$(jq -n \
  --arg ts "$TIMESTAMP" \
  --arg tool "$TOOL_NAME" \
  --arg ptype "$PERMISSION_TYPE" \
  --argjson input "$INPUT" \
  '{
    timestamp: $ts,
    tool_name: $tool,
    permission_type: $ptype,
    tool_input: $input.tool_input
  }')

echo "$LOG_ENTRY" >> "$LOG_FILE"

# Optional: auto-deny specific patterns
# Uncomment and customize the block below to auto-deny without user prompting.
#
# COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
# AUTO_DENY_PATTERNS=(
#   "npm publish"
#   "git push --force"
# )
# for PATTERN in "${AUTO_DENY_PATTERNS[@]}"; do
#   if echo "$COMMAND" | grep -qF "$PATTERN"; then
#     jq -n \
#       --arg reason "Auto-denied by permission-request-logger: matches '$PATTERN'" \
#       '{
#         hookSpecificOutput: {
#           hookEventName: "PermissionRequest",
#           permissionDecision: "deny",
#           permissionDecisionReason: $reason
#         },
#         continue: true
#       }'
#     exit 0
#   fi
# done

# Default: defer to normal permission dialog
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PermissionRequest",
    permissionDecision: "defer"
  },
  continue: true
}'

exit 0
