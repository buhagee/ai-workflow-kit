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

### 1. Install the MCP server

The integrations use `sooperset/mcp-atlassian` (covers both Jira and Confluence).

```bash
# Requires uv/uvx — install from https://docs.astral.sh/uv/
uvx mcp-atlassian --help   # verify it works
```

Or use the official Atlassian remote MCP (no local install):
- URL: `https://mcp.atlassian.com/v1/sse`
- Requires an Atlassian API token

### 2. Set environment variables

```bash
# For community server (sooperset/mcp-atlassian)
export JIRA_URL="https://your-org.atlassian.net"
export JIRA_USERNAME="your-email@example.com"
export JIRA_API_TOKEN="your-api-token"
export CONFLUENCE_URL="https://your-org.atlassian.net/wiki"
export CONFLUENCE_USERNAME="your-email@example.com"
export CONFLUENCE_API_TOKEN="your-api-token"   # same token works for both
```

Get your API token at: https://id.atlassian.com/manage-profile/security/api-tokens

### 3. Configure your IDE's MCP settings

Run `setup.sh --with-jira` or `setup.sh --with-confluence` to merge the MCP
config snippet automatically. Or manually merge
`extensions/integrations/jira/mcp-config.json` into your IDE's MCP config file.

**IDE MCP config locations:**
- Kiro: `.kiro/settings/mcp.json`
- Claude Code: `.claude/settings/mcp.json`
- Cursor: `.cursor/mcp.json`
- Copilot: `.github/mcp.json`

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

**MCP server not found:** Run `uvx mcp-atlassian --help` to verify installation.
If uvx is not installed, see https://docs.astral.sh/uv/getting-started/installation/

**Authentication errors:** Verify your API token at
https://id.atlassian.com/manage-profile/security/api-tokens. Tokens expire —
generate a new one if needed.

**Confluence page creation fails:** Check that your user has "Create" permission
in the target space. Space admins can grant this in Space Settings → Permissions.

**Jira transition fails:** The transition names in the rules (In Progress, In Review,
Done) must match your project's workflow. Edit `extensions/integrations/jira/jira-sync.md`
Rule JIRA-04 through JIRA-06 to use your project's actual status names.
