---
name: agent-estimation
description: >
  Estimate AI agent work effort and produce a full client-billable hours
  estimate. Phase 1 uses tool-call rounds as the base unit (not human time
  anchoring) to estimate code generation effort. Phase 2 classifies project
  size, adds AIDLC planning overhead, non-coding delivery work, human review
  time, and contingency to produce a complete billable breakdown. Works
  pre-project (plain description) or post-Inception (AIDLC units-of-work
  artifacts). Use when asked to estimate, scope, or produce a project quote.
---

# Agent Work Estimation Skill

> **Adapted from** [ZhangHanDong/agent-estimation](https://github.com/ZhangHanDong/agent-estimation) (MIT)
> with AIDLC-awareness layer and client billing phase added.

---

## STEP 0: Detect Input Mode

Before estimating, determine which input mode applies:

### Mode A — Pre-project (no AIDLC artifacts)

**Signals:** User provides a plain description, brief, or requirements doc.
No `aidlc-docs/` directory exists, or it has no units-of-work file.

**Action:** Perform a lightweight decomposition yourself (Step 1A), then
proceed. Do NOT run the full AIDLC Inception workflow — this is a standalone
estimation, not a development kickoff.

### Mode B — Post-Inception (AIDLC artifacts exist)

**Signals:** `aidlc-docs/inception/application-design/` exists and contains
a units-of-work or application-design file.

**Action:** Read the units-of-work artifact as your module list (Step 1B).
Skip decomposition — AIDLC already did it properly with stakeholder approval.

---

## STEP 0.5: Clarification Questions (MANDATORY — before any files are created)

**CRITICAL**: Do NOT create any estimate files until this step is complete.
The developer is the driver. The agent must not make assumptions about ambiguous
scope — every assumption that turns out to be wrong invalidates the estimate.

### What to analyse

Before writing questions, analyse the input for:

- **Scope ambiguities** — items that could be interpreted as in or out of scope
- **Technical unknowns** — integrations, APIs, or systems mentioned without detail
- **Team and role assumptions** — who is involved, what they own, what is done by others
- **Existing code assumptions** — what exists, what needs to be built, what needs to be modified
- **Constraint gaps** — performance, security, compliance requirements not stated
- **Option ambiguities** — where multiple implementation approaches exist and the choice affects effort significantly

### Question file

Create `estimates/[slug]-clarification-questions.md` (or
`aidlc-docs/estimation/[slug]-clarification-questions.md` if `aidlc-docs/` exists).

**File format — follow this exactly:**

```markdown
# Estimation Clarification Questions
## [Project name]

I need to clarify a few things before producing the estimate. Please answer
each question by filling in the letter choice after the [Answer]: tag.
If none of the options match, choose the last option and describe your answer.

Let me know when you're done.

## Question 1
[Clear, specific question about one ambiguity]

A) [First meaningful option]
B) [Second meaningful option]
C) [Third meaningful option — only if genuinely distinct]
X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 2
...
```

**Rules for questions:**

- Ask only about genuine ambiguities — do not ask questions you can reasonably
  infer from the input
- Each question covers exactly one ambiguity — no compound questions
- Options must be mutually exclusive and cover the realistic choices
- Always include `X) Other` as the last option — the developer may have a
  different answer than any option you provide
- Minimum 2 meaningful options before Other; maximum 5
- Do not pad options to fill A, B, C, D slots — only include realistic choices
- Questions must be ordered by impact on the estimate (highest impact first)

### ⛔ GATE: Await Developer Answers

**STOP after creating the question file.** Tell the developer:

> "I've created `[path-to-questions-file]` with [N] questions about scope and
> technical details that affect the estimate. Please answer each question by
> filling in the letter choice after the `[Answer]:` tag. Let me know when
> you're done."

Do NOT proceed to Step 1 until the developer confirms they are done.

### After receiving answers

1. Read the question file
2. Extract all answers from `[Answer]:` tags
3. Check every answer is filled in — if any are blank, ask the developer to
   complete them before proceeding
4. **Check for contradictions and ambiguities** in the answers:
   - Scope mismatch (e.g. "small change" but "affects multiple systems")
   - Risk mismatch (e.g. "low risk" but "unknown third-party API")
   - If contradictions found: create `[slug]-clarification-questions-2.md`,
     explain the contradiction clearly, ask targeted follow-up questions,
     and wait again before proceeding
5. Only when all answers are received and consistent: proceed to Step 1

**The developer's answers replace any assumptions the agent would have made.**
Update the module decomposition, risk coefficients, and Phase 2 overhead
based on what the developer has confirmed — not on what was initially inferred.

---

# PHASE 1 — Code Generation Estimate (Rounds)

## Problem

AI coding agents systematically overestimate task duration because they anchor
to human developer timelines absorbed from training data. A task an agent can
complete in 30 minutes gets estimated as "2-3 days" because that's what a human
developer forum post would say.

## Solution

Estimate from the agent's own operational units — **tool-call rounds** — and
only convert to human time at the very end.

---

## Core Units

| Unit | Definition | Scale |
|------|-----------|-------|
| **Round** | One tool-call cycle: think → write code → execute → verify → fix | ~2-4 min agent wallclock |
| **Module** | A functional unit built from multiple rounds until usable | 2-15 rounds |
| **Wave** | A batch of modules with no mutual dependencies, executable in parallel | 1-N modules |
| **Project** | All waves sequentially + integration + debugging | Sum of waves |

---

## Step 1A: Decompose into Modules (Mode A)

Break the described project into functional modules. Each module should be
independently buildable and testable.

Guidelines:
- Aim for 3-12 modules for a typical feature; more for a full system
- Shared infrastructure (auth, DB layer, config) is its own module
- UI and API for the same feature are separate modules
- Document decomposition before estimating — don't do both at once

## Step 1B: Load Modules from AIDLC Artifacts (Mode B)

Read the units-of-work file. Check these paths in order:
- `aidlc-docs/inception/application-design/units-of-work.md`
- `aidlc-docs/inception/application-design/` (any file with "unit" in the name)
- `aidlc-docs/inception/units-generation/`

Each AIDLC unit maps directly to one module. Use the unit name and description
as-is. Do NOT re-decompose. If functional design artifacts exist under
`aidlc-docs/construction/<unit-name>/functional-design/`, read them for
complexity detail.

---

## Step 2: Estimate Rounds per Module

| Pattern | Typical Rounds | Examples |
|---------|---------------|----------|
| **Boilerplate / known pattern** | 1-2 | CRUD endpoint, config file, standard API client |
| **Moderate complexity** | 3-5 | Custom UI layout, state management, data pipeline |
| **Exploratory / under-documented** | 5-10 | Unfamiliar framework, platform-specific APIs, complex integrations |
| **High uncertainty** | 8-15 | Undocumented behaviour, novel algorithms, multi-system debugging |

Calibration rules:
- Code generatable in one shot that will likely run → **1 round**
- Generate, run, see an error, fix → **2-3 rounds**
- Sparse docs, guessing at API behaviour → **5+ rounds**
- Platform permissions, OS-level APIs, manual user verification → add **2-3 rounds**
- AIDLC NFR requirements exist with non-trivial patterns → add rounds per NFR

---

## Step 3: Assign Risk Coefficients

| Risk Level | Coefficient | When to Apply |
|------------|------------|---------------|
| **Low** | 1.0 | Mature ecosystem, clear docs, strong pattern match |
| **Medium** | 1.3 | Minor unknowns, may need 1-2 extra debug rounds |
| **High** | 1.5 | Sparse docs, platform quirks, integration unknowns |
| **Very High** | 2.0 | Possible dead ends, may need to change approach entirely |

---

## Step 3.5: Construct Waves (Optional — parallel / multi-agent)

If the user asks for fastest completion or multi-agent execution:

1. Map dependencies: for each module, list which others it depends on
2. Group into waves (Wave 1 = no dependencies, Wave N = depends on Wave N-1)
3. Note agent count for parallel execution within each wave

Skip for single-agent sequential execution or fewer than 3 modules.

---

## Step 4: Calculate Round Totals

**Sequential mode:**
```
Module effective rounds = base rounds × risk coefficient
Project rounds = Σ(module effective rounds) + integration rounds
Integration rounds = 10-20% of base total
```

**Wave mode:**
```
Wave duration = max(effective rounds of modules in wave)
Project rounds = Σ(wave durations) + coordination rounds + integration rounds
Coordination rounds = 2-3 rounds upfront
```

---

## Step 5: Convert Rounds to Developer Hours

This is NOT the same as agent wallclock time. A developer overseeing AI-assisted
development is reviewing output, making decisions, handling edge cases, and
course-correcting — not just watching.

```
Developer hours (code generation) = project rounds × review_factor
```

**Review factor by complexity:**

| Project complexity | Review factor | Rationale |
|---|---|---|
| Low (boilerplate, known patterns) | 10 min/round | Quick review, minimal decisions |
| Medium (standard features) | 15 min/round | Some review, occasional rework |
| High (complex logic, integrations) | 20 min/round | Careful review, frequent decisions |
| Very high (novel, exploratory) | 30 min/round | Deep review, significant rework expected |

Use the weighted average across modules if complexity varies significantly.
Round up to the nearest 0.5 hour.

**Phase 1 output:** `code_generation_hours` — developer hours for AI-assisted
code generation only. This feeds into Phase 2.

---

# PHASE 2 — Full Client Estimate

Phase 2 takes `code_generation_hours` from Phase 1 and builds the complete
billable estimate by adding all the work that surrounds code generation.

---

## Step 6: Classify Project Size

Project size drives the overhead profiles in Steps 7-10. Classify based on
`code_generation_hours` and the nature of the work:

| Size | Code gen hours | Signals | Typical team |
|------|---------------|---------|--------------|
| **Micro** | < 4h | Single unit, isolated change, bug fix, config update | 1 person (tech lead or senior dev) |
| **Small** | 4-16h | 2-5 units, single feature, clear scope | Tech lead + 1-2 devs |
| **Medium** | 16-80h | 5-15 units, multi-feature, some integration work | BA + tech lead + 2-4 devs |
| **Large** | 80-300h | 15-30 units, new system or major subsystem | BA + architect + tech lead + 4-8 devs + stakeholders |
| **Enterprise** | 300h+ | 30+ units, platform-level, multi-team | Full programme team |

If signals conflict (e.g. low hours but high stakeholder complexity), use
judgement and note the reason in assumptions.

---

## Step 7: AIDLC Planning Overhead

AIDLC planning is real work that takes real time. It involves human participants
at every approval gate — it is not just AI running autonomously.

### Planning hours by project size

| Size | Planning hours | What's included |
|------|---------------|-----------------|
| **Micro** | 0.5-1h | Tech lead reviews scope, approves approach. No formal AIDLC phases needed. |
| **Small** | 2-4h | Requirements Analysis + light Application Design. Tech lead drives, 1-2 stakeholder touchpoints. |
| **Medium** | 8-20h | Full Inception (requirements, user stories, application design, units). Construction design per unit. Multiple stakeholder review rounds. |
| **Large** | 20-60h | Full Inception with BA-led requirements workshops. Architecture sessions. NFR design. Infrastructure design. Multiple domain experts involved. |
| **Enterprise** | 60-120h+ | Programme-level planning. Multiple workstreams. Governance gates. External stakeholder sign-off. |

### Planning roles and time allocation

For Medium and above, break planning hours down by role:

| Role | Micro | Small | Medium | Large |
|------|-------|-------|--------|-------|
| Business Analyst | — | — | 40-50% of planning hours | 50-60% |
| Architect / Tech Lead | 100% | 60-70% | 30-40% | 20-30% |
| Software Engineer | — | 30-40% | 20-30% | 15-20% |
| Stakeholder / Domain Expert | — | — | 10-20% | 15-25% |

Note: planning hours are elapsed time shared across roles, not additive.
If BA and tech lead both attend a 2-hour requirements session, that is 4 person-hours
but 2 elapsed hours. Bill person-hours, not elapsed hours.

---

## Step 8: Non-Coding Developer Work

These are the hours a **developer** spends on work surrounding code generation.
This is NOT the full QA or deployment effort — those teams produce their own
separate estimates. This covers only the developer's involvement and support time.

### 8a. Developer testing support

The developer writes unit tests (covered in Phase 1 rounds). Beyond that,
developers support QA but do not own the full test effort.

| Size | Developer QA hours | What's included |
|------|-------------------|-----------------|
| Micro | 0.5h | Smoke test own code, fix any immediate issues found |
| Small | 1-2h | Unit test review, fix bugs found during QA team's testing |
| Medium | 3-6h | Support QA team during integration testing, fix bugs, clarify behaviour |
| Large | 6-16h | Dedicated bug-fix sprint alongside QA, test environment support |

> The QA team's full testing effort (integration, regression, UAT, performance)
> is estimated separately by the QA team and is NOT included here.

### 8b. Developer deployment support

Developers support the deployment team but do not own the full deployment effort.

| Size | Developer deployment hours | What's included |
|------|---------------------------|-----------------|
| Micro | 0.5h | Provide deployment notes, available for questions |
| Small | 1-2h | Deployment runbook, support staging and prod deploy |
| Medium | 2-6h | Deployment runbook, environment-specific config, support go-live |
| Large | 4-12h | Detailed runbook, infrastructure-as-code handover, go-live support |

> The deployment team's full effort (environment provisioning, CI/CD pipeline,
> DR setup, rollback procedures) is estimated separately and is NOT included here.

