# How to Use the Estimation Workflow

This workflow produces two outputs:
1. A **technical breakdown** (internal) — round-based code generation estimate
2. A **client-facing estimate** — full billable hours including planning, QA,
   deployment, meetings, support, and contingency

It works at any stage of a project — before any AIDLC planning has happened,
or after Inception is complete.

---

## The two phases

### Before any files are created — clarification questions

The first thing the agent does after analysing your input is create a
clarification questions file. **No estimate files are produced until you answer
these questions.**

This is intentional. Every assumption the agent makes without asking you is a
potential error in the estimate. The questions cover scope ambiguities, technical
unknowns, team and role boundaries, and anything where the choice significantly
affects effort.

You answer by filling in the letter choice after each `[Answer]:` tag in the
file. The agent waits for you to confirm you're done, then reads your answers
before proceeding. If your answers contain contradictions, it asks a second round
of targeted follow-up questions before moving on.

The developer is the driver — the agent does not proceed on assumptions.

### Phase 1 — Code generation estimate

Uses tool-call rounds as the base unit to estimate AI-assisted development
effort. Rounds are converted to developer hours using a review factor (not
agent wallclock time — a developer overseeing AI output is reviewing, deciding,
and course-correcting, not just watching).

### Phase 2 — Full client estimate (developer hours)

Takes the Phase 1 hours and adds all surrounding developer work. This is
**developer hours only** — QA and deployment teams produce their own separate
estimates. The developer's involvement in those areas (bug fixes during QA,
deployment runbook, go-live support) is included, but not the full team effort.

| Added in Phase 2 | What's included | What's NOT included |
|---|---|---|
| AIDLC planning overhead | Requirements sessions, design reviews, approval gates | — |
| Developer testing support | Bug fixes during QA, test environment help | Full QA team testing effort |
| Developer deployment support | Deployment runbook, go-live support | Full deployment team effort |
| Meetings and communication | Kickoff, check-ins, demos, retro | — |
| Documentation | Technical docs, runbook, knowledge transfer | — |
| Developer support window | Post-launch bug fixes, questions | Full support team engagement |
| Contingency | Scope changes and technical unknowns | — |

The split between Phase 1 and Phase 2 is driven by **project size** — a micro
change (single unit, isolated) needs almost no overhead; a large programme needs
significant planning, governance, and support time.

---

## When to use it

- **Pre-project quote**: You have a brief or requirements doc. Produce an
  estimate before any development starts or any AIDLC workflow is run.
- **Post-Inception quote**: AIDLC Inception is complete. Use the approved
  units-of-work for a more accurate estimate grounded in stakeholder-validated
  decomposition.
- **Re-estimate**: Scope has changed mid-project. Re-run against remaining units.
- **Internal sizing**: Not for a client — just need to know if something is a
  1-week or 1-month job before committing.

---

## How to invoke it

### Pre-project (plain description)

```
Using the agent-estimation skill, produce a full client estimate for:

[paste your project description, brief, or requirements here]

Include both the technical breakdown and the client-facing summary.
```

### Pre-project (from a document)

```
Using the agent-estimation skill, produce a full client estimate for the
project described in [path/to/brief.md].

Include both the technical breakdown and the client-facing summary.
```

### Post-Inception (AIDLC artifacts exist)

```
Using the agent-estimation skill, produce a full client estimate for this
project. AIDLC Inception is complete — use the units-of-work artifacts in
aidlc-docs/.

Include both the technical breakdown and the client-facing summary.
```

### Code generation only (no client deliverable needed)

```
Using the agent-estimation skill, estimate the development effort only
(Phase 1 — rounds and developer hours). No client summary needed.
```

### Re-estimate remaining work

```
Using the agent-estimation skill, re-estimate the remaining units.
Units already complete: [list them].
Use the units-of-work artifacts in aidlc-docs/.
```

---

## What the agent needs from you

**Mode A (pre-project):**
- Your project description — the more detail the better
- Tech stack and known constraints (if any)
- Known integrations required
- Team's familiarity with the domain
- Whether you need a fixed-scope or T&M estimate

**Mode B (post-Inception):**
- Nothing extra — the agent reads `aidlc-docs/` directly
- Optionally: your team's typical review pace (fast/careful) to adjust the
  review factor

**For Phase 2 (both modes):**
- Whether the project is greenfield or brownfield
- Whether infrastructure already exists or needs provisioning
- Expected support window length after go-live
- Any roles that are NOT involved (e.g. "no dedicated BA, tech lead covers it")

---

## Adjusting the estimate

### Review factor (Phase 1)

The agent uses a review factor based on complexity. You can override:

| Tell the agent | When |
|---|---|
| "Use 10 min/round" | Boilerplate work, team knows the stack well |
| "Use 15 min/round" | Standard features (default for medium complexity) |
| "Use 20 min/round" | Complex logic, unfamiliar integrations |
| "Use 30 min/round" | Exploratory work, high uncertainty |

### Planning overhead (Phase 2)

If your team structure differs from the standard profiles:

```
"There is no dedicated BA — the tech lead covers requirements.
 Reduce planning hours accordingly."

"This project has a fixed-price contract with a governance board.
 Add 20% to planning hours for sign-off overhead."
```

### Contingency

```
"The client has a history of scope changes — use 30% contingency."
"This is a well-defined internal tool with locked scope — use 10%."
```

---

## Output files

The agent saves one markdown file and one CSV:

| File | Contents | Share with |
|---|---|---|
| `[slug]-estimate.md` | Client summary (three scenarios) + internal workings | Client summary → client/manager; workings → on demand |
| `[slug]-estimate.csv` | Developer effort breakdown — Low / Median / High columns | Paste into Jira comment or ticket |

The CSV has three columns — Low, Median, High — plus a recommended scenario row.
Pick the scenario that fits the client relationship and paste that column into Jira.

The client summary shows all three scenarios so the client can see the range.
The internal workings section explains how each scenario was derived.

Keep both sections in your working copy. Strip the internal workings before sending to the client.

Saved to:
- `aidlc-docs/estimation/` if AIDLC docs exist (Mode B)
- `estimates/` if pre-project (Mode A)

The `client-estimate-template.md` in this directory is the structural template
the agent uses. You can customise it for your team's branding and standard terms.

---

## Feeding the estimate into Jira

If you have the Jira integration enabled, after the estimate is produced:

```
Create a Jira Epic for this project using the estimate at
aidlc-docs/estimation/[slug]-estimate.md.
Use the work areas from the effort breakdown as Epics or Stories.
Set story points based on effective rounds (1 point = 1 round).
```

This is manual — the estimation workflow does not auto-create Jira tickets.
Jira auto-creation only happens during a full AIDLC workflow with Jira opted in.

---

## Relationship to the full AIDLC workflow

The estimation workflow is **independent**. Running an estimate does not start
or commit you to a development workflow.

If you later decide to build the project:

```
Using AI-DLC, build [project name]
```

The agent starts full AIDLC Inception. If an estimate exists in
`aidlc-docs/estimation/` or `estimates/`, the agent references it during
Requirements Analysis as context — but still runs the full planning process.
The estimate does not replace planning; it informs it.

---

## Skill location

`extensions/workflows/estimation/SKILL.md`

Installed into your IDE's skills directory by `setup.sh`. For Kiro it uses
`inclusion: manual` — load it explicitly with `#agent-estimation` or by
referencing it in your prompt.
