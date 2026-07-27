#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_FILE="$SCRIPT_DIR/upstream.lock"
EXTENSIONS_DIR="$SCRIPT_DIR/extensions"
TMPDIR_WORK="$(mktemp -d)"

LOCK_AIDLC_REPO="https://github.com/awslabs/aidlc-workflows"
LOCK_AIDLC_REF="v2"
LOCK_AIDLC_COMMIT="c38ba24aa5633b4071fb15b5d654cdb9c7aa9b51"
LOCK_AIDLC_VERSION="2.5.10"
if [[ -f "$LOCK_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$LOCK_FILE"
fi

AIDLC_SOURCE_DIR="$SCRIPT_DIR/vendor/aidlc-workflows"
COPILOT_ROOT="${AIDLC_COPILOT_ROOT:-$HOME/.copilot/aidlc}"
PROJECT_DIR="${AIDLC_PROJECT_DIR:-$PWD}"
PROJECT_DIR_EXPLICIT=false
[[ -n "${AIDLC_PROJECT_DIR:-}" ]] && PROJECT_DIR_EXPLICIT=true
IDE="${AIDLC_IDE:-}"
SKIP_DOCTOR=false
UPDATE_ONLY=false

info() { printf '  [ok] %s\n' "$*"; }
warn() { printf '  [warn] %s\n' "$*"; }
section() { printf '\n==> %s\n' "$*"; }
die() { printf '[error] %s\n' "$*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required. $2"
}

usage() {
  cat <<'EOF'
AI-DLC v2 distribution installer

Usage:
  ./setup.sh --ide <claude|copilot|kiro-ide|kiro-cli|codex|opencode>
  ./setup.sh --update --project-dir <path>

Options:
  --ide <name>              Select Claude, Copilot, Kiro, Codex, or opencode.
  --project-dir <path>      Install into a project other than the current directory.
  --skip-doctor             Install without running the harness health check.
  --update                  Reapply the vendored distribution and team overlays.
  --help                    Show this help.

Normal setup is offline and never contacts upstream. Maintainers update the
vendored source with scripts/update-upstream.sh.

GitHub Copilot uses the user-level VS Code customization locations and does not
copy the AI-DLC engine into projects. Cursor, Cline, and Amazon Q are not
supported by this installer.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ide=*) IDE="${1#*=}"; shift ;;
      --ide) [[ $# -ge 2 ]] || die "--ide requires a value"; IDE="$2"; shift 2 ;;
      --project-dir=*) PROJECT_DIR="${1#*=}"; PROJECT_DIR_EXPLICIT=true; shift ;;
      --project-dir) [[ $# -ge 2 ]] || die "--project-dir requires a value"; PROJECT_DIR="$2"; PROJECT_DIR_EXPLICIT=true; shift 2 ;;
      --skip-doctor) SKIP_DOCTOR=true; shift ;;
      --update) UPDATE_ONLY=true; shift ;;
      --help|-h) usage; exit 0 ;;
      *) die "Unknown option: $1. Use --help for usage." ;;
    esac
  done
}

normalise_ide() {
  case "$IDE" in
    claude|claudecode) IDE="claude" ;;
    copilot) IDE="copilot" ;;
    kiro|kiro-ide) IDE="kiro-ide" ;;
    kiro-cli) IDE="kiro-cli" ;;
    codex) IDE="codex" ;;
    opencode) IDE="opencode" ;;
    cursor|cline|amazonq)
      die "AI-DLC v2 has no official '$IDE' distribution. Use Claude, Copilot, Kiro, Codex, or opencode." ;;
    *) die "Unsupported or missing harness '$IDE'. Choose claude, copilot, kiro-ide, kiro-cli, codex, or opencode." ;;
  esac
}

