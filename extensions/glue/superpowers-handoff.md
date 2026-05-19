# Superpowers Execution Handoff

> **When to read this file:** Only when AIDLC reaches the Code Generation stage
> (Construction Phase). Do NOT read this during Inception or any design stage.
> All planning is done by the main agent directly.

---

## Rule GLUE-00: Task Classification (Code Generation Entry Check)

Before dispatching any subagent for code execution, confirm the request type:

| Type | Signals | Action |
|---|---|---|
| **A — New Feature / System** | Arrived here via full AIDLC planning | Proceed with subagent dispatch per GLUE-01 |
| **B — Bug Fix** | "fix", "bug", "error", "failing", "broken" | Skip Code Generation. Invoke `systematic-debugging` skill directly. |
| **C — Refactoring** | "refactor", "rewrite", "migrate", "upgrade" | Invoke `brainstorming` skill for design, then proceed with subagent dispatch. |
| **D — Simple Change** | Single-file edits, config changes, renames | Dispatch a single subagent with TDD. No full AIDLC needed. |
| **E — Resume Session** | "continue", "resume", "pick up" | Read `aidlc-docs/aidlc-state.md`. Resume from last checkpoint. See GLUE-06. |

**If the request arrived here via full AIDLC planning (Type A), proceed directly to GLUE-01.**

---

## Rule GLUE-01: Execution Layer Handoff

You are now at Code Generation. Hand off execution to Superpowers. Do not write
implementation code yourself.

**Mandatory steps:**

1. Resolve your skills directory using GLUE-05 (path resolution order)
2. Read the `using-superpowers` skill from that directory
3. Read the `subagent-driven-development` skill from that directory
4. Follow it exactly — AIDLC owns the plan content, story traceability, and
   approval gates; Superpowers owns execution mechanics (fresh subagent per task,
   two-stage spec + quality review after each task)
5. Before dispatching any subagent, read the `test-driven-development` skill and
   include "Use the test-driven-development skill" in every subagent's task text
6. After each subagent completes, invoke `verification-before-completion` then
   `requesting-code-review` before marking the plan step `[x]`
7. The plan file produced by AIDLC Code Planning is the input to
   `subagent-driven-development` — pass it as the plan file path

**The main agent NEVER writes implementation code directly.** Its job during
execution is coordination, context management, and review — not implementation.
Dispatch a subagent for every coding task.

**AIDLC stage hooks for Superpowers skills:**

| AIDLC stage | Mandatory skill invocation |
|---|---|
| Code Generation Part 1 (Planning) | Read `writing-plans` skill; ensure plan header includes the REQUIRED SUB-SKILL directive (see GLUE-04) |
| Code Generation Part 2 (Execution) | Read `subagent-driven-development`; dispatch subagent per task |
| Every subagent dispatch | Include "Use test-driven-development skill" in task text |
| After each subagent completes | Invoke `verification-before-completion` |
| After verification passes | Invoke `requesting-code-review` |
| Build and Test complete | Invoke `verification-before-completion` then `requesting-code-review` |
| Bug fix request (Type B) | Invoke `systematic-debugging` before any code changes |
| Starting any feature branch | Invoke `using-git-worktrees` |
| Merging / closing branch | Invoke `finishing-a-development-branch` |
| Multiple independent units | Invoke `dispatching-parallel-agents` (see GLUE-07) |

---

## Rule GLUE-02: Skill Invocation Trigger Map

Once in execution mode, check this table before each action:

| Situation | Skill to invoke |
|---|---|
| Implementing a plan (Type A) | `subagent-driven-development` |
| Bug / unexpected behaviour (Type B) | `systematic-debugging` immediately |
| Refactoring (Type C) | `brainstorming` → then `subagent-driven-development` |
| Writing any code | `test-driven-development` (always in subagent task text) |
| Claiming work is done | `verification-before-completion` |
| After completing a task | `requesting-code-review` |
| Receiving review feedback | `receiving-code-review` |
| Starting feature branch | `using-git-worktrees` |
| Merging / closing branch | `finishing-a-development-branch` |
| Multiple independent tasks | `dispatching-parallel-agents` |

**Priority rule when multiple skills apply:** The order in the table above is the
priority order.

---

## Rule GLUE-03: Subagent Context Isolation

When dispatching subagents:
- Provide the full task text directly — do not make the subagent read the plan file
- Include scene-setting context (where this fits, dependencies, architectural notes)
- The subagent must never inherit the main session's conversation history
- The main agent reads only the subagent's summary report, not its full output

This preserves the main agent's context for coordination work across the full
feature lifecycle.

**MANDATORY: Subagent Context Bundle**

Every subagent dispatch MUST include all of the following sections in the task
text. Missing any section is a violation of this rule.