### 8c. Meetings and communication

Every project has coordination overhead that doesn't produce artifacts.

| Size | Meeting hours | What's included |
|------|--------------|-----------------|
| Micro | 0.5h | Brief kickoff + handoff |
| Small | 2-4h | Kickoff, mid-point check-in, demo, retrospective |
| Medium | 6-16h | Sprint ceremonies, stakeholder updates, design reviews, demo, retro |
| Large | 16-40h | Programme ceremonies, steering committee, architecture reviews, demos, retros |

### 8d. Documentation

| Size | Docs hours | What's included |
|------|-----------|-----------------|
| Micro | 0h | Code comments sufficient |
| Small | 1-2h | README update, deployment notes for the deployment team |
| Medium | 4-8h | Technical design doc, API docs, deployment runbook for handover |
| Large | 8-24h | Architecture decision records, full technical docs, runbook, knowledge transfer sessions |

### 8e. Developer support window

Post-delivery developer availability for questions, bug fixes, and knowledge
transfer. This is the developer's time only — not a full support team engagement.

| Size | Developer support hours | Notes |
|------|------------------------|-------|
| Micro | 0.5h | Available for questions |
| Small | 1-3h | Bug fixes for issues found post-launch, clarifications |
| Medium | 4-8h | Bug fixes, knowledge transfer to support/ops team |
| Large | 8-20h | Dedicated bug-fix time, knowledge transfer sessions, documentation updates |

