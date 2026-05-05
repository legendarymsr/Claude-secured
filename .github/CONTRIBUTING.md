# Contributing

## Filing issues

- **Broken links or outdated content**: Open an issue with the file path and what changed.
- **New security findings**: Describe the finding, link to official Claude Code documentation, and explain why it belongs in this guide.
- **Inaccurate examples**: Paste the problematic config/script and the corrected version.

## Proposing new example files

All new files in `examples/` must:
1. Include a comment header pointing to the explanatory doc in `docs/`
2. Be tested against an actual Claude Code installation
3. Contain no real credentials, API keys, or personal paths
4. Use only POSIX-compatible shell (`#!/usr/bin/env bash`)

## Review standard

Pull requests require at least one maintainer review. Accuracy takes priority over completeness — a shorter, correct doc is better than a longer, speculative one.

## What we do not accept

- Generated content that is not verified against official documentation
- Config examples that weaken security (e.g., unconditional `bypassPermissions: true`)
- Hook scripts that auto-approve without explicit user intent
