#!/usr/bin/env bash
# setup.sh — Install AI-DLC + Superpowers + optional integrations
#
# Usage:
#   ./setup.sh                        # detect IDE, install both layers
#   ./setup.sh --ide cursor           # force a specific IDE
#   ./setup.sh --with-jira            # include Jira MCP config
#   ./setup.sh --with-confluence      # include Confluence MCP config
#   ./setup.sh --with-jira --with-confluence
#   ./setup.sh --update               # re-pull upstreams, keep extensions
#
# Supported IDEs: kiro, amazonq, cursor, cline, claudecode, copilot, codex

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
AIDLC_REPO="https://github.com/awslabs/aidlc-workflows"
AIDLC_VERSION="latest"   # set to a tag like "v1.2.0" to pin
SUPERPOWERS_REPO="https://github.com/obra/superpowers"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSIONS_DIR="$SCRIPT_DIR/extensions"
TMPDIR_WORK="$(mktemp -d)"

# ── Flags ─────────────────────────────────────────────────────────────────────
IDE=""
WITH_JIRA=false
WITH_CONFLUENCE=false
UPDATE_ONLY=false

for arg in "$@"; do
  case $arg in
    --ide=*)      IDE="${arg#*=}" ;;
    --ide)        shift; IDE="$1" ;;
    --with-jira)  WITH_JIRA=true ;;
    --with-confluence) WITH_CONFLUENCE=true ;;
    --update)     UPDATE_ONLY=true ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { echo "  ✓ $*"; }
warn()    { echo "  ⚠ $*"; }
section() { echo; echo "▶ $*"; }
die()     { echo "✗ ERROR: $*" >&2; exit 1; }

require() {
  command -v "$1" &>/dev/null || die "$1 is required but not installed. $2"
}

# inject_inclusion_manual <skill_file>
# Ensures the SKILL.md has `inclusion: manual` in its YAML front-matter.
# Works on Git Bash (Windows), macOS, and Linux without relying on sed \n.
inject_inclusion_manual() {
  local skill_file="$1"
  [[ -f "$skill_file" ]] || return 0

  if ! head -1 "$skill_file" | grep -q "^---"; then
    # No front-matter at all — prepend a minimal one
    local tmp_file
    tmp_file="$(mktemp)"
    printf -- '---\ninclusion: manual\n---\n\n' | cat - "$skill_file" > "$tmp_file"
    mv "$tmp_file" "$skill_file"
  elif ! grep -q "inclusion:" "$skill_file"; then
    # Has front-matter but no inclusion key — insert after the opening ---
    # Use Python for portable in-place edit (avoids sed \n portability issues)
    python3 - "$skill_file" <<'PYEOF'
import sys, re
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()
# Insert 'inclusion: manual' after the first '---' line
patched = re.sub(r'^---\n', '---\ninclusion: manual\n', content, count=1)
with open(path, 'w', encoding='utf-8') as f:
    f.write(patched)
PYEOF
  fi
}

# ── IDE Detection ─────────────────────────────────────────────────────────────
detect_ide() {
  if [[ -n "$IDE" ]]; then return; fi

  # Check for IDE-specific marker files/dirs
  # Note: on first run none of these exist yet — use --ide to be explicit
  if [[ -d ".kiro" ]];         then IDE="kiro";       return; fi
  if [[ -d ".amazonq" ]];      then IDE="amazonq";    return; fi
  if [[ -d ".cursor" ]];       then IDE="cursor";     return; fi
  if [[ -d ".clinerules" ]];   then IDE="cline";      return; fi
  if [[ -d ".claude" ]];       then IDE="claudecode"; return; fi
  if [[ -f "CLAUDE.md" ]];     then IDE="claudecode"; return; fi
  if [[ -d ".github" ]];       then IDE="copilot";    return; fi
  if [[ -f "AGENTS.md" ]];     then IDE="codex";      return; fi

  # Try to detect from environment (Kiro sets KIRO_SESSION, Q sets AWS_CODEWHISPERER)
  if [[ -n "${KIRO_SESSION:-}" ]]; then IDE="kiro";    return; fi
  if [[ -n "${KIRO_IDE:-}" ]];     then IDE="kiro";    return; fi

  # Default
  IDE="codex"
  warn "Could not detect IDE — defaulting to AGENTS.md (Codex/generic)."
  warn "For Kiro run: ./setup.sh --ide kiro"
  warn "For Claude Code run: ./setup.sh --ide claudecode"
}

