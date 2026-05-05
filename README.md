# Claude-secured

A practical security guide for [Claude Code](https://code.claude.com) — Anthropic's agentic coding CLI. Covers the permission system, hooks, MCP servers, prompt injection, network security, and copy-paste-ready example configurations.

## Who this is for

- **Individual developers** who want to understand what Claude Code can and cannot do on their machine
- **Teams** setting up shared `.claude/settings.json` with sensible defaults
- **Enterprise/security engineers** enforcing policy via managed settings and audit hooks

## Quick start

Copy [`examples/settings/settings.minimal.jsonc`](examples/settings/settings.minimal.jsonc) into your project's `.claude/settings.json` (strip comments first — Claude Code reads standard JSON). This gives you a restrictive baseline to expand from.

---

## Documentation

| File | Summary |
|------|---------|
| [docs/01-overview.md](docs/01-overview.md) | What Claude Code is, the agentic loop, and why it's a different security model than a chatbot |
| [docs/02-permissions.md](docs/02-permissions.md) | Permission modes, rule syntax for Bash/Read/Edit/WebFetch/MCP, compound commands |
| [docs/03-settings.md](docs/03-settings.md) | The four configuration scopes, settings.json schema, sensitive file protection |
| [docs/04-hooks.md](docs/04-hooks.md) | Hook event types, stdin/stdout payload format, exit codes, security implications |
| [docs/05-mcp-security.md](docs/05-mcp-security.md) | MCP server risks, vetting checklist, scoping permissions to specific tools |
| [docs/06-prompt-injection.md](docs/06-prompt-injection.md) | How injection works in an agentic context, built-in protections, user defenses |
| [docs/07-network-api-security.md](docs/07-network-api-security.md) | What data leaves your machine, TLS, Zero Data Retention, telemetry opt-outs |
| [docs/08-best-practices.md](docs/08-best-practices.md) | Checklist for individual developers, teams, and enterprise/CI environments |
| [docs/09-common-mistakes.md](docs/09-common-mistakes.md) | Anti-patterns with their consequences and correct alternatives |
| [docs/10-slash-commands.md](docs/10-slash-commands.md) | Security-relevant built-in commands and risks of custom slash commands |

---

## Examples

### Settings configs
| File | Use case |
|------|----------|
| [examples/settings/settings.minimal.jsonc](examples/settings/settings.minimal.jsonc) | Restrictive starter — good default for any project |
| [examples/settings/settings.team.jsonc](examples/settings/settings.team.jsonc) | Shared project config for a Node.js/Python team |
| [examples/settings/settings.enterprise.jsonc](examples/settings/settings.enterprise.jsonc) | Managed policy with ZDR, audit hooks, locked-down modes |

> **Note:** Files use `.jsonc` (JSON with comments) for readability. Strip comments before placing in `.claude/settings.json`.

### Hook scripts
| File | Hook event | What it does |
|------|-----------|-------------|
| [examples/hooks/block-dangerous-commands.sh](examples/hooks/block-dangerous-commands.sh) | `PreToolUse` | Blocks Bash commands matching a destructive pattern list |
| [examples/hooks/pre-tool-audit.sh](examples/hooks/pre-tool-audit.sh) | `PreToolUse` | Writes every tool call to a structured audit log |
| [examples/hooks/permission-request-logger.sh](examples/hooks/permission-request-logger.sh) | `PermissionRequest` | Logs permission requests; shows how to auto-deny patterns |
| [examples/hooks/post-tool-notify.sh](examples/hooks/post-tool-notify.sh) | `PostToolUse` | Desktop notification after file edits (Linux + macOS) |

### Permission rule references
| File | Summary |
|------|---------|
| [examples/rules/bash-allowlist.md](examples/rules/bash-allowlist.md) | Annotated safe Bash patterns by use-case |
| [examples/rules/mcp-rules.md](examples/rules/mcp-rules.md) | MCP tool scoping syntax and patterns |

---

## License

[GNU General Public License v3.0](LICENSE)