detect_ide() {
  [[ -n "$IDE" ]] && return
  local detected=()
  [[ -d "$PROJECT_DIR/.claude" ]] && detected+=("claude")
  [[ -d "$PROJECT_DIR/.kiro" ]] && detected+=("kiro-ide")
  [[ -d "$PROJECT_DIR/.codex" ]] && detected+=("codex")
  [[ -d "$PROJECT_DIR/.opencode" ]] && detected+=("opencode")
  if [[ -f "$PROJECT_DIR/.github/copilot-instructions.md" || -d "$PROJECT_DIR/.github/skills" ]]; then
    detected+=("copilot")
  fi
  if [[ ${#detected[@]} -eq 1 ]]; then
    IDE="${detected[0]}"
    return
  fi
  if [[ ${#detected[@]} -gt 1 ]]; then
    die "Multiple AI-DLC harnesses detected (${detected[*]}). Pass --ide explicitly."
  fi
  die "Could not detect an AI-DLC v2 harness. Pass --ide explicitly."
}

dist_name() {
  case "$IDE" in
    claude) printf 'claude' ;;
    copilot) printf 'claude' ;;
    kiro-ide) printf 'kiro-ide' ;;
    kiro-cli) printf 'kiro' ;;
    codex) printf 'codex' ;;
    opencode) printf 'opencode' ;;
  esac
}

harness_dir() {
  case "$IDE" in
    claude) printf '.claude' ;;
    copilot) printf '.claude' ;;
    kiro-ide|kiro-cli) printf '.kiro' ;;
    codex) printf '.codex' ;;
    opencode) printf '.aidlc' ;;
  esac
}

skills_dir() {
  case "$IDE" in
    claude) printf '.claude/skills' ;;
    copilot) printf '%s/skills' "$HOME/.copilot" ;;
    kiro-ide|kiro-cli) printf '.kiro/skills' ;;
    codex) printf '.agents/skills' ;;
    opencode) printf '.aidlc/skills' ;;
  esac
}

ensure_project() {
  [[ -d "$PROJECT_DIR" ]] || die "Project directory does not exist: $PROJECT_DIR"
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
  if [[ "$IDE" != "copilot" && "$PROJECT_DIR" == "$SCRIPT_DIR" && "$PROJECT_DIR_EXPLICIT" != true ]]; then
    die "The kit cannot install AI-DLC into itself. Run from the target project or pass --project-dir <path>."
  fi
  cd "$PROJECT_DIR"
}

ensure_aidlc_source() {
  section "Preparing AI-DLC v2 source"
  AIDLC_SOURCE_DIR="$(cd "$SCRIPT_DIR/vendor/aidlc-workflows" 2>/dev/null && pwd)" \
    || die "Approved AI-DLC source not found at $SCRIPT_DIR/vendor/aidlc-workflows. Run scripts/update-upstream.sh as a maintainer."
  [[ -d "$AIDLC_SOURCE_DIR/dist/$(dist_name)" ]] \
    || die "Approved AI-DLC source has no dist/$(dist_name) tree: $AIDLC_SOURCE_DIR"
  info "Using AI-DLC v${LOCK_AIDLC_VERSION} from $AIDLC_SOURCE_DIR"
}

copy_tree_contents() {
  local source_dir="$1"
  local destination_dir="$2"
  mkdir -p "$destination_dir"
  cp -R "$source_dir"/. "$destination_dir"/
}