# ── Download AIDLC ────────────────────────────────────────────────────────────
download_aidlc() {
  section "Downloading AIDLC rules from awslabs/aidlc-workflows"
  require curl "Install curl: https://curl.se"
  require unzip "Install unzip via your package manager"

  local zip_url
  if [[ "$AIDLC_VERSION" == "latest" ]]; then
    # Resolve latest release tag via GitHub API
    local tag
    tag=$(curl -fsSL "https://api.github.com/repos/awslabs/aidlc-workflows/releases/latest" \
      | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    [[ -n "$tag" ]] || die "Could not resolve latest AIDLC release tag"
    zip_url="https://github.com/awslabs/aidlc-workflows/releases/download/${tag}/ai-dlc-rules-${tag}.zip"
    info "Latest AIDLC release: $tag"
  else
    zip_url="https://github.com/awslabs/aidlc-workflows/releases/download/${AIDLC_VERSION}/ai-dlc-rules-${AIDLC_VERSION}.zip"
  fi

  curl -fsSL "$zip_url" -o "$TMPDIR_WORK/aidlc.zip" \
    || die "Failed to download AIDLC from $zip_url"
  unzip -q "$TMPDIR_WORK/aidlc.zip" -d "$TMPDIR_WORK/aidlc"
  info "Downloaded and extracted AIDLC rules"

  # Patch the upstream core-workflow.md so Code Generation hands off to Superpowers
  patch_core_workflow "$TMPDIR_WORK/aidlc/aidlc-rules/aws-aidlc-rules/core-workflow.md"
}

# ── Patch upstream core-workflow.md ──────────────────────────────────────────
# The upstream AIDLC core-workflow.md tells the agent to generate code itself
# in Code Generation Part 2. We replace that instruction with the Superpowers
# handoff so the AIDLC workflow itself enforces the handoff — not just the
# preamble sitting above it.
patch_core_workflow() {
  local core_workflow="$1"   # path to the core-workflow.md to patch in-place
  [[ -f "$core_workflow" ]] || return 0

  python3 - "$core_workflow" <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Locate the Code Generation section and replace Part 2 execution step.
# We match the specific upstream text and replace it with the Superpowers handoff.
old = (
    "3. **PART 1 - Planning**: Create code generation plan with checkboxes, get user approval\n"
    "4. **PART 2 - Generation**: Execute approved plan to generate code for this unit"
)
new = (
    "3. **PART 1 - Planning**: Create code generation plan with checkboxes, get user approval\n"
    "4. **PART 2 - Generation (Superpowers handoff — MANDATORY)**:\n"
    "   - Read the Superpowers handoff file (path resolved in the preamble above)\n"
    "   - Follow Rule GLUE-01: read `using-superpowers` skill, then `subagent-driven-development`\n"
    "   - Dispatch a subagent for EVERY coding task — do NOT write implementation code yourself\n"
    "   - Include \"Use the test-driven-development skill\" in every subagent's task text\n"
    "   - After each subagent: invoke `verification-before-completion`, then `requesting-code-review`"
)

if old in content:
    content = content.replace(old, new, 1)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("  ✓ Patched Code Generation Part 2 → Superpowers handoff")
else:
    print("  ⚠ Code Generation patch target not found — upstream may have changed; preamble still enforces handoff")
PYEOF
}

# ── Install AIDLC per IDE ─────────────────────────────────────────────────────
install_aidlc() {
  section "Installing AIDLC rules for IDE: $IDE"

  local rules_src="$TMPDIR_WORK/aidlc/aidlc-rules/aws-aidlc-rules"
  local details_src="$TMPDIR_WORK/aidlc/aidlc-rules/aws-aidlc-rule-details"
  local preamble="$EXTENSIONS_DIR/glue/entry-point-preamble.md"

  [[ -d "$rules_src" ]] || die "Expected aws-aidlc-rules/ in downloaded zip — structure may have changed"

  # assemble_entry_point <dest_file> <upstream_src>
  # Writes: preamble (if present) + upstream content → dest_file
  assemble_entry_point() {
    local dest="$1"
    local src="$2"
    if [[ -f "$preamble" ]]; then
      cat "$preamble" "$src" > "$dest"
    else
      cp "$src" "$dest"
    fi
  }

  case "$IDE" in
    kiro)
      # Kiro auto-loads every .md file in .kiro/steering/ into context.
      # We only want the single AIDLC entry point (core-workflow.md) auto-loaded.
      # Rule-details are read on-demand by the agent — keep them outside steering/.
      mkdir -p .kiro/steering
      # Write a single steering file with Kiro front-matter + preamble + core workflow
      {
        printf -- '---\ndescription: "AI-DLC adaptive workflow for software development"\ninclusion: always\n---\n\n'
        [[ -f "$preamble" ]] && cat "$preamble"
        cat "$rules_src/core-workflow.md"
      } > .kiro/steering/aidlc-workflow.md
      # Rule-details go outside steering/ so they are NOT auto-loaded
      cp -R "$details_src" .kiro/aws-aidlc-rule-details
      info "Installed AIDLC entry point to .kiro/steering/aidlc-workflow.md (auto-loaded)"
      info "Installed rule-details to .kiro/aws-aidlc-rule-details/ (on-demand)"
      ;;
    amazonq)
      mkdir -p .amazonq/rules
      cp -R "$rules_src" .amazonq/rules/
      cp -R "$details_src" .amazonq/
      info "Installed to .amazonq/rules/aws-aidlc-rules/ and .amazonq/aws-aidlc-rule-details/"
      if [[ -f ".amazonq/rules/aws-aidlc-rules/core-workflow.md" ]]; then
        assemble_entry_point \
          "$TMPDIR_WORK/amazonq-entry.md" \
          ".amazonq/rules/aws-aidlc-rules/core-workflow.md"
        mv "$TMPDIR_WORK/amazonq-entry.md" ".amazonq/rules/aws-aidlc-rules/core-workflow.md"
        info "Prepended entry-point preamble to .amazonq/rules/aws-aidlc-rules/core-workflow.md"
      fi
      ;;
    cursor)
      mkdir -p .cursor/rules
      {
        printf -- '---\ndescription: "AI-DLC adaptive workflow for software development"\nalwaysApply: true\n---\n\n'
        [[ -f "$preamble" ]] && cat "$preamble"
        cat "$rules_src/core-workflow.md"
      } > .cursor/rules/ai-dlc-workflow.mdc
      mkdir -p .aidlc-rule-details
      cp -R "$details_src"/. .aidlc-rule-details/
      info "Installed to .cursor/rules/ai-dlc-workflow.mdc and .aidlc-rule-details/"
      ;;
    cline)
      mkdir -p .clinerules
      assemble_entry_point ".clinerules/core-workflow.md" "$rules_src/core-workflow.md"
      mkdir -p .aidlc-rule-details
      cp -R "$details_src"/. .aidlc-rule-details/
      info "Installed to .clinerules/core-workflow.md and .aidlc-rule-details/"
      ;;
    claudecode)
      assemble_entry_point "./CLAUDE.md" "$rules_src/core-workflow.md"
      mkdir -p .aidlc-rule-details
      cp -R "$details_src"/. .aidlc-rule-details/
      info "Installed to CLAUDE.md and .aidlc-rule-details/"
      ;;
    copilot)
      mkdir -p .github
      assemble_entry_point ".github/copilot-instructions.md" "$rules_src/core-workflow.md"
      mkdir -p .aidlc-rule-details
      cp -R "$details_src"/. .aidlc-rule-details/
      info "Installed to .github/copilot-instructions.md and .aidlc-rule-details/"
      ;;
    codex|*)
      assemble_entry_point "./AGENTS.md" "$rules_src/core-workflow.md"
      mkdir -p .aidlc-rule-details
      cp -R "$details_src"/. .aidlc-rule-details/
      info "Installed to AGENTS.md and .aidlc-rule-details/"
      ;;
  esac

  [[ -f "$preamble" ]] && info "Entry-point preamble prepended from extensions/glue/entry-point-preamble.md"
}

