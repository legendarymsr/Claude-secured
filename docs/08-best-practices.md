# 08 — Best Practices

Security checklists for three environments. Start with the individual checklist, add team practices when collaborating, and the enterprise section for CI/production.

---

## Individual developers

- [ ] Start with `plan` mode in any unfamiliar repo (`Shift+Tab` to switch)
- [ ] Add deny rules for credential files in `~/.claude/settings.json` — protects you in every project
- [ ] Read what Claude proposes before clicking approve — especially "Yes, don't ask again"
- [ ] Use `/clear` between unrelated tasks to reset context
- [ ] Run Claude Code from the project root, not your home directory

<details>
<summary>📖 Why each of these matters</summary>

### Start with plan mode
`plan` mode is read-only. Claude can analyze, explain, and propose — but nothing changes. This is the right way to explore an unfamiliar codebase before giving Claude edit access.

### Deny rules in ~/.claude/settings.json
The user-level settings apply to every project you open. Credential deny rules here act as a safety net for projects that don't have their own settings file:

```json
{
  "permissions": {
    "deny": [
      "Read(~/.aws/**)",
      "Read(~/.ssh/**)",
      "Read(~/.gnupg/**)",
      "Read(~/.kube/**)",
      "Read(~/.config/gh/**)",
      "Read(~/.docker/config.json)"
    ]
  }
}
```

### Read before approving
The approval dialog shows the exact command or file change. Reading it takes five seconds. "Yes, don't ask again" creates a permanent allow rule — use it only for genuinely repetitive safe operations like `npm run test`.

### Use /clear between tasks
Each task starts with a clean context. Accumulated context from previous tasks increases confusion risk and expands the surface area for prompt injection. Run `/clear` when switching tasks.

### Run from the project root
`cd my-project && claude` scopes Claude Code's default access to that directory. Running from `~/` or `/` gives Claude access to your entire home directory or filesystem by default.

</details>

---

## Teams

- [ ] Commit `.claude/settings.json` with test/build allow rules and credential deny rules
- [ ] Keep `.claude/settings.local.json` in `.gitignore`
- [ ] Vet any MCP server before adding it to the shared config
- [ ] Add a `PreToolUse` audit hook that logs every tool call

<details>
<summary>📖 Team settings.json starter</summary>

```json
{
  "defaultMode": "default",
  "permissions": {
    "allow": [
      "Bash(npm run test *)",
      "Bash(npm run lint *)",
      "Bash(npm run build *)",
      "Bash(npm run typecheck *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)"
    ],
    "ask": [
      "Bash(git push *)",
      "Bash(git commit *)",
      "Bash(npm install *)"
    ],
    "deny": [
      "Bash(git push --force *)",
      "Bash(npm publish *)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(~/.aws/**)",
      "Read(~/.ssh/**)"
    ]
  }
}
```

See [examples/settings/settings.team.jsonc](../examples/settings/settings.team.jsonc) for an annotated version.

</details>

<details>
<summary>📖 MCP vetting before adding to team config</summary>

Any MCP server in `.claude/settings.json` runs for every team member. Before committing a new MCP server:

1. Review the source code — especially the tool implementations and any outbound network calls
2. Check whether it reads files outside its stated purpose
3. Pin it to a specific version (not `latest`)
4. Scope the tools Claude can access with allow/deny rules

See [docs/05-mcp-security.md](05-mcp-security.md) for the full vetting checklist.

</details>

---

## Enterprise & CI/CD

- [ ] Deploy managed settings that lock `bypassPermissions` and restrict MCP servers
- [ ] Use `auto` mode (not `bypassPermissions`) for CI pipelines
- [ ] Run CI Claude Code sessions in isolated containers with no production credentials
- [ ] Use short-lived, scoped API keys for the `ANTHROPIC_API_KEY`
- [ ] Read `CLAUDE.md` before running Claude Code in any repo you didn't create

<details>
<summary>📖 Managed settings to deploy org-wide</summary>

```json
{
  "permissions": {
    "disableBypassPermissionsMode": true,
    "deny": [
      "Read(~/.aws/**)", "Read(~/.ssh/**)",
      "Bash(curl *)", "Bash(wget *)",
      "Bash(rm -rf *)"
    ]
  },
  "allowManagedMcpServersOnly": true,
  "allowManagedHooksOnly": true,
  "env": { "DISABLE_TELEMETRY": "1" }
}
```

See [examples/settings/settings.enterprise.jsonc](../examples/settings/settings.enterprise.jsonc) for a complete template.

</details>

<details>
<summary>📖 Container isolation for CI</summary>

For CI pipelines processing external PRs or untrusted inputs:

```yaml
- name: Run Claude Code (isolated)
  run: |
    docker run --rm \
      --network none \
      --read-only \
      --tmpfs /tmp:size=100m \
      -v ${{ github.workspace }}:/workspace:rw \
      -e ANTHROPIC_API_KEY=${{ secrets.ANTHROPIC_API_KEY }} \
      -w /workspace \
      node:20 \
      npx @anthropic-ai/claude-code --permission-mode auto \
        -p "Fix type errors and run tests"
```

Checklist:
- [ ] No production credentials mounted (`AWS_*`, `DATABASE_URL`, etc.)
- [ ] Network disabled if Claude only needs to work on local files (`--network none`)
- [ ] Filesystem scoped to the repo only
- [ ] Container runs as non-root
- [ ] Image pinned to a specific digest

See [docs/13-ci-cd-guide.md](13-ci-cd-guide.md) for GitHub Actions and GitLab CI examples.

</details>

---

## See also

- [docs/09-common-mistakes.md](09-common-mistakes.md) — What not to do
- [docs/13-ci-cd-guide.md](13-ci-cd-guide.md) — CI/CD security in depth
- [examples/settings/](../examples/settings/) — Config templates
