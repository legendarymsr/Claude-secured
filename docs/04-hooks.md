# 04 — Hooks

Hooks are shell scripts (or HTTP endpoints) that run automatically at specific points in Claude Code's lifecycle. They are the enforcement layer — the place where you can inspect, log, block, or modify Claude's actions with full programmatic control.

## Hooks vs. permission rules

Permission rules match tool names and simple patterns. Hooks can do anything a shell script can do:

| Permission rules | Hooks |
|-----------------|-------|
| Match by tool name and command prefix | Match by inspecting the full tool input JSON |
| Static — defined at config time | Dynamic — run logic at execution time |
| Block or allow | Block, allow, log, notify, modify input |
| No output visible | Can write messages shown to user |

**Use rules for simple categorical decisions. Use hooks for anything requiring logic.**

## How hooks work

1. A lifecycle event fires (e.g., Claude is about to run a bash command)
2. Claude Code serializes the event as JSON and sends it to the hook via **stdin**
3. The hook script runs, reads stdin, does its work, writes to stdout/stderr
4. Claude Code reads the exit code and any JSON on stdout to decide what to do

## Exit codes

| Exit code | Meaning | What Claude does |
|-----------|---------|-----------------|
| `0` | Success | Reads stdout for a JSON decision; continues |
| `2` | Hard block | Shows stderr to the user; stops the tool call |
| Anything else | Non-blocking error | Logs the failure; continues anyway |

**When to use exit 2:** Use it when you want to stop a tool call and surface a clear error message. The stderr text is shown to the user in the Claude Code interface.

**When to use exit 0:** Always, unless you're blocking. Exit 0 with a JSON permissionDecision of `deny` is an alternative to exit 2 — it blocks silently via the permission system rather than showing an error.

## JSON output format

Write to stdout to influence Claude's behavior:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Matches destructive pattern",
    "additionalContext": "This will be added to Claude's next context window"
  },
  "continue": true
}
```

### `permissionDecision` values

| Value | Effect |
|-------|--------|
| `allow` | Tool runs without showing approval dialog |
| `deny` | Tool is blocked; reason shown if provided |
| `ask` | Shows approval dialog to the user |
| `defer` | Falls back to normal permission system |

### `continue`

`continue: false` terminates the entire Claude Code session immediately. This is a drastic action — use it only for critical security violations where you want to halt everything. `continue: true` is the normal value for all other cases.

### `additionalContext`

Text in `additionalContext` is injected into Claude's next context window. Use it to explain *why* a block happened, so Claude can course-correct. For example: `"Command blocked because rm -rf is disallowed. Use specific file deletion instead."` — Claude will see this and try a different approach.

## Configuring hooks in settings.json

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/block-dangerous-commands.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/post-tool-notify.sh"
          }
        ]
      }
    ]
  }
}
```

`matcher` filters by tool name. Use `"*"` to match all tools, `"Bash"` for all bash calls, `"Edit"` for file edits, etc.

**Use absolute paths** for hook scripts. Relative paths can break depending on the working directory when Claude Code starts.

## Event types in detail

### PreToolUse ⚠️ Most important

Fires **before** any tool runs. The hook receives the full tool call as JSON and can block it.

**Stdin payload:**
```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf ./dist"
  }
}
```

For `Edit` tool:
```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/home/user/project/src/main.ts",
    "old_string": "const x = 1",
    "new_string": "const x = 2"
  }
}
```

For `WebFetch`:
```json
{
  "tool_name": "WebFetch",
  "tool_input": {
    "url": "https://example.com/data"
  }
}
```

Use `PreToolUse` for: blocking destructive commands, validating inputs, audit logging, inspecting what Claude is about to do.

### PostToolUse

Fires **after** a tool succeeds. Cannot block the action (it already ran) — only observe.

**Stdin payload:**
```json
{
  "tool_name": "Edit",
  "tool_input": { "file_path": "src/main.ts", "old_string": "...", "new_string": "..." },
  "tool_result": { "success": true }
}
```

Use `PostToolUse` for: desktop notifications, downstream logging, triggering format/lint after edits, recording what changed.

### PermissionRequest

Fires when a permission approval dialog is about to appear. Can auto-approve or auto-deny, bypassing the dialog entirely.

**Stdin payload:**
```json
{
  "tool_name": "Bash",
  "tool_input": { "command": "npm run build" },
  "permission_type": "bash_command"
}
```

