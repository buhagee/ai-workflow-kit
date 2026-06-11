# AI-DLC + Superpowers Workflow

A zero-maintenance AI development workflow that combines two upstream open-source
projects with a thin extension layer for integrations and org-specific rules.

## What this repo is

This repo contains **only what you need to maintain yourself**:

- `extensions/glue/` — handoff rule + **entry-point preamble** prepended to every IDE's workflow file
- `extensions/skills/` — custom skills installed alongside upstream Superpowers skills
- `extensions/integrations/` — optional Jira and Confluence sync
- `extensions/org-standards/` — your team's custom rules (add your own here)
- `setup.sh` — assembles both upstream layers + your extensions into the IDE-specific entry point

Everything else is upstream:

| Layer | Source | What it does |
|---|---|---|
| Planning | [awslabs/aidlc-workflows](https://github.com/awslabs/aidlc-workflows) | Inception → Construction → Operations phases |
| Execution | [obra/superpowers](https://github.com/obra/superpowers) | TDD, debugging, subagent dispatch, code review |

### How entry points are assembled

`setup.sh` builds the IDE-specific entry point by concatenating:

```
extensions/glue/entry-point-preamble.md   ← always first (mandatory gates)
+
upstream core-workflow.md                 ← AIDLC planning rules
=
.github/copilot-instructions.md           ← (or CLAUDE.md, AGENTS.md, etc.)
```

Skills are assembled the same way:

```
upstream superpowers skills               ← obra/superpowers
+
extensions/skills/<your-skills>/          ← your custom skills
=
.github/skills/                           ← (or .kiro/steering/superpowers-skills/, etc.)
```

The generated files are **not committed** — re-created by `./setup.sh`.
To customise the entry point for all IDEs, edit `extensions/glue/entry-point-preamble.md`.
To add a custom skill for all IDEs, add it under `extensions/skills/`.

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

> **Windows users:** `setup.sh` requires bash. Use Git Bash, WSL, or run inside a
> Docker container (`docker run --rm -v $(pwd):/repo -w /repo ubuntu:22.04 bash setup.sh`).
> Native PowerShell is not supported.

```
Using AI-DLC, build a user authentication system
```

The agent handles the rest — requirements, design, planning, subagent execution,
code review, and optionally Jira/Confluence sync.

**New to this repo?** See [docs/ONBOARDING.md](docs/ONBOARDING.md) for a
step-by-step guide covering prerequisites, IDE setup, credential configuration,
and day-to-day usage.

## Day-to-day usage

### Starting an AIDLC development session

Prefix your request with `Using AI-DLC` to trigger the full planning workflow:

```
Using AI-DLC, build a REST API for user authentication with JWT tokens
Using AI-DLC, add dark mode support to the settings page
Using AI-DLC, refactor the payment service to use the new Stripe SDK
```

To resume a session that was interrupted:

```
Using AI-DLC, continue work on the authentication feature
```

The agent reads `aidlc-docs/aidlc-state.md` and picks up from the last checkpoint.

### Invoking skills on demand

Skills are invoked by describing what you want in plain language — the agent
recognises the trigger phrases and loads the skill automatically.

#### Caveman mode — ultra-compressed responses ([upstream](https://github.com/JuliusBrussee/caveman))

Cuts response verbosity ~75% while keeping full technical accuracy. Useful when
you want fast, dense answers without filler.

```
caveman mode
/caveman
use caveman
```

Switch intensity:

```
/caveman lite    # professional but tight — keeps full sentences
/caveman full    # classic caveman (default)
/caveman ultra   # maximum compression — arrows for causality, abbreviations
```

Turn off: `stop caveman` or `normal mode`

#### Estimation workflow

Produces a billable-hours estimate from a plain description or from AIDLC
units-of-work artifacts generated during Inception.

```
Using the agent-estimation skill, estimate the effort for:
[your project description]
```

See [extensions/workflows/estimation/how-to-use.md](extensions/workflows/estimation/how-to-use.md)
for full options including post-Inception mode (higher accuracy).

#### Other Superpowers skills

These activate automatically when the context matches, or can be invoked explicitly:

| Skill | When it activates |
|---|---|
| `test-driven-development` | Any feature or bugfix implementation |
| `systematic-debugging` | Any bug, test failure, or unexpected behaviour |
| `subagent-driven-development` | Executing implementation plans with parallel tasks |
| `verification-before-completion` | Before claiming work is complete or tests pass |
| `requesting-code-review` | After completing a feature or before merging |
| `receiving-code-review` | When acting on code review feedback |
| `finishing-a-development-branch` | When implementation is complete and ready to integrate |
| `dispatching-parallel-agents` | When 2+ independent tasks can run in parallel |

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

1. Create an Atlassian API token for your Atlassian Cloud account
2. Copy `.env.example` to `.env` and fill in `ATLASSIAN_API_TOKEN`
3. Run `./setup.sh --with-jira --with-confluence`
4. At workflow start, answer the opt-in questions

The agent will then use Atlassian's official remote MCP to create Epics,
Stories, and sub-tasks in Jira and publish design artifacts to Confluence as
the workflow progresses.

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
├── .env.example                      ← copy to .env, add your credentials
├── README.md
│
├── extensions/                       ← the only thing you maintain
│   ├── glue/
│   │   ├── superpowers-handoff.md    ← AIDLC→Superpowers handoff rules
│   │   └── entry-point-preamble.md  ← prepended to every IDE entry point
│   ├── skills/
│   │   └── <your-skill>/            ← add team-specific custom skills here
│   │       └── SKILL.md
│   ├── workflows/
│   │   └── estimation/              ← standalone estimation workflow
│   │       ├── SKILL.md             ← agent-estimation skill (AIDLC-aware)
│   │       └── how-to-use.md        ← invocation guide
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
    ├── ONBOARDING.md                 ← start here if you're new to this repo
    └── WORKING-WITH-INTEGRATIONS.md
```

After running `setup.sh`, the IDE-specific directories are created (e.g.
`.kiro/`, `CLAUDE.md`, `.cursor/rules/`, `.github/skills/`) but are not
committed — they are generated artifacts pulled from upstream. Add them to
`.gitignore` if you prefer, or commit them if you want the workflow available
without running setup.

Each developer runs `./setup.sh --ide <their-ide>` once to install the workflow
for their tool. Run `./setup.sh --update` to pull the latest upstream rules and
skills at any time.

## Supported IDEs

| IDE | Detection | AIDLC location | Skills location |
|---|---|---|---|
| Kiro | `.kiro/` exists | `.kiro/steering/aws-aidlc-rules/` | `.kiro/steering/superpowers-skills/` |
| Amazon Q | `.amazonq/` exists | `.amazonq/rules/aws-aidlc-rules/` | `.amazonq/rules/superpowers-skills/` |
| Cursor | `.cursor/` exists | `.cursor/rules/ai-dlc-workflow.mdc` | `~/.agents/skills/superpowers/` |
| Cline | `.clinerules/` exists | `.clinerules/core-workflow.md` | `~/.agents/skills/superpowers/` |
| Claude Code | `.claude/` or `CLAUDE.md` | `CLAUDE.md` | `.claude/skills/` |
| GitHub Copilot | `.github/` exists | `.github/copilot-instructions.md` | `.github/skills/` |
| Codex / other | fallback | `AGENTS.md` | `~/.agents/skills/superpowers/` |

### GitHub Copilot / VS Code — Skills Discovery

VS Code Copilot auto-discovers skills from `.github/skills/<skill-name>/SKILL.md`.
`setup.sh --ide copilot` copies all 10 relevant Superpowers skills there automatically (4 are excluded as redundant with AIDLC — see below).

After running setup, open VS Code and type `/` in Copilot Chat — you should see
the relevant skills listed (systematic-debugging, subagent-driven-development,
test-driven-development, verification-before-completion, etc.).

**Skills excluded when AIDLC is the planning layer** (to avoid confusion):

| Skill | Why excluded |
|---|---|
| `brainstorming` | AIDLC Inception phase covers requirements + design |
| `writing-plans` | AIDLC Code Generation Part 1 is the plan stage |
| `executing-plans` | Fallback for no-subagent platforms; AIDLC uses `subagent-driven-development` |
| `writing-skills` | Meta-skill for Superpowers contributors, not end users |

To update skills after a Superpowers upstream update:
```bash
./setup.sh --ide copilot --update
```

## License

Extensions in this repo: MIT.
AIDLC upstream: MIT-0 (awslabs/aidlc-workflows).
Superpowers upstream: MIT (obra/superpowers).
