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

## ⛔ MANDATORY FIRST ACTIONS — Before anything else

1. **Resolve your skills directory** (first path that exists):
   - `.github/skills/` — GitHub Copilot
   - `.kiro/steering/superpowers-skills/` — Kiro
   - `.amazonq/rules/superpowers-skills/` — Amazon Q
   - `.claude/skills/` — Claude Code
   - `~/.agents/skills/superpowers/` — global fallback

2. **Read the `using-superpowers` skill** from that directory. Now.

3. **Classify the request** (Type A/B/C/D/E — see your IDE's workflow entry point).

4. **If this involves any code, tests, debugging, or implementation:**
   Read the `subagent-driven-development` skill. You will dispatch subagents.
   **You will not write implementation code yourself. Not even one line.**

5. **If resuming a session (Type E):**
   Read `aidlc-docs/aidlc-state.md`, then re-read the plan file header.
   Complete the GLUE-06 resumption checklist before touching anything.

---

## Where the Workflow Rules Live (by IDE)

| IDE | Workflow entry point | Skills location |
|---|---|---|
| GitHub Copilot (VS Code) | `.github/copilot-instructions.md` *(generated)* | `.github/skills/` *(committed)* |
| Kiro | `.kiro/steering/aws-aidlc-rules/` *(generated)* | `.kiro/steering/superpowers-skills/` *(generated)* |
| Amazon Q | `.amazonq/rules/aws-aidlc-rules/` *(generated)* | `.amazonq/rules/superpowers-skills/` *(generated)* |
| Claude Code | `CLAUDE.md` *(generated)* | `.claude/skills/` *(generated)* |
| Cursor / Cline | `.cursor/rules/` or `.clinerules/` *(generated)* | `~/.agents/skills/superpowers/` |
| Codex / generic | `AGENTS.md` *(generated)* | `~/.agents/skills/superpowers/` |

Run `./setup.sh --ide <your-ide>` to generate the entry point for your IDE.
Run `./setup.sh --update` to refresh both upstream layers.

---

## Architecture

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

---

## Layer 1 — Planning (AIDLC)

**Governs:** Requirements, design, architecture, documentation.

**Entry point:** The AIDLC core workflow rules loaded by your IDE (see setup.sh).

**Use when:**
- Starting any new feature, change, or investigation
- Requirements, user stories, or design decisions need to be made
- Architecture or infrastructure choices need to be documented

**Start any workflow with:**
```
Using AI-DLC, [describe your task]
```

---

## Layer 2 — Execution (Superpowers)

**Governs:** All coding, testing, debugging, deployment, code review.

**Entry point:** `using-superpowers` skill — invoke before any execution task.

**Use when:**
- Writing, modifying, or reviewing code
- Running or debugging tests
- Deploying or verifying a build
- Creating or merging a branch

**The main agent NEVER writes implementation code directly.** Dispatch a
subagent for every coding task using `subagent-driven-development`.

---

## Layer 3 — Extensions

**Governs:** Optional integrations and org-specific rules.

**Location:** `extensions/` in this repo, copied to AIDLC rule-details by setup.sh.

**Active extensions:**
- `glue/superpowers-handoff.md` — enforces AIDLC→Superpowers handoff (always active)
- `integrations/jira/` — Jira sync (opt-in at workflow start)
- `integrations/confluence/` — Confluence sync (opt-in at workflow start)
- `org-standards/` — team-specific rules (always active, add your own)

---

## Handoff Points

| AIDLC Stage | Action |
|---|---|
| **Before any workflow** | Classify request (Type A/B/C/D/E) per GLUE-00 |
| Code Generation (Planning) | Invoke `writing-plans` skill; add Superpowers plan header (GLUE-04) |
| Code Generation (Execution) | Invoke `subagent-driven-development` skill (GLUE-01) |
| Any coding work | Invoke `test-driven-development` skill (always in subagent task text) |
| After each subagent completes | Invoke `verification-before-completion` skill |
| After verification passes | Invoke `requesting-code-review` skill |
| Build and Test complete | Invoke `verification-before-completion` then `requesting-code-review` |
| Bug or unexpected behaviour | Invoke `systematic-debugging` skill — skip AIDLC (Type B) |
| Starting feature branch | Invoke `using-git-worktrees` skill |
| Merging or closing branch | Invoke `finishing-a-development-branch` skill |
| Multiple independent tasks | Invoke `dispatching-parallel-agents` skill (see GLUE-07) |
| Session resumption | Verify partial work on disk; re-run staleness check; re-apply GLUE-02 |

---

## Skill Invocation Rule

Before responding to any user message, classify the request (Type A/B/C/D/E per
GLUE-00 in the glue extension), then check whether a Superpowers skill applies.
If there is even a 1% chance a skill is relevant, invoke it. This is not optional.

Skills directory resolution order (GLUE-05):
1. `.github/skills/` (Copilot)
2. `.kiro/steering/superpowers-skills/` (Kiro)
3. `.amazonq/rules/superpowers-skills/` (Amazon Q)
4. `.claude/skills/` (Claude Code)
5. `~/.agents/skills/superpowers/` (global)
6. `~/.codex/superpowers/skills/` (direct clone)

---

## Upstream Sources

- AIDLC: https://github.com/awslabs/aidlc-workflows (MIT-0)
- Superpowers: https://github.com/obra/superpowers (MIT)
- Setup: run `./setup.sh` to install/update both layers
