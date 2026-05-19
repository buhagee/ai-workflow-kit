# AGENT.md — Entry Point for All AI Agents

> **Read this file first.**
>
> This project uses two upstream open-source workflow systems plus a thin
> extension layer. Do not implement code directly — follow the workflow below.
>
> **Session continuity:** If `aidlc-docs/aidlc-state.md` exists, read it first.
> It is the authoritative record of what has been built, what is in progress,
> and what comes next.

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
| Code Generation (Planning) | Invoke `writing-plans` skill |
| Code Generation (Execution) | Invoke `subagent-driven-development` skill |
| Any coding work | Invoke `test-driven-development` skill |
| Before marking work done | Invoke `verification-before-completion` skill |
| After completing a task | Invoke `requesting-code-review` skill |
| After review feedback | Invoke `receiving-code-review` skill |
| Bug or unexpected behaviour | Invoke `systematic-debugging` skill |
| Starting feature branch | Invoke `using-git-worktrees` skill |
| Merging or closing branch | Invoke `finishing-a-development-branch` skill |
| Multiple independent tasks | Invoke `dispatching-parallel-agents` skill |

---

## Skill Invocation Rule

Before responding to any user message, check whether a Superpowers skill applies.
If there is even a 1% chance a skill is relevant, invoke it. This is not optional.

---

## Upstream Sources

- AIDLC: https://github.com/awslabs/aidlc-workflows (MIT-0)
- Superpowers: https://github.com/obra/superpowers (MIT)
- Setup: run `./setup.sh` to install/update both layers
