# 03 — Settings & Configuration

Claude Code reads settings from JSON files. These control permissions, hooks, environment variables, and which tools are available.

---

## The four config files

| File | Who | Shared? |
|------|-----|---------|
| Managed (MDM/admin) | Organization | Yes — cannot be overridden |
| `.claude/settings.json` | Team | Yes — commit to git |
| `.claude/settings.local.json` | You, this repo | No — gitignored |
| `~/.claude/settings.json` | You, all projects | No |

**Higher overrides lower. Managed always wins.**

---

## Which file to use

- **Credential deny rules** → put in `.claude/settings.json` so teammates are protected too  
- **Test/build allow rules** → `.claude/settings.json` (team-specific)  
- **Personal preferences** → `~/.claude/settings.json`  
- **Temporary per-machine overrides** → `.claude/settings.local.json`

---

## Core schema

```json
{
  "permissions": { "allow": [], "ask": [], "deny": [] },
  "defaultMode": "default",
  "env": {},
  "hooks": {},
  "disableTools": [],
  "mcpServers": {}
}
```

**Never put secrets in `env`.** It's committed to git and visible in process listings. Use shell environment variables instead.

<details>
<summary>📖 How scope merging works in detail</summary>

Settings are merged key by key. For arrays like `permissions.allow`, the higher-precedence scope's array **replaces** the lower scope's — it does not append.

**Example:**

`~/.claude/settings.json`:
```json
{ "permissions": { "deny": ["Read(~/.ssh/**)"] } }
```

`.claude/settings.json`:
```json
{ "permissions": { "deny": ["Read(./.env)"] } }
```

Result in this project: only `Read(./.env)` is denied. The user-level `~/.ssh` rule is overridden.

**Implication:** Don't rely on your user-level rules to protect you in projects that have their own `settings.json`. Repeat critical deny rules in both files, or use managed settings.

</details>

<details>
<summary>📖 Every settings key explained</summary>

### `permissions`
The most important key. Controls tool access via allow/ask/deny arrays. See [docs/02-permissions.md](02-permissions.md) for full syntax.

### `defaultMode`
Starting permission mode for every session. Valid values: `default`, `acceptEdits`, `plan`, `auto`, `bypassPermissions`.

For team configs: always leave as `"default"`. Never set `"bypassPermissions"` in a committed file.

### `env`
Environment variables injected into every Claude Code session:
```json
{ "env": { "NODE_ENV": "development", "DISABLE_TELEMETRY": "1" } }
```

Safe for: non-secret config, telemetry opt-outs, log levels.  
Unsafe for: API keys, passwords, tokens — these belong in your shell environment.

### `hooks`
Event handler definitions. See [docs/04-hooks.md](04-hooks.md).

### `disableTools`
Completely removes tools from Claude's available set. Claude cannot use them even with an allow rule:
```json
{ "disableTools": ["WebFetch", "WebSearch"] }
```

Use for air-gapped environments or when you want to eliminate a tool entirely.

### `mcpServers`
Configures MCP server integrations. See [docs/05-mcp-security.md](05-mcp-security.md).

### `model`
Override which Claude model is used:
```json
{ "model": "claude-sonnet-4-6" }
```

### `additionalDirectories`
Grant read access to directories outside the project:
```json
{ "additionalDirectories": ["/path/to/shared-libs"] }
```
Note: CLAUDE.md, hooks, and settings are only discovered from the main project root and `~/.claude/` — not from additional directories.

</details>

<details>
<summary>📖 Protecting sensitive files</summary>

Put these deny rules in `.claude/settings.json` to protect everyone on the team:

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
      "Read(~/.gnupg/**)",
      "Read(~/.kube/**)",
      "Read(~/.docker/config.json)",
      "Read(~/.config/gh/**)"
    ]
  }
}
```

Also add the home-directory rules to `~/.claude/settings.json` as a fallback for projects without their own settings file.

</details>

<details>
<summary>📖 Managed settings for enterprise</summary>

Managed settings are deployed by IT/admins and cannot be overridden by users:

| Key | Effect |
|-----|--------|
| `permissions.disableBypassPermissionsMode` | Prevents anyone from using `bypassPermissions` mode |
| `allowManagedMcpServersOnly` | Only admin-approved MCP servers are allowed |
| `allowManagedPermissionRulesOnly` | User and project permission rules are ignored entirely |
| `allowManagedHooksOnly` | Only hooks from managed config are active |

Full example: [examples/settings/settings.enterprise.jsonc](../examples/settings/settings.enterprise.jsonc)

</details>

<details>
<summary>📖 Validating your settings file</summary>

If `settings.json` has invalid JSON, Claude Code reports a parse error and won't start. Validate before committing:

```bash
python3 -m json.tool .claude/settings.json && echo "Valid JSON"
# or
cat .claude/settings.json | jq . > /dev/null && echo "Valid"
```

Note: the example files in this repo use `.jsonc` (JSON with Comments). Strip `//` comments before using as actual `settings.json`.

</details>

---

## See also

- [docs/02-permissions.md](02-permissions.md) — Rule syntax
- [docs/04-hooks.md](04-hooks.md) — Hook configuration
- [docs/12-secrets-management.md](12-secrets-management.md) — Handling credentials safely
- [examples/settings/](../examples/settings/) — Copy-paste templates