# ── Copy extensions into AIDLC rule-details ───────────────────────────────────
install_extensions() {
  section "Installing extensions"

  # Determine where aidlc-rule-details lives for this IDE
  local details_dest
  case "$IDE" in
    kiro)     details_dest=".kiro/aws-aidlc-rule-details" ;;
    amazonq)  details_dest=".amazonq/aws-aidlc-rule-details" ;;
    *)        details_dest=".aidlc-rule-details" ;;
  esac

  mkdir -p "$details_dest/extensions"

  # Glue layer (always installed)
  mkdir -p "$details_dest/extensions/glue"
  cp "$EXTENSIONS_DIR/glue/superpowers-handoff.md" "$details_dest/extensions/glue/"
  info "Installed glue/superpowers-handoff.md → $details_dest/extensions/glue/"

  # Jira (always copy opt-in file; rules file only if --with-jira)
  mkdir -p "$details_dest/extensions/integrations/jira"
  cp "$EXTENSIONS_DIR/integrations/jira/jira-sync.opt-in.md" \
     "$details_dest/extensions/integrations/jira/"
  if $WITH_JIRA; then
    cp "$EXTENSIONS_DIR/integrations/jira/jira-sync.md" \
       "$details_dest/extensions/integrations/jira/"
    info "Installed Jira integration rules"
  else
    info "Installed Jira opt-in prompt (rules not active — re-run with --with-jira to enable)"
  fi

  # Confluence (always copy opt-in file; rules file only if --with-confluence)
  mkdir -p "$details_dest/extensions/integrations/confluence"
  cp "$EXTENSIONS_DIR/integrations/confluence/confluence-sync.opt-in.md" \
     "$details_dest/extensions/integrations/confluence/"
  if $WITH_CONFLUENCE; then
    cp "$EXTENSIONS_DIR/integrations/confluence/confluence-sync.md" \
       "$details_dest/extensions/integrations/confluence/"
    info "Installed Confluence integration rules"
  fi

  # Org standards (copy everything, skip README)
  if compgen -G "$EXTENSIONS_DIR/org-standards/*.md" > /dev/null 2>&1; then
    mkdir -p "$details_dest/extensions/org-standards"
    for f in "$EXTENSIONS_DIR/org-standards/"*.md; do
      [[ "$(basename "$f")" == "README.md" ]] && continue
      cp "$f" "$details_dest/extensions/org-standards/"
      info "Installed org-standard: $(basename "$f")"
    done
  fi
}

