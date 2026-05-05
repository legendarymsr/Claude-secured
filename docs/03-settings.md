# 03 — Settings & Configuration

Claude Code uses a layered JSON configuration system. Understanding which file takes effect where is critical for teams and enterprise deployments.

## The four configuration scopes

Settings are merged in this precedence order — **higher overrides lower**:

| Scope | Location | Who controls it | Shared? |
|-------|----------|----------------|---------|
| **Managed** | Deployed by MDM/admin tooling | Organization | Yes — enforced for all users |
| **Local project** | `.claude/settings.local.json` | You, this repo only | No — gitignored |
| **Project** | `.claude/settings.json` | Team | Yes — committed to git |
| **User** | `~/.claude/settings.json` | You, all projects | No |

When the same key appears in multiple scopes, the more-specific scope wins. Managed policy always wins.

## Core settings.json schema

```json
{
  "permissions": {
    "allow": [],
    "ask": [],
    "deny": []
  },
  "defaultMode": "default",
  "env": {},
  "hooks": {},
  "model": "claude-opus-4-7",
  "disableTools": []
}
```

### `permissions`

Array of permission rules. See [docs/02-permissions.md](02-permissions.md) for full rule syntax.

### `defaultMode`

Sets the starting permission mode for sessions. Valid values: `default`, `acceptEdits`, `plan`, `auto`, `bypassPermissions`.

### `env`

Environment variables injected into every Claude Code session. Use for non-secret config like `NODE_ENV`. **Never store API keys or credentials here** — they end up in the committed settings file.

```json
{
  "env": {
    "NODE_ENV": "development",
    "DISABLE_TELEMETRY": "1"
  }
}
```

### `hooks`

Hook definitions by event type. See [docs/04-hooks.md](04-hooks.md).

### `disableTools`

Array of tool names to remove from Claude's available tools entirely.

```json
{
  "disableTools": ["WebFetch", "WebSearch"]
}
```

## Protecting sensitive files

Add deny rules to prevent Claude from reading credentials and secrets:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./config/credentials.json)",
      "Read(~/.aws/**)",
      "Read(~/.ssh/**)"
    ]
  }
}
```

Place this in `.claude/settings.json` (committed) so it applies to all team members.

## Managed settings keys

Enterprise admins can lock down behavior via managed settings:

| Key | Effect |
|-----|--------|
| `permissions.disableBypassPermissionsMode` | Prevents users from switching to `bypassPermissions` mode |
| `allowManagedMcpServersOnly` | Only MCP servers from managed config are allowed |
| `allowManagedPermissionRulesOnly` | Users cannot add their own permission rules |
| `allowManagedHooksOnly` | Only hooks from managed config are allowed |

## Additional directories

Grant Claude read access to directories outside the project with `additionalDirectories` in settings or `--add-dir` at startup:

```json
{
  "additionalDirectories": ["/path/to/shared-libs"]
}
```

Hooks, MCP servers, and other config are only discovered from the main project root and `~/.claude/` — not from additional directories.

## Secrets in settings: what not to do

| Wrong | Right |
|-------|-------|
| `"env": { "OPENAI_KEY": "sk-..." }` in committed settings | Pass via shell environment before launching Claude Code |
| Hardcoded paths to credentials files in allow rules | Use deny rules to block credential files |
| Checking `.claude/settings.local.json` into git | It's gitignored for a reason — keep it that way |

## See also

- [docs/02-permissions.md](02-permissions.md) — Rule syntax details
- [docs/04-hooks.md](04-hooks.md) — Hook configuration
- [examples/settings/](../examples/settings/) — Ready-to-use config templates
