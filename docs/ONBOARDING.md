# Developer Onboarding

Welcome to the team. This guide gets you from zero to running the AI-DLC +
Superpowers workflow in your IDE in about 10 minutes.

## What this workflow is

A structured AI-driven development process that combines two upstream projects:

- **AIDLC** (awslabs/aidlc-workflows) — guides the AI through planning phases:
  requirements, user stories, application design, and units of work before a
  single line of code is written
- **Superpowers** (obra/superpowers) — takes over at code generation: TDD,
  subagent dispatch, code review, debugging

Your team's extensions (Jira/Confluence sync, org standards, custom skills) sit
on top of both layers and are maintained in this repo.

```
┌─────────────────────────────────────────────────────────┐
│  LAYER 3: EXTENSIONS  (this repo — extensions/)         │
│  Jira · Confluence · org standards · custom skills      │
├─────────────────────────────────────────────────────────┤
│  LAYER 2: EXECUTION  (obra/superpowers — upstream)      │
│  TDD · debugging · subagent dispatch · code review      │
├─────────────────────────────────────────────────────────┤
│  LAYER 1: PLANNING  (awslabs/aidlc-workflows — upstream)│
│  Inception · Construction · Operations phases           │
└─────────────────────────────────────────────────────────┘
```

You never edit the upstream layers directly. Everything your team customises
lives in `extensions/`.

---

## Step 1 — Prerequisites

You need:

- **git** — to clone this repo and for Superpowers to clone itself
- **bash** — to run `setup.sh` (Git Bash on Windows, or WSL)
- **curl** and **unzip** — used by `setup.sh` to download AIDLC
- **python3** — used by `setup.sh` for a few patching steps (usually pre-installed)
- **uvx** — only needed if you want Jira/Confluence integration

Check you have the basics:

```bash
git --version
bash --version
curl --version
python3 --version
```

If you want Jira/Confluence integration, install uvx:

```bash
pip install uv   # or: brew install uv
uvx --version    # verify
```

---

## Step 2 — Clone this repo

```bash
git clone <this-repo-url>
cd <repo-name>
```

---

## Step 3 — Run setup

```bash
# Auto-detects your IDE
./setup.sh

# Or specify your IDE explicitly (recommended on first run)
./setup.sh --ide kiro          # Kiro
./setup.sh --ide claudecode    # Claude Code
./setup.sh --ide cursor        # Cursor
./setup.sh --ide copilot       # GitHub Copilot / VS Code
./setup.sh --ide amazonq       # Amazon Q Developer
./setup.sh --ide cline         # Cline
./setup.sh --ide codex         # Codex / generic AGENTS.md
```

With Jira/Confluence (if your team uses them):

```bash
./setup.sh --ide kiro --with-jira --with-confluence
```

Setup does three things:
1. Downloads the latest AIDLC rules from awslabs/aidlc-workflows
2. Clones obra/superpowers skills to `~/.codex/superpowers/`
3. Copies your team's extensions into the IDE-specific directories

The generated files (`.kiro/`, `CLAUDE.md`, `.cursor/rules/`, etc.) are not
committed — they are re-created by `setup.sh`. Run it once per machine, and
again after `git pull` if the team has updated extensions.

---

## Step 4 — Set up credentials (if using Jira/Confluence)

Copy the example env file and fill in your values:

```bash
cp .env.example .env
# edit .env with your Atlassian credentials
```

Get your API token at: https://id.atlassian.com/manage-profile/security/api-tokens

Then load the variables in your shell. The simplest approach — add to your
`~/.bashrc` or `~/.zshrc`:

```bash
export JIRA_URL="https://your-org.atlassian.net"
export JIRA_USERNAME="your-email@example.com"
export JIRA_API_TOKEN="your-api-token-here"
export CONFLUENCE_URL="https://your-org.atlassian.net/wiki"
export CONFLUENCE_USERNAME="your-email@example.com"
export CONFLUENCE_API_TOKEN="your-api-token-here"
```

See `.env.example` for alternative approaches (direnv, IDE secret store,
1Password/Vault).

**Never commit `.env` to version control.** It is already in `.gitignore`.

---

## Step 5 — Verify the install

After setup, check that the workflow entry point exists for your IDE:

| IDE | File to check |
|---|---|
| Kiro | `.kiro/steering/aidlc-workflow.md` |
| Claude Code | `CLAUDE.md` |
| Cursor | `.cursor/rules/ai-dlc-workflow.mdc` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Amazon Q | `.amazonq/rules/aws-aidlc-rules/core-workflow.md` |
| Cline | `.clinerules/core-workflow.md` |
| Codex | `AGENTS.md` |

Also check that skills were installed:

```bash
ls ~/.codex/superpowers/skills/          # upstream Superpowers skills
ls ~/.agents/skills/superpowers/         # symlink — same content
```

For Kiro, also check:

```bash
ls .kiro/steering/superpowers-skills/    # skills copied into Kiro steering
```

---

## Step 6 — Start a workflow

Open your IDE and type:

```
Using AI-DLC, build a user authentication system
```

The agent will:
1. Detect the workspace state
2. Ask structured questions about requirements
3. Generate planning artifacts in `aidlc-docs/`
4. Wait for your approval at each stage before proceeding
5. Hand off to Superpowers at Code Generation — dispatching subagents per task
   with TDD, then running verification and code review after each one

You answer questions by editing the generated question files and adding
`[Answer]: A` (or B, C, etc.) tags.

---

## Day-to-day usage

**Resuming a session:**

```
Using AI-DLC, continue work on the authentication system
```

The agent reads `aidlc-docs/aidlc-state.md` and picks up from the last
checkpoint.

**Keeping upstreams current:**

```bash
./setup.sh --update
```

Re-downloads the latest AIDLC release and pulls the latest Superpowers skills.
Your extensions are not touched.

**Switching IDEs:**

```bash
./setup.sh --ide cursor   # installs for Cursor, removes stale files from other IDEs
```

Note: if you switch IDE mid-workflow, re-run setup before continuing. The
`aidlc-docs/` planning artifacts are preserved — only the IDE entry point files
change.

---

## What lives where

```
.
├── setup.sh                    ← run this to install/update
├── .env.example                ← copy to .env, add your credentials
│
├── extensions/                 ← everything your team maintains
│   ├── glue/                   ← AIDLC→Superpowers handoff rules (don't edit unless you know why)
│   ├── skills/                 ← add team-specific custom skills here
│   ├── integrations/           ← Jira and Confluence sync rules
│   └── org-standards/          ← your team's coding rules and constraints
│
├── docs/
│   ├── ONBOARDING.md           ← this file
│   └── WORKING-WITH-INTEGRATIONS.md
│
└── aidlc-docs/                 ← generated during a workflow run (not committed)
    ├── inception/              ← requirements, user stories, application design
    ├── construction/           ← functional design, NFR, code generation plans
    ├── aidlc-state.md          ← current workflow state (read this to resume)
    └── audit.md                ← full audit trail of every AI decision
```

---

## Adding team-specific rules

Drop a `.md` file into `extensions/org-standards/`. Each rule follows this
structure:

```markdown
## Rule ORG-01: Your Rule Title
### Rule
What is required.
### Verification
How the agent checks compliance before proceeding.
```

Rules here are always enforced. To make a rule opt-in (user is asked at
workflow start), add a matching `<name>.opt-in.md` alongside it — see the
Jira/Confluence examples for the format.

Re-run `./setup.sh` after adding rules to copy them into the IDE rule-details
directory.

---

## Adding a custom skill

Custom skills live in `extensions/skills/<skill-name>/SKILL.md`. They are
installed alongside the upstream Superpowers skills by `setup.sh`.

Use custom skills for team-specific patterns that don't belong in the upstream
Superpowers project — your internal API conventions, domain-specific patterns,
or workflow extensions tied to your org's tooling.

See `extensions/skills/README.md` for the full guide.

---

## Troubleshooting

**`setup.sh` fails with "curl: command not found"**
Install curl via your package manager (`brew install curl`, `apt install curl`, etc.)

**`setup.sh` fails with "Could not resolve latest AIDLC release tag"**
GitHub API rate limit or network issue. Try again in a few minutes, or pin a
specific version: edit `AIDLC_VERSION` at the top of `setup.sh`.

**Agent ignores the workflow and writes code immediately**
The entry point file is missing or not being loaded. Re-run `./setup.sh --ide <your-ide>`
and verify the file exists (see Step 5 above).

**Skills not appearing in IDE**
For Kiro: skills use `inclusion: manual` — they won't auto-load. Reference them
explicitly in your prompt or via the `#` context key.
For Copilot: type `/` in Copilot Chat to see available skills.
For other IDEs: check `~/.agents/skills/superpowers/` exists and is not empty.

**Jira/Confluence MCP not connecting**
Run `uvx mcp-atlassian --help` to verify the server is installed.
Check your env vars are exported in the shell your IDE uses (not just your
terminal). See `docs/WORKING-WITH-INTEGRATIONS.md` for full troubleshooting.

**Switching IDEs mid-workflow**
Re-run `./setup.sh --ide <new-ide>`. Your `aidlc-docs/` artifacts are safe —
only the IDE entry point files are regenerated. Resume normally after setup.
