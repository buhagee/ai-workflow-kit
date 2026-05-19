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
}

# ── Install AIDLC per IDE ─────────────────────────────────────────────────────
install_aidlc() {
  section "Installing AIDLC rules for IDE: $IDE"

  local rules_src="$TMPDIR_WORK/aidlc/aidlc-rules/aws-aidlc-rules"
  local details_src="$TMPDIR_WORK/aidlc/aidlc-rules/aws-aidlc-rule-details"

  [[ -d "$rules_src" ]] || die "Expected aws-aidlc-rules/ in downloaded zip — structure may have changed"

  case "$IDE" in
    kiro)
      mkdir -p .kiro/steering
      cp -R "$rules_src" .kiro/steering/
      cp -R "$details_src" .kiro/
      info "Installed to .kiro/steering/aws-aidlc-rules/ and .kiro/aws-aidlc-rule-details/"
      ;;
    amazonq)
      mkdir -p .amazonq/rules
      cp -R "$rules_src" .amazonq/rules/
      cp -R "$details_src" .amazonq/
      info "Installed to .amazonq/rules/aws-aidlc-rules/ and .amazonq/aws-aidlc-rule-details/"
      ;;
    cursor)
      mkdir -p .cursor/rules
      {
        printf -- '---\ndescription: "AI-DLC adaptive workflow for software development"\nalwaysApply: true\n---\n\n'
        cat "$rules_src/core-workflow.md"
      } > .cursor/rules/ai-dlc-workflow.mdc
      mkdir -p .aidlc-rule-details
      cp -R "$details_src"/. .aidlc-rule-details/
      info "Installed to .cursor/rules/ai-dlc-workflow.mdc and .aidlc-rule-details/"
      ;;
    cline)
      mkdir -p .clinerules
      cp "$rules_src/core-workflow.md" .clinerules/
      mkdir -p .aidlc-rule-details
      cp -R "$details_src"/. .aidlc-rule-details/
      info "Installed to .clinerules/core-workflow.md and .aidlc-rule-details/"
      ;;
    claudecode)
      cp "$rules_src/core-workflow.md" ./CLAUDE.md
      mkdir -p .aidlc-rule-details
      cp -R "$details_src"/. .aidlc-rule-details/
      info "Installed to CLAUDE.md and .aidlc-rule-details/"
      ;;
    copilot)
      mkdir -p .github
      cp "$rules_src/core-workflow.md" .github/copilot-instructions.md
      mkdir -p .aidlc-rule-details
      cp -R "$details_src"/. .aidlc-rule-details/
      info "Installed to .github/copilot-instructions.md and .aidlc-rule-details/"
      ;;
    codex|*)
      cp "$rules_src/core-workflow.md" ./AGENTS.md
      mkdir -p .aidlc-rule-details
      cp -R "$details_src"/. .aidlc-rule-details/
      info "Installed to AGENTS.md and .aidlc-rule-details/"
      ;;
  esac
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
  info "Installed glue/superpowers-handoff.md"

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

# ── Install Superpowers ───────────────────────────────────────────────────────
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
    git -C "$clone_dir" pull --quiet
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
      cp -R "$clone_dir/skills" "$kiro_skills"
      info "Copied Superpowers skills to $kiro_skills (visible in Kiro steering panel)"
      ;;
    amazonq)
      local q_skills=".amazonq/rules/superpowers-skills"
      if [[ -d "$q_skills" ]]; then
        rm -rf "$q_skills"
      fi
      cp -R "$clone_dir/skills" "$q_skills"
      info "Copied Superpowers skills to $q_skills"
      ;;
    claudecode)
      local claude_skills=".claude/skills"
      mkdir -p "$claude_skills"
      # Copy each skill as a subdirectory (Claude Code skill discovery format)
      for skill_dir in "$clone_dir/skills"/*/; do
        skill_name="$(basename "$skill_dir")"
        rm -rf "$claude_skills/$skill_name"
        cp -R "$skill_dir" "$claude_skills/$skill_name"
      done
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
      info "Copilot also supports the plugin marketplace:"
      info "  copilot plugin marketplace add obra/superpowers-marketplace"
      info "  copilot plugin install superpowers@superpowers-marketplace"
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

# ── Main ──────────────────────────────────────────────────────────────────────
echo
echo "╔══════════════════════════════════════════════════════╗"
echo "║  AI-DLC + Superpowers Setup                          ║"
echo "╚══════════════════════════════════════════════════════╝"

detect_ide
info "Detected IDE: $IDE"

download_aidlc
install_aidlc
install_extensions
install_superpowers
install_mcp_config

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
