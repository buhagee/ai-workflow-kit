# Getting Started

A concise quickstart for developers and maintainers using this workflow kit.

## Prerequisites

- Git
- Bun (on PATH) — required for packaging, hooks, and some runtime adapters
- A supported host (VS Code + GitHub Copilot, Claude Code, Kiro, Codex, opencode)

## Quickstart — GitHub Copilot (global per developer)

```bash
# clone the kit (once per machine)
git clone <workflow-kit-url>
cd ai-workflow-kit
./setup.sh --ide copilot
```

Verify the runtime and doctor:

```bash
which bun
bun --version
bun "$HOME/.copilot/aidlc/aidlc-copilot-runner.ts" tool aidlc-utility.ts doctor
```

Reload VS Code after the installer completes so Copilot discovers new skills.

## Quickstart — Project-local install (claude / kiro / codex / opencode)

From the kit root, copy the desired harness into an existing project:

```bash
./setup.sh --ide claude --project-dir ../my-project
# or
./setup.sh --ide kiro-ide --project-dir ../my-project
```

Then, in the project folder, run a health check:

```bash
cd ../my-project
# run the bundled doctor for the harness (example uses the installed /aidlc runner)
./aidlc --doctor
```

## Reapplying the vetted runtime to a project

When maintainers update `vendor/aidlc-workflows/`, redeploy the reviewed runtime to projects:

```bash
# in the kit repo (maintainer)
./scripts/update-upstream.sh --ref v2
# in the project
./setup.sh --update --project-dir .
# then verify
./aidlc --doctor
```

## Troubleshooting

- Windows PowerShell may block `bun` installers; run the bun installer in Git Bash or set ExecutionPolicy:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

- If hooks appear not to run on Kiro IDE, ensure you copied the correct `dist/kiro-ide/.kiro/` tree using the content-copy semantics (`cp -R <src>/. <dst>/`).
- If a Copilot install fails, verify `bun` is on PATH and re-run `./setup.sh --ide copilot`.

For deeper diagnostics, use `/aidlc --doctor --export` to produce a redacted diagnostic bundle.
