#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENDOR_DIR="$KIT_ROOT/vendor/aidlc-workflows"

# shellcheck disable=SC1090
source "$KIT_ROOT/upstream.lock"

version_file="$VENDOR_DIR/core/tools/aidlc-version.ts"
[[ -f "$version_file" ]] || { printf '[error] vendor is missing: %s\n' "$version_file" >&2; exit 1; }

vendor_version="$(sed -n 's/.*AIDLC_VERSION = "\([^"]*\)".*/\1/p' "$version_file" | head -1)"
[[ "$vendor_version" == "$LOCK_AIDLC_VERSION" ]] \
  || { printf '[error] lock version %s != vendor version %s\n' "$LOCK_AIDLC_VERSION" "$vendor_version" >&2; exit 1; }

for harness in claude kiro kiro-ide codex opencode; do
  [[ -d "$VENDOR_DIR/dist/$harness" ]] \
    || { printf '[error] vendor is missing dist/%s\n' "$harness" >&2; exit 1; }
done

command -v bun >/dev/null 2>&1 \
  || { printf '[error] bun is required for the upstream package drift check\n' >&2; exit 1; }

bun "$VENDOR_DIR/scripts/package.ts" --check
printf 'vendor validation passed: AI-DLC %s at %s\n' "$LOCK_AIDLC_VERSION" "$LOCK_AIDLC_COMMIT"