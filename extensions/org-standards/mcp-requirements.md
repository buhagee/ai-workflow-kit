# MCP Requirements

> **Status**: Always enforced (no opt-in required)
>
> This extension ensures that required MCP tools are identified before planning
> begins, and that subagents receive explicit guidance on which tools to use.

---

## Rule MCP-01: Pre-flight Check Before Planning External Integrations

Before creating any design document or code generation plan that involves an
external service (payment processors, email providers, cloud APIs, databases,
version control, etc.), check which MCP servers are configured and available.

**How to check:**
1. Look for MCP config in this order:
  - IDE user-level MCP settings (for VS Code/Copilot this is typically `%APPDATA%/Code/User/mcp.json` on Windows, `~/Library/Application Support/Code/User/mcp.json` on macOS, `~/.config/Code/User/mcp.json` on Linux)
  - `.kiro/settings/mcp.json`
  - `.github/mcp.json`
  - `.cursor/mcp.json`
  - `.claude/settings/mcp.json`
  - `mcp.json` (workspace root)
2. List the configured `mcpServers` keys
3. For each external service the feature requires, determine whether a matching
   MCP server is configured

**If a required MCP is not configured:**
- Document the gap in the Requirements Analysis artifact
- Include a fallback approach in the NFR Requirements (SDK, direct HTTP, mock)
- Do NOT plan the feature assuming MCP availability — plan for the fallback
- Inform the user: "The [service] MCP server is not configured. I'll plan using
  the [SDK/HTTP] approach. To use MCP instead, add the server in your IDE MCP settings and re-run."

---

## Rule MCP-02: MCP Tool Names in Subagent Task Text

When an MCP server IS configured for a required service, include the MCP server
name and relevant tool names in the subagent's SKILLS TO USE section.

Example:
```
### SKILLS TO USE
- Use the test-driven-development skill.
- Use the `stripe` MCP server for payment operations:
  - `stripe_create_payment_intent` for creating charges
  - `stripe_create_customer` for customer management
  - `stripe_list_payment_methods` for retrieving saved cards
- Use the `github` MCP server for repository operations:
  - `create_pull_request` after implementation is complete
```

---

## Rule MCP-03: MCP Requirements Section in NFR Documents

Every NFR Requirements document for a unit that uses external services MUST
include an "MCP Requirements" section:

```markdown
## MCP Requirements

| External Service | MCP Server | Status | Fallback |
|---|---|---|---|
| Stripe payments | `stripe` | ✅ Configured | Stripe SDK (npm stripe) |
| GitHub PRs | `github` | ❌ Not configured | gh CLI or REST API |
| PostgreSQL | `postgres` | ✅ Configured | pg npm package |
```

---

## Rule MCP-04: Recommended MCP Servers for Development Workflows

The following MCP servers are recommended for common development tasks. Teams
should configure them in their IDE MCP config file.

| Use case | MCP server | Install |
|---|---|---|
| GitHub PRs, issues, branches | `github` (official) | `uvx mcp-server-github` |
| PostgreSQL queries | `postgres` | `uvx mcp-server-postgres` |
| SQLite queries | `sqlite` | `uvx mcp-server-sqlite` |
| Browser / E2E testing | `playwright` | `uvx mcp-server-playwright` |
| File system operations | `filesystem` | `uvx mcp-server-filesystem` |
| Web search | `brave-search` | `uvx mcp-server-brave-search` |

These are recommendations, not requirements. Configure only what your project needs.
