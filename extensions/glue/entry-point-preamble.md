# AI-DLC + Superpowers Workflow

> This preamble is prepended to the AIDLC core-workflow.md entry point.
> It does two things the upstream cannot do on its own:
> 1. Prevents skipping AIDLC phases under user pressure
> 2. Tells the agent where to find the Superpowers handoff file at Code Generation

## MANDATORY: Do Not Skip Phases

Follow every AIDLC phase in sequence. If the user asks to skip a stage, explain
why it matters and offer a lightweight version rather than skipping it entirely.
Do not invoke Superpowers skills during Inception or Construction design stages —
skills are only for Code Generation and later.

---

## MANDATORY: Superpowers Handoff at Code Generation

When you reach Code Generation Part 2, read the Superpowers handoff file before
writing a single line of code. Resolve the path using the first that exists:

- `.kiro/aws-aidlc-rule-details/extensions/glue/superpowers-handoff.md` (Kiro)
- `.amazonq/aws-aidlc-rule-details/extensions/glue/superpowers-handoff.md` (Amazon Q)
- `.aidlc-rule-details/extensions/glue/superpowers-handoff.md` (all other IDEs)

---

