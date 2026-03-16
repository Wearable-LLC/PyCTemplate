#!/usr/bin/env bash
# =============================================================================
# sync-template.sh
#
# Pulls the latest shared config files from the upstream cpp-project template
# repo into this project. Run this periodically to stay in sync with tooling
# updates (CI, devcontainer, clang-format, VS Code config).
#
# Usage:
#   bash scripts/sync-template.sh
#
# Configuration:
#   Set TEMPLATE_REPO below to the raw GitHub base URL of your template repo.
#
# What gets synced (project-agnostic files only — your code is never touched):
#   .clang-format
#   .devcontainer/Dockerfile
#   .devcontainer/devcontainer.json
#   .devcontainer/post-create.sh
#   .github/workflows/ci.yml
#   .vscode/extensions.json
#   .vscode/launch.json
#   .vscode/tasks.json
#   scripts/update-submodules.sh
#   scripts/sync-template.sh   (self-update)
# =============================================================================
set -euo pipefail

# ── Configuration — update this URL ──────────────────────────────────────────

TEMPLATE_REPO="https://raw.githubusercontent.com/YOUR_ORG/YOUR_TEMPLATE_REPO/main"

# ── Helpers ───────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

info()  { echo -e "${GREEN}[sync]${NC} $*"; }
warn()  { echo -e "${YELLOW}[sync]${NC} $*"; }
error() { echo -e "${RED}[sync]${NC} $*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Validate config ───────────────────────────────────────────────────────────

if [[ "$TEMPLATE_REPO" == *"YOUR_ORG"* ]]; then
    error "TEMPLATE_REPO is not configured. Edit scripts/sync-template.sh and set the URL."
fi

# Require curl
if ! command -v curl &>/dev/null; then
    error "curl is required but not installed."
fi

# ── Files to sync ─────────────────────────────────────────────────────────────

# Format: "remote/path local/path"
SYNC_FILES=(
    ".clang-format                          .clang-format"
    ".devcontainer/Dockerfile               .devcontainer/Dockerfile"
    ".devcontainer/devcontainer.json        .devcontainer/devcontainer.json"
    ".devcontainer/post-create.sh           .devcontainer/post-create.sh"
    ".github/workflows/ci.yml               .github/workflows/ci.yml"
    ".vscode/extensions.json                .vscode/extensions.json"
    ".vscode/launch.json                    .vscode/launch.json"
    ".vscode/tasks.json                     .vscode/tasks.json"
    "scripts/update-submodules.sh           scripts/update-submodules.sh"
    "scripts/sync-template.sh              scripts/sync-template.sh"
)

# ── Fetch and diff each file ──────────────────────────────────────────────────

UPDATED=0
UNCHANGED=0
FAILED=0

for entry in "${SYNC_FILES[@]}"; do
    REMOTE_PATH="$(echo "$entry" | awk '{print $1}')"
    LOCAL_PATH="$(echo "$entry"  | awk '{print $2}')"
    LOCAL_FULL="${REPO_ROOT}/${LOCAL_PATH}"
    URL="${TEMPLATE_REPO}/${REMOTE_PATH}"

    # Ensure local directory exists
    mkdir -p "$(dirname "$LOCAL_FULL")"

    # Fetch to a temp file
    TMP="$(mktemp)"
    if ! curl -fsSL "$URL" -o "$TMP" 2>/dev/null; then
        warn "Failed to fetch ${REMOTE_PATH} — skipping"
        rm -f "$TMP"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Compare with existing file
    if [[ -f "$LOCAL_FULL" ]] && diff -q "$TMP" "$LOCAL_FULL" > /dev/null 2>&1; then
        UNCHANGED=$((UNCHANGED + 1))
    else
        cp "$TMP" "$LOCAL_FULL"
        # Restore execute bit for shell scripts
        if [[ "$LOCAL_PATH" == *.sh ]]; then
            chmod +x "$LOCAL_FULL"
        fi
        info "Updated: ${LOCAL_PATH}"
        UPDATED=$((UPDATED + 1))
    fi

    rm -f "$TMP"
done

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}Sync complete:${NC}"
echo "  Updated:   ${UPDATED}"
echo "  Unchanged: ${UNCHANGED}"
[[ $FAILED -gt 0 ]] && echo -e "  ${YELLOW}Failed:    ${FAILED}${NC}"
echo ""

if [[ $UPDATED -gt 0 ]]; then
    info "Review changes with: git diff"
    info "Stage and commit:    git add -p && git commit -m 'chore: sync template config'"
fi
