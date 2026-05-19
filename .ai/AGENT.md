# AGENT.md — Project Overview for AI Agents

> **This is the committed project overview.** It explains the architecture and
> tells you where the real workflow rules live for your IDE.
>
> The actual workflow instructions are in IDE-specific generated files (not
> committed). Run `./setup.sh` to install them for your IDE. See the table below.
>
> **Session continuity:** If `aidlc-docs/aidlc-state.md` exists, read it first.
> It is the authoritative record of what has been built, what is in progress,
> and what comes next.

---

## How This Workflow Works

```
┌─────────────────────────────────────────────────────────┐
│  LAYER 3: EXTENSIONS  (this repo — extensions/)         │
│  Jira · Confluence · org standards · glue rules         │
├─────────────────────────────────────────────────────────┤
│  LAYER 2: EXECUTION  (obra/superpowers — upstream)      │
│  TDD · debugging · subagent dispatch · code review      │
├─────────────────────────────────────────────────────────┤
│  LAYER 1: PLANNING  (awslabs/aidlc-workflows — upstream)│
│  Inception · Construction · Operations phases           │
└─────────────────────────────────────────────────────────┘
```

**The main agent owns all of Layer 1 (planning) directly.**
Superpowers (Layer 2) only activates when AIDLC reaches Code Generation.

---

## ⛔ MANDATORY FIRST ACTION

Read your IDE's workflow entry point (see table below). That file contains all
instructions. Follow it from the top.

Do NOT read Superpowers skills at session start. They are invoked by the AIDLC
workflow at the right time (Code Generation stage).

---

## Where the Workflow Rules Live (by IDE)

| IDE | Workflow entry point | Skills location |
|---|---|---|
| Kiro | `.kiro/steering/aidlc-workflow.md` *(generated)* | `.kiro/steering/superpowers-skills/` *(generated, manual-load)* |
| Amazon Q | `.amazonq/rules/aws-aidlc-rules/core-workflow.md` *(generated)* | `.amazonq/rules/superpowers-skills/` *(generated)* |
| Claude Code | `CLAUDE.md` *(generated)* | `.claude/skills/` *(generated)* |
| GitHub Copilot | `.github/copilot-instructions.md` *(generated)* | `.github/skills/` *(committed)* |
| Cursor / Cline | `.cursor/rules/` or `.clinerules/` *(generated)* | `~/.agents/skills/superpowers/` |
| Codex / generic | `AGENTS.md` *(generated)* | `~/.agents/skills/superpowers/` |

Run `./setup.sh --ide <your-ide>` to generate the entry point for your IDE.
Run `./setup.sh --update` to refresh both upstream layers.

---

## Layer 1 — Planning (AIDLC)

**Governs:** All phases from Inception through Construction design stages.

**The main agent works directly** — no subagents, no skill invocations.

Phases:
- **Inception** — requirements, user stories, application design, units of work
- **Construction (design)** — functional design, NFR design, infrastructure design
- **Construction (code generation)** — hands off to Layer 2 at this point

---

## Layer 2 — Execution (Superpowers)

**Activates at:** Code Generation stage of the Construction Phase.

**Entry point:** Read `extensions/glue/superpowers-handoff.md` (or its installed
copy in the rule-details directory) when AIDLC reaches Code Generation.

**The main agent NEVER writes implementation code directly.** Dispatch a
subagent for every coding task using `subagent-driven-development`.

---

## Layer 3 — Extensions

**Location:** `extensions/` in this repo, copied to rule-details by setup.sh.

**Active extensions:**
- `glue/superpowers-handoff.md` — AIDLC→Superpowers handoff (read at Code Generation)
- `integrations/jira/` — Jira sync (opt-in at workflow start)
- `integrations/confluence/` — Confluence sync (opt-in at workflow start)
- `org-standards/` — team-specific rules (always active)

---

## Upstream Sources

- AIDLC: https://github.com/awslabs/aidlc-workflows (MIT-0)
- Superpowers: https://github.com/obra/superpowers (MIT)
- Setup: run `./setup.sh` to install/update both layers
