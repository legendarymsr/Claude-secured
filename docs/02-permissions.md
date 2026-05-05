# 02 — Permission System

The permission system is the primary security control in Claude Code. It determines what tools Claude can use, which commands it can run, and whether it must ask before acting. Understanding it deeply is the most important thing you can do to use Claude Code safely.

## Why permissions matter

Claude Code is not a chatbot — it takes real actions on your machine. Without permissions, a single misunderstood instruction could delete files, push code, or make network requests you didn't intend. Permissions are the gate between Claude's intentions and your system.

## Permission modes

Every Claude Code session has an active permission mode. You cycle through modes with `Shift+Tab` during a session (a small indicator appears in the UI), or set a default in `settings.json`:

```json
{ "defaultMode": "default" }
```

| Mode | Behavior | When to use |
|------|----------|-------------|
| `default` | Asks before edits and most commands | Everyday development — the safe starting point |
| `acceptEdits` | Auto-accepts file edits and basic fs commands (`mkdir`, `touch`, `mv`, `cp`); still asks for other shell commands | When you trust the task but want shell oversight |
| `plan` | Read-only; Claude can analyze and propose but cannot modify or execute | Reviewing an unfamiliar codebase safely |
| `auto` | Background classifier evaluates actions; blocks scope escalation and hostile content automatically | Experimental autonomous use — more safety than `bypassPermissions` |
| `bypassPermissions` | Skips all approval prompts | CI/CD only, with additional safeguards. Never as a daily driver. |

> **`plan` mode** is underused and underrated. Whenever you open an unfamiliar repo, start in `plan` mode — Claude will read, analyze, and propose, giving you a full picture before anything changes.

## Permission rules

Rules are stored in `settings.json` under `permissions.allow`, `permissions.ask`, and `permissions.deny`. They define exactly which tool calls Claude can make without asking, which it must ask about, and which are blocked entirely.

```json
{
  "permissions": {
    "allow": ["Bash(npm run test)", "Read(./src/**)"],
    "ask":   ["Bash(git push *)"],
    "deny":  ["Bash(rm -rf *)", "Read(./.env)"]
  }
}
```

### Evaluation order: deny wins

The evaluation order is: **deny → ask → allow**. The first matching rule wins.

This means:
- If a command matches a deny rule, it is blocked — even if it also matches an allow rule
- If it matches ask but not deny, Claude shows an approval dialog
- If it matches allow and not deny or ask, it runs without prompting
- If nothing matches, Claude defaults to asking (fail-closed)

**Practical example:**
```json
{
  "permissions": {
    "allow": ["Bash(npm *)"],
    "deny":  ["Bash(npm publish *)"]
  }
}
```
`npm run test` → matches allow → runs without prompt  
`npm publish` → matches deny (checked first) → blocked

### Why have an `ask` list?

`ask` is useful for operations you want to review every time but not permanently allow or deny:
- `Bash(git push *)` — you want to see every push before it happens
- `Bash(npm install *)` — you want to inspect what's being installed

The alternative to `ask` would be removing from `allow`, which causes the same approval dialog, or adding to `deny`, which blocks it permanently. `ask` is the explicit middle ground.

## Bash rule syntax

### Basic matching

| Pattern | What it matches |
|---------|----------------|
| `Bash` | Every bash command |
| `Bash(npm run build)` | Exact string `npm run build` only |
| `Bash(npm run *)` | Any command starting with `npm run ` |
| `Bash(npm*)` | Any command starting with `npm` (including `npmx`, `npm-check`) |
| `Bash(* --version)` | Any command ending with ` --version` |
| `Bash(git * main)` | `git` followed by anything followed by `main` |

### Word boundaries: the space matters

A space before `*` enforces a word boundary:

```
Bash(ls *)     → matches: ls -la, ls ./src   does NOT match: lsof, lsblk
Bash(ls*)      → matches: ls -la, ls ./src,  AND lsof, lsblk
```

This is critical for rules like `Bash(git *)` — without the space this would match any command starting with the letters "git", including a hypothetical `gitdestroy`.

### Compound commands and shell operators

