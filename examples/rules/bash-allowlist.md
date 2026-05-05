# Bash Allowlist Reference

Safe Bash permission rules organized by use-case. Copy individual entries into your `settings.json` under `permissions.allow`.

See [docs/02-permissions.md](../../docs/02-permissions.md) for full rule syntax.

---

## File inspection (read-only)

```json
"Bash(ls *)",
"Bash(cat *)",
"Bash(head *)",
"Bash(tail *)",
"Bash(find *)",
"Bash(grep *)",
"Bash(wc *)",
"Bash(stat *)",
"Bash(du *)",
"Bash(diff *)",
"Bash(file *)"
```

**Risk:** Low. These commands read but do not modify. Note that `find` with `-exec` can run arbitrary commands — be aware of the patterns Claude might construct.

---

## Git read-only

```json
"Bash(git status)",
"Bash(git diff *)",
"Bash(git log *)",
"Bash(git show *)",
"Bash(git branch *)",
"Bash(git remote *)",
"Bash(git stash list)"
```

**Risk:** Low. None of these modify the repo.

**Do NOT include without review:**
- `Bash(git commit *)` — creates commits
- `Bash(git push *)` — pushes to remote
- `Bash(git reset *)` — rewrites history
- `Bash(git clean *)` — deletes untracked files

---

## Node.js / npm

```json
"Bash(npm run test *)",
"Bash(npm run lint *)",
"Bash(npm run build *)",
"Bash(npm run typecheck *)",
"Bash(npm list *)",
"Bash(npm outdated)"
```

**Risk:** Medium. Script names like `test` and `lint` are safe if you control the project's `package.json`. Avoid `Bash(npm *)` — it also allows `npm install`, `npm publish`, and `npm run arbitrary-script`.

---

## Python

```json
"Bash(python -m pytest *)",
"Bash(python -m pytest --tb=short *)",
"Bash(python -m ruff *)",
"Bash(python -m mypy *)",
"Bash(python -m black --check *)",
"Bash(python -c *)"
```

**Risk:** Low to medium. `python -c *` allows arbitrary Python — allow it only if you're comfortable with that. `python -m pytest` is safe for testing.

---

## Make / task runners

```json
"Bash(make test *)",
"Bash(make lint *)",
"Bash(make build *)",
"Bash(make clean)"
```

**Risk:** Medium. `make` targets execute whatever the Makefile defines. Only allow targets you have reviewed.

---

## Process inspection

```json
"Bash(ps *)",
"Bash(top -b -n 1)",
"Bash(lsof *)",
"Bash(netstat *)",
"Bash(ss *)"
```

**Risk:** Low. These read system state but do not modify it.

---

## What to avoid in allow rules

| Pattern | Risk |
|---------|------|
| `"Bash"` or `"Bash(*)"` | Allows every command — equivalent to no permission system |
| `"Bash(rm *)"` | Allows any deletion |
| `"Bash(curl *)"` | Allows arbitrary network requests |
| `"Bash(sudo *)"` | Allows privilege escalation |
| `"Bash(sh *)"` or `"Bash(bash *)"` | Allows arbitrary shell execution |
| `"Bash(chmod *)"` | Allows permission changes |
| `"Bash(chown *)"` | Allows ownership changes |
