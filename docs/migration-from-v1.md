# Migration from AI-DLC v1 → v2

This page describes the minimal steps and checklist to migrate a project from
AI-DLC v1 to AI-DLC v2 using this kit. v2 includes behavioural and packaging
changes; plan a short maintenance window and create a branch before attempting
the migration.

## Overview

- v2 migrates the old `aidlc-docs/` layout automatically the first time the
  engine runs in a workspace, but some harness-specific files and expectations
  must be refreshed manually (hooks, `dist/<harness>/` runtime trees).
- Always create a branch or backup before migrating.

## Quick migration checklist

1. Create a branch in the project repo:

```bash
git checkout -b migrate/aidlc-v2
```

2. Ensure the developer machine has Bun and the kit's installer available.

3. Option A — migration-only command (recommended): run the installer wrapper
  that performs only the legacy layout conversion:

```bash
./setup.sh --migrate-v1 --project-dir . --ide copilot --dry-run
./setup.sh --migrate-v1 --project-dir . --ide copilot
```

This path is guarded and safe: it only migrates when
`aidlc-docs/aidlc-state.md` exists. If no legacy v1 state is present, it exits
as a no-op. The dry run previews the exact command and expected file changes
without writing migration output.

4. Option B — lightweight workflow start: run the kit's `/aidlc` in the project
  (this also triggers migration, but then continues through normal workflow
  orchestration):

```text
# open the project in the supported IDE and run
/aidlc
```

5. Option C — explicit reapply (recommended for maintainers): copy the vetted
   `dist/<harness>/` from this kit into the project:

```bash
# in the kit repo (maintainer)
./scripts/update-upstream.sh --ref v2
# in the project
./setup.sh --update --project-dir .
```

6. Run health checks and repair:

```bash
./aidlc --doctor
./aidlc --doctor --export   # optional diagnostic bundle
```

7. Address common upgrade items:

- **Codex users:** ensure Codex CLI >= 0.145.0 (v2 relies on compact-source SessionStart). Upgrade the Codex client if needed.
- **Kiro users:** copy `dist/kiro-ide/.kiro/` using content-copy semantics (`cp -R <src>/. <dst>/`) to avoid nested `.kiro` directories.
- **Model pins:** shipped agents no longer hard-pin models — verify any org-owned agents that expect a fixed model and update `tier_cap` or per-agent projection overrides if needed.
- **Reviewer scope enforcement:** PreToolUse reviewer-scope checks may block some reviewer tool calls; if a false-positive occurs set `AIDLC_DISABLE_REVIEWER_SCOPE_HOOK=1` temporarily and file a remediation.

8. Run workflow smoke-tests (start a safe intent, step through the first few stages).

9. When satisfied, merge the migration branch.

## Rollback

- If migration reveals a blocking regression, revert the branch or restore the
  backup. The project `aidlc/` workspace may be left in a partially-upgraded
  state; keep the branch until rollback is complete.

## Further reading

See `vendor/aidlc-workflows/CHANGELOG.md` for detailed v2 release notes and the
upstream docs referenced from this kit.