**When to use instead of PreToolUse:** Use `PermissionRequest` when you want to automate the human approval step (e.g., in CI, auto-approve a specific set of commands you've pre-vetted). Use `PreToolUse` when you want to block unconditionally before the permission system even runs.

### UserPromptSubmit

Fires before Claude processes any user prompt. Can reject the prompt before Claude sees it.

**Stdin payload:**
```json
{
  "prompt": "Delete all log files and push to production"
}
```

Use for: org-level content policies, blocking certain types of requests in shared environments.

### SessionStart

Fires once when the session begins. Cannot block tool calls. Useful for injecting initial context, logging session start, or setting up environment.

### Other event types

| Event | When | Common use |
|-------|------|-----------|
| `PostToolUseFailure` | After a tool fails | Log failures; alert on repeated failures |
| `SubagentStart` | When a subagent spawns | Track delegated work |
| `SubagentStop` | When a subagent finishes | Log subagent outcomes |
| `Notification` | When Claude sends a notification | Forward notifications to Slack/email |
| `PreCompact` | Before context compaction | Log that compaction is happening |
| `PostCompact` | After context compaction | Resume work with awareness that context was compressed |
| `InstructionsLoaded` | When CLAUDE.md is loaded | Log which instructions are active |

## Hook script best practices

### Always use `set -euo pipefail`

```bash
#!/usr/bin/env bash
set -euo pipefail
```

This causes the script to exit immediately on any error (`-e`), treat unset variables as errors (`-u`), and propagate pipe failures (`-o pipefail`). Without this, a failed `jq` call might silently pass through.

### Validate that jq is available

```bash
if ! command -v jq &>/dev/null; then
  echo "jq is required but not installed" >&2
  exit 0  # non-blocking — don't break Claude Code over a missing tool
fi
```

### Read stdin once into a variable

```bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
```

Reading stdin multiple times won't work — it's a stream. Store it in a variable first.

### Handle empty tool inputs gracefully

Some tool inputs may not have the field you expect. Use `// empty` or `// "unknown"` in jq to avoid null errors:

```bash
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if [[ -z "$COMMAND" ]]; then
  exit 0  # not a bash command, nothing to check
fi
```

### Escape shell metacharacters in pattern matching

When matching command strings, be careful with regex metacharacters:

```bash
# Safe: use grep -F for literal string matching
if echo "$COMMAND" | grep -qF "rm -rf /"; then ...

# Safe: use case for pattern matching
case "$COMMAND" in
  "rm -rf "*)  exit 2 ;;
esac
```

Avoid passing untrusted command strings directly into shell evaluation.

## Security implications by hook type

| Hook | Security level | What a compromised/buggy hook can do |
|------|---------------|-------------------------------------|
| `PreToolUse` | Critical | Block legitimate work OR permit dangerous commands |
| `PermissionRequest` | High | Auto-approve dangerous actions without user seeing them |
| `UserPromptSubmit` | High | Silently reject or modify user prompts |
| `PostToolUse` | Medium | Can only observe; cannot undo actions |
| `SessionStart` | Low | Can only inject context |

**Hook scripts run with your OS user's privileges.** A malicious or buggy hook is a full code execution vector with the same access Claude Code has.

Protect hook scripts:
- Store them in a version-controlled directory
- Restrict write permissions: `chmod 755 hook.sh` (owner can write, others only read/execute)
- Review hooks from third-party sources as carefully as you would any executable
- In enterprise: use `allowManagedHooksOnly: true` to restrict hooks to admin-approved sources

## What happens if a hook crashes?

If a hook exits with a non-2 code (including crashing), Claude Code treats it as a non-blocking failure and continues. This is intentional — a buggy hook shouldn't break your entire Claude Code session.

However, this also means a hook that crashes when it should block will silently fail to block. Test your hooks against real payloads before deploying them.

## Hook timeouts

Hooks that block indefinitely will stall Claude Code. Keep hooks fast:
- Logging: should complete in milliseconds
- Network calls (e.g., sending to Slack): use async or fire-and-forget patterns
- Complex validation: cache results where possible

There is no built-in timeout per hook invocation. Use `timeout 5 your-script.sh` in the command if you need one:

```json
{ "type": "command", "command": "timeout 5 /path/to/hook.sh" }
```

## See also

- [docs/02-permissions.md](02-permissions.md) — Permission rules (simpler alternative to hooks for static decisions)
- [examples/hooks/block-dangerous-commands.sh](../examples/hooks/block-dangerous-commands.sh) — PreToolUse block example
- [examples/hooks/pre-tool-audit.sh](../examples/hooks/pre-tool-audit.sh) — Audit logging example
- [examples/hooks/permission-request-logger.sh](../examples/hooks/permission-request-logger.sh) — PermissionRequest example
