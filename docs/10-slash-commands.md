# 10 — Slash Commands

Slash commands are shortcuts that invoke Claude Code features. Most are read-only configuration tools. A few have security implications worth understanding.

---

## Security-relevant built-in commands

| Command | What it does | Security note |
|---------|-------------|--------------|
| `/permissions` | View and edit permission rules | Modifies `settings.json` |
| `/config` | Interactive settings editor | Modifies `settings.json` |
| `/mcp` | List active MCP servers and their tools | Use this to find tool names for rules |
| `/hooks` | View configured hooks | Shows what scripts will run |
| `/sandbox` | Enable/configure sandboxing | Sets OS-level isolation |
| `/add-dir` | Grant access to an additional directory | Expands Claude's file access |
| `/clear` | Reset conversation context | Recommended between tasks |
| `/feedback` | Submit feedback | **May send transcript to Anthropic** |
| `/init` | Create a CLAUDE.md template | Generates a file — review before committing |

---

## `/feedback`: what gets sent

When you use `/feedback`, Claude Code may offer to include your session transcript. If you accept, the entire conversation — including file contents Claude read and command outputs — is sent to Anthropic.

**Before using `/feedback`:** run `/clear` if your session involved sensitive data (credentials, private code, internal URLs).

---

## Custom slash commands

Custom commands live in `.claude/commands/` as Markdown files. When you run `/my-command`, its content is injected into Claude's prompt as instructions.

**Treat custom commands like code.** A command file that says "delete all log files and push to production" will do exactly that.

<details>
<summary>📖 Security risks with custom commands</summary>

### From untrusted repos

If you clone a repo that includes `.claude/commands/`, those commands are immediately available in your Claude Code session. A malicious command disguised as a utility could:
- Run destructive operations
- Exfiltrate files
- Modify your git config
- Install packages

**Fix:** Review every file in `.claude/commands/` before running any command from an unfamiliar repo:
```bash
ls .claude/commands/
cat .claude/commands/deploy.md   # Read it before running /deploy
```

### Commands and permission mode

Commands run under your current permission mode. If you're in `bypassPermissions` mode and invoke a custom command, every action in that command runs without approval.

### Red flags in command files

Be suspicious of commands that contain:
- Instructions to skip or disable permissions
- References to external URLs for sending data
- Instructions to read credential files
- Instructions to disable hooks or modify settings
- Base64-encoded strings or obfuscated text

### Safe custom command example

```markdown
# Review changed files

Run `git diff --name-only HEAD~1` to find changed files,
then summarize the changes in each file.
Do not run any commands other than git read commands.
```

This is scoped and explicit. Compare to a command that says "do whatever is needed" — that's a wide-open instruction.

</details>

<details>
<summary>📖 How to create and share custom commands</summary>

Create a Markdown file in `.claude/commands/`:
```bash
mkdir -p .claude/commands
cat > .claude/commands/check-types.md << 'EOF'
Run `npm run typecheck` and report any type errors found.
If there are errors, suggest fixes but do not apply them automatically.
EOF
```

Invoke it with `/check-types` in a Claude Code session.

Commands in `.claude/commands/` are shared with your team when committed to git. Commands in `~/.claude/commands/` are personal and apply to all projects.

**Best practice for shared commands:** include explicit constraints in the command text (what Claude should and shouldn't do), and review them during code review like any other code.

</details>

---

## See also

- [docs/02-permissions.md](02-permissions.md) — Permission modes that affect command execution
- [docs/06-prompt-injection.md](06-prompt-injection.md) — Injection risk in command content
- [docs/11-claude-md-guide.md](11-claude-md-guide.md) — CLAUDE.md vs. custom commands