Claude Code understands `&&`, `||`, `;`, `|`, `&`. A rule matching part of a compound command does **not** match the whole thing.

**Example:**
```json
{ "permissions": { "allow": ["Bash(npm run test)"] } }
```
- `npm run test` → allowed ✓
- `npm run test && rm -rf ./dist` → NOT allowed — `rm -rf ./dist` is evaluated separately and fails to match ✗

When you approve a compound command once with "Yes, don't ask again," Claude saves individual rules for each risky subcommand. Review what gets saved.

### Process wrappers: stripped automatically

These wrappers are transparent to rule matching:

| Stripped (transparent) | Not stripped (must include in rule) |
|----------------------|-----------------------------------|
| `timeout`, `time`, `nice`, `nohup`, `stdbuf`, `xargs` | `npx`, `docker exec`, `direnv exec`, `devbox run`, `mise exec` |

So `Bash(npm test *)` matches `timeout 30 npm test` automatically.  
But for `npx jest`, you need `Bash(npx jest *)` explicitly.

## Read / Edit rule syntax

Paths follow gitignore-style patterns. The prefix determines where they resolve from:

| Prefix | Resolves from | Example |
|--------|--------------|---------|
| `//path` | Filesystem root | `Read(//etc/hosts)` |
| `~/path` | Home directory | `Read(~/.ssh/id_rsa)` |
| `/path` | Project root | `Edit(/src/**/*.ts)` |
| `./path` or `path` | Current working directory | `Read(./.env)` |

`**` matches recursively (any number of subdirectories). `*` matches within a single directory level.

**Blocking sensitive files:**
```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Read(./secrets/**)"
    ]
  }
}
```

## WebFetch rule syntax

```json
"WebFetch(domain:example.com)"
```

This allows fetches to `example.com`. Without an allow rule, every WebFetch call requires manual approval.

You can't restrict to a specific path — only the domain. Use hooks if you need path-level control.

## MCP rule syntax

```
mcp__server-name                     → any tool from this server
mcp__server-name__tool_name          → one specific tool
```

Server names come from the keys in your `mcpServers` config. See [examples/rules/mcp-rules.md](../examples/rules/mcp-rules.md) for full scoping patterns.

## What "auto-approved" means for read-only commands

These commands run in any mode without prompts: `ls`, `cat`, `head`, `tail`, `grep`, `find`, `wc`, `diff`, `stat`, `du`, and read-only `git` commands.

This is intentional — reading your own files is expected behavior. The risk surface is writes and executions, not reads.

> **Exception:** `find -exec` can run arbitrary commands. Claude Code is aware of this and will prompt for `find` with write/exec flags.

## Choosing the right rule

| Situation | Rule type |
|-----------|----------|
| Command is always safe to run automatically | `allow` |
| Command should always require review | `ask` |
| Command should never run | `deny` |
| Not listed anywhere | Defaults to asking (safe) |

## How many rules does a typical project need?

A minimal project might have:
- 5–10 allow rules for test/build/lint scripts
- 3–5 deny rules for credentials and dangerous commands
- 1–2 ask rules for operations like `git push`

Don't over-engineer it. Start minimal and add rules only when you find yourself repeatedly approving the same safe command. See [examples/settings/settings.minimal.jsonc](../examples/settings/settings.minimal.jsonc) for a working starting point.

## Permissions vs. hooks: when to use which

| Use permissions rules when... | Use hooks when... |
|------------------------------|------------------|
| The rule is simple (command prefix, path) | You need to inspect the actual content of a command |
| You want to block/allow categorically | You need conditional logic (block only if parameter X is present) |
| You want a team-shared policy | You want to log every tool call |
| The decision is static | The decision depends on runtime state |

## See also

- [docs/03-settings.md](03-settings.md) — Where rules are stored and scope precedence
- [docs/04-hooks.md](04-hooks.md) — Dynamic enforcement with hooks
- [examples/rules/bash-allowlist.md](../examples/rules/bash-allowlist.md) — Safe Bash patterns by use-case
- [examples/settings/settings.minimal.jsonc](../examples/settings/settings.minimal.jsonc) — Restrictive starter config
