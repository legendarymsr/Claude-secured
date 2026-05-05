# 08 — Best Practices

Security checklists for three environments: individual development, team projects, and enterprise/CI.

---

## Individual developers

### Start restrictive, expand as needed

Don't begin with broad allow rules. Start with a minimal config and add permissions only when you need them:

```json
{
  "permissions": {
    "allow": ["Bash(npm run *)", "Bash(git status)", "Bash(git diff *)"],
    "deny": ["Bash(curl *)", "Bash(wget *)", "Read(./.env)"]
  }
}
```

### Use `plan` mode for unfamiliar codebases

Before making changes to a repo you don't know well, run a session in `plan` mode (`Shift+Tab` to cycle). Claude can analyze and explain without modifying anything.

### Always read what Claude proposes before approving

The approval dialog shows the exact command or edit. Read it. "Yes, don't ask again" is permanent for that command — use it only for genuinely repetitive, safe actions.

### Keep sensitive files out of reach

Add deny rules for credentials before starting any session:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)", "Read(./.env.*)",
      "Read(~/.aws/**)", "Read(~/.ssh/**)",
      "Read(./secrets/**)"
    ]
  }
}
```

Place this in `~/.claude/settings.json` so it applies to all projects.

### Use `/clear` between unrelated tasks

Each new task should start with a clean context. Accumulated context from previous tasks can cause confusion and increases the injection surface.

### Run from the project root

```bash
cd my-project && claude
```

This scopes Claude Code's default access to the project directory. Avoid launching from your home directory or `/`.

---

## Team projects

### Commit `.claude/settings.json` with team-safe defaults

Check in a project-level settings file with your team's agreed-upon permission rules. This ensures everyone starts with the same baseline:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run test)", "Bash(npm run lint)", "Bash(npm run build)",
      "Bash(git status)", "Bash(git diff *)", "Bash(git log *)"
    ],
    "deny": [
      "Bash(git push --force *)", "Bash(npm publish *)",
      "Read(./.env)", "Read(./.env.*)"
    ]
  }
}
```

### Gitignore `.claude/settings.local.json`

This file is already gitignored by default. Do not check it in — it's for individual overrides.

### Vet MCP servers before adding to project settings

Any MCP server in `.claude/settings.json` runs for everyone on the team. Apply the checklist in [docs/05-mcp-security.md](05-mcp-security.md) before committing.

### Use hooks for team-wide audit logging

Add a `PreToolUse` hook that logs every tool call. This creates an audit trail without blocking anyone:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "*",
      "hooks": [{ "type": "command", "command": "/path/to/pre-tool-audit.sh" }]
    }]
  }
}
```

See [examples/hooks/pre-tool-audit.sh](../examples/hooks/pre-tool-audit.sh).

---

## Enterprise and CI/CD

### Lock down `bypassPermissions` via managed settings

```json
{
  "permissions": {
    "disableBypassPermissionsMode": true
  }
}
```

This prevents any user or CI script from switching to fully unattended mode.

### Use `allowManagedMcpServersOnly`

Prevent users from adding arbitrary MCP servers:

```json
{
  "allowManagedMcpServersOnly": true
}
```

Define approved MCP servers in the managed settings file.

### For CI: prefer `auto` mode over `bypassPermissions`

`auto` mode uses a background classifier to block scope escalation and hostile content, while still running unattended. It's safer than `bypassPermissions` for CI pipelines.

If you must use `bypassPermissions` in CI, run inside a container with:
- Read-only mounts for source code
- No network access to production systems
- No production credentials mounted

### Rotate API keys regularly

Claude Code uses your `ANTHROPIC_API_KEY`. Rotate it on a schedule and invalidate old keys immediately if there's any suspected compromise.

### Review CLAUDE.md before trusting a repo

When working in a repository you didn't create, read `CLAUDE.md` before starting Claude Code. A malicious `CLAUDE.md` can prime Claude with bad instructions. If the file looks suspicious, delete or rename it before running.

### Enable sandboxing for untrusted repos

```json
{
  "sandbox": {
    "enabled": true,
    "filesystem": {
      "denyRead": ["~/.ssh", "~/.aws"],
      "allowWrite": ["./"]
    }
  }
}
```

This limits what Claude can access at the OS level, independent of permission rules.

---

## See also

- [docs/02-permissions.md](02-permissions.md) — Rule syntax
- [docs/09-common-mistakes.md](09-common-mistakes.md) — What not to do
- [examples/settings/settings.enterprise.jsonc](../examples/settings/settings.enterprise.jsonc) — Enterprise config template
