# Superpowers Execution Handoff

## Rule GLUE-01: Execution Layer Handoff

When AIDLC reaches the **Code Generation** stage (Construction Phase), you MUST
hand off execution to the Superpowers skills layer. Do not implement code directly
in the planning session.

**Mandatory steps at Code Generation:**

1. Read the `subagent-driven-development` skill from your skills directory
2. Follow it exactly — AIDLC owns the plan content, story traceability, and
   approval gates; Superpowers owns execution mechanics (fresh subagent per task,
   two-stage spec + quality review after each task)
3. The plan file produced by AIDLC Code Planning is the input to
   `subagent-driven-development` — pass it as the plan file path

**The main agent NEVER writes implementation code directly.** Its job during
execution is coordination, context management, and review — not implementation.
Dispatch a subagent for every coding task.

## Rule GLUE-02: Skill Invocation Before Any Response

Before responding to any user message, check whether a Superpowers skill applies.
If there is even a 1% chance a skill is relevant, invoke it. This is not optional.

Skill trigger mapping:

| User intent | Skill to invoke |
|---|---|
| New feature / change | `brainstorming` → `writing-plans` → `subagent-driven-development` |
| Bug / unexpected behaviour | `systematic-debugging` |
| Implementing a plan | `subagent-driven-development` or `executing-plans` |
| Writing any code | `test-driven-development` |
| Claiming work is done | `verification-before-completion` |
| After completing a task | `requesting-code-review` |
| Receiving review feedback | `receiving-code-review` |
| Starting feature branch | `using-git-worktrees` |
| Merging / closing branch | `finishing-a-development-branch` |
| Multiple independent tasks | `dispatching-parallel-agents` |

## Rule GLUE-03: Subagent Context Isolation

When dispatching subagents:
- Provide the full task text directly — do not make the subagent read the plan file
- Include scene-setting context (where this fits, dependencies, architectural notes)
- The subagent must never inherit the main session's conversation history
- The main agent reads only the subagent's summary report, not its full output

This preserves the main agent's context for coordination work across the full
feature lifecycle.
