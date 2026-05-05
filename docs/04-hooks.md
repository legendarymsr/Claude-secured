# 04 — Hooks

Hooks are shell scripts, HTTP endpoints, or LLM prompts that run automatically at specific lifecycle points in a Claude Code session. They're the enforcement layer — where you can validate, log, block, or modify Claude's actions.

## How hooks work

1. A lifecycle event fires (e.g., Claude is about to run a bash command)
2. Claude Code sends a JSON payload to the hook via stdin
3. The hook inspects the payload and exits with a code
4. Claude Code acts on the exit code and any JSON written to stdout

## Exit codes

| Exit code | Meaning |
|-----------|---------|
| `0` | Success — Claude Code reads stdout for a JSON decision |
| `2` | Blocking error — tool call is prevented; stderr is shown to the user |
| Any other | Non-blocking error — execution continues |

## JSON output format

Write to stdout to influence Claude's behavior:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Matches destructive pattern",
    "additionalContext": "Context injected into Claude's next prompt"
  },
  "continue": true
}
```

`permissionDecision` values: `allow`, `deny`, `ask`, `defer`

## Event types

### PreToolUse

Fires **before** any tool runs. The most powerful hook — can block any tool call.

```json
{
  "tool_name": "Bash",
  "tool_input": { "command": "rm -rf ./dist" }
}
```

Use for: blocking destructive commands, validating inputs, audit logging.

### PostToolUse

Fires **after** a tool succeeds. Cannot block (the tool already ran).

```json
{
  "tool_name": "Edit",
  "tool_input": { "file_path": "src/main.ts", ... },
  "tool_result": { "success": true }
}
```

Use for: notifications, downstream logging, triggering lint/format.

### PermissionRequest

Fires when a permission approval dialog appears. Can auto-approve or auto-deny.

```json
{
  "tool_name": "Bash",
  "tool_input": { "command": "npm run build" },
  "permission_type": "bash_command"
}
```

Use for: automating approvals for known-safe commands in CI, blocking specific patterns without user interaction.

### UserPromptSubmit

Fires before Claude processes a user prompt. Can reject the prompt entirely.

```json
{
  "prompt": "Delete all files in /home"
}
```

Use for: org-level content policy enforcement.

### SessionStart

Fires when a session begins. Cannot block tool calls — only useful for context injection and setup logging.

### Other event types

| Event | When it fires |
|-------|--------------|
| `PostToolUseFailure` | After a tool fails |
| `SubagentStart` / `SubagentStop` | Subagent lifecycle |
| `Notification` | When Claude sends a notification |
| `PreCompact` / `PostCompact` | Before/after context compaction |
| `InstructionsLoaded` | When CLAUDE.md is loaded |

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
            "command": "/path/to/block-dangerous-commands.sh"
          }
        ]
      }
    ]
  }
}
```

`matcher` filters by tool name. Use `"Bash"` for all bash calls, or a specific tool name.

## Security implications by hook type

| Hook | Security level | Risk if compromised |
|------|---------------|-------------------|
| `PreToolUse` | Critical | Can block or permit any tool |
| `PermissionRequest` | High | Can auto-approve dangerous actions |
| `UserPromptSubmit` | High | Can silently reject or modify prompts |
| `PostToolUse` | Medium | Tool already ran; can only observe |
| `SessionStart` | Low | Context injection only |

**Key point**: Hook scripts run with the same OS user as Claude Code. A malicious or buggy hook is a full code execution vector. Treat hook scripts with the same care as any privileged script.

Enforce with managed settings: use `allowManagedHooksOnly: true` to restrict hooks to admin-approved sources only.

## See also

- [docs/02-permissions.md](02-permissions.md) — Permission rule syntax (used in hook matchers)
- [examples/hooks/block-dangerous-commands.sh](../examples/hooks/block-dangerous-commands.sh) — PreToolUse block example
- [examples/hooks/pre-tool-audit.sh](../examples/hooks/pre-tool-audit.sh) — Audit logging example
- [examples/hooks/permission-request-logger.sh](../examples/hooks/permission-request-logger.sh) — PermissionRequest example
