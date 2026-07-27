# Organization Standards

This directory is optional. When present, the v2 installer combines these
Markdown files into a managed block in the active space's
`aidlc/spaces/default/memory/team.md`.

That makes them team practices in AI-DLC v2. The framework itself does not
require this directory; it already ships its baseline in `memory/org.md`.

## Included rules (always enforced)

| File | Purpose |
|---|---|
| `mcp-requirements.md` | Pre-flight MCP availability checks; subagent MCP tool guidance |

## Authoring

Create a `.md` file with concise, imperative guidance under topical `##`
headings. AI-DLC v2 treats the content as additive team memory; it does not
parse v1 rule IDs, `### Rule`/`### Verification` blocks, or `.opt-in.md` files.

Use this surface for requirements a reviewer would reject when violated. Put
reference material in `extensions/knowledge/` and optional behavior in a skill.

## Examples of what belongs here

- Coding standards specific to your stack
- Security policies beyond the AIDLC baseline
- Compliance requirements (SOC2, HIPAA, PCI-DSS etc.)
- Naming conventions for your project
- Required reviewers or approval gates
- Documentation standards

## Examples of what does NOT belong here

- Generic best practices already covered by AI-DLC
- Rules that should be contributed back to awslabs/aidlc-workflows