copy_workspace_tree() {
  local source_dir="$1"
  local destination_dir="$2"
  mkdir -p "$destination_dir"

  while IFS= read -r -d '' source_file; do
    local relative_path="${source_file#"$source_dir"/}"
    local destination_file="$destination_dir/$relative_path"
    local preserve=false
    case "$relative_path" in
      active-space|spaces/*/active-intent|spaces/*/intents.json|spaces/*/intents/*|spaces/*/codekb/*|spaces/*/knowledge/*|spaces/*/templates/*|spaces/*/memory/team.md|spaces/*/memory/project.md|spaces/*/memory/phases/*)
        preserve=true
        ;;
    esac
    if $preserve && [[ -e "$destination_file" ]]; then
      continue
    fi
    mkdir -p "$(dirname "$destination_file")"
    cp "$source_file" "$destination_file"
  done < <(find "$source_dir" -type f -print0)
}

install_project_file() {
  local source_file="$1"
  local destination_file="$2"
  [[ -f "$source_file" ]] || return 0
  if [[ ! -e "$destination_file" ]]; then
    mkdir -p "$(dirname "$destination_file")"
    cp "$source_file" "$destination_file"
    info "Installed $(basename "$destination_file")"
    return 0
  fi
  if cmp -s "$source_file" "$destination_file"; then
    return 0
  fi
  local conflict_dir="$PROJECT_DIR/.ai-workflow-kit/upstream-conflicts"
  mkdir -p "$conflict_dir"
  cp "$source_file" "$conflict_dir/$(basename "$source_file")"
  warn "Existing $(basename "$destination_file") was preserved; review $conflict_dir/$(basename "$source_file")"
}

install_distribution() {
  section "Installing AI-DLC v2 harness: $IDE"
  local distribution="$AIDLC_SOURCE_DIR/dist/$(dist_name)"
  local engine_destination="$PROJECT_DIR/$(harness_dir)"
  local workspace_source="$distribution/aidlc"

  [[ -d "$workspace_source" ]] || die "AI-DLC v2 workspace shell is missing: $workspace_source"
  copy_tree_contents "$distribution/$(harness_dir)" "$engine_destination"
  case "$IDE" in
    codex) copy_tree_contents "$distribution/.agents" "$PROJECT_DIR/.agents" ;;
    opencode) copy_tree_contents "$distribution/.opencode" "$PROJECT_DIR/.opencode" ;;
  esac
  copy_workspace_tree "$workspace_source" "$PROJECT_DIR/aidlc"

  install_project_file "$distribution/AGENTS.md" "$PROJECT_DIR/AGENTS.md"
  install_project_file "$distribution/.mcp.json" "$PROJECT_DIR/.mcp.json"
  install_project_file "$distribution/opencode.json" "$PROJECT_DIR/opencode.json"
  info "Installed engine to $engine_destination"
  info "Preserved existing project data under $PROJECT_DIR/aidlc"
}

merge_managed_block() {
  local target_file="$1"
  local block_file="$2"
  local block_id="$3"
  local begin="<!-- ai-workflow-kit:$block_id:start -->"
  local end="<!-- ai-workflow-kit:$block_id:end -->"
  local temporary_file="$TMPDIR_WORK/managed-$block_id.md"

  if [[ -f "$target_file" ]] && grep -Fq "$begin" "$target_file" && ! grep -Fq "$end" "$target_file"; then
    die "Managed block '$block_id' is incomplete in $target_file"
  fi

  mkdir -p "$(dirname "$target_file")"
  if [[ ! -f "$target_file" ]]; then
    printf '# Team Practices\n\n' > "$target_file"
  fi

  awk -v begin="$begin" -v end="$end" -v block="$block_file" '
    BEGIN {
      while ((getline line < block) > 0) lines[++count] = line
      close(block)
      inside = 0
      found = 0
    }
    $0 == begin {
      print
      for (i = 1; i <= count; i++) print lines[i]
      inside = 1
      found = 1
      next
    }
    $0 == end {
      if (inside) {
        print
        inside = 0
        next
      }
    }
    !inside { print }
    END {
      if (!found) {
        print ""
        print begin
        for (i = 1; i <= count; i++) print lines[i]
        print end
      }
    }
  ' "$target_file" > "$temporary_file"
  mv "$temporary_file" "$target_file"
  info "Applied managed overlay: $block_id"
}

build_sources() {
  local output_file="$1"
  shift
  : > "$output_file"
  local source_file
  for source_file in "$@"; do
    [[ -f "$source_file" ]] || continue
    cat "$source_file" >> "$output_file"
    printf '\n\n' >> "$output_file"
  done
}

install_org_rules_at() {
  local target_file="$1"
  local block_file="$TMPDIR_WORK/org-rules.md"
  local sources=()
  local source_file
  for source_file in "$EXTENSIONS_DIR/org-standards"/*.md; do
    [[ -f "$source_file" ]] || continue
    [[ "$(basename "$source_file")" == "README.md" ]] && continue
    sources+=("$source_file")
  done
  [[ ${#sources[@]} -gt 0 ]] || return 0
  build_sources "$block_file" "${sources[@]}"
  merge_managed_block "$target_file" "$block_file" "org-rules"
}

install_org_rules() {
  install_org_rules_at "$PROJECT_DIR/aidlc/spaces/default/memory/team.md"
}

install_extra_knowledge() {
  local knowledge_source="$EXTENSIONS_DIR/knowledge"
  [[ -d "$knowledge_source" ]] || return 0
  local knowledge_destination="$PROJECT_DIR/aidlc/spaces/default/knowledge"
  local source_file
  while IFS= read -r -d '' source_file; do
    local relative_path="${source_file#"$knowledge_source"/}"
    local destination_file="$knowledge_destination/$relative_path"
    if [[ -f "$destination_file" ]]; then
      if cmp -s "$source_file" "$destination_file"; then
        continue
      fi
      local conflict_file="$PROJECT_DIR/.ai-workflow-kit/upstream-conflicts/knowledge/$relative_path"
      mkdir -p "$(dirname "$conflict_file")"
      cp "$source_file" "$conflict_file"
      warn "Existing team knowledge was preserved; review $conflict_file"
      continue
    fi
    mkdir -p "$(dirname "$destination_file")"
    cp "$source_file" "$destination_file"
  done < <(find "$knowledge_source" -type f -print0)
  info "Installed team knowledge overlay"
}

install_extra_skills() {
  local destination="$PROJECT_DIR/$(skills_dir)"
  local source_root
  local skill_dir
  local skill_name
  for source_root in "$EXTENSIONS_DIR/skills" "$EXTENSIONS_DIR/workflows"; do
    [[ -d "$source_root" ]] || continue
    for skill_dir in "$source_root"/*/; do
      [[ -f "$skill_dir/SKILL.md" ]] || continue
      skill_name="$(basename "$skill_dir")"
      copy_tree_contents "$skill_dir" "$destination/$skill_name"
      info "Installed team skill: $skill_name"
    done
  done
}