# ── Install extension skills into IDE skills directory ────────────────────────
# Called after install_superpowers so extension skills layer on top of upstream.
# Source: extensions/skills/<skill-name>/  (committed, user-maintained)
# Dest:   same IDE skills directory that install_superpowers wrote to
install_extension_skills() {
  local ext_skills_dir="$EXTENSIONS_DIR/skills"
  [[ -d "$ext_skills_dir" ]] || return 0   # nothing to install

  # Count skill dirs that actually contain a SKILL.md
  local count=0
  for d in "$ext_skills_dir"/*/; do
    [[ -f "$d/SKILL.md" ]] && count=$((count + 1))
  done
  [[ $count -eq 0 ]] && return 0

  section "Installing extension skills"

  local home_dir="$HOME"
  local clone_dir="$home_dir/.codex/superpowers"

  case "$IDE" in
    kiro)
      local dest=".kiro/steering/superpowers-skills"
      mkdir -p "$dest"
      for skill_dir in "$ext_skills_dir"/*/; do
        [[ -f "$skill_dir/SKILL.md" ]] || continue   # skip dirs without a SKILL.md
        skill_name="$(basename "$skill_dir")"
        cp -R "$skill_dir" "$dest/$skill_name"
        # Inject inclusion: manual so Kiro doesn't auto-load extension skills either
        inject_inclusion_manual "$dest/$skill_name/SKILL.md"
        info "Installed extension skill: $skill_name → $dest/ (inclusion: manual)"
      done
      ;;
    amazonq)
      local dest=".amazonq/rules/superpowers-skills"
      mkdir -p "$dest"
      for skill_dir in "$ext_skills_dir"/*/; do
        [[ -f "$skill_dir/SKILL.md" ]] || continue
        skill_name="$(basename "$skill_dir")"
        cp -R "$skill_dir" "$dest/$skill_name"
        info "Installed extension skill: $skill_name → $dest/"
      done
      ;;
    claudecode)
      local dest=".claude/skills"
      mkdir -p "$dest"
      for skill_dir in "$ext_skills_dir"/*/; do
        [[ -f "$skill_dir/SKILL.md" ]] || continue
        skill_name="$(basename "$skill_dir")"
        rm -rf "$dest/$skill_name"
        cp -R "$skill_dir" "$dest/$skill_name"
        info "Installed extension skill: $skill_name → $dest/"
      done
      ;;
    copilot)
      local dest=".github/skills"
      mkdir -p "$dest"
      for skill_dir in "$ext_skills_dir"/*/; do
        [[ -f "$skill_dir/SKILL.md" ]] || continue
        skill_name="$(basename "$skill_dir")"
        cp -R "$skill_dir" "$dest/$skill_name"
        # Inject inclusion:manual (Kiro also reads .github/skills/)
        inject_inclusion_manual "$dest/$skill_name/SKILL.md"
        info "Installed extension skill: $skill_name → $dest/ (inclusion: manual)"
      done
      ;;
    cursor|cline|codex|*)
      # These IDEs use the global ~/.agents/skills/superpowers/ path.
      # Copy extension skills alongside upstream skills in the global symlink target.
      local global_skills="$home_dir/.agents/skills/superpowers"
      if [[ -d "$global_skills" || -L "$global_skills" ]]; then
        # Resolve symlink to actual directory
        local real_skills
        real_skills="$(readlink -f "$global_skills" 2>/dev/null || echo "$global_skills")"
        for skill_dir in "$ext_skills_dir"/*/; do
          [[ -f "$skill_dir/SKILL.md" ]] || continue
          skill_name="$(basename "$skill_dir")"
          cp -R "$skill_dir" "$real_skills/$skill_name"
          info "Installed extension skill: $skill_name → $real_skills/"
        done
      else
        warn "Global skills directory not found — extension skills not installed for $IDE"
        warn "Run setup again after Superpowers is cloned, or copy manually:"
        warn "  cp -R $ext_skills_dir/* ~/.agents/skills/superpowers/"
      fi
      ;;
  esac
}

