# AI-DLC Workflow Kit

This repository distributes AI-DLC Workflows v2 and organization-owned overlays.
The upstream runtime is the baseline; this repository owns the lock file, team
rules, knowledge, and extra skills.

## First Action

When working on this repository, inspect the relevant source under `extensions/`
or `setup.sh`. Do not edit a copied AI-DLC engine in a consuming project to
add organization policy. Change the overlay source here instead.

## Distribution Contract

`setup.sh` is the single installer entry point. The installer:

1. Reads the reviewed revision in `upstream.lock` from `vendor/aidlc-workflows/`.
2. Copies one approved AI-DLC v2 distribution from the vendored `dist/<harness>/`.
3. Preserves project-owned `aidlc/` state and learning files.
4. Applies managed organization-rule blocks to `aidlc/spaces/default/memory/team.md`.
5. Installs team knowledge and native harness skills.
6. Runs the harness doctor unless explicitly skipped.

The supported harnesses are GitHub Copilot in VS Code, Claude Code, Kiro IDE,
Kiro CLI, Codex CLI, and opencode. Copilot uses the kit's global adapter; the
other harnesses use their official v2 project distributions. Cursor, Cline, and
Amazon Q are not supported.

## Team-Owned Surfaces

| Surface | Source | Consuming project destination |
|---|---|---|
| Mandatory rules | `extensions/org-standards/` | `aidlc/spaces/default/memory/team.md` |
| Reference knowledge | `extensions/knowledge/` | `aidlc/spaces/default/knowledge/` |
| Extra skills | `extensions/skills/` | native harness skills directory, or `~/.copilot/skills/` |
| Workflow skills | `extensions/workflows/` | native harness skills directory, or `~/.copilot/skills/` |

AI-DLC's learning loop writes project and team practices under the active
space. Installer updates must preserve those files. Managed blocks use
`ai-workflow-kit:<id>:start/end` markers and may be replaced only by the
installer.

## Workspace Model

AI-DLC v2 stores state and artifacts under the consuming project's neutral
`aidlc/` workspace. A flat v1 `aidlc-docs/` workspace is legacy input and may be
migrated by AI-DLC v2 on first run; never delete it automatically.

## Upstream Rules

- Pin upstream changes in `upstream.lock`; do not use a floating `latest` release.
- Run `scripts/update-upstream.sh` only as a maintainer operation; developers
  install the committed vendor snapshot offline.
- Copy generated `dist/<harness>/` output; do not patch `core/` or generated files.
- Use the upstream plugin mechanism for additive stages, agents, sensors, and
  contributions.
- Use the upstream harness-porting guide before adding another IDE.
- Keep organization policy in overlays, not in the framework runtime.
