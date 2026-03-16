#!/usr/bin/env bash
# =============================================================================
# install-hooks.sh
#
# Symlinks the tracked hooks from scripts/hooks/ into .git/hooks/.
# Idempotent — safe to re-run; existing symlinks pointing to the same target
# are left alone, stale ones are replaced, and non-symlink files are not
# overwritten without --force.
#
# Usage:
#   bash scripts/install-hooks.sh           # install all hooks
#   bash scripts/install-hooks.sh --force   # overwrite non-symlink files too
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[hooks]${NC} $*"; }
warn()  { echo -e "${YELLOW}[hooks]${NC} $*"; }
error() { echo -e "${RED}[hooks]${NC} $*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HOOKS_SRC="${SCRIPT_DIR}/hooks"
HOOKS_DST="${REPO_ROOT}/.git/hooks"
FORCE="${1:-}"

if [[ ! -d "${REPO_ROOT}/.git" ]]; then
    error "Not a git repository: ${REPO_ROOT}"
fi

if [[ ! -d "$HOOKS_SRC" ]]; then
    warn "No scripts/hooks/ directory found — nothing to install."
    exit 0
fi

INSTALLED=0
SKIPPED=0

for src in "${HOOKS_SRC}"/*; do
    [[ -f "$src" ]] || continue
    hook_name="$(basename "$src")"
    dst="${HOOKS_DST}/${hook_name}"
    abs_src="${HOOKS_SRC}/${hook_name}"

    # Already a symlink pointing to the right place — nothing to do
    if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$abs_src" ]]; then
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Stale symlink — replace it
    if [[ -L "$dst" ]]; then
        rm "$dst"
    # Real file exists and --force not set — warn and skip
    elif [[ -f "$dst" ]] && [[ "$FORCE" != "--force" ]]; then
        warn "Skipping ${hook_name}: a non-symlink file already exists at ${dst}"
        warn "  Run with --force to overwrite it."
        SKIPPED=$((SKIPPED + 1))
        continue
    elif [[ -f "$dst" ]]; then
        rm "$dst"
    fi

    chmod +x "$src"
    ln -s "$abs_src" "$dst"
    info "Installed: .git/hooks/${hook_name} → scripts/hooks/${hook_name}"
    INSTALLED=$((INSTALLED + 1))
done

echo ""
info "Done — installed: ${INSTALLED}, skipped: ${SKIPPED}"