install_copilot_skills() {
  local destination="$HOME/.copilot/skills"
  local source_root
  local skill_dir
  local skill_name
  for source_root in "$EXTENSIONS_DIR/skills" "$EXTENSIONS_DIR/workflows"; do
    [[ -d "$source_root" ]] || continue
    for skill_dir in "$source_root"/*/; do
      [[ -f "$skill_dir/SKILL.md" ]] || continue
      skill_name="$(basename "$skill_dir")"
      copy_tree_contents "$skill_dir" "$destination/$skill_name"
      info "Installed global Copilot skill: $skill_name"
    done
  done
}

rewrite_copilot_markdown() {
  local source_file="$1"
  local destination_file="$2"
  local runtime_ref='$HOME/.copilot/aidlc/runtime/.claude'
  mkdir -p "$(dirname "$destination_file")"
  sed -E \
    -e 's#bun \.claude/tools/aidlc-orchestrate\.ts#bun "$HOME/.copilot/aidlc/aidlc-copilot-runner.ts" orchestrate#g' \
    -e 's#bun \.claude/tools/([A-Za-z0-9._-]+\.ts)#bun "$HOME/.copilot/aidlc/aidlc-copilot-runner.ts" tool \1#g' \
    -e "s#\\.claude/#$runtime_ref/#g" \
    "$source_file" > "$destination_file"
}

install_copilot_vendored_skills() {
  local source_root="$AIDLC_SOURCE_DIR/dist/claude/.claude/skills"
  local destination="$HOME/.copilot/skills"
  local skill_dir
  local skill_name
  for skill_dir in "$source_root"/*/; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    skill_name="$(basename "$skill_dir")"
    rm -rf "$destination/$skill_name"
    copy_tree_contents "$skill_dir" "$destination/$skill_name"
    rewrite_copilot_markdown "$skill_dir/SKILL.md" "$destination/$skill_name/SKILL.md"
    if grep -Fq 'bun .claude/tools/' "$destination/$skill_name/SKILL.md"; then
      die "Copilot skill still contains a project-local Claude tool path: $destination/$skill_name/SKILL.md"
    fi
    info "Installed global Copilot skill: $skill_name"
  done
}

