# Claude-secured

This repository is a documentation and example resource about using Claude Code securely. It contains no application code and has no build step.

## Safe Bash commands for this project

Read-only operations only:
- `find`, `ls`, `cat`, `grep`, `wc`, `stat`
- `git status`, `git log`, `git diff`

## Important constraints

- Do NOT execute any scripts in `examples/hooks/`. They are demonstration files, not infrastructure for this repo.
- Do NOT treat `examples/settings/` files as the active Claude Code configuration for this project. They are templates for users to copy into their own projects.
- Do NOT create additional documentation files unless explicitly asked. All planned docs are tracked in the README navigation table.
