# 03 — Settings & Configuration

Claude Code uses a layered JSON configuration system. Every setting you care about — permissions, hooks, MCP servers, environment variables — lives in one of four settings files. Understanding which file to use and how they interact is fundamental to managing Claude Code safely.

## The four configuration scopes

Settings merge in this precedence order. **Higher overrides lower. Managed always wins.**

| Scope | Location | Who controls it | In git? |
|-------|----------|----------------|---------|
| **Managed** | Deployed by MDM or admin tooling | Organization | Yes — enforced org-wide |
| **Local project** | `.claude/settings.local.json` | You, this repo only | No — gitignored |
| **Project** | `.claude/settings.json` | Your team | Yes — committed |
| **User** | `~/.claude/settings.json` | You, all projects | No |

### How merging works in practice

Settings are merged key by key. For arrays (like `permissions.allow`), the higher-precedence scope's array **replaces** the lower scope's array for that key — it does not append.

**Example:**

`~/.claude/settings.json` (user scope):
```json
{ "permissions": { "deny": ["Read(~/.ssh/**)"] } }
```

`.claude/settings.json` (project scope):
```json
{ "permissions": { "deny": ["Read(./.env)"] } }
```

Result: The project scope overrides the user scope for `permissions.deny`. The user-level `~/.ssh` deny rule is **not active** in this project.

**Implication:** Don't rely on your user-level deny rules to protect you in a project that has its own `settings.json`. Repeat important deny rules in the project config, or use managed settings to enforce them globally.

### Which scope to use for different rule types

| Rule type | Recommended scope | Reason |
|-----------|------------------|--------|
| Credential deny rules (`~/.aws`, `~/.ssh`) | User + Project | User scope catches projects without their own settings; Project scope ensures teammates are protected |
| Test/lint/build allow rules | Project | Team-specific, should be shared |
| Personal preferences (notification style, preferred mode) | User | Personal, not for the team |
| Organization security policy | Managed | Cannot be overridden by users |
| Per-machine overrides | Local project | Machine-specific, should not be committed |

## Core settings.json schema

```json
{
  "permissions": {
    "allow": [],
    "ask":   [],
    "deny":  []
  },
  "defaultMode": "default",
  "env": {},
  "hooks": {},
  "model": "claude-opus-4-7",
  "disableTools": [],
  "mcpServers": {}
}
```

### `permissions`

Arrays of permission rules controlling tool access. See [docs/02-permissions.md](02-permissions.md) for full rule syntax. The most important key in the whole file.

### `defaultMode`

Sets the starting permission mode for every session opened in this project. Valid values: `default`, `acceptEdits`, `plan`, `auto`, `bypassPermissions`.

For shared project configs, leave this as `default` unless you have a specific reason. Individual developers can change mode per-session with `Shift+Tab`.

### `env`

Environment variables injected into every Claude Code session for this project:

```json
{
  "env": {
    "NODE_ENV": "development",
    "DISABLE_TELEMETRY": "1"
  }
}
```

**Never store secrets here.** Reasons:
1. Project `settings.json` is committed to git — anyone with repo access can read it
2. User `settings.json` is on disk — readable by other processes running as your user
3. Env vars set here appear in process listings (`ps aux`) and may end up in logs

Pass secrets via your shell before launching Claude Code:
```bash
export DATABASE_URL="postgres://..."
claude
```

Or use a secrets manager that injects them into the shell environment.

### `hooks`

