# AI-DLC + Superpowers Workflow

A zero-maintenance AI development workflow that combines two upstream open-source
projects with a thin extension layer for integrations and org-specific rules.

## What this repo is

This repo contains **only what you need to maintain yourself**:

- `extensions/glue/` — handoff rule connecting AIDLC planning to Superpowers execution
- `extensions/integrations/` — optional Jira and Confluence sync
- `extensions/org-standards/` — your team's custom rules (add your own here)
- `setup.sh` — installs both upstream layers and wires extensions into place

Everything else is upstream:

| Layer | Source | What it does |
|---|---|---|
| Planning | [awslabs/aidlc-workflows](https://github.com/awslabs/aidlc-workflows) | Inception → Construction → Operations phases |
| Execution | [obra/superpowers](https://github.com/obra/superpowers) | TDD, debugging, subagent dispatch, code review |

## Quick start

```bash
# Install for your current IDE (auto-detected)
./setup.sh

# With Jira integration
./setup.sh --with-jira

# With Confluence integration
./setup.sh --with-confluence

# Both
./setup.sh --with-jira --with-confluence

# Force a specific IDE
./setup.sh --ide cursor   # kiro | amazonq | cursor | cline | claudecode | copilot | codex
```

Then start any workflow:

```
Using AI-DLC, build a user authentication system
```

The agent handles the rest — requirements, design, planning, subagent execution,
code review, and optionally Jira/Confluence sync.

## How it works

### Planning layer (AIDLC)

AIDLC guides the agent through three phases:

- **Inception** — requirements, user stories, application design, units of work
- **Construction** — functional design, NFR design, infrastructure design, code generation
- **Operations** — deployment and monitoring (placeholder, future)

At each stage the agent asks structured questions, generates artifacts in
`aidlc-docs/`, and waits for your approval before proceeding.

### Execution layer (Superpowers)

When AIDLC reaches Code Generation, it hands off to Superpowers. The main agent
dispatches a fresh subagent per task — each subagent gets the full task text,
implements it with TDD, and goes through two review stages (spec compliance, then
code quality) before the main agent marks the task done.

The main agent never writes implementation code directly. It coordinates,
reviews, and keeps context across the full feature lifecycle.

### Extensions

Extensions are AIDLC rule files that add behaviour at specific workflow stages.
They live in `extensions/` and are copied into the AIDLC rule-details directory
by `setup.sh`.

- **Glue** (`extensions/glue/`) — always active, enforces the AIDLC→Superpowers handoff
- **Integrations** (`extensions/integrations/`) — opt-in at workflow start
- **Org standards** (`extensions/org-standards/`) — always active, add your own rules here

## Jira / Confluence integration

See [docs/WORKING-WITH-INTEGRATIONS.md](docs/WORKING-WITH-INTEGRATIONS.md) for
full setup instructions.

**Short version:**

1. Install the MCP server: `uvx mcp-atlassian` (or use the official Atlassian remote MCP)
2. Set env vars: `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN`
3. Run `./setup.sh --with-jira --with-confluence`
4. At workflow start, answer the opt-in questions

The agent will then create Epics, Stories, and sub-tasks in Jira and publish
design artifacts to Confluence as the workflow progresses.

## Updating upstreams

```bash
./setup.sh --update
```

This re-downloads the latest AIDLC release, runs `git pull` on the Superpowers clone, and re-installs extensions. Your extensions are not touched.

To update Superpowers manually at any time:
```bash
cd ~/.codex/superpowers && git pull
```

Skills update instantly through the symlink — no restart needed.

## Adding org-specific rules

Add `.md` files to `extensions/org-standards/`. Each rule follows this structure:

```markdown
## Rule ORG-01: Your Rule Title
### Rule
What is required.
### Verification
How the agent checks compliance before proceeding.
```

Rules in `org-standards/` are always enforced (no opt-in). To make a rule
opt-in, add a matching `<name>.opt-in.md` file alongside it — see the Jira
and Confluence examples for the format.

## Repo structure

```
.
├── setup.sh                          ← run this first
├── README.md
│
├── extensions/                       ← the only thing you maintain
│   ├── glue/
│   │   └── superpowers-handoff.md    ← AIDLC→Superpowers handoff rules
│   ├── integrations/
│   │   ├── jira/
│   │   │   ├── jira-sync.md          ← Jira sync rules (active when opted in)
│   │   │   ├── jira-sync.opt-in.md   ← opt-in prompt shown at workflow start
│   │   │   └── mcp-config.json       ← MCP server config snippet
│   │   └── confluence/
│   │       ├── confluence-sync.md
│   │       ├── confluence-sync.opt-in.md
│   │       └── mcp-config.json
│   └── org-standards/
│       └── README.md                 ← add your team's rules here
│
└── docs/
    └── WORKING-WITH-INTEGRATIONS.md
```

After running `setup.sh`, the IDE-specific directories are created (e.g.
`.kiro/`, `CLAUDE.md`, `.cursor/rules/`) but are not committed — they are
generated artifacts. Add them to `.gitignore` if you prefer, or commit them
if you want the workflow available without running setup.

## Supported IDEs

| IDE | Detection | AIDLC location |
|---|---|---|
| Kiro | `.kiro/` exists | `.kiro/steering/aws-aidlc-rules/` |
| Amazon Q | `.amazonq/` exists | `.amazonq/rules/aws-aidlc-rules/` |
| Cursor | `.cursor/` exists | `.cursor/rules/ai-dlc-workflow.mdc` |
| Cline | `.clinerules/` exists | `.clinerules/core-workflow.md` |
| Claude Code | `.claude/` or `CLAUDE.md` | `CLAUDE.md` |
| GitHub Copilot | `.github/` exists | `.github/copilot-instructions.md` |
| Codex / other | fallback | `AGENTS.md` |

## License

Extensions in this repo: MIT.
AIDLC upstream: MIT-0 (awslabs/aidlc-workflows).
Superpowers upstream: MIT (obra/superpowers).
