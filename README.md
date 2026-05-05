# Claude-secured

A security guide for [Claude Code](https://code.claude.com) — Anthropic's agentic coding CLI.

> Claude Code can read files, run shell commands, make network requests, and commit code. This guide covers how to control what it can do and how to keep your machine and credentials safe.

---

## Start here

**New to Claude Code security?** Read these three things first:

1. Copy [`examples/settings/settings.minimal.jsonc`](examples/settings/settings.minimal.jsonc) into your project as `.claude/settings.json` (strip comments)
2. Add deny rules for your credential files (`.env`, `~/.aws`, `~/.ssh`)
3. Always review what Claude proposes before approving it

---

## Documentation

| Guide | One-line summary |
|-------|-----------------|
| [01 — Overview](docs/01-overview.md) | What Claude Code is and why it's a different security model |
| [02 — Permissions](docs/02-permissions.md) | How to control what Claude can and can't do |
| [03 — Settings](docs/03-settings.md) | Config files, scopes, and the settings schema |
| [04 — Hooks](docs/04-hooks.md) | Scripts that run before/after Claude's actions |
| [05 — MCP Security](docs/05-mcp-security.md) | Risks of third-party tool extensions |
| [06 — Prompt Injection](docs/06-prompt-injection.md) | How malicious content tries to hijack Claude |
| [07 — Network & API Security](docs/07-network-api-security.md) | What data leaves your machine |
| [08 — Best Practices](docs/08-best-practices.md) | Checklists for devs, teams, and enterprise |
| [09 — Common Mistakes](docs/09-common-mistakes.md) | What not to do, and why |
| [10 — Slash Commands](docs/10-slash-commands.md) | Security-relevant built-in commands |
| [11 — CLAUDE.md Guide](docs/11-claude-md-guide.md) | What CLAUDE.md is and how to write it safely |
| [12 — Secrets Management](docs/12-secrets-management.md) | Keeping credentials out of Claude's context |
| [13 — CI/CD Security](docs/13-ci-cd-guide.md) | Running Claude Code safely in automated pipelines |

---

## Examples

<details>
<summary><strong>Settings templates</strong> — copy these into your project</summary>

| File | Use case |
|------|----------|
| [settings.minimal.jsonc](examples/settings/settings.minimal.jsonc) | Restrictive starter — good default for any project |
| [settings.team.jsonc](examples/settings/settings.team.jsonc) | Shared config for a Node.js/Python team |
| [settings.enterprise.jsonc](examples/settings/settings.enterprise.jsonc) | Managed policy with audit hooks and locked-down modes |

> Strip `//` comments before using — Claude Code reads standard `.json`.

</details>

<details>
<summary><strong>Hook scripts</strong> — drop these into your project and wire up in settings.json</summary>

| File | Event | What it does |
|------|-------|-------------|
| [block-dangerous-commands.sh](examples/hooks/block-dangerous-commands.sh) | `PreToolUse` | Blocks Bash commands matching a destructive pattern list |
| [pre-tool-audit.sh](examples/hooks/pre-tool-audit.sh) | `PreToolUse` | Logs every tool call to a structured audit file |
| [permission-request-logger.sh](examples/hooks/permission-request-logger.sh) | `PermissionRequest` | Logs permission dialogs; shows how to auto-deny patterns |
| [post-tool-notify.sh](examples/hooks/post-tool-notify.sh) | `PostToolUse` | Desktop notification after file edits |

</details>

<details>
<summary><strong>Permission rule references</strong></summary>

| File | Summary |
|------|---------|
| [bash-allowlist.md](examples/rules/bash-allowlist.md) | Safe Bash patterns organized by use-case |
| [mcp-rules.md](examples/rules/mcp-rules.md) | MCP tool scoping syntax and patterns |

</details>

---

## Video resources

- [Claude Code: Full tutorial](https://youtu.be/JaTcjGUDlhk)
- [Claude Code: Advanced features](https://youtu.be/SXeGudJGnDk)

---

## Shoutout

[uwu underground](https://discord.gg/uwuunderground) — a community worth knowing.

---

## License

[GNU General Public License v3.0](LICENSE)
