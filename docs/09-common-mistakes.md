# 09 — Common Mistakes

Anti-patterns that create real security risk, with explanations and correct alternatives.

---

## Using `bypassPermissions` as your default

**Mistake:** Setting `defaultMode: bypassPermissions` in `~/.claude/settings.json` because approval dialogs feel slow.

**Risk:** Claude can modify any file your OS user can write, run any command, and install anything without asking. A prompt injection attack, a misunderstood instruction, or a runaway agentic loop can cause severe damage with no opportunity for review.

**Fix:** Keep `defaultMode: default`. Use `acceptEdits` if you trust the file edits for a specific session. Use `auto` mode for supervised autonomous runs. Reserve `bypassPermissions` for isolated CI pipelines only.

---

## Installing MCP servers from untrusted sources

**Mistake:** Running `npm install -g @random-user/claude-mcp-github` and adding it to project settings.

**Risk:** The package executes code in your environment with your OS user's privileges. It can read files, make network requests, and steal credentials. Supply chain attacks against MCP packages have occurred.

**Fix:** Only use MCP servers from official vendors (Anthropic, GitHub, Atlassian, etc.) or packages whose source code you have personally reviewed. Pin to a specific version. See [docs/05-mcp-security.md](05-mcp-security.md).

---

## Running in CI with `bypassPermissions` and no isolation

**Mistake:** Using `claude -p "do the thing" --dangerously-skip-permissions` in a CI job that has access to production credentials and a live database connection.

**Risk:** A malicious commit or injected prompt can execute arbitrary commands against your production environment.

**Fix:** Run CI Claude Code jobs in an isolated container with no production credentials mounted. Use `auto` mode when possible. Apply `disableBypassPermissionsMode` in managed settings so the flag can't be used at all. See [docs/08-best-practices.md](08-best-practices.md#enterprise-and-cicd).

---

## Granting `Bash(*)` in allow rules

**Mistake:** Adding `"allow": ["Bash"]` to silence all approval dialogs.

**Risk:** This allows every possible bash command — including destructive ones, network calls, and privilege escalation attempts — without any review.

**Fix:** Enumerate the specific commands you need:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run test)",
      "Bash(npm run lint)",
      "Bash(git status)",
      "Bash(git diff *)"
    ]
  }
}
```

See [examples/rules/bash-allowlist.md](../examples/rules/bash-allowlist.md) for a starting point.

---

## Storing secrets in settings.json

**Mistake:** Putting API keys or passwords in the `env` block of `.claude/settings.json` and committing the file.

**Risk:** Credentials are now in your git history and visible to anyone with repo access.

**Fix:** Pass secrets as environment variables in your shell before launching Claude Code:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
claude
```

Or use a secrets manager to inject them at runtime. Never put plaintext credentials in any committed file.

---

## Ignoring hook exit codes and warnings

**Mistake:** Dismissing hook-generated blocks or errors with "it's probably fine" and proceeding.

**Risk:** Hooks are your last-line enforcement. If a `PreToolUse` hook blocked a command, it had a reason — the command matched a dangerous pattern. Bypassing it removes the protection.

**Fix:** When a hook blocks something, investigate why before changing any config. If the block is a false positive, update the hook logic — don't disable the hook.

---

## Checking in `.claude/settings.local.json`

**Mistake:** Removing `.claude/settings.local.json` from `.gitignore` and committing it.

**Risk:** Local settings often contain personal paths, local MCP server configs, and session-specific overrides that are unsuitable for other users' machines. If they contain credentials, those are now shared.

**Fix:** Keep `settings.local.json` gitignored. Use `settings.json` for anything the team should share.

---

## Trusting CLAUDE.md files from unknown repos

**Mistake:** Cloning an unfamiliar repository and immediately running `claude` without reading `CLAUDE.md`.

**Risk:** A malicious `CLAUDE.md` can instruct Claude to exfiltrate files, run harmful commands, or behave deceptively — all framed as "project conventions."

**Fix:** Read `CLAUDE.md` before starting a Claude Code session in any repo you didn't create. If it contains instructions to skip permissions, disable tools, or perform unexpected network calls, treat the repo as hostile.

---

## See also

- [docs/02-permissions.md](02-permissions.md) — Building a safe permission rule set
- [docs/05-mcp-security.md](05-mcp-security.md) — MCP vetting checklist
- [docs/08-best-practices.md](08-best-practices.md) — Positive security practices