---

## Step 9: Contingency

Contingency covers scope creep, unexpected technical blockers, and estimation
error. It is applied to the sum of all hours above (excluding itself).

| Size | Contingency % | Rationale |
|------|--------------|-----------|
| Micro | 10% | Scope is clear and contained |
| Small | 15% | Some unknowns, limited blast radius |
| Medium | 20% | Multiple integrations, stakeholder-driven scope changes likely |
| Large | 25-30% | High complexity, long timeline, requirements will evolve |
| Enterprise | 30-40% | Programme-level uncertainty, external dependencies |

For Mode A estimates (no AIDLC artifacts), add an additional 5% to contingency
to account for decomposition uncertainty — the modules were AI-generated without
stakeholder validation.

---

## Step 10: Assemble the Full Estimate

```
subtotal = code_generation_hours
         + planning_hours
         + developer_testing_support_hours
         + developer_deployment_support_hours
         + meeting_hours
         + documentation_hours
         + developer_support_window_hours
```

**The subtotal is a single fixed number.** Only the contingency varies across
scenarios — do NOT recalculate the subtotal per scenario.

```
low    = round(subtotal × (1 + contingency_rate × 0.5),  nearest 0.5h)
median = round(subtotal × (1 + contingency_rate),        nearest 0.5h)
high   = round(subtotal × (1 + contingency_rate × 1.5),  nearest 0.5h)
```