install_copilot_agents() {
  local source_root="$AIDLC_SOURCE_DIR/dist/claude/.claude/agents"
  local destination="$HOME/.copilot/agents"
  local source_file
  local agent_name
  mkdir -p "$destination"
  rm -f "$destination"/aidlc-*.agent.md
  for source_file in "$source_root"/aidlc-*-agent.md; do
    [[ -f "$source_file" ]] || continue
    agent_name="$(basename "$source_file" .md)"
    rewrite_copilot_markdown "$source_file" "$destination/$agent_name.agent.md"
    info "Installed global Copilot agent: $agent_name"
  done
}

install_copilot_hooks() {
  local destination="$HOME/.copilot/hooks/ai-dlc.json"
  mkdir -p "$(dirname "$destination")"
  printf '%s\n' '{' > "$destination"
  printf '%s\n' '  "hooks": {' >> "$destination"
  printf '%s\n' '    "SessionStart": [{"type":"command","command":"bun \"$HOME/.copilot/aidlc/aidlc-copilot-hook.ts\" session-start"}], ' >> "$destination"
  printf '%s\n' '    "UserPromptSubmit": [{"type":"command","command":"bun \"$HOME/.copilot/aidlc/aidlc-copilot-hook.ts\" mint"}], ' >> "$destination"
  printf '%s\n' '    "PreToolUse": [{"type":"command","command":"bun \"$HOME/.copilot/aidlc/aidlc-copilot-hook.ts\" pretool"}], ' >> "$destination"
  printf '%s\n' '    "PostToolUse": [{"type":"command","command":"bun \"$HOME/.copilot/aidlc/aidlc-copilot-hook.ts\" posttool"}], ' >> "$destination"
  printf '%s\n' '    "PreCompact": [{"type":"command","command":"bun \"$HOME/.copilot/aidlc/aidlc-copilot-hook.ts\" precompact"}], ' >> "$destination"
  printf '%s\n' '    "SubagentStop": [{"type":"command","command":"bun \"$HOME/.copilot/aidlc/aidlc-copilot-hook.ts\" subagent-stop"}], ' >> "$destination"
  printf '%s\n' '    "Stop": [{"type":"command","command":"bun \"$HOME/.copilot/aidlc/aidlc-copilot-hook.ts\" stop"}]' >> "$destination"
  printf '%s\n' '  }' >> "$destination"
  printf '%s\n' '}' >> "$destination"
  info "Installed global Copilot hooks"
}

