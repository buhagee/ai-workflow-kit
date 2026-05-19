# AGENT.md — Single Entry File for All AI Agents

> Read this file first. It tells you which system governs which kind of work.
>
> **Project context is discovered automatically.** The AIDLC workflow detects the workspace, determines if it is greenfield or brownfield, and stores all project-specific context in `aidlc-docs/`. Read `aidlc-docs/aidlc-state.md` if it exists — it is the authoritative record of what has been built, what is in progress, and what comes next.

---

## Two-Layer System

This project uses two complementary systems that work at different stages of development. They do not overlap — each owns a distinct responsibility.

### Layer 1 — Planning (AIDLC)

**Governs**: All planning, requirements, design, architecture, and documentation work.

**Entry point**: `.ai/aidlc/instructions.md`

**Use this layer when**:
- Starting any new feature, change, or investigation
- You need to understand what to build before building it
- Requirements, user stories, or design decisions need to be made
- Architecture or infrastructure choices need to be documented

**Rule details** (loaded on demand during the workflow): `.ai/aidlc/rules/`

---

### Layer 2 — Execution (Superpowers Skills)

**Governs**: All coding, testing, debugging, deployment, and code review work.

**Entry point**: `.ai/skills/using-superpowers/SKILL.md` — invoke this at the start of any execution task.

**Skills directory**: `.ai/skills/`

**Use this layer when**:
- You are writing, modifying, or reviewing code
- You are running or debugging tests
- You are deploying or verifying a build
- You are creating or merging a branch

---

## Handoff Points — When Each Layer Hands Off to the Other

| AIDLC Stage | Triggers this skill |
|---|---|
| Code Generation (Part 1 - Planning) | `writing-plans` — structures the implementation plan |
| Code Generation (Part 2 - Execution) | `subagent-driven-development` or `executing-plans` |
| Any coding work | `test-driven-development` — governs all implementation |
| Before marking a unit done | `verification-before-completion` |
| After a unit is complete | `requesting-code-review` |
| After review feedback arrives | `receiving-code-review` |
| Bug or unexpected behaviour | `systematic-debugging` |
| Starting feature work on a branch | `using-git-worktrees` |
| Merging or closing a branch | `finishing-a-development-branch` |
| Multiple independent tasks | `dispatching-parallel-agents` |

---

## Package Structure Reference

```
[project root]/
│
├── .ai/                            ← ENTIRE AGENT PACKAGE LIVES HERE
│   ├── AGENT.md                    ← YOU ARE HERE — read first
│   ├── aidlc/
│   │   ├── instructions.md         ← AIDLC planning workflow
│   │   └── rules/                  ← Detailed phase rule files
│   │       ├── common/
│   │       ├── inception/
│   │       ├── construction/
│   │       └── operations/
│   └── skills/                     ← Superpowers execution skills
│       ├── using-superpowers/      ← Start here for execution tasks
│       ├── brainstorming/
│       ├── writing-plans/
│       ├── test-driven-development/
│       ├── verification-before-completion/
│       ├── requesting-code-review/
│       ├── receiving-code-review/
│       ├── systematic-debugging/
│       ├── using-git-worktrees/
│       ├── executing-plans/
│       ├── finishing-a-development-branch/
│       ├── dispatching-parallel-agents/
│       ├── subagent-driven-development/
│       └── writing-skills/
│
└── aidlc-docs/                     ← Generated project docs (not part of the package)
    ├── aidlc-state.md
    ├── audit.md
    ├── inception/
    └── construction/
```