# copy_relevant_skills <src_skills_dir> <dest_dir>
# Copies only the Superpowers skills that are relevant when AIDLC is the planning
# layer. Skills that duplicate AIDLC stages or are Superpowers-internal tooling
# are excluded to avoid confusion and unnecessary context loading.
#
# Excluded (AIDLC replaces them):
#   brainstorming      — AIDLC Inception covers requirements + design
#   writing-plans      — AIDLC Code Generation Part 1 is the plan stage
#   executing-plans    — fallback for no-subagent platforms; AIDLC uses subagent-driven-development
#   writing-skills     — meta-skill for Superpowers contributors, not end users
copy_relevant_skills() {
  local src="$1"
  local dest="$2"
  local excluded="brainstorming writing-plans executing-plans writing-skills"

  mkdir -p "$dest"
  for skill_dir in "$src"/*/; do
    local skill_name
    skill_name="$(basename "$skill_dir")"
    # Skip excluded skills
    local skip=false
    for ex in $excluded; do
      [[ "$skill_name" == "$ex" ]] && skip=true && break
    done
    $skip && continue
    cp -R "$skill_dir" "$dest/$skill_name"
  done
}
install_superpowers() {
  section "Installing Superpowers (obra/superpowers)"
  require git "Install git: https://git-scm.com"

  local home_dir="$HOME"
  local clone_dir="$home_dir/.codex/superpowers"
  local skills_dir="$home_dir/.agents/skills"
  local symlink_target="$skills_dir/superpowers"

  # Clone or update
  if [[ -d "$clone_dir/.git" ]]; then
    info "Superpowers already cloned at $clone_dir — pulling latest"
    git -C "$clone_dir" pull --quiet || warn "Could not pull latest Superpowers (network issue?) — using existing clone"
  else
    info "Cloning obra/superpowers to $clone_dir"
    git clone --quiet --depth=1 https://github.com/obra/superpowers.git "$clone_dir"
  fi

  # Always create ~/.agents/skills/ symlink (cross-IDE standard path)
  mkdir -p "$skills_dir"
  if [[ -L "$symlink_target" ]]; then
    info "Symlink already exists at $symlink_target"
  elif [[ -e "$symlink_target" ]]; then
    warn "$symlink_target exists but is not a symlink — skipping global symlink"
  else
    ln -s "$clone_dir/skills" "$symlink_target" \
      && info "Created symlink: $symlink_target → $clone_dir/skills" \
      || warn "Could not create symlink (try running as Administrator on Windows)"
  fi

  # IDE-specific: copy skills into the IDE's native skills/steering directory
  # so they are visible in the IDE UI and auto-loaded without plugin install
  case "$IDE" in
    kiro)
      local kiro_skills=".kiro/steering/superpowers-skills"
      if [[ -d "$kiro_skills" ]]; then
        rm -rf "$kiro_skills"
      fi
      copy_relevant_skills "$clone_dir/skills" "$kiro_skills"
      while IFS= read -r -d '' skill_file; do
        inject_inclusion_manual "$skill_file"
      done < <(find "$kiro_skills" -name "SKILL.md" -print0)
      info "Copied Superpowers skills to $kiro_skills (inclusion: manual — loaded on demand)"
      ;;
    amazonq)
      local q_skills=".amazonq/rules/superpowers-skills"
      if [[ -d "$q_skills" ]]; then
        rm -rf "$q_skills"
      fi
      copy_relevant_skills "$clone_dir/skills" "$q_skills"
      info "Copied Superpowers skills to $q_skills"
      ;;
    claudecode)
      local claude_skills=".claude/skills"
      mkdir -p "$claude_skills"
      for skill_dir in "$clone_dir/skills"/*/; do
        skill_name="$(basename "$skill_dir")"
        rm -rf "$claude_skills/$skill_name"
      done
      copy_relevant_skills "$clone_dir/skills" "$claude_skills"
      info "Copied Superpowers skills to $claude_skills"
      info "Claude Code also supports the plugin marketplace:"
      info "  /plugin install superpowers@claude-plugins-official"
      ;;
    cursor)
      info "Cursor uses ~/.agents/skills/ for skill discovery"
      info "Cursor also supports the plugin marketplace:"
      info "  /add-plugin superpowers  (in Cursor Agent chat)"
      ;;
    copilot)
      local copilot_skills=".github/skills"
      if [[ -d "$copilot_skills" ]]; then
        rm -rf "$copilot_skills"
      fi
      copy_relevant_skills "$clone_dir/skills" "$copilot_skills"
      # Inject inclusion:manual into every SKILL.md
      while IFS= read -r -d '' skill_file; do
        inject_inclusion_manual "$skill_file"
      done < <(find "$copilot_skills" -name "SKILL.md" -print0)
      info "Copied Superpowers skills to $copilot_skills/ (inclusion: manual — Kiro-safe)"
      info "Skills are also available at ~/.agents/skills/superpowers/ for CLI use"
      ;;
  esac

  info "Superpowers skills available at ~/.agents/skills/superpowers/"
  info "To update later: cd $clone_dir && git pull"
}

