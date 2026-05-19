# ⛔ BEFORE YOU DO ANYTHING — READ THIS FIRST

These steps are mandatory before ANY other action, including reading files,
asking questions, or writing a single line of code.

**Step 1 — Resolve your skills directory** (first path that exists):
- `.github/skills/` ← GitHub Copilot
- `.kiro/steering/superpowers-skills/` ← Kiro
- `.amazonq/rules/superpowers-skills/` ← Amazon Q
- `.claude/skills/` ← Claude Code
- `~/.agents/skills/superpowers/` ← global fallback

**Step 2 — Read the `using-superpowers` skill** from that directory. Do it now.

**Step 2b — Read the `coordinating-agent` skill.** This defines your role for
the entire session.

**Step 3 — Classify the request** (Type A/B/C/D/E — see Task Classification
below).

**Step 4 — If this involves ANY code, tests, debugging, or implementation:**
Read the `subagent-driven-development` skill now. You will dispatch subagents.
You will not write code yourself.

**Step 5 — Check the Red Flags list:**

| If you are thinking this... | It means... |
|---|---|
| "I'll just write this file quickly" | STOP. Dispatch a subagent. |
| "I know what this needs, let me implement it" | STOP. Dispatch a subagent. |
| "I'll dispatch a subagent after I get started" | STOP. Dispatch first, always. |
| "This is a small change, subagent is overkill" | STOP. No exceptions. |
| "Let me explore the codebase first" | STOP. Read skills first, they tell you how. |
| "I need more context before reading skills" | STOP. Skills come before everything. |
| "I remember what this skill says" | STOP. Skills evolve. Read the current version. |

**The main agent NEVER writes implementation code. NEVER. Not even one line.**
Dispatch a subagent for every coding task. This is not optional.

---
