# Custom Skills

Add your own Superpowers-compatible skills here. Each skill lives in its own
subdirectory with a `SKILL.md` file:

```
extensions/skills/
  my-skill/
    SKILL.md
```

`setup.sh` copies everything here into the IDE's skills directory alongside the
upstream Superpowers skills. For Kiro, `inclusion: manual` front-matter is
injected automatically so skills are not auto-loaded into context.

## What belongs here

Skills that are specific to your team or workflow and not suitable for
contributing back to obra/superpowers. Examples:

- Company-specific coding standards enforced as a skill
- Domain-specific patterns (e.g. your internal API conventions)
- Workflow extensions that depend on your org's tooling

## What does NOT belong here

- Skills that duplicate or summarise rules already in `extensions/glue/superpowers-handoff.md`
  (the GLUE rules already enforce coordinator behaviour, subagent dispatch, review gates, etc.)
- Generic skills that would be useful to all Superpowers users — contribute those
  upstream to https://github.com/obra/superpowers instead

## Note on the coordinating-agent skill

The `coordinating-agent` skill was removed because its content is fully covered by:
- `extensions/glue/superpowers-handoff.md` (GLUE-01 through GLUE-07)
- The upstream `subagent-driven-development` skill
- The upstream `verification-before-completion` and `requesting-code-review` skills

Having a duplicate summary skill risks the agent loading the weaker version
instead of the authoritative rules.
