# 12 — Secrets & Credential Management

Claude Code sessions involve file reads, shell commands, and API calls — all of which can inadvertently expose credentials. This doc covers how to handle secrets safely when using Claude Code.

## The threat model

Credentials can leak through Claude Code in several ways:

1. **Claude reads a secret file** — e.g., `.env`, `~/.aws/credentials`, `~/.ssh/id_rsa`
2. **A command outputs a secret** — e.g., `printenv`, `cat .env`, `aws configure list`
3. **Secrets in settings.json** — stored in git and readable by anyone with repo access
4. **Secrets in CLAUDE.md** — same problem
5. **Secrets in command history** — if Claude runs a command with a secret as an argument
6. **Prompt injection triggers exfiltration** — a malicious file manipulates Claude into sending credentials somewhere

## Preventing Claude from reading credential files

Use deny rules to block access to credential files at the permission-system level:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./.env.local)",
      "Read(./.env.production)",
      "Read(./secrets/**)",
      "Read(./config/credentials*)",
      "Read(~/config.json)",
      "Read(~/.aws/**)",
      "Read(~/.ssh/**)",
      "Read(~/.gnupg/**)",
      "Read(~/.netrc)",
      "Read(~/.npmrc)",
      "Read(~/.pypirc)",
      "Read(~/.docker/config.json)",
      "Read(~/.kube/**)",
      "Read(~/.config/gh/**)"
    ]
  }
}
```

Place the most sensitive rules (home directory paths) in `~/.claude/settings.json` so they apply across all projects. Place project-specific rules (`.env`, `secrets/`) in `.claude/settings.json`.

## Passing secrets to Claude Code sessions

### The right way: shell environment variables

Set credentials in your shell before launching Claude Code. They're available to commands Claude runs without being stored anywhere:

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export DATABASE_URL="postgres://..."
claude
```

Claude Code inherits your shell's environment. Commands it runs (like `aws s3 ls`) will use these variables automatically.

### Using a secrets manager

For team environments, use a secrets manager to inject credentials at runtime:

**AWS Secrets Manager + direnv:**
```bash
# .envrc (not committed — add to .gitignore)
export DATABASE_URL=$(aws secretsmanager get-secret-value \
  --secret-id prod/db-url --query SecretString --output text)
```

**HashiCorp Vault:**
```bash
export API_KEY=$(vault kv get -field=api_key secret/myapp)
claude
```

**1Password CLI:**
```bash
eval $(op signin)
export GITHUB_TOKEN=$(op item get "GitHub Token" --fields credential)
claude
```

### For CI/CD pipelines

In GitHub Actions, use encrypted secrets:

```yaml
- name: Run Claude Code
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
  run: claude -p "run the tests and fix any failures"
```

Never hardcode credentials in workflow files or pass them as command arguments.

## Preventing secrets from appearing in command output

Some commands print secrets when run. Add deny rules or hooks to block them:

**Deny rules:**
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

**PreToolUse hook to block secrets in command output:**

```bash
#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block commands that commonly expose secrets
RISKY_PATTERNS=(
  "printenv"
  "cat .*\\.env"
  "cat .*credentials"
  "echo.*PASSWORD"
  "echo.*SECRET"
  "echo.*API_KEY"
)

for PATTERN in "${RISKY_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$PATTERN"; then
    echo "Command may expose secrets: $COMMAND" >&2
    exit 2
  fi
done
exit 0
```

## Secrets in git: detection and prevention

### Pre-commit scanning with gitleaks

Install [gitleaks](https://github.com/gitleaks/gitleaks) to scan commits for secrets before they're pushed:

```bash
# Install
brew install gitleaks  # macOS
# or: go install github.com/gitleaks/gitleaks/v8@latest

# Scan the current repo
gitleaks detect --source .

# Use as a pre-commit hook
gitleaks protect --staged
```

Add to your git hooks (`.git/hooks/pre-commit`):
```bash
#!/bin/bash
gitleaks protect --staged --redact
```

### .gitignore for secret files

```gitignore
# Credentials and secrets
.env
.env.*
.env.local
.env.production
*.pem
*.key
*.p12
*.pfx
secrets/
config/credentials*
.claude/settings.local.json
```

### If a secret was already committed

If credentials were committed to git, rotation is mandatory — the secret is compromised regardless of whether you've "deleted" the file from git, since the object remains in git history.

1. **Rotate the credential immediately** — treat it as compromised
2. Remove from history: `git filter-branch` or `git filter-repo`
3. Force-push all branches
4. Notify GitHub to scan for the secret: GitHub secret scanning alerts

## The ANTHROPIC_API_KEY

Claude Code uses your `ANTHROPIC_API_KEY` for every API call. Treat it as a highly sensitive credential:

- Store it in your system keychain or a secrets manager, not in `.bashrc`/`.zshrc`
- Rotate it regularly (quarterly minimum)
- Use separate API keys for different environments (dev, CI, production)
- Monitor usage for anomalies in the Anthropic console
- If compromised: revoke immediately in the Anthropic console, rotate, investigate what was accessed

```bash
# Recommended: set per-session from a secrets manager
export ANTHROPIC_API_KEY=$(op item get "Anthropic API Key" --fields credential)
claude
```

## What Claude Code sends to Anthropic

When Claude reads a file containing a secret (even if accidentally), the secret content is sent to the Anthropic API as part of the context. This is why deny rules for credential files are the most important setting in any config.

If Zero Data Retention (ZDR) is configured for your organization, API inputs are not stored server-side after the request completes. Without ZDR, standard retention policies apply.

See [docs/07-network-api-security.md](07-network-api-security.md) for details on what leaves your machine.

## See also

- [docs/02-permissions.md](02-permissions.md) — Deny rules for credential files
- [docs/03-settings.md](03-settings.md) — Scope management for deny rules
- [docs/07-network-api-security.md](07-network-api-security.md) — What data reaches Anthropic
- [docs/09-common-mistakes.md](09-common-mistakes.md) — Storing secrets in settings.json
