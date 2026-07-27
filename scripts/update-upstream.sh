#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENDOR_DIR="$KIT_ROOT/vendor/aidlc-workflows"
LOCK_FILE="$KIT_ROOT/upstream.lock"
TMPDIR_WORK="$(mktemp -d)"

REPO_URL="https://github.com/awslabs/aidlc-workflows"
REF="v2"
COMMIT=""
LOCAL_SOURCE=""
SOURCE_DIR=""

info() { printf '  [ok] %s\n' "$*"; }
warn() { printf '  [warn] %s\n' "$*"; }
die() { printf '[error] %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Maintainer-only AI-DLC upstream updater

Usage:
  ./scripts/update-upstream.sh --from-local <checkout>
  ./scripts/update-upstream.sh --ref v2
  ./scripts/update-upstream.sh --ref v2 --commit <sha>

Options:
  --from-local <path>  Archive a reviewed local AI-DLC checkout; no network.
  --repo <url>         Use a fork or mirror instead of awslabs/aidlc-workflows.
  --ref <ref>          Branch or tag to review (default: v2).
  --commit <sha>       Exact commit to vendor; overrides the ref tip.
  --help               Show this help.

The command replaces vendor/aidlc-workflows and updates upstream.lock. Review
the resulting Git diff and run the kit validation before merging the change.
Normal developer setup never runs this command and never contacts upstream.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from-local) [[ $# -ge 2 ]] || die "--from-local requires a path"; LOCAL_SOURCE="$2"; shift 2 ;;
      --repo) [[ $# -ge 2 ]] || die "--repo requires a URL"; REPO_URL="$2"; shift 2 ;;
      --ref) [[ $# -ge 2 ]] || die "--ref requires a value"; REF="$2"; shift 2 ;;
      --commit) [[ $# -ge 2 ]] || die "--commit requires a SHA or ref"; COMMIT="$2"; shift 2 ;;
      --help|-h) usage; exit 0 ;;
      *) die "Unknown option: $1. Use --help for usage." ;;
    esac
  done
}

require() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required. $2"
}

read_version() {
  local version_file="$1/core/tools/aidlc-version.ts"
  [[ -f "$version_file" ]] || die "Missing AI-DLC version file: $version_file"
  sed -n 's/.*AIDLC_VERSION = "\([^"]*\)".*/\1/p' "$version_file" | head -1
}

prepare_source() {
  local source_dir
  if [[ -n "$LOCAL_SOURCE" ]]; then
    source_dir="$(cd "$LOCAL_SOURCE" 2>/dev/null && pwd)" \
      || die "Local AI-DLC checkout not found: $LOCAL_SOURCE"
    git -C "$source_dir" diff --quiet || die "Local AI-DLC checkout has unstaged changes: $source_dir"
    git -C "$source_dir" diff --cached --quiet || die "Local AI-DLC checkout has staged changes: $source_dir"
    COMMIT="${COMMIT:-$(git -C "$source_dir" rev-parse HEAD)}"
    git -C "$source_dir" cat-file -e "$COMMIT^{commit}" \
      || die "Commit not found in local AI-DLC checkout: $COMMIT"
    COMMIT="$(git -C "$source_dir" rev-parse "$COMMIT")"
    SOURCE_DIR="$source_dir"
    return 0
  fi

  require git "Install Git before updating the vendored upstream."
  info "Cloning $REPO_URL for maintainer review"
  git clone --quiet --filter=blob:none "$REPO_URL" "$TMPDIR_WORK/source"
  if [[ -n "$COMMIT" ]]; then
    git -C "$TMPDIR_WORK/source" fetch --quiet origin "$COMMIT"
    git -C "$TMPDIR_WORK/source" checkout --quiet --detach "$COMMIT"
  else
    git -C "$TMPDIR_WORK/source" fetch --quiet origin "$REF"
    git -C "$TMPDIR_WORK/source" checkout --quiet --detach FETCH_HEAD
  fi
  COMMIT="$(git -C "$TMPDIR_WORK/source" rev-parse HEAD)"
  SOURCE_DIR="$TMPDIR_WORK/source"
}

vendor_source() {
  local source_dir="$1"
  local next_dir="$TMPDIR_WORK/vendor"
  mkdir -p "$next_dir"
  git -C "$source_dir" archive --format=tar "$COMMIT" | tar -x -C "$next_dir"

  for harness in claude kiro kiro-ide codex opencode; do
    [[ -d "$next_dir/dist/$harness" ]] || die "Vendored source is missing dist/$harness"
  done
  [[ -n "$(read_version "$next_dir")" ]] || die "Could not read the vendored AI-DLC version"

  local old_dir="$TMPDIR_WORK/previous-vendor"
  if [[ -e "$VENDOR_DIR" ]]; then
    mv "$VENDOR_DIR" "$old_dir"
  fi
  if ! mv "$next_dir" "$VENDOR_DIR"; then
    [[ -e "$old_dir" ]] && mv "$old_dir" "$VENDOR_DIR"
    die "Could not install the new vendor tree"
  fi
  rm -rf "$old_dir"
}

write_lock() {
  local version
  version="$(read_version "$VENDOR_DIR")"
  local lock_tmp="$TMPDIR_WORK/upstream.lock"
  printf 'LOCK_AIDLC_REPO="%s"\n' "$REPO_URL" > "$lock_tmp"
  printf 'LOCK_AIDLC_REF="%s"\n' "$REF" >> "$lock_tmp"
  printf 'LOCK_AIDLC_COMMIT="%s"\n' "$COMMIT" >> "$lock_tmp"
  printf 'LOCK_AIDLC_VERSION="%s"\n' "$version" >> "$lock_tmp"
  mv "$lock_tmp" "$LOCK_FILE"
  info "Locked AI-DLC v$version at $COMMIT"
}

cleanup() { rm -rf "$TMPDIR_WORK"; }
trap cleanup EXIT

main() {
  parse_args "$@"
  prepare_source
  vendor_source "$SOURCE_DIR"
  write_lock
  info "Review the vendor and lock diff before merging."
}

main "$@"