Hook event handlers. See [docs/04-hooks.md](04-hooks.md) for the full reference.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "/path/to/hook.sh" }]
      }
    ]
  }
}
```

### `model`

Which Claude model to use. Defaults to the latest available. Lock this in team settings if you need consistent behavior:

```json
{ "model": "claude-sonnet-4-6" }
```

### `disableTools`

Completely removes tools from Claude's available set. Claude cannot use a disabled tool at all — not even with explicit permission rules:

```json
{
  "disableTools": ["WebFetch", "WebSearch"]
}
```

Use this for air-gapped environments or when you want to prevent any network activity.

### `mcpServers`

Configures MCP server integrations. See [docs/05-mcp-security.md](05-mcp-security.md) for security implications.

## Protecting sensitive files

Add deny rules in `.claude/settings.json` so they apply to the whole team:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./.env.local)",
      "Read(./secrets/**)",
      "Read(./config/credentials*)",
      "Read(~/.aws/**)",
      "Read(~/.ssh/**)",
      "Read(~/.gnupg/**)"
    ]
  }
}
```

Also add personal credential paths in `~/.claude/settings.json` as a backup:

```json
{
  "permissions": {
    "deny": [
      "Read(~/.aws/**)",
      "Read(~/.ssh/**)",
      "Read(~/.config/gh/**)",
      "Read(~/.kube/**)"
    ]
  }
}
```

## What happens with invalid JSON?

If `settings.json` contains invalid JSON, Claude Code will fail to start and report the parse error. Use a JSON validator before saving:

```bash
python3 -m json.tool .claude/settings.json
```

Note: `.jsonc` files (JSON with comments) are useful for templates but must have comments stripped before Claude Code can read them.

## Managed settings

Enterprise admins can enforce settings by deploying a managed config file. Keys in managed settings **cannot be overridden** by project or user settings.

### Available lockdown keys

| Key | Effect |
|-----|--------|
| `permissions.disableBypassPermissionsMode` | Prevents `bypassPermissions` mode from being selected |
| `allowManagedMcpServersOnly` | Only MCP servers in managed config are allowed; users can't add their own |
| `allowManagedPermissionRulesOnly` | User and project permission rules are ignored; only managed rules apply |
| `allowManagedHooksOnly` | Only hooks defined in managed config are active |

### Example managed settings

```json
{
  "permissions": {
    "disableBypassPermissionsMode": true,
    "deny": [
      "Read(~/.aws/**)",
      "Read(~/.ssh/**)",
      "Bash(curl *)",
      "Bash(wget *)"
    ]
  },
  "allowManagedMcpServersOnly": true,
  "allowManagedHooksOnly": true,
  "env": {
    "DISABLE_TELEMETRY": "1"
  }
}
```

See [examples/settings/settings.enterprise.jsonc](../examples/settings/settings.enterprise.jsonc) for a complete enterprise template.

## Additional directories

Grant Claude read access to directories outside the project:

```json
{ "additionalDirectories": ["/path/to/shared-libs"] }
```

Or at startup: `claude --add-dir /path/to/shared-libs`  
Or in-session: `/add-dir /path/to/shared-libs`

**Important limits:**
- Files in additional directories can be read (and possibly edited, subject to permission rules)
- Claude Code does **not** look for CLAUDE.md, settings.json, hooks, or MCP configs in additional directories — only in the main project root and `~/.claude/`
- Don't grant parent directory access (e.g., `--add-dir ~/`) — this gives Claude Code access to everything in your home directory

## Common configuration mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Committing `.claude/settings.local.json` | Personal overrides exposed to team; potential credential leak | Keep it gitignored |
| Secrets in `env` block | Exposed in git history and process listings | Use shell env vars or secrets manager |
| No deny rules for credentials | Claude can read `~/.aws/credentials` if asked | Add deny rules in both project and user settings |
| Relying on user settings.json to protect projects with their own settings | User rules are overridden by project rules | Repeat critical deny rules in project settings |
| Using `disableTools` when you mean to use deny rules | `disableTools` removes the tool entirely; deny rules block specific uses | Use deny rules for selective blocking; `disableTools` for complete removal |

## See also

- [docs/02-permissions.md](02-permissions.md) — Permission rule syntax
- [docs/04-hooks.md](04-hooks.md) — Hook configuration
- [examples/settings/](../examples/settings/) — Ready-to-use config templates