# ── MCP Config Merge ──────────────────────────────────────────────────────────
install_mcp_config() {
  if ! $WITH_JIRA && ! $WITH_CONFLUENCE; then return; fi

  section "Configuring Atlassian MCP server"

  # Determine IDE MCP config path
  local mcp_config_path
  case "$IDE" in
    kiro)       mcp_config_path=".kiro/settings/mcp.json" ;;
    claudecode) mcp_config_path=".claude/settings/mcp.json" ;;
    cursor)     mcp_config_path=".cursor/mcp.json" ;;
    copilot)    mcp_config_path=".github/mcp.json" ;;
    *)          mcp_config_path="mcp.json" ;;
  esac

  local mcp_snippet="$EXTENSIONS_DIR/integrations/jira/mcp-config.json"

  if [[ -f "$mcp_config_path" ]]; then
    warn "MCP config already exists at $mcp_config_path"
    warn "Manually merge the Atlassian server entry from:"
    warn "  $mcp_snippet"
    warn "into $mcp_config_path"
  else
    mkdir -p "$(dirname "$mcp_config_path")"
    # Extract just the mcpServers block from the snippet
    python3 -c "
import json, sys
with open('$mcp_snippet') as f:
    data = json.load(f)
out = {'mcpServers': data['mcpServers']}
print(json.dumps(out, indent=2))
" > "$mcp_config_path" 2>/dev/null \
      || cp "$mcp_snippet" "$mcp_config_path"
    info "Created $mcp_config_path with Atlassian MCP server config"
    info "Set environment variables: JIRA_URL, JIRA_USERNAME, JIRA_API_TOKEN"
    info "See docs/WORKING-WITH-INTEGRATIONS.md for full setup instructions"
  fi
}

