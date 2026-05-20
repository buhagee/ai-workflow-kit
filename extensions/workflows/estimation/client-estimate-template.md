# Client Estimate Template

> This template is the deliverable produced by the estimation workflow.
> The agent fills it in — you review, adjust, and distribute as appropriate.
>
> **Three audiences, two sections:**
> - **Client** → share the top section only (Executive Summary → Next Steps).
>   Effort by work area, no component detail.
> - **Manager / tech lead** → the top section is your default share.
>   The internal workings section is on-demand — share it if they ask
>   "how did you get to that number?" or want to challenge the estimate.
> - **You** → keep both sections as your working document.
>
> Delete this instruction block before sharing.

---

# PROJECT ESTIMATE
## [Project Name]

**Client:** [Client name]
**Prepared by:** [Your name / team]
**Date:** [YYYY-MM-DD]
**Valid for:** 30 days from date above
**Estimate type:** ☐ Fixed scope  ☐ Time and materials  ☐ Capped T&M

---

## Executive Summary

[2-3 sentences describing what is being built and the overall effort range.
Example: "This estimate covers the design, development, and delivery of a
customer-facing authentication system including login, registration, password
reset, and MFA. Total estimated effort is 48-58 hours across a 3-week delivery
window."]

---

## Scope Included

[Bullet list of what IS included. Be specific — vague scope leads to disputes.]

- [ ] [Feature or deliverable 1]
- [ ] [Feature or deliverable 2]
- [ ] [Feature or deliverable 3]

## Scope Excluded

[Bullet list of what is explicitly NOT included. This protects you.]

- [ ] [Excluded item 1 — e.g. "Mobile app (web only)"]
- [ ] [Excluded item 2 — e.g. "Third-party API costs"]
- [ ] [Excluded item 3 — e.g. "Ongoing hosting and maintenance after handover"]

---

## Effort Breakdown

> **Scope:** This estimate covers **developer hours only**. QA team testing,
> deployment team infrastructure work, and ongoing support team effort are
> estimated separately by those teams.

| Work area                         | Low    | Median | High   | Notes                                                          |
| -----------------------------------| --------| --------| --------| ----------------------------------------------------------------|
| Discovery and planning            |        |        |        | Requirements workshops, design sessions, stakeholder reviews   |
| Architecture and technical design |        |        |        | Included in planning above if tech lead involvement throughout |
| Development (AI-assisted)         |        |        |        | Code generation, unit tests, code review                       |
| Developer testing support         |        |        |        | Bug fixes during QA, test environment support                  |
| Developer deployment support      |        |        |        | Deployment runbook, go-live support                            |
| Project management and meetings   |        |        |        | Kickoff, check-ins, demos, retrospective                       |
| Documentation                     |        |        |        | Technical docs, runbook, knowledge transfer                    |
| Developer support window          |        |        |        | Post-launch bug fixes and questions                            |
| **Subtotal**                      | **Xh** | **Xh** | **Xh** | Same across all scenarios — the work estimate does not change  |
| **Contingency ([X]%)**            | +Xh    | +Xh    | +Xh    | 0.5x / 1x / 1.5x contingency rate                              |
| **TOTAL**                         | **Lh** | **Mh** | **Hh** |                                                                |

> Note: the per-row hours are identical across Low, Median, and High. Only the
> contingency buffer and total change between scenarios. The three scenarios
> model estimation uncertainty and scope risk — not different amounts of work.

*Low = optimistic (scope locked, assumptions hold)*
*Median = base estimate (most defensible — recommended default)*
*High = pessimistic (key risks materialise, significant unknowns)*

**Recommended scenario: [Low / Median / High]** — [one sentence reason]

> Separate estimates for full QA testing, infrastructure provisioning, and
> ongoing support will be provided by the respective teams.

---

## Team and Roles

| Role                    | Estimated hours | Responsibilities                                    |
| -------------------------| -----------------| -----------------------------------------------------|
| [Business Analyst]      |                 | Requirements, stakeholder liaison, UAT coordination |
| [Architect / Tech Lead] |                 | Technical design, code review, deployment           |
| [Software Engineer]     |                 | Development, unit testing                           |
| [QA Engineer]           |                 | Integration testing, UAT support                    |
| **Total**               |                 |                                                     |

> Note: hours above are person-hours. Where multiple roles attend the same
> meeting or session, each person's time is counted separately.

---

## Timeline

| Phase                  | Duration       | Depends on                                    |
| ------------------------| ----------------| -----------------------------------------------|
| Discovery and planning | [X days/weeks] | Client availability for requirements sessions |
| Design                 | [X days/weeks] | Planning sign-off                             |
| Development            | [X days/weeks] | Design sign-off                               |
| Testing                | [X days/weeks] | Development complete                          |
| Deployment             | [X days]       | Testing sign-off                              |
| Support window         | [X weeks]      | Go-live                                       |
| **Total elapsed**      | **[X weeks]**  |                                               |

> Elapsed time assumes [N] developers working in parallel and client feedback
> within [X] business days at each approval gate.

---

## Key Assumptions

The following assumptions are built into this estimate. Changes to these
assumptions may require a revised estimate.

1. [Assumption about tech stack — e.g. "Existing React frontend, Node.js backend"]
2. [Assumption about environment — e.g. "AWS infrastructure already provisioned"]
3. [Assumption about client availability — e.g. "Stakeholder available for 2x 1-hour sessions during planning"]
4. [Assumption about third-party APIs — e.g. "Stripe API documentation is current and accurate"]
5. [Assumption about scope stability — e.g. "Core requirements are stable; minor changes covered by contingency"]

---

## Risks and Mitigations

| Risk     | Likelihood   | Impact       | Mitigation         |
| ----------| --------------| --------------| --------------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [How it's handled] |
| [Risk 2] |              |              |                    |
| [Risk 3] |              |              |                    |

---

## What Happens Next

To proceed with this project:

1. **Review and approve this estimate** — confirm scope, timeline, and budget
2. **Schedule a kickoff** — [X]-hour session to align on requirements and approach
3. **Sign off on planning artifacts** — after the AIDLC planning phase, you will
   review and approve requirements, user stories, and technical design before
   development begins
4. **Development begins** — each unit of work goes through design → code → review
   → test before being marked complete

You will have visibility and approval rights at every stage. Nothing moves to
the next phase without your sign-off.

---

## Revision History

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | [date] | [name] | Initial estimate |

---

---

# INTERNAL ESTIMATION WORKINGS
## Share with your manager / tech lead — do not send to client

> This section shows how the estimate was derived. Use it to justify the
> numbers if challenged, brief your manager before client discussions, or
> hand off to another estimator to revise.

**Input mode:** [A — plain description | B — AIDLC units-of-work]
**Project size classification:** [Micro | Small | Medium | Large | Enterprise]

### Module Breakdown (Phase 1)

| #   | Module | Base Rounds | Risk Coeff | Effective Rounds | Complexity | Notes |
| -----| --------| -------------| ------------| ------------------| ------------| -------|
| 1   |        |             |            |                  |            |       |
| 2   |        |             |            |                  |            |       |
| 3   |        |             |            |                  |            |       |

**Integration rounds:** +[X] ([Y]% of base)
**Total effective rounds:** [Z]
**Review factor:** [N] min/round ([complexity level])
**Code generation hours:** [H] hours

### Phase 2 Calculation

| Category                     | Hours | Basis                            |
| ------------------------------| -------| ----------------------------------|
| Code generation              |       | Phase 1 output                   |
| AIDLC planning               |       | [Size profile used]              |
| Developer testing support    |       | Bug fixes + QA team support only |
| Developer deployment support |       | Runbook + go-live support only   |
| Meetings                     |       | [Size profile used]              |
| Documentation                |       | [Size profile used]              |
| Developer support window     |       | Post-launch availability only    |
| **Subtotal**                 |       |                                  |
| **Contingency**              |       | [X]% — [reason for rate chosen]  |
| **Total**                    |       |                                  |

> Scope: developer hours only. QA team, deployment team, and support team
> estimates are produced separately by those teams.

### Estimation Notes

- [Any deviations from standard size profiles and why]
- [Modules with unusually high or low round counts and the reasoning]
- [Items that were borderline between size classifications]
- [Mode A: note that decomposition was AI-generated and should be validated in planning]
