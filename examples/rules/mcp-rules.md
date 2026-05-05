# MCP Permission Rules Reference

How to write permission rules that scope Claude Code's access to specific MCP server tools.

See [docs/05-mcp-security.md](../../docs/05-mcp-security.md) for MCP security background.

---

## Rule syntax

```
mcp__<server-name>                       # any tool from this server
mcp__<server-name>__<tool_name>          # specific tool only
```

Server names come from the keys in your `mcpServers` config. Tool names come from what the server exposes.

---

## Pattern 1: Allow specific read-only tools, deny everything else

```json
{
  "permissions": {
    "allow": [
      "mcp__github__list_issues",
      "mcp__github__get_issue",
      "mcp__github__list_pull_requests",
      "mcp__github__get_file_contents"
    ],
    "deny": [
      "mcp__github__create_issue",
      "mcp__github__update_issue",
      "mcp__github__create_pull_request",
      "mcp__github__delete_file",
      "mcp__github__push_files",
      "mcp__github"    // catch-all: deny any tool not explicitly allowed above
    ]
  }
}
```

The catch-all deny `mcp__github` at the end blocks any new tool the server adds that isn't in your allow list. **Always include a catch-all deny for each MCP server you partially allow.**

---

## Pattern 2: Allow an entire server (use with caution)

```json
{
  "permissions": {
    "allow": [
      "mcp__internal-db"   // allows ALL tools from this server
    ]
  }
}
```

Only use this for fully trusted, internally-developed servers where you have reviewed every tool.

---

## Pattern 3: Deny an entire server

```json
{
  "permissions": {
    "deny": [
      "mcp__untrusted-server"
    ]
  }
}
```

If a server is configured in `mcpServers` but you want Claude to never use it in the current project, add a blanket deny. This is useful when you have different servers configured globally and want to restrict a project.

---

## Pattern 4: Scoping a Jira server to read-only

```json
{
  "permissions": {
    "allow": [
      "mcp__jira__get_issue",
      "mcp__jira__search_issues",
      "mcp__jira__list_projects"
    ],
    "deny": [
      "mcp__jira__create_issue",
      "mcp__jira__update_issue",
      "mcp__jira__transition_issue",
      "mcp__jira__add_comment",
      "mcp__jira"    // catch-all
    ]
  }
}
```

---

## Discovering tool names

To find the tool names a server exposes, run `/mcp` in a Claude Code session. It lists all active servers and their available tools.

---

## Key principle

Treat each MCP server as you would a third-party API. Grant only the minimum access needed for the task. If you're unsure which tools are needed, start with everything denied (`"deny": ["mcp__server-name"]`) and expand only when Claude asks.
