#!/usr/bin/env bash
# PreToolUse hook — blocks Bash commands matching a destructive pattern list
# See: docs/04-hooks.md
#
# Install in settings.json:
#   "hooks": {
#     "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "/path/to/block-dangerous-commands.sh" }] }]
#   }
#
# Exit code 2 = block the tool call and show stderr to the user
# Exit code 0 = allow (Claude reads stdout for optional JSON decisions)

set -euo pipefail

# Read the JSON payload from stdin
INPUT=$(cat)

# Extract the bash command (requires jq)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Destructive patterns to block unconditionally
BLOCKLIST=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf \$HOME"
  ":(){ :|:& };:"       # fork bomb
  "mkfs"                # disk format
  "dd if=/dev/zero"     # disk wipe
  "curl.*|.*bash"       # curl pipe to bash
  "curl.*|.*sh"
  "wget.*|.*bash"
  "wget.*|.*sh"
  "chmod 777 /"
  "chmod -R 777"
  "> /etc/passwd"
  "> /etc/shadow"
)

for PATTERN in "${BLOCKLIST[@]}"; do
  if echo "$COMMAND" | grep -qE "$PATTERN"; then
    # Write a JSON explanation to stdout for Claude's context
    jq -n \
      --arg reason "Command matches blocked pattern: $PATTERN" \
      --arg cmd "$COMMAND" \
      '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason: $reason,
          additionalContext: ("Blocked command: " + $cmd)
        },
        continue: true
      }'

    # Exit 2 to surface the block to the user
    echo "BLOCKED: command matches pattern '$PATTERN': $COMMAND" >&2
    exit 2
  fi
done

# Command passed all checks — allow it
exit 0
