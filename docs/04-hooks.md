# 04 — Hooks

Hooks are shell scripts that run automatically at specific points in Claude Code's lifecycle. They can inspect, log, block, or modify Claude's actions with full programmatic control.

---

## When to use hooks vs. permission rules

- **Permission rules** — simple categorical decisions (block this command prefix, allow that path)
- **Hooks** — anything requiring logic (inspect the full command content, log to a file, conditional blocking)

---

## How a hook works

1. A lifecycle event fires (e.g., Claude is about to run a bash command)
2. Claude Code sends a JSON payload to the hook script via **stdin**
3. The script reads stdin, does its work, exits with a code
4. Claude Code acts on the exit code and any JSON on stdout

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success — Claude reads stdout for an optional JSON decision |
| `2` | **Hard block** — tool call is stopped; stderr shown to user |
| Other | Non-blocking error — execution continues |

---

## Minimal working hook

```bash
#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block a specific pattern
if echo "$COMMAND" | grep -qF "rm -rf /"; then
  echo "Blocked: $COMMAND" >&2
  exit 2
fi
exit 0
```

Wire it up in `settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{ "type": "command", "command": "/absolute/path/to/hook.sh" }]
    }]
  }
}
```

> Always use **absolute paths** for hook scripts. Relative paths break depending on the working directory.

---

## Event types

| Event | When it fires | Can block? |
|-------|--------------|-----------|
| `PreToolUse` | Before any tool runs | ✅ Yes |
| `PostToolUse` | After a tool succeeds | ❌ No (already ran) |
| `PermissionRequest` | When an approval dialog appears | ✅ Yes (auto-approve/deny) |
| `UserPromptSubmit` | Before Claude processes a prompt | ✅ Yes |
| `SessionStart` | When session begins | ❌ Context only |
| `PostToolUseFailure` | After a tool fails | ❌ No |
| `SubagentStart/Stop` | Subagent lifecycle | ❌ No |
| `Notification` | When Claude sends a notification | ❌ No |

<details>
<summary>📖 Full JSON payload for each event type</summary>

### PreToolUse

**Bash:**
```json
{
  "tool_name": "Bash",
  "tool_input": { "command": "rm -rf ./dist" }
}
```

**Edit:**
```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/project/src/main.ts",
    "old_string": "const x = 1",
    "new_string": "const x = 2"
  }
}
```

**WebFetch:**
```json
{
  "tool_name": "WebFetch",
  "tool_input": { "url": "https://example.com/data" }
}
```

**MCP tool:**
```json
{
  "tool_name": "mcp__github__create_issue",
  "tool_input": { "title": "Bug report", "body": "..." }
}
```

### PostToolUse
```json
{
  "tool_name": "Edit",
  "tool_input": { "file_path": "src/main.ts", "old_string": "...", "new_string": "..." },
  "tool_result": { "success": true }
}
```

### PermissionRequest
```json
{
  "tool_name": "Bash",
  "tool_input": { "command": "npm run build" },
  "permission_type": "bash_command"
}
```

### UserPromptSubmit
```json
{
  "prompt": "Delete all the log files and push to production"
}
```

</details>

<details>
<summary>📖 JSON output format — controlling Claude's behavior from a hook</summary>

Write to stdout to influence what Claude does next:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Matches destructive pattern",
    "additionalContext": "Use 'rm -rf ./dist' instead of 'rm -rf /' for project cleanup."
  },
  "continue": true
}
```

### `permissionDecision` values

| Value | Effect |
|-------|--------|
| `allow` | Tool runs without approval dialog |
| `deny` | Tool is blocked |
| `ask` | Shows approval dialog to user |
| `defer` | Falls back to normal permission system |

### `additionalContext`

Text here is injected into Claude's next context window. Use it to explain why a block happened and suggest an alternative — Claude will see it and course-correct.

### `continue: false`

Terminates the entire Claude Code session immediately. Use only for critical security violations. `continue: true` is the normal value.

</details>

<details>
<summary>📖 Hook script best practices</summary>

### Always use set -euo pipefail
```bash
#!/usr/bin/env bash
set -euo pipefail
```
This exits on any error, treats unset variables as errors, and propagates pipe failures.

### Read stdin once
```bash
INPUT=$(cat)  # Read once into variable
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
```
stdin is a stream — reading it twice gives nothing the second time.

### Handle missing fields
```bash
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if [[ -z "$COMMAND" ]]; then
  exit 0  # Not a bash command — nothing to check
fi
```

### Use grep -F for literal strings (no regex metacharacters)
```bash
# Safe
if echo "$COMMAND" | grep -qF "rm -rf /"; then ...

# Safer for patterns
case "$COMMAND" in
  "rm -rf /"*) exit 2 ;;
esac
```

### Check if jq is available
```bash
if ! command -v jq &>/dev/null; then
  exit 0  # Don't break Claude Code over a missing tool
fi
```

### Add a timeout to slow hooks
```json
{ "type": "command", "command": "timeout 5 /path/to/hook.sh" }
```
Hooks that block indefinitely stall Claude Code — there's no built-in timeout per invocation.

</details>

<details>
<summary>📖 Security implications by hook type</summary>

Hook scripts run with your OS user's privileges — the same as Claude Code itself. A compromised or buggy hook is a full code execution vector.

| Hook | Risk if compromised |
|------|-------------------|
| `PreToolUse` | Can silently permit any dangerous command |
| `PermissionRequest` | Can auto-approve without user seeing it |
| `UserPromptSubmit` | Can silently modify or reject prompts |
| `PostToolUse` | Can only observe — cannot undo |
| `SessionStart` | Can inject malicious context |

**Protect hook scripts:**
- Store in version control
- Set permissions: `chmod 755 hook.sh` (only owner can write)
- Review hooks from external sources as carefully as any executable
- Enterprise: use `allowManagedHooksOnly: true` to restrict to admin-approved hooks

**What happens if a hook crashes?**

A hook that exits with any code other than 2 is treated as a non-blocking failure — Claude Code continues. This means a hook that crashes when it should block will silently fail to block. Test hooks against real payloads before deploying.

</details>

---

## See also

- [docs/02-permissions.md](02-permissions.md) — Simpler alternative for static rules
- [examples/hooks/block-dangerous-commands.sh](../examples/hooks/block-dangerous-commands.sh) — PreToolUse block example
- [examples/hooks/pre-tool-audit.sh](../examples/hooks/pre-tool-audit.sh) — Audit logging
- [examples/hooks/permission-request-logger.sh](../examples/hooks/permission-request-logger.sh) — PermissionRequest example
