# 02 — Permission System

The permission system is the primary security control in Claude Code. It determines what tools Claude can use, which commands it can run, and whether it needs to ask before acting.

## Permission modes

Cycle through modes with `Shift+Tab` during a session, or set `defaultMode` in settings:

| Mode | Behavior | When to use |
|------|----------|-------------|
| `default` | Asks before edits and most commands | Everyday development |
| `acceptEdits` | Auto-accepts file edits and basic fs commands (`mkdir`, `touch`, `mv`, `cp`); still asks for other commands | When you trust the task but want shell oversight |
| `plan` | Read-only; Claude can analyze but not modify or execute | Reviewing an unfamiliar codebase |
| `auto` | Background classifier evaluates actions; blocks scope escalation and hostile content | Experimental autonomous use |
| `bypassPermissions` | Skips all approval prompts | CI/CD only, with additional safeguards |

> **Never** set `bypassPermissions` as your default interactive mode. See [docs/09-common-mistakes.md](09-common-mistakes.md).

## Permission rules

Rules live in `settings.json` under `permissions.allow`, `permissions.ask`, and `permissions.deny`. **Evaluation order is: deny → ask → allow. First match wins.**

```json
{
  "permissions": {
    "allow": ["Bash(npm run test)", "Read(./src/**)"],
    "ask":   ["Bash(git push *)"],
    "deny":  ["Bash(rm -rf *)", "Read(./.env)"]
  }
}
```

### Bash rule syntax

| Pattern | Matches |
|---------|---------|
| `Bash` | Every bash command |
| `Bash(npm run build)` | Exact command only |
| `Bash(npm run *)` | Any command starting with `npm run ` (space before `*` enforces word boundary) |
| `Bash(npm*)` | Any command starting with `npm` — also matches `npmx`, `npm-check` |
| `Bash(* --version)` | Any command ending with ` --version` |
| `Bash(git * main)` | Any git command with `main` as the last word |

The single `*` matches any sequence including spaces. A space before `*` (`ls *`) enforces a word boundary — it matches `ls -la` but not `lsof`.

### Read / Edit rule syntax

Paths follow gitignore-style patterns with these prefix meanings:

| Prefix | Resolves from |
|--------|--------------|
| `//path` | Filesystem root (`/path`) |
| `~/path` | Home directory |
| `/path` | Project root |
| `./path` or `path` | Current working directory |

Use `**` for recursive matching. Examples:
- `Read(./src/**)` — all files under `src/` relative to cwd
- `Edit(/src/**/*.ts)` — all `.ts` files under project root's `src/`
- `Read(./.env)` — deny reading the `.env` file

### WebFetch rule syntax

```
WebFetch(domain:example.com)
```

Restricts fetches to a specific hostname. Without a rule, WebFetch requires manual approval.

### MCP rule syntax

```
mcp__server-name                    # any tool from this server
mcp__server-name__tool_name         # specific tool only
```

See [examples/rules/mcp-rules.md](../examples/rules/mcp-rules.md) for scoping patterns.

## Compound commands

Claude Code understands shell operators (`&&`, `||`, `;`, `|`, `&`). A rule matching `safe-cmd *` does **not** match `safe-cmd && other-cmd`. Each component is evaluated independently.

When you approve a compound command with "Yes, don't ask again," Claude saves separate rules for each risky subcommand.

## Process wrappers

Claude Code strips known wrappers before matching rules:

**Stripped** (transparent): `timeout`, `time`, `nice`, `nohup`, `stdbuf`, bare `xargs`

So `Bash(npm test *)` matches `timeout 30 npm test`.

**Not stripped** (must be included in rule): `npx`, `docker exec`, `direnv exec`, `devbox run`, `mise exec`

## Auto-approved read-only commands

These run without prompts in any mode: `ls`, `cat`, `head`, `tail`, `grep`, `find`, `wc`, `diff`, `stat`, `du`, read-only `git` commands.

## See also

- [docs/03-settings.md](03-settings.md) — Where rules are stored and scope precedence
- [examples/rules/bash-allowlist.md](../examples/rules/bash-allowlist.md) — Safe Bash patterns by use-case
- [examples/settings/settings.minimal.jsonc](../examples/settings/settings.minimal.jsonc) — A restrictive starter config
