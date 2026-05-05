# 09 — Common Mistakes

The most frequent ways people misconfigure Claude Code — and how to fix them.

---

## Using `bypassPermissions` as your daily mode

**Risk:** Claude can modify any file, run any command, and make any network request without asking. A misunderstood instruction, prompt injection, or runaway loop causes unrecoverable damage.

**Fix:** Keep `defaultMode: default`. Use `auto` for supervised autonomous runs.

---

## Installing MCP servers from untrusted sources

**Risk:** An MCP server is a subprocess with your OS user's full privileges. A malicious package can read credentials, exfiltrate files, and install backdoors.

**Fix:** Only use MCP servers from official vendors or packages you've personally reviewed. Pin to a specific version. See [docs/05-mcp-security.md](05-mcp-security.md).

---

## Granting `"allow": ["Bash"]` or `"Bash(*)"` 

**Risk:** Allows every possible bash command — including `rm -rf`, `curl`, privilege escalation, and anything else.

**Fix:** List only the specific commands you need:
```json
{ "permissions": { "allow": ["Bash(npm run test)", "Bash(npm run lint)"] } }
```

---

## Storing secrets in settings.json

**Risk:** `settings.json` is committed to git. Secrets are in your git history and visible to everyone with repo access.

**Fix:** Set secrets in your shell environment before launching Claude Code:
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
claude
```

<details>
<summary>📖 All the ways secrets can leak through settings</summary>

| Where | Why it's risky |
|-------|---------------|
| `"env": { "API_KEY": "..." }` in committed `settings.json` | In git history forever |
| `"env": { "API_KEY": "..." }` in `settings.local.json` | Still plaintext on disk, visible to other processes |
| Credentials in hook script comments | Hooks are often committed too |
| Credentials in CLAUDE.md | Committed, visible to all |
| Credentials in allow rule comments | Committed, visible to all |

Safe alternatives: shell env vars, direnv with a gitignored `.envrc`, 1Password CLI, HashiCorp Vault. See [docs/12-secrets-management.md](12-secrets-management.md).

</details>

---

## Running CI with `bypassPermissions` and no isolation

**Risk:** A malicious PR or injected prompt runs arbitrary commands against production systems with no oversight.

**Fix:** Use `auto` mode. Run in an isolated container with no production credentials. See [docs/13-ci-cd-guide.md](13-ci-cd-guide.md).

---

## Trusting CLAUDE.md from an unfamiliar repo

**Risk:** A malicious `CLAUDE.md` primes Claude with bad instructions — to skip permissions, exfiltrate files, or behave deceptively.

**Fix:** Always read `CLAUDE.md` before running Claude Code in a repo you didn't create:
```bash
cat CLAUDE.md
ls .claude/
```

If the instructions look unusual — especially anything about permissions, external URLs, or skipping confirmations — investigate before proceeding.

---

## Checking in `.claude/settings.local.json`

**Risk:** Local settings contain personal machine paths, session-specific overrides, and possibly credentials. Committing them exposes this to your team and git history.

**Fix:** Keep it gitignored. Use `.claude/settings.json` for anything the team should share.

---

## Ignoring hook blocks or errors

**Risk:** Hooks are your last-line enforcement. Dismissing a block means the protection didn't work — and you've now approved an action the hook was specifically designed to stop.

**Fix:** When a hook blocks something, investigate before changing any config. If it's a false positive, fix the hook logic — don't disable the hook.

---

## Approving "Yes, don't ask again" without reading what you're approving

**Risk:** "Yes, don't ask again" creates a permanent allow rule for that command. If the command is more permissive than you realize (e.g., a compound command with a dangerous second part), you've permanently allowed something dangerous.

**Fix:** Read the exact command in the approval dialog before clicking. For compound commands (`&&`, `||`, `;`), read every part.

<details>
<summary>📖 More mistakes: read/WebFetch/MCP-specific</summary>

### Too-broad Read rules
```json
// These allow Claude to read your entire home directory
"Read(~/**)"
"Read(/home/**)"
```
Scope Read rules to the project: `"Read(./src/**)"` not `"Read(~/**)"`.

### Allowing WebFetch to internal IP ranges
```json
// Risky — allows Claude to probe internal services
"WebFetch(domain:192.168.1.1)"
"WebFetch(domain:localhost)"
```
Only allow WebFetch to specific external domains you trust.

### Allowing an entire MCP server without a catch-all deny
```json
// Missing the catch-all
{
  "allow": ["mcp__github__list_issues", "mcp__github__get_issue"]
  // No deny catch-all — new tools the server adds are automatically available
}
```

Always add a catch-all deny after specific allows:
```json
{
  "allow": ["mcp__github__list_issues", "mcp__github__get_issue"],
  "deny": ["mcp__github"]
}
```

</details>

---

## See also

- [docs/02-permissions.md](02-permissions.md) — Building safe permission rules
- [docs/05-mcp-security.md](05-mcp-security.md) — MCP vetting
- [docs/12-secrets-management.md](12-secrets-management.md) — Credential handling