**Example** (subtotal = 57h, contingency rate = 25%):
```
low    = 57 × 1.125 = 64h
median = 57 × 1.25  = 71h   ← recommended default
high   = 57 × 1.375 = 78h
```
This gives a 14h spread — realistic for a medium project. If the spread looks
too wide, the contingency rate is too high, not the formula.

### What each scenario means

| Scenario | When to use it |
|---|---|
| **Low** | Assumptions confirmed by developer answers, scope is locked, team knows the stack. Use for internal planning or hard-budget clients with genuinely fixed scope. |
| **Median** | Base estimate — standard risk applied, normal contingency. The most defensible number. Use as the default T&M quote. |
| **High** | Key risks materialise: assumptions prove wrong, scope clarifications add work, rework required. Use for fixed-price contracts or projects with significant unknowns. |

The developer picks one scenario to put forward. All three are documented in the
technical workings so the choice is transparent and can be revisited.

**Architecture and technical design row in the client template:** If architecture
work is fully embedded in planning (tech lead involvement throughout), collapse
both rows into "Discovery and planning" and note this in the table. Do not leave
the architecture row blank without explanation.

---

## Output Format

Produce the estimate in two parts:

### Part 1 — Technical breakdown (internal)

```markdown
### Technical Estimate: [project name]

**Input mode:** [A — plain description | B — AIDLC units-of-work]
**Project size:** [Micro | Small | Medium | Large | Enterprise]
**Date:** [ISO date]

#### Module Breakdown

| # | Module | Base Rounds | Risk | Effective Rounds | Notes |
|---|--------|------------|------|-----------------|-------|
| 1 | ...    | N          | 1.x  | M               | why   |

#### Phase 1 Summary
- **Total effective rounds:** X
- **Integration rounds:** +Y
- **Review factor:** Z min/round ([complexity level])
- **Code generation hours:** A hours

#### Phase 2 Summary
| Category | Hours | Notes |
|---|---|---|
| Code generation (AI-assisted) | A | Phase 1 output |
| AIDLC planning | B | [roles involved] |
| Developer testing support | C | Bug fixes, QA team support — not full QA effort |
| Developer deployment support | D | Runbook, go-live support — not full deployment effort |
| Meetings and communication | E | |
| Documentation | F | |
| Developer support window | G | Post-launch availability — not full support team |
| **Subtotal** | **H** | |

**Three scenarios (contingency rate: X%):**

| Scenario | Contingency | Total | When to use |
|---|---|---|---|
| **Low** | H × (rate × 0.5) | **L hours** | Scope locked, assumptions hold, optimistic |
| **Median** | H × rate | **M hours** | Base estimate — most defensible |
| **High** | H × (rate × 1.5) | **H hours** | Key risks materialise, significant unknowns |

**→ Recommended scenario for this estimate:** [Low / Median / High] — [one sentence reason]

> **Scope note:** This estimate covers developer hours only. QA team testing,
> deployment team infrastructure work, and ongoing support team effort are
> estimated separately by those teams.

#### Biggest Risks
1. [specific risk and what could blow up the estimate]

#### Assumptions
- [List all assumptions — tech stack, team familiarity, scope boundaries]
- [For Mode A: note decomposition was AI-generated, not stakeholder-validated]
```