# ── Cleanup ───────────────────────────────────────────────────────────────────
cleanup() {
  rm -rf "$TMPDIR_WORK"
}
trap cleanup EXIT

# ── Remove stale entry-point files from other IDEs ────────────────────────────
# Each IDE writes its workflow rules to a specific file/directory. When you
# switch IDEs (or re-run setup for a different one), the old files stay on disk
# and confuse agents into thinking there are multiple entry points.
# This function removes every entry-point artifact that does NOT belong to the
# currently selected IDE.
remove_stale_entrypoints() {
  section "Removing stale entry-point files for other IDEs"

  # ── Mid-workflow IDE switch warning ─────────────────────────────────────────
  # If aidlc-docs/aidlc-state.md exists, a workflow is in progress.
  # Switching IDEs is safe (aidlc-docs/ is never touched), but the agent needs
  # to be told to re-read the state file after the switch.
  if [[ -f "aidlc-docs/aidlc-state.md" ]]; then
    # Detect whether any OTHER IDE's entry point currently exists on disk
    # (i.e. this is actually a switch, not just a re-install for the same IDE)
    local other_ide_found=false
    local other_ide_name=""
    local switch_checks=(
      "kiro:.kiro/steering/aidlc-workflow.md"
      "amazonq:.amazonq/rules/aws-aidlc-rules"
      "cursor:.cursor/rules/ai-dlc-workflow.mdc"
      "cline:.clinerules/core-workflow.md"
      "claudecode:CLAUDE.md"
      "copilot:.github/copilot-instructions.md"
      "codex:AGENTS.md"
    )
    for entry in "${switch_checks[@]}"; do
      local owner="${entry%%:*}"
      local path="${entry#*:}"
      if [[ "$owner" != "$IDE" && -e "$path" ]]; then
        other_ide_found=true
        other_ide_name="$owner"
        break
      fi
    done

    if $other_ide_found; then
      echo
      echo "  ⚠ ─────────────────────────────────────────────────────────────"
      echo "  ⚠  MID-WORKFLOW IDE SWITCH DETECTED"
      echo "  ⚠"
      echo "  ⚠  A workflow is in progress (aidlc-docs/aidlc-state.md exists)"
      echo "  ⚠  and you are switching from '$other_ide_name' to '$IDE'."
      echo "  ⚠"
      echo "  ⚠  Your planning artifacts in aidlc-docs/ are safe — they will"
      echo "  ⚠  not be modified. However, after setup completes you MUST"
      echo "  ⚠  tell the agent to resume the workflow:"
      echo "  ⚠"
      echo "  ⚠    'Using AI-DLC, continue work on <your feature>'"
      echo "  ⚠"
      echo "  ⚠  The agent will read aidlc-docs/aidlc-state.md and pick up"
      echo "  ⚠  from the last checkpoint. Do NOT start a new workflow."
      echo "  ⚠ ─────────────────────────────────────────────────────────────"
      echo
    fi
  fi

  # Map: IDE → its entry-point file/dir (the one we DO NOT remove for $IDE)
  # Format: "ide:path_to_remove"
  # Each entry is "owner:path". Only paths whose owner != $IDE are removed.
  # All generated paths are safe to delete — nothing here is a committed asset.
  local all_entrypoints=(
    "kiro:.kiro/steering/aidlc-workflow.md"
    "kiro:.kiro/aws-aidlc-rule-details"
    "kiro:.kiro/steering/superpowers-skills"
    "amazonq:.amazonq/rules/aws-aidlc-rules"
    "amazonq:.amazonq/aws-aidlc-rule-details"
    "amazonq:.amazonq/rules/superpowers-skills"
    "cursor:.cursor/rules/ai-dlc-workflow.mdc"
    "cline:.clinerules/core-workflow.md"
    "claudecode:CLAUDE.md"
    "claudecode:.claude/skills"
    "copilot:.github/copilot-instructions.md"
    "copilot:.github/skills"
    "codex:AGENTS.md"
  )

  # .aidlc-rule-details is shared by cursor/cline/claudecode/copilot/codex
  # Only remove it when switching TO kiro or amazonq (which use their own paths)
  if [[ "$IDE" == "kiro" || "$IDE" == "amazonq" ]]; then
    if [[ -e ".aidlc-rule-details" ]]; then
      rm -rf ".aidlc-rule-details"
      info "Removed .aidlc-rule-details (not used by $IDE)"
    fi
  fi

  local removed=0
  for entry in "${all_entrypoints[@]}"; do
    local owner="${entry%%:*}"
    local path="${entry#*:}"
    # Skip the entry that belongs to the current IDE
    [[ "$owner" == "$IDE" ]] && continue
    if [[ -e "$path" ]]; then
      rm -rf "$path"
      info "Removed stale: $path (was for $owner)"
      removed=$((removed + 1))
    fi
  done

  [[ $removed -eq 0 ]] && info "No stale entry-point files found"
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo
echo "╔══════════════════════════════════════════════════════╗"
echo "║  AI-DLC + Superpowers Setup                          ║"
echo "╚══════════════════════════════════════════════════════╝"

detect_ide
info "Detected IDE: $IDE"

if $UPDATE_ONLY; then
  section "Update mode — re-pulling upstreams only"
  download_aidlc
  install_aidlc
  install_superpowers
  info "Upstreams updated. Extensions and MCP config unchanged."
else
  download_aidlc
  install_aidlc
  install_extensions
  install_superpowers
  install_extension_skills
  install_mcp_config
  remove_stale_entrypoints
fi

echo
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Setup complete                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo
echo "  Planning layer:   awslabs/aidlc-workflows (upstream)"
echo "  Execution layer:  obra/superpowers → ~/.agents/skills/superpowers/"
echo "  Extensions:       extensions/ (this repo)"
echo
echo "  Start a workflow: 'Using AI-DLC, [describe your task]'"
echo
if $WITH_JIRA || $WITH_CONFLUENCE; then
  echo "  Atlassian MCP:    configure env vars, see docs/WORKING-WITH-INTEGRATIONS.md"
  echo
fi
echo "  To update upstreams: ./setup.sh --update"
echo
