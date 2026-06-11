# Working with Integrations

This document covers how the optional Jira and Confluence integrations work
within the AI-DLC workflow.

## Overview

Integrations are implemented as AIDLC extensions — opt-in rule files that the
agent loads during Requirements Analysis. They add sync behaviour at specific
workflow stages without changing the core planning or execution flow.

```
AIDLC Workflow Stage          → Integration Action
─────────────────────────────────────────────────────
Requirements Analysis done    → Jira: create Epic
                              → Confluence: publish requirements page
User Stories done             → Jira: create Stories
                              → Confluence: publish stories page
Units Generation done         → Jira: create sub-tasks
Application Design done       → Confluence: publish design page
Per-unit design done          → Confluence: publish unit design page
Code Generation starts        → Jira: transition to In Progress
Code Generation done          → Jira: transition to In Review
Build and Test done           → Jira: transition to Done
                              → Confluence: publish test summary
```

## Prerequisites

### 1. Use Atlassian's official remote MCP

The integrations use Atlassian's official remote MCP for both Jira and
Confluence.

- URL: `https://mcp.atlassian.com/v1/sse`
- Requires an Atlassian API token
- No local `uv` or `uvx` install required

### 2. Make credentials available to your IDE

Copy `.env.example` to `.env` and fill in your values if that helps you manage
secrets locally, but the important part is making `ATLASSIAN_API_TOKEN`
available to your IDE process. The Atlassian MCP server does not read this
repository's `.env` file by itself.

Use whichever approach your IDE supports: VS Code user MCP input/secret store,
shell profile export, direnv, 1Password/Vault injection, or similar.

```bash
export ATLASSIAN_API_TOKEN="your-api-token"
```

Get your API token at: https://id.atlassian.com/manage-profile/security/api-tokens

**Never commit `.env` to version control** — it is already in `.gitignore`.
`.env.example` (no real values) is committed and safe to share.

### 3. Install Atlassian MCP in your IDE

This repository no longer generates or stores Atlassian MCP config in project
files. Install Atlassian's official MCP server directly in your IDE's user-level
MCP settings.

For VS Code / Copilot, the user-level config is typically:
- Windows: `%APPDATA%/Code/User/mcp.json`
- macOS: `~/Library/Application Support/Code/User/mcp.json`
- Linux: `~/.config/Code/User/mcp.json`

Use Atlassian's official remote MCP endpoint:
- URL: `https://mcp.atlassian.com/v1/sse`
- Header: `Authorization: Bearer ${ATLASSIAN_API_TOKEN}`

## Using the integrations

Once configured, the agent will ask at workflow start whether to enable Jira
and/or Confluence sync. Answer the opt-in questions in the generated question
files.

All created references (Epic keys, Story keys, page URLs) are stored in
`aidlc-docs/integrations/` so they persist across sessions.

## Resuming a workflow with existing Jira tickets

If you already have a Jira Epic or ticket, provide it at workflow start:

```
Using AI-DLC, continue work on PROJ-123
```

The agent will fetch the ticket context and use it during Requirements Analysis.

## Troubleshooting

**MCP not connecting:** Confirm your IDE user-level MCP config includes the
Atlassian server and that `ATLASSIAN_API_TOKEN` is available to the IDE process.

**Authentication errors:** Verify your API token at
https://id.atlassian.com/manage-profile/security/api-tokens. Tokens expire —
generate a new one if needed.

**Confluence page creation fails:** Check that your user has "Create" permission
in the target space. Space admins can grant this in Space Settings → Permissions.

**Jira transition fails:** The transition names in the rules (In Progress, In Review,
Done) must match your project's workflow. Edit `extensions/integrations/jira/jira-sync.md`
Rule JIRA-04 through JIRA-06 to use your project's actual status names.