### Part 2 — Client-facing summary (external)

```markdown
## Project Estimate: [project name]

**Prepared:** [date]
**Estimate type:** [Fixed scope | Time and materials]

### Effort Summary

| Work area | Low | Median | High |
|---|---|---|---|
| Discovery and planning | X | X | X |
| Development (AI-assisted) | X | X | X |
| Developer testing support | X | X | X |
| Developer deployment support | X | X | X |
| Project management and meetings | X | X | X |
| Documentation | X | X | X |
| Developer support window | X | X | X |
| **Total** | **L hrs** | **M hrs** | **H hrs** |

*Low = optimistic (scope locked, assumptions hold)*
*Median = base estimate (recommended)*
*High = pessimistic (key risks materialise)*

### Notes
- This estimate covers developer hours only. QA, deployment, and support team
  estimates are provided separately.
- Contingency of [X]% is included for scope changes and technical unknowns.
- [Any items explicitly excluded from scope.]

### Next steps
To proceed, we recommend [running full AIDLC Inception / scheduling a
requirements workshop / reviewing the technical breakdown].
```

---

## Output Storage

Save the following files (create directories if they don't exist):

**1. Full estimate document** (client summary + internal workings):
- `aidlc-docs/estimation/[slug]-estimate.md` (if `aidlc-docs/` exists)
- `estimates/[slug]-estimate.md` (pre-project, Mode A)

**2. Developer estimate CSV** (for pasting into Jira comments, tickets, or spreadsheets):
- `aidlc-docs/estimation/[slug]-estimate.csv`
- `estimates/[slug]-estimate.csv`

The CSV contains only the developer effort breakdown — no round counts, no risk
coefficients, no internal methodology. The subtotal is a single fixed number;
only the contingency varies across scenarios. Format:

```csv
Work Area,Hours,Notes
Discovery and planning,X,"..."
Development (AI-assisted),X,"..."
Developer testing support,X,"..."
Developer deployment support,X,"..."
Project management and meetings,X,"..."
Documentation,X,"..."
Developer support window,X,"..."
Subtotal,X,""
,,""
Scenario,Total Hours,When to use
Low (contingency X%),X,"Scope locked, assumptions confirmed, team knows the stack"
Median (contingency X%),X,"Base estimate — recommended for T&M quote"
High (contingency X%),X,"Key risks materialise — use for fixed-price or high-uncertainty contracts"
,,""
Recommended,[Low/Median/High],"[one sentence reason]"
```

**CRITICAL**: The subtotal row is the same number in all three scenarios.
Only the contingency percentage changes (0.5× / 1× / 1.5× the contingency rate).
Do NOT use different subtotals per scenario — that produces a nonsensical range.

Announce all saved paths to the user.

---

## Anti-Patterns to Avoid

1. **Human-time anchoring in Phase 1**: "A developer would take 2 weeks..." → NO. Start from rounds.
2. **Padding by vibes**: Adding time without specific rationale → NO. Use risk coefficients and size profiles.
3. **Quoting only code generation hours**: Giving the client Phase 1 hours alone → NO. Always include planning, meetings, documentation, and developer support time in Phase 2.
4. **Overstepping scope**: Including full QA team testing, full deployment team effort, or full support team engagement → NO. This estimate covers developer hours only. Those teams estimate their own work separately. Include only the developer's involvement time (bug fixes, runbook, go-live support, knowledge transfer).
5. **Treating planning as free**: AIDLC planning involves real people in real meetings. It is billable developer and BA time.
6. **Flat contingency regardless of size**: A micro change does not need 30% contingency. A large programme does not survive on 10%.
7. **Additive person-hours for meetings**: If three people attend a 1-hour meeting, that is 3 person-hours billed, not 1. Be explicit about this in the breakdown.
8. **Re-decomposing in Mode B**: AIDLC units-of-work were stakeholder-approved. Do not second-guess them.
9. **Omitting the client-facing summary**: The technical breakdown is for internal use. The client needs a clean summary without round counts and risk coefficients.
