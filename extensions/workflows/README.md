# Workflow Extensions

Standalone AI-assisted workflows that sit **outside** the main AIDLC development
loop. Each workflow is self-contained — you can run it independently without
starting or committing to a full AIDLC development session.

## How this differs from `integrations/` and `skills/`

| Directory | Purpose |
|---|---|
| `integrations/` | Hooks that fire during an AIDLC workflow to sync artifacts to external tools (Jira, Confluence) |
| `skills/` | Team-specific skills loaded by subagents during code generation |
| `workflows/` | Standalone processes you invoke on demand, independent of the AIDLC loop |

## Available workflows

| Workflow | Invoke with | What it does |
|---|---|---|
| `estimation/` | `"Using the agent-estimation skill, estimate..."` | Produces a round-based effort estimate from a plain description or AIDLC units-of-work artifacts |

## How workflows are installed

`setup.sh` copies each workflow's `SKILL.md` into the IDE's skills directory
alongside the upstream Superpowers skills. They are available on demand — not
auto-loaded into context.

For Kiro: skills use `inclusion: manual`. Reference the skill explicitly in
your prompt or load it via the `#` context key.

## Adding a new workflow

1. Create a subdirectory: `extensions/workflows/<workflow-name>/`
2. Add a `SKILL.md` following the Agent Skills format (front-matter + markdown)
3. Add a `how-to-use.md` explaining invocation, inputs, and outputs
4. Re-run `./setup.sh` to install it into your IDE

Workflows that would be useful to all teams using this setup should be
contributed back upstream. Workflows specific to your org belong here.
