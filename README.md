# AI-DLC Workflow Kit

A team distribution layer for [AI-DLC Workflows v2](https://github.com/awslabs/aidlc-workflows/tree/v2).
The kit keeps the upstream workflow intact while distributing organization-owned
rules, knowledge, and skills across projects.

## Design

The kit follows the whitepaper's extensibility and learning model:

```text
AI-DLC v2 distribution       upstream baseline: engine, stages, agents, hooks
        +
Team overlays                organization rules, domain knowledge, skills
        +
Project workspace            aidlc/ spaces, intents, artifacts, and learnings
```

The approved upstream source, including its generated `dist/<harness>/` trees, is
vendored under `vendor/aidlc-workflows/` at the reviewed revision in
[upstream.lock](upstream.lock). Developer setup is offline: it never clones or
fetches upstream. The installer never patches `core/`, rewrites the upstream
conductor, or replaces project learning data.

## Supported Harnesses

AI-DLC v2 currently ships official distributions for:

- Claude Code: `--ide claude`
- GitHub Copilot in VS Code: `--ide copilot`
- Kiro IDE: `--ide kiro-ide`
- Kiro CLI: `--ide kiro-cli`
- Codex CLI: `--ide codex`
- opencode: `--ide opencode`

GitHub Copilot uses the kit's reviewed global adapter rather than an upstream
AI-DLC distribution. Cursor, Cline, and Amazon Q are not supported.

## Install

Install Bun and Git first. AI-DLC v2 runs natively on Windows; the installer uses
Bash through Git for Windows so the same distribution command works on every team
machine.

Prerequisites — Bun

Install Bun using the platform installer and verify it's on PATH before running
the kit. Example commands:

```bash
# macOS / Linux
curl -fsSL https://bun.sh/install | bash

# Windows PowerShell
irm https://bun.sh/install.ps1 | iex

# Windows (CMD)
powershell -c "irm https://bun.sh/install.ps1 | iex"
```

Verification

```bash
which bun        # Git Bash / macOS / Linux
bun --version

# Or on PowerShell
Get-Command bun
bun --version
```

Windows note: PowerShell may block running downloaded scripts (bun.ps1) via
ExecutionPolicy. If you encounter ``running scripts is disabled`` errors, either
run installer in Git Bash/CMD, or allow local signed scripts for current user:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

From Git Bash (including Windows):

```bash
./setup.sh --ide claude --project-dir ../my-project
./setup.sh --ide copilot
./setup.sh --ide kiro-ide --project-dir ../my-project
./setup.sh --ide codex --project-dir ../my-project
```

The installer:

1. Reads the reviewed, vendored AI-DLC v2 source.
2. Copies the selected native harness distribution.
3. Copies the neutral `aidlc/` workspace shell without overwriting project records.
4. Applies organization rules as managed blocks in `aidlc/spaces/default/memory/team.md`.
5. Installs team knowledge and custom skills.
6. Runs the harness-specific AI-DLC doctor check.

For Copilot, setup installs the approved runtime, the full reviewed AI-DLC
skill set, AI-DLC custom agents, organization instructions, hooks, and team
skills such as `estimation` and `caveman` under the developer profile:

```text
~/.copilot/aidlc/
~/.copilot/skills/
~/.copilot/instructions/
~/.copilot/hooks/
```

It does not copy the engine or skills into the project. The first `/aidlc`
invocation creates only the project's `aidlc/` workspace and intent records.

Start a workflow from the selected harness with:

```text
/aidlc Build a user authentication service
```

Codex uses `$aidlc` instead of `/aidlc`.

## Developer Workflow

For the primary VS Code Copilot setup, a developer does this once per machine
from Git Bash:

```powershell
git clone <workflow-kit-url>
cd ai-workflow-kit
./setup.sh --ide copilot
```

Then, for normal project work:

1. Open the target project in VS Code.
2. Open Copilot Chat and type `/aidlc` followed by the task, for example:
    `/aidlc Build the monitoring API`.
3. Approve or revise each AI-DLC stage when prompted.
4. Let the workflow create project state under `aidlc/`; do not copy the runtime
    or skill files into the project.
5. Start a new VS Code session later and type `/aidlc` to resume the active
    intent from its saved state.

The first invocation creates the project's `aidlc/` workspace. Subsequent work
uses that project's intents, audit trail, memory, knowledge, and artifacts.
The global runtime and organization skills stay under the developer profile.

When the workflow-kit repository changes, pull the new reviewed revision and
rerun `./setup.sh --ide copilot`; then reload VS Code so updated skills,
agents, and hooks are discovered.

For a project migration from AI-DLC v1, create a branch first, open the project,
and invoke `/aidlc`. AI-DLC v2 migrates the old `aidlc-docs/` layout when the
workflow starts.

## Global vs Project

For Claude, Kiro, Codex, and opencode, the supported upstream install remains
project-local. For the primary VS Code Copilot workflow, the kit installs a
global bridge that sets `AIDLC_PROJECT_DIR` and `AIDLC_RUNTIME_HARNESS_ROOT` for
each invocation. The runtime is reviewed once in this repository; project state
stays under `aidlc/`.

## What Teams Maintain

### Mandatory organization rules

Add Markdown files to `extensions/org-standards/`. The installer combines these
files into one managed block in the v2 team memory layer. This block is updated on
future installs without overwriting project-specific rules or AI-DLC learnings.

Use this layer for rules a reviewer would reject when violated, such as:

- security and data handling requirements
- required architecture or testing practices
- mandatory review and deployment controls
- organization-wide MCP or integration policy

### Reference knowledge

Add agent-facing reference material under `extensions/knowledge/` using the v2
layout. For example:

```text
extensions/knowledge/
└── aidlc-shared/
    └── company-architecture-principles.md
```

The installer copies this to the project's active space:

```text
aidlc/spaces/default/knowledge/
```

Use knowledge for patterns and context. Use `extensions/org-standards/` for
non-negotiable behavior.

### Extra skills

Add a skill directory containing `SKILL.md` under either:

```text
extensions/skills/<skill-name>/
extensions/workflows/<workflow-name>/
```

The installer copies these into the selected harness's native skill directory.
Team skills are additive and remain separate from the upstream AI-DLC engine.

## Learning and Project State

AI-DLC v2 stores all workflow state under the project-local, harness-neutral
workspace:

```text
aidlc/
└── spaces/default/
    ├── memory/       team and project practices
    ├── knowledge/    team reference material
    ├── codekb/       per-repository code knowledge
    └── intents/      state, audit trail, and artifacts for each piece of work
```

The v2 learning loop can promote corrections into `memory/project.md` or
`memory/team.md`. The installer preserves those files. Do not hand-edit the
framework-owned files inside `.claude/`, `.kiro/`, `.codex/`, or `.aidlc/` to add
team policy; use the overlay directories instead.

A project that still has the v1 flat `aidlc-docs/` layout can be migrated by
AI-DLC v2 on its first workflow run. Make a branch or backup before starting that
migration.

## Updating AI-DLC (Maintainers)

Normal setup never updates AI-DLC. A maintainer can prepare an upstream update:

```bash
# Use the local checkout you have reviewed
./scripts/update-upstream.sh --from-local ../aidlc/aidlc-workflows

# Or fetch a selected upstream ref as a maintainer operation
./scripts/update-upstream.sh --ref v2
```

The updater replaces `vendor/aidlc-workflows/` and updates `upstream.lock`.
Review the Git diff, run the vendor validation, and merge that change into the
kit's main branch. Developers receive the new AI-DLC version only after that
merge.

To reapply the approved version to a project:

```bash
./setup.sh --update --project-dir ../my-project
```

There is no floating `latest` mode. Upstream's v1 release ZIP is not used.

## Extending AI-DLC Itself

Use the upstream [plugin mechanism](https://github.com/awslabs/aidlc-workflows/blob/v2/docs/reference/18-plugin-mechanism.md)
for optional stages, agents, sensors, and additive stage contributions. Plugins must
remain additive; they cannot silently override an upstream stage.

Use the upstream [new harness guide](https://github.com/awslabs/aidlc-workflows/blob/v2/docs/harness-engineering/09-porting-to-a-new-harness.md)
when adding support for another coding harness.

## Repository Structure

```text
.
├── setup.sh                  # Git Bash entry point
├── setup.sh                  # the single developer entry point
├── upstream.lock            # reviewed upstream revision
├── vendor/aidlc-workflows/  # reviewed upstream source + generated distributions
├── scripts/
│   ├── update-upstream.sh   # maintainer-only vendor update
│   └── copilot/             # reviewed global VS Code adapter
├── extensions/
│   ├── org-standards/        # mandatory team rules
│   ├── knowledge/            # team reference material
│   ├── skills/               # extra skills
│   ├── workflows/            # extra workflow skills
│   └── copilot/              # Copilot user-level instructions
```

The copied AI-DLC engine and `aidlc/` workspace belong to the consuming project.
The kit repository remains the source of the upstream lock and team overlays.