install_copilot_global() {
  section "Installing AI-DLC for GitHub Copilot in VS Code"
  local distribution="$AIDLC_SOURCE_DIR/dist/claude"
  local runtime="$COPILOT_ROOT/runtime/.claude"
  rm -rf "$COPILOT_ROOT/runtime" "$COPILOT_ROOT/memory-seed" "$COPILOT_ROOT/knowledge"
  mkdir -p "$COPILOT_ROOT"
  copy_tree_contents "$distribution/.claude" "$runtime"
  copy_tree_contents "$distribution/aidlc/spaces/default/memory" "$COPILOT_ROOT/memory-seed"
  install_org_rules_at "$COPILOT_ROOT/memory-seed/team.md"
  if [[ -d "$EXTENSIONS_DIR/knowledge" ]]; then
    copy_tree_contents "$EXTENSIONS_DIR/knowledge" "$COPILOT_ROOT/knowledge"
  fi
  cp "$SCRIPT_DIR/scripts/copilot/aidlc-copilot-runtime.ts" "$COPILOT_ROOT/"
  cp "$SCRIPT_DIR/scripts/copilot/aidlc-copilot-runner.ts" "$COPILOT_ROOT/"
  cp "$SCRIPT_DIR/scripts/copilot/aidlc-copilot-hook.ts" "$COPILOT_ROOT/"
  install_copilot_vendored_skills
  install_copilot_skills
  install_copilot_agents
  mkdir -p "$HOME/.copilot/instructions"
  cp "$EXTENSIONS_DIR/copilot/ai-dlc.instructions.md" "$HOME/.copilot/instructions/"
  install_copilot_hooks
  [[ -f "$COPILOT_ROOT/runtime/.claude/tools/aidlc-utility.ts" ]] \
    || die "Copilot runtime is missing the AI-DLC utility"
  [[ -f "$HOME/.copilot/skills/aidlc/SKILL.md" ]] \
    || die "Copilot /aidlc skill was not installed"
  [[ -f "$HOME/.copilot/agents/aidlc-developer-agent.agent.md" ]] \
    || die "Copilot AI-DLC agents were not installed"
  info "Approved runtime installed at $COPILOT_ROOT"
}

warn_about_legacy_workspace() {
  if [[ -f "$PROJECT_DIR/aidlc-docs/aidlc-state.md" ]]; then
    warn "Detected v1 aidlc-docs/ state. AI-DLC v2 can migrate it on the first workflow run; make a branch or backup first."
  fi
}

run_doctor() {
  if [[ "$IDE" == "copilot" ]]; then
    info "Copilot global install checks passed"
    return 0
  fi
  $SKIP_DOCTOR && { warn "Skipped AI-DLC doctor by request"; return 0; }
  require bun "Install Bun before installing AI-DLC v2."
  local tool_dir
  tool_dir="$PROJECT_DIR/$(harness_dir)/tools/aidlc-utility.ts"
  [[ -f "$tool_dir" ]] || die "AI-DLC utility not found after installation: $tool_dir"
  section "Running AI-DLC doctor"
  (cd "$PROJECT_DIR" && bun "$tool_dir" doctor)
}

cleanup() { rm -rf "$TMPDIR_WORK"; }
trap cleanup EXIT

main() {
  parse_args "$@"
  [[ -n "$IDE" ]] && normalise_ide
  ensure_project
  detect_ide
  normalise_ide
  info "Selected harness: $IDE"
  ensure_aidlc_source
  if [[ "$IDE" == "copilot" ]]; then
    install_copilot_global
  else
    install_distribution
    install_org_rules
    install_extra_knowledge
    install_extra_skills
  fi
  warn_about_legacy_workspace
  run_doctor

  printf '\nAI-DLC v2 installation complete.\n'
  printf '  Harness: %s\n' "$IDE"
  printf '  Version: %s (%s)\n' "$LOCK_AIDLC_VERSION" "$LOCK_AIDLC_COMMIT"
  if [[ "$IDE" == "copilot" ]]; then
    printf '  Global runtime: %s\n' "$COPILOT_ROOT"
    printf '  Start: open any project in VS Code and type /aidlc <description>\n'
  else
    printf '  Workspace: %s/aidlc\n' "$PROJECT_DIR"
    printf '  Start: /aidlc <description>\n'
  fi
  printf '  Update: ./setup.sh --update --project-dir <path>\n'
}

main "$@"
