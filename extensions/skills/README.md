# Custom Skills

Add your own AI-DLC v2-compatible skills here. Each skill lives in its own
subdirectory with a `SKILL.md` file:

```
extensions/skills/
  my-skill/
    SKILL.md
```

`setup.sh` copies everything here into the selected harness's native skills
directory. The upstream AI-DLC engine remains separate from these team-owned
skills.

## What belongs here

Skills that are specific to your team or workflow and not suitable for
contributing back to AI-DLC upstream. Examples:

- Company-specific coding standards enforced as a skill
- Domain-specific patterns (e.g. your internal API conventions)
- Workflow extensions that depend on your org's tooling

## What does NOT belong here

- Skills that duplicate the AI-DLC engine's own orchestrator, state machine, or
  approval-gate behavior
- Generic skills that would be useful to every AI-DLC user — contribute those
  upstream to https://github.com/awslabs/aidlc-workflows instead

The v2 engine owns coordination, delegation, review, and workflow state. A team
skill should add domain context or a repeatable team workflow rather than
reimplementing those engine responsibilities.
