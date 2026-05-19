# Org Standards Extensions

Place your organisation-specific rules here. These are loaded as AIDLC extensions
and become blocking constraints at each workflow stage.

## Included rules (always enforced)

| File | Purpose |
|---|---|
| `mcp-requirements.md` | Pre-flight MCP availability checks; subagent MCP tool guidance |

## How to add a rule file

1. Create a `.md` file in this directory (or a subdirectory)
2. Structure each rule as:
   ```markdown
   ## Rule ORG-NN: Title
   ### Rule
   [What is required]
   ### Verification
   [How the agent checks compliance before proceeding]
   ```
3. Rule IDs must be unique across all loaded extensions (use a prefix like
   `ORG-`, `SEC-`, `COMP-` etc.)
4. To make a rule opt-in rather than always-enforced, add a matching
   `<name>.opt-in.md` file alongside it (see Jira/Confluence examples)

## Examples of what belongs here

- Coding standards specific to your stack
- Security policies beyond the AIDLC baseline
- Compliance requirements (SOC2, HIPAA, PCI-DSS etc.)
- Naming conventions for your project
- Required reviewers or approval gates
- Documentation standards

## Examples of what does NOT belong here

- Generic best practices already covered by AIDLC or Superpowers
- Rules that should be contributed back to awslabs/aidlc-workflows
