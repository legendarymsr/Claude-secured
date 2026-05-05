# 02 — Permission System

Permissions control what Claude Code can do without asking you first. **This is the most important security control in Claude Code.**

---

## Quick start

Add this to `.claude/settings.json` to get a safe baseline:

```json
{
  "permissions": {
    "allow": ["Bash(npm run test)", "Bash(npm run lint)", "Bash(git status)"],
    "deny":  ["Read(./.env)", "Read(~/.aws/**)", "Read(~/.ssh/**)"]
  }
}
```

- `allow` — runs without asking
- `deny` — always blocked, even if Claude wants to do it
- Anything not listed → Claude asks you first (safe default)

---

## Permission modes

Switch with `Shift+Tab` during a session, or set `"defaultMode"` in settings:

| Mode | What happens | Use when |
|------|-------------|----------|
| `default` | Claude asks before edits and commands | Everyday use |
| `acceptEdits` | Auto-approves file edits; still asks for shell commands | You trust the edits |
| `plan` | Read-only — Claude can analyze but not change anything | Exploring unfamiliar code |
| `auto` | Background AI classifier evaluates each action | Autonomous use with safety |
| `bypassPermissions` | No approval prompts at all | CI only, with isolation |

> **Start with `default`.** Use `plan` whenever you open an unfamiliar repo.

<details>
<summary>📖 How each mode works in detail</summary>

### `default`
The standard mode. Claude shows an approval dialog before:
- Any file edit
- Any shell command (except read-only ones like `ls`, `cat`, `grep`)
- Any network request

Read-only commands (`ls`, `cat`, `head`, `tail`, `grep`, `find`, `wc`, `diff`, `stat`, `du`, read-only `git`) run automatically in any mode.

### `acceptEdits`
Automatically approves:
- File edits (`Edit`, `Write`)
- Basic filesystem commands: `mkdir`, `touch`, `mv`, `cp`

Still asks before:
- Shell commands with side effects
- Network requests
- Git operations with remote effects

### `plan`
Claude Code runs entirely in read mode. It can read files, search code, and produce analysis and plans — but every tool call that would modify anything is blocked. Use this when you want Claude's analysis without any risk of changes.

### `auto`
A background AI classifier evaluates each proposed tool call before it runs. The classifier blocks:
- Scope escalation (Claude trying to access things outside the current task)
- Hostile or destructive patterns
- Actions inconsistent with the stated goal

This is the best mode for autonomous use that still needs some safety. It's experimental — don't rely on it as your only control.

### `bypassPermissions`
Skips all approval dialogs. Claude runs every tool call immediately. Only safe when:
- Running inside a container with limited filesystem and network access
- No production credentials are present in the environment
- You have compensating controls (strict allow/deny rules, hooks)

Never use `bypassPermissions` as your daily interactive mode.

</details>

---

## Rule syntax

### Evaluation order: **deny → ask → allow — first match wins**

```json
{
  "permissions": {
    "allow": ["Bash(npm *)"],
    "deny":  ["Bash(npm publish *)"]
  }
}
```

`npm run test` → matches allow → runs ✓  
`npm publish` → matches deny first → blocked ✗

<details>
<summary>📖 Full Bash rule syntax</summary>

### Exact match
```
Bash(npm run build)   → matches only "npm run build"
```

### Prefix match (most common)
```
Bash(npm run *)       → matches "npm run test", "npm run lint", etc.
```

The space before `*` enforces a word boundary:
- `Bash(ls *)` → matches `ls -la`, `ls ./src` but NOT `lsof`
- `Bash(ls*)` → matches `ls -la`, `ls ./src` AND `lsof`, `lsblk`

### Suffix match
```
Bash(* --version)     → matches any command ending with "--version"
```

### Middle wildcard
```
Bash(git * main)      → matches "git push origin main", "git merge main"
```

### Compound commands (`&&`, `||`, `;`, `|`)

Rules match individual commands — not compound ones. `Bash(safe-cmd *)` does NOT match `safe-cmd && dangerous-cmd`.

Each part of a compound command is evaluated separately. If any part fails to match an allow rule, Claude asks before the whole compound runs.

### Process wrappers

These wrappers are stripped before matching (transparent):
- `timeout`, `time`, `nice`, `nohup`, `stdbuf`, bare `xargs`

So `Bash(npm test *)` also matches `timeout 30 npm test`.

These are NOT stripped (include them in your rule):
- `npx`, `docker exec`, `direnv exec`, `devbox run`, `mise exec`

For `npx jest`, you need `Bash(npx jest *)` explicitly.

</details>

<details>
<summary>📖 Read / Edit rule syntax</summary>

Paths use gitignore-style patterns. The prefix sets where they resolve from:

| Prefix | Resolves from | Example |
|--------|--------------|---------|
| `//` | Filesystem root | `Read(//etc/passwd)` |
| `~/` | Home directory | `Read(~/.ssh/**)` |
| `/` | Project root | `Edit(/src/**/*.ts)` |
| `./` or no prefix | Current working dir | `Read(./.env)` |

`**` = match any depth (recursive)  
`*` = match within one directory level

**Block all credential files:**
```json
{
  "permissions": {
    "deny": [
      "Read(./.env)", "Read(./.env.*)",
      "Read(~/.aws/**)", "Read(~/.ssh/**)",
      "Read(~/.gnupg/**)", "Read(./secrets/**)"
    ]
  }
}
```

</details>

<details>
<summary>📖 WebFetch and MCP rule syntax</summary>

### WebFetch
```
WebFetch(domain:example.com)
```
Allows fetches to a specific hostname. Without a rule, every WebFetch requires approval. You can't restrict to a path — only the domain.

### MCP tools
```
mcp__server-name                  → any tool from this server
mcp__server-name__tool_name       → one specific tool
```

**Best practice:** allow only the tools you need, then add a catch-all deny:
```json
{
  "permissions": {
    "allow": ["mcp__github__list_issues", "mcp__github__get_issue"],
    "deny":  ["mcp__github"]
  }
}
```
The catch-all `mcp__github` blocks any new tool the server adds. Without it, new tools are automatically available to Claude.

</details>

<details>
<summary>📖 Permissions vs. hooks — when to use which</summary>

| Use permission rules when... | Use hooks when... |
|-----------------------------|------------------|
| The decision is based on the tool name or a simple command prefix | You need to inspect the full content of a command |
| You want to block or allow a whole category | You need conditional logic (block only if parameter X matches) |
| You want a static, committed team policy | You want to log every tool call |
| The rule is the same regardless of context | The decision depends on runtime state |

Example where hooks are better than rules:

```bash
# A rule can block "rm -rf *" but not "rm -rf ./dist"
# A hook can check the exact argument and decide
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')
if echo "$COMMAND" | grep -qE "rm -rf /(home|root|etc)"; then
  exit 2  # Block system-level deletions
fi
# Allow project-level deletions like rm -rf ./dist
exit 0
```

</details>

---

## See also

- [docs/03-settings.md](03-settings.md) — Where rules are stored
- [docs/04-hooks.md](04-hooks.md) — Dynamic enforcement
- [examples/rules/bash-allowlist.md](../examples/rules/bash-allowlist.md) — Safe Bash patterns
- [examples/settings/settings.minimal.jsonc](../examples/settings/settings.minimal.jsonc) — Starter config
