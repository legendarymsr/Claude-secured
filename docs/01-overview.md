# 01 — What is Claude Code

Claude Code is an agentic coding assistant that reads your codebase, edits files, and runs shell commands. It's not a chatbot — it takes real actions on your machine.

**The right mental model:** a developer with full shell access to your machine, who does exactly what you ask — including things you didn't mean to ask for.

---

## The agentic loop

Every session runs in a cycle:

1. **Gather context** — read files, search code, run read-only commands
2. **Take action** — edit files, run bash, call MCP tools, fetch URLs
3. **Verify** — run tests, check output, look for errors
4. Repeat until done or until it needs your input

A single prompt can trigger dozens of tool calls across many files.

---

## Tool surface (what Claude Code can do)

| Tool | What it does |
|------|-------------|
| `Read` | Read any file on your system |
| `Edit` / `Write` | Modify or create files |
| `Bash` | Run any shell command |
| `Glob` / `Grep` | Search files by name or content |
| `WebFetch` / `WebSearch` | Fetch URLs, search the web |
| `MCP tools` | Anything a configured MCP server exposes |
| `Agent` | Spawn subagents for delegated work |

---

## Interactive vs. headless use

**Interactive (default):** Claude asks for approval before edits and commands. You review each action.

**Headless / CI:** Launched with `-p` for scripted use. No human reviewer — requires additional safeguards.

<details>
<summary>📖 More on interactive vs. headless security</summary>

In interactive mode, every tool call shows you what Claude is about to do before it happens. You can read the exact command, file path, or edit. This review step is your primary safety check.

In headless mode (`claude -p "do the task"`), there is no review step. Every action Claude decides to take runs automatically. This makes headless use powerful for automation but dangerous without:

- Strict permission rules that limit what Claude can do
- `auto` mode (which has a background safety classifier) rather than `bypassPermissions`
- Container isolation so mistakes don't reach production systems
- Credential restrictions so Claude can't access sensitive data even if instructed to

See [docs/13-ci-cd-guide.md](13-ci-cd-guide.md) for CI-specific guidance.

</details>

---

## Why this is a different security model

A chatbot produces text. Claude Code:
- Deletes files
- Commits and pushes code
- Installs packages
- Makes network requests
- Runs any command your OS user can run

Every one of these actions is gated by the permission system — but only if you configure it. The default settings are permissive. This guide explains how to tighten them.

<details>
<summary>📖 What Claude Code can and can't access by default</summary>

**By default, Claude Code can:**
- Read any file your OS user can read (including `~/.ssh`, `~/.aws`, `.env`)
- Run any bash command (including `rm -rf`, `curl`, `git push`)
- Make network requests via WebFetch and WebSearch
- Spawn subagents that have the same capabilities

**By default, Claude Code cannot:**
- Bypass your OS permissions (it runs as your user, not root)
- Access files on other machines (unless you configure MCP servers that connect to them)
- Approve its own permission requests (the human must approve in interactive mode)
- Remember anything between sessions (each session starts fresh)

**The implication:** the most important security controls are deny rules that prevent Claude from reading credential files and permission rules that prevent unexpected commands from running. See [docs/02-permissions.md](02-permissions.md) and [docs/12-secrets-management.md](12-secrets-management.md).

</details>

---

## See also

- [docs/02-permissions.md](02-permissions.md) — How to control what Claude Code can do
- [docs/07-network-api-security.md](07-network-api-security.md) — What data leaves your machine
- [docs/09-common-mistakes.md](09-common-mistakes.md) — Common ways people misconfigure Claude Code
