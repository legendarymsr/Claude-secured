# 12 — Secrets & Credential Management

Claude Code reads files and runs commands. If your credentials are in files Claude can read — or in settings committed to git — they will be exposed.

---

## The two rules

1. **Block credential files** with deny rules so Claude can't read them
2. **Never put secrets in `settings.json`** — it's committed to git

---

## Block credential files (do this now)

Add to `.claude/settings.json`:
```json
{
  "permissions": {
    "deny": [
      "Read(./.env)", "Read(./.env.*)",
      "Read(~/.aws/**)", "Read(~/.ssh/**)",
      "Read(~/.gnupg/**)", "Read(./secrets/**)",
      "Read(~/.kube/**)", "Read(~/.docker/config.json)"
    ]
  }
}
```

Also add home-directory rules to `~/.claude/settings.json` as a fallback for projects without their own settings.

---

## Pass secrets via shell environment

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export DATABASE_URL="postgres://user:pass@host/db"
claude
```

Claude Code inherits your shell environment. Commands it runs will have access to these variables — but they don't appear in any file Claude reads.

<details>
<summary>📖 Secrets manager integrations</summary>

### direnv (simplest for teams)

```bash
# .envrc — add to .gitignore!
export DATABASE_URL="postgres://..."
export API_KEY="..."
```

```bash
# .gitignore
.envrc
```

Add a deny rule so Claude can't read it anyway:
```json
{ "permissions": { "deny": ["Read(./.envrc)"] } }
```

### 1Password CLI

```bash
eval $(op signin)
export GITHUB_TOKEN=$(op item get "GitHub Token" --fields credential)
claude
```

Or use `op run`:
```bash
# .env.tpl — references, not real values (safe to commit)
DATABASE_URL=op://vault/item/field

op run --env-file=.env.tpl -- claude
```

### HashiCorp Vault

```bash
export DB_PASSWORD=$(vault kv get -field=password secret/myapp/db)
claude
```

### AWS Secrets Manager

```bash
export DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id prod/db/password \
  --query SecretString --output text)
claude
```

</details>

<details>
<summary>📖 Preventing secrets from appearing in command output</summary>

Even if Claude can't read `.env`, a command can print secrets. Add deny rules for common culprits:

```json
{
  "permissions": {
    "deny": [
      "Bash(printenv *)",
      "Bash(env)",
      "Bash(cat ~/.netrc)",
      "Bash(aws configure list *)"
    ]
  }
}
```

Or use a hook to block commands whose output would contain secrets:

```bash
#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -qiE "printenv|^env$|\.env|credentials"; then
  echo "Command may expose secrets" >&2
  exit 2
fi
exit 0
```

</details>

<details>
<summary>📖 Secrets in CI/CD pipelines</summary>

In GitHub Actions:
```yaml
- name: Run Claude Code
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
    # DO NOT add production credentials here
  run: claude --permission-mode auto -p "run tests and fix failures"
```

Never pass production credentials (`AWS_ACCESS_KEY_ID`, `DATABASE_URL`, etc.) to CI Claude Code sessions unless Claude genuinely needs them for the task — and even then, use read-only scoped credentials.

</details>

<details>
<summary>📖 If a credential was already exposed</summary>

If Claude read a credential file (e.g., before you added the deny rule), assume the credential is compromised:

1. **Rotate the credential immediately** — don't wait to see if anything bad happened
2. **Check Anthropic's retention policy** for your account (standard vs. Zero Data Retention)
3. **Audit the credential's usage logs** — AWS CloudTrail, GitHub audit log, etc.
4. **Add the deny rule** so it can't happen again

For secrets committed to git, rotation alone isn't enough — remove from history:
```bash
git filter-repo --path .env --invert-paths
git push --force --all
```

Then notify GitHub/GitLab to scan for the exposed secret in their systems.

</details>

<details>
<summary>📖 The ANTHROPIC_API_KEY</summary>

Claude Code uses your `ANTHROPIC_API_KEY` for every API call. Treat it as a high-value credential:

- Use separate keys for dev, CI, and production
- Rotate quarterly (or immediately if suspected compromise)
- Set spend limits in the Anthropic console
- Monitor usage for anomalies
- Store in a secrets manager, not in `.bashrc`

```bash
# Recommended: fetch from secrets manager each session
export ANTHROPIC_API_KEY=$(op item get "Anthropic API Key" --fields credential)
claude
```

</details>

---

## See also

- [docs/02-permissions.md](02-permissions.md) — Deny rules for credential files
- [docs/03-settings.md](03-settings.md) — Why not to use the `env` block for secrets
- [docs/07-network-api-security.md](07-network-api-security.md) — What reaches Anthropic's API
