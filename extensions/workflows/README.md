# On-demand Skills

On-demand workflows are Agent Skills. This directory is an organizational
category for skills that can run independently of the main AI-DLC lifecycle; it
is not a separate v2 runtime or extension mechanism.

## Relationship to `extensions/skills/`

| Directory | Purpose |
|---|---|
| `extensions/skills/` | General team skills |
| `extensions/workflows/` | On-demand skills with a complete workflow |

## Available workflows

| Workflow | Invoke with | What it does |
|---|---|---|
| `estimation/` | `"Using the agent-estimation skill, estimate..."` | Produces a round-based effort estimate from a plain description or AIDLC units-of-work artifacts |

## How workflows are installed

`setup.sh` copies each workflow's `SKILL.md` into the selected harness's native
skills directory. They use the same frontmatter and discovery rules as every
other skill.

Reference the skill explicitly in your prompt or load it via the harness's
skill picker.

## Adding a new workflow

1. Create a subdirectory: `extensions/workflows/<workflow-name>/`
2. Add a `SKILL.md` following the Agent Skills format (front-matter + markdown)
3. Add a `how-to-use.md` explaining invocation, inputs, and outputs
4. Re-run `./setup.sh` to install it into your IDE

Skills specific to this organization belong here. If a workflow is useful to
every AI-DLC user, contribute it upstream instead.
