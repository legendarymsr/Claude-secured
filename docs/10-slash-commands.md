# 10 — Slash Commands

Slash commands are shortcuts that invoke built-in Claude Code features or custom workflows. Most are safe — they configure Claude Code's behavior rather than executing arbitrary code. A few carry security-relevant implications worth understanding.

## Security-relevant built-in commands

| Command | What it does | Security note |
|---------|-------------|--------------|
| `/permissions` | View and edit current permission rules | Safe — shows and modifies your settings.json |
| `/config` | Interactive settings editor | Safe — UI for settings.json |
| `/doctor` | Configuration health check | Safe — reads and validates your config |
| `/mcp` | List active MCP servers and their tools | Safe — inspect what servers are loaded |
| `/hooks` | View configured hooks | Safe — shows hook definitions |
| `/sandbox` | Enable/configure sandboxing | Safe — sets OS-level isolation |
| `/add-dir` | Grant access to an additional directory | Safe — expands Claude's read scope |
| `/clear` | Reset conversation context | Recommended between unrelated tasks |
| `/feedback` | Submit feedback with optional transcript | **Sends data to Anthropic** — ensure no secrets in context before using |
| `/init` | Create a CLAUDE.md template | Safe — generates a template file |

## `/feedback`: what gets sent

When you use `/feedback`, Claude Code may offer to include your session transcript with the report. If you accept, the entire conversation — including file contents Claude read, command outputs, and your prompts — is sent to Anthropic.

Best practice: use `/clear` before running `/feedback` if your session involved sensitive data.

## Custom slash commands

Custom commands live in `.claude/commands/` as Markdown files. When invoked, their content is injected into Claude's prompt as instructions.

**Security considerations:**

1. **Treat custom commands like code.** A command that says "delete all log files and push to prod" will do exactly that when invoked.

2. **Don't source commands from untrusted repos.** If you clone a repo that includes `.claude/commands/`, review every file before running any command from that repo. A malicious command could be disguised as a utility.

3. **Commands run under your current permission mode.** If you're in `bypassPermissions` mode and run a custom command, that command runs without any approval gates.

4. **Commands can call tools.** If a command's instructions tell Claude to run a bash command, that bash command goes through the normal permission system — but a cleverly written command can work around your expectations if your allow rules are too broad.

## Custom command example: what to check

Before using a custom command from any source, read the file:

```bash
cat .claude/commands/deploy.md
```

Flags to look for:
- Instructions to skip permissions or use `--dangerously-skip-permissions`
- Network calls to unexpected destinations
- References to credentials or secret files
- Instructions to disable hooks or modify settings

## See also

- [docs/02-permissions.md](02-permissions.md) — Permission modes that affect command execution
- [docs/06-prompt-injection.md](06-prompt-injection.md) — Injection risk in command content
- [docs/03-settings.md](03-settings.md) — Settings commands modify