```
### TASK
[What to build/fix/investigate — specific and actionable]

### CONTEXT
[Where this fits in the overall system — 2-3 sentences]

### RELEVANT DESIGN DOCS
[Paste or summarize: functional design, NFR requirements, API contracts for this unit]

### EXISTING CODE STRUCTURE
[Relevant files and their purposes from reverse engineering artifacts.
 For brownfield: list files that exist and must be modified in-place, not duplicated.
 For greenfield: state "No existing files — create new."]

### COMPLETED STEPS
[List of plan steps already marked [x], so the subagent does not regenerate them.
 For first dispatch: "None — this is the first task."]

### SKILLS TO USE
[Explicit list. Always include: "Use the test-driven-development skill."
 Add others as needed: "Use systematic-debugging before writing any fix."]

### TECH STACK
[Language, framework, test runner, linter, package manager]

### EXPECTED OUTPUT
[What the main agent needs back: summary of changes, test results, files modified]

### DEPENDENCIES
[Other units/services this task depends on, with their API contracts or interfaces]
```

---

## Rule GLUE-04: Plan Document Format

The AIDLC Code Generation plan document MUST include the Superpowers plan header
so that `subagent-driven-development` can consume it correctly.

Every `{unit-name}-code-generation-plan.md` file MUST start with:

```markdown
# [Unit Name] Implementation Plan

> ⛔ MAIN AGENT — MANDATORY BEFORE IMPLEMENTING ANY TASK IN THIS PLAN:
> 1. Read the `subagent-driven-development` skill from your skills directory
> 2. Dispatch a subagent for EVERY task — do not write a single line of implementation code yourself
> 3. Include "Use the test-driven-development skill" in every subagent's task text
> 4. After each subagent completes: invoke `verification-before-completion`, then `requesting-code-review`
>
> **REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development**

**Goal:** [One sentence from unit-of-work.md]
**Architecture:** [2-3 sentences from functional design]
**Tech Stack:** [From nfr-requirements tech-stack-decisions.md]
**Brownfield files to modify in-place:** [List from reverse engineering, or "N/A — greenfield"]
```

On session resumption (Type E), re-read this header before doing anything else.
If it contains a `REQUIRED SUB-SKILL` directive, invoke that skill immediately.

---

## Rule GLUE-05: Skills Directory Resolution

Resolve the skills directory in this order. Use the first path that exists and
contains skill subdirectories.

1. `.github/skills/` — GitHub Copilot (VS Code), committed to repo
2. `.kiro/steering/superpowers-skills/` — Kiro IDE
3. `.amazonq/rules/superpowers-skills/` — Amazon Q
4. `.claude/skills/` — Claude Code
5. `~/.agents/skills/superpowers/` — global symlink, all IDEs
6. `~/.codex/superpowers/skills/` — direct clone path

If no path resolves, log a warning and proceed without skill invocation. Do not
silently skip skills — state explicitly that the skill directory was not found.

---

## Rule GLUE-06: Session Resumption

When the request is classified as Type E (Resume Session):

1. Read `aidlc-docs/aidlc-state.md` — this is the authoritative state record
2. Identify the current stage and the first uncompleted `[ ]` checkbox in the plan
3. **Verify partial work**: Before resuming, check whether the code for the
   current step already exists on disk. If files are partially written, include
   their current state in the subagent's EXISTING CODE STRUCTURE section
4. **Staleness check**: Re-run the reverse engineering staleness check from
   `inception/workspace-detection.md` Step 3, even on resumption. If artifacts
   are stale, re-run Reverse Engineering before continuing
5. **Skill re-invocation**: GLUE-02 applies on resumption exactly as on first
   start. Check the skill trigger table before dispatching any subagent
6. Include in the subagent's COMPLETED STEPS section: all steps marked `[x]`
   in the plan file, plus a list of files that already exist in the workspace

**MANDATORY resumption checklist — tick every box before any other action:**

- [ ] Read `aidlc-docs/aidlc-state.md`
- [ ] Identify last completed stage — if still in planning, resume AIDLC directly (no skills needed yet)
- [ ] If resuming at Code Generation or later: read `using-superpowers` skill
- [ ] If resuming at Code Generation or later: read `subagent-driven-development` skill
- [ ] Re-read the plan file header — if it contains a `REQUIRED SUB-SKILL` directive, invoke that skill now
- [ ] Confirm: I will not write any implementation code directly

Only after all boxes are checked: proceed with resumption.

---

## Rule GLUE-07: Parallel Unit Execution

When the request involves multiple independent units (microservices, parallel
features), choose an execution mode before starting Construction:

**Sequential mode** (default):
- Complete each unit fully (design + code) before starting the next
- Use when units have dependencies on each other, or context is limited

**Parallel mode** (opt-in, requires explicit user approval):
- Invoke `dispatching-parallel-agents` skill
- **Prerequisites before dispatching any coding subagent:**
  1. Complete ALL design stages (Functional Design, NFR, Infrastructure) for ALL
     units before dispatching any coding subagent
  2. Identify shared code (models, utilities, auth libraries) — create a
     "shared" unit and complete it first, sequentially, before parallel dispatch
  3. Each subagent writes only to its own unit directory — no shared file writes
     during parallel execution
- **State management during parallel execution:**
  - `aidlc-state.md` is updated by the main agent only, never by subagents
  - `audit.md` updates are aggregated by the main agent after all parallel
    subagents complete — subagents return their audit entries in their summary
  - If a subagent completes out of order, the main agent marks its steps `[x]`
    and waits for remaining subagents before proceeding to Build and Test
- **Inter-service contracts**: Before dispatching subagent N that depends on
  service M's API, extract service M's API contract from its design docs and
  include it in subagent N's DEPENDENCIES section
