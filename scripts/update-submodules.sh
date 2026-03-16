#!/usr/bin/env bash
# =============================================================================
# update-submodules.sh
#
# Idempotent submodule initialisation and update.
# Safe to run on a fresh clone, an existing checkout, or after adding new
# submodules to .gitmodules.
#
# Usage:
#   bash scripts/update-submodules.sh              # update all submodules
#   bash scripts/update-submodules.sh <path>       # update one submodule
#
# Behaviour:
#   - Inits any submodules that have never been cloned
#   - Updates all submodules to the SHA recorded in the parent repo
#   - Recurses into nested submodules
#   - Prints a clear summary of what changed
# =============================================================================
set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${GREEN}[submodules]${NC} $*"; }
warn()  { echo -e "${YELLOW}[submodules]${NC} $*"; }
step()  { echo -e "${CYAN}[submodules]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

# ── Guard: nothing to do if no .gitmodules ────────────────────────────────────

if [[ ! -f ".gitmodules" ]]; then
    warn "No .gitmodules found in repo root — nothing to do."
    exit 0
fi

# ── Optional single-submodule path argument ───────────────────────────────────

TARGET_PATH="${1:-}"

# ── Check we are inside a git repo ───────────────────────────────────────────

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: not inside a git repository." >&2
    exit 1
fi

# ── Collect submodule list ────────────────────────────────────────────────────

# git submodule status exits 0 even with uninitialised modules (shown as '-')
SUBMODULE_STATUS="$(git submodule status --recursive 2>/dev/null || true)"

if [[ -z "$SUBMODULE_STATUS" ]]; then
    warn ".gitmodules exists but no submodules are registered yet."
    exit 0
fi

# Count uninitialised (lines starting with '-') and outdated (lines starting with '+')
UNINIT_COUNT=$(echo "$SUBMODULE_STATUS" | grep -c '^-' || true)
OUTDATED_COUNT=$(echo "$SUBMODULE_STATUS" | grep -c '^+' || true)
TOTAL_COUNT=$(echo "$SUBMODULE_STATUS" | grep -c '.' || true)

step "Found ${TOTAL_COUNT} submodule(s) — ${UNINIT_COUNT} uninitialised, ${OUTDATED_COUNT} outdated"

# ── Init + update ─────────────────────────────────────────────────────────────

if [[ -n "$TARGET_PATH" ]]; then
    step "Updating single submodule: ${TARGET_PATH}"
    git submodule update --init --recursive -- "${TARGET_PATH}"
else
    step "Updating all submodules..."
    git submodule update --init --recursive
fi

# ── Report final state ────────────────────────────────────────────────────────

echo ""
info "Submodule state after update:"
git submodule status --recursive | while IFS= read -r line; do
    PREFIX="${line:0:1}"
    REST="${line:1}"
    case "$PREFIX" in
        ' ') echo -e "  ${GREEN}✓${NC} ${REST}" ;;   # up to date
        '+') echo -e "  ${YELLOW}↑${NC} ${REST}" ;;  # newer than recorded SHA (shouldn't happen after update)
        '-') echo -e "  ${RED}✗${NC} ${REST}" ;;     # still uninitialised (shouldn't happen)
        'U') echo -e "  ${RED}⚠${NC} ${REST}" ;;    # merge conflict
        *)   echo "    ${line}" ;;
    esac
done

echo ""
info "Done ✓"
