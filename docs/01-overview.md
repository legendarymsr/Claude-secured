# 01 — What is Claude Code

Claude Code is an agentic coding assistant from Anthropic, available as a CLI, VS Code/JetBrains extension, desktop app, and web interface. Unlike a code-completion tool or a chatbot, Claude Code reads your actual codebase, edits files, runs shell commands, and autonomously works through multi-step tasks.

## The agentic loop

Every Claude Code session operates in a cycle:

1. **Gather context** — Read files, search code, run read-only commands
2. **Take action** — Edit files, run bash commands, call MCP tools, search the web
3. **Verify results** — Run tests, compare output, check for errors
4. Repeat until the task is done or it needs your input

This loop is what makes Claude Code powerful — and what makes it different from a passive assistant. A single prompt can cause dozens of tool calls across many files.

## Tool surface

Claude Code can use the following tools:

| Tool | What it does |
|------|-------------|
| `Read` | Read file contents |
| `Edit` / `Write` | Modify or create files |
| `Bash` | Run any shell command |
| `Glob` / `Grep` | Search files by name or content |
| `WebFetch` / `WebSearch` | Fetch URLs, search the web |
| `MCP tools` | Any tool exposed by a configured MCP server |
| `Agent` | Spawn subagents for delegated work |

## Interactive vs. headless use

**Interactive**: The default. Claude asks for approval before edits and commands. You review each action.

**Headless / CI**: Launched with `-p` (print mode) or piped input. Often used with `--dangerously-skip-permissions` for automation. This mode has no human reviewer — see [docs/09-common-mistakes.md](09-common-mistakes.md) for why this is risky without additional safeguards.

## Why this is a different security model

A traditional chatbot can only produce text. Claude Code can:
- Delete files
- Commit and push code
- Install packages
- Make network requests
- Run any command your OS user can run

The right mental model is **a junior engineer with full shell access to your machine**. The permission system, hooks, and settings covered in this guide are how you constrain that access appropriately.

## See also

- [docs/02-permissions.md](02-permissions.md) — How to control what Claude Code can do
- [docs/07-network-api-security.md](07-network-api-security.md) — What data leaves your machine
