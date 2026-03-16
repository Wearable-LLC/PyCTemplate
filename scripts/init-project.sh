#!/usr/bin/env bash
# =============================================================================
# init-project.sh
#
# Renames and wires up a new project created from the cpp-project template.
# Safe to run from any directory — always operates on the repo root.
#
# Usage:
#   bash scripts/init-project.sh <ProjectName>
#
# Example:
#   bash scripts/init-project.sh TorqueController
#
# What it does:
#   1. Validates the project name (CamelCase or snake_case, no spaces)
#   2. Replaces 'my_project' in CMakeLists.txt with the snake_case project name
#   3. Renames placeholder source/header/test files
#   4. Removes the setup checklist block from README.md
#   5. Initialises git submodules if any are present
# =============================================================================
set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()    { echo -e "${GREEN}[init]${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

# Resolve repo root regardless of where the script is called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Argument validation ───────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
    echo "Usage: bash scripts/init-project.sh <ProjectName>"
    echo "  ProjectName: alphanumeric + underscores only (e.g. TorqueController or torque_controller)"
    exit 1
fi

INPUT_NAME="$1"

# Reject names with spaces or special characters
if [[ ! "$INPUT_NAME" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]]; then
    error "Invalid project name '${INPUT_NAME}'. Use letters, digits, and underscores only."
fi

# Convert CamelCase → snake_case for CMake (MyProject → my_project)
to_snake() {
    echo "$1" \
        | sed 's/\([A-Z]\)/_\1/g' \
        | sed 's/^_//' \
        | tr '[:upper:]' '[:lower:]'
}

PROJECT_SNAKE="$(to_snake "${INPUT_NAME}")"
PLACEHOLDER="my_project"

info "Initialising project '${INPUT_NAME}' (cmake name: '${PROJECT_SNAKE}')"
info "Repo root: ${REPO_ROOT}"

# Guard: don't re-run if already initialised
if grep -q "^project(${PROJECT_SNAKE}" "${REPO_ROOT}/CMakeLists.txt" 2>/dev/null; then
    warn "CMakeLists.txt already uses '${PROJECT_SNAKE}' — skipping CMake rename."
    CMAKE_DONE=1
else
    CMAKE_DONE=0
fi

# ── 1. Rename project in CMakeLists.txt ──────────────────────────────────────

if [[ $CMAKE_DONE -eq 0 ]]; then
    sed -i "s/project(${PLACEHOLDER}/project(${PROJECT_SNAKE}/" \
        "${REPO_ROOT}/CMakeLists.txt"
    info "CMakeLists.txt: renamed project to '${PROJECT_SNAKE}'"
fi

# ── 2. Rename placeholder source files ───────────────────────────────────────

rename_if_exists() {
    local old="$1" new="$2"
    if [[ -f "$old" && ! -f "$new" ]]; then
        mv "$old" "$new"
        info "Renamed: $(basename "$old") → $(basename "$new")"
    elif [[ -f "$new" ]]; then
        warn "$(basename "$new") already exists — skipping rename."
    fi
}

rename_if_exists \
    "${REPO_ROOT}/src/placeholder.cpp" \
    "${REPO_ROOT}/src/${PROJECT_SNAKE}.cpp"

rename_if_exists \
    "${REPO_ROOT}/include/placeholder.hpp" \
    "${REPO_ROOT}/include/${PROJECT_SNAKE}.hpp"

rename_if_exists \
    "${REPO_ROOT}/tests/test_placeholder.cpp" \
    "${REPO_ROOT}/tests/test_${PROJECT_SNAKE}.cpp"

# ── 3. Update CMakeLists.txt src reference ────────────────────────────────────

if grep -q "src/placeholder.cpp" "${REPO_ROOT}/CMakeLists.txt" 2>/dev/null; then
    sed -i "s|src/placeholder.cpp|src/${PROJECT_SNAKE}.cpp|g" \
        "${REPO_ROOT}/CMakeLists.txt"
    info "CMakeLists.txt: updated src reference to '${PROJECT_SNAKE}.cpp'"
fi

# ── 4. Update tests/CMakeLists.txt ───────────────────────────────────────────

if grep -q "test_placeholder.cpp" "${REPO_ROOT}/tests/CMakeLists.txt" 2>/dev/null; then
    sed -i \
        "s|placeholder_tests test_placeholder.cpp|${PROJECT_SNAKE}_tests test_${PROJECT_SNAKE}.cpp|g" \
        "${REPO_ROOT}/tests/CMakeLists.txt"
    info "tests/CMakeLists.txt: updated test target"
fi

# ── 5. Update placeholder file contents ──────────────────────────────────────

# src file
SRC_FILE="${REPO_ROOT}/src/${PROJECT_SNAKE}.cpp"
if [[ -f "$SRC_FILE" ]] && grep -q "placeholder" "$SRC_FILE"; then
    cat > "$SRC_FILE" << SRCEOF
#include "${PROJECT_SNAKE}.hpp"

// TODO: implement ${PROJECT_SNAKE}
SRCEOF
    info "src/${PROJECT_SNAKE}.cpp: updated contents"
fi

# header file
HDR_FILE="${REPO_ROOT}/include/${PROJECT_SNAKE}.hpp"
if [[ -f "$HDR_FILE" ]] && grep -q "placeholder" "$HDR_FILE"; then
    GUARD="$(echo "${PROJECT_SNAKE}" | tr '[:lower:]' '[:upper:]')_HPP"
    cat > "$HDR_FILE" << HDREOF
#pragma once

// TODO: declare ${PROJECT_SNAKE}
HDREOF
    info "include/${PROJECT_SNAKE}.hpp: updated contents"
fi

# test file
TEST_FILE="${REPO_ROOT}/tests/test_${PROJECT_SNAKE}.cpp"
if [[ -f "$TEST_FILE" ]] && grep -q "Placeholder" "$TEST_FILE"; then
    cat > "$TEST_FILE" << TESTEOF
#include <gtest/gtest.h>
#include "${PROJECT_SNAKE}.hpp"

// TODO: add tests for ${PROJECT_SNAKE}
TEST(${INPUT_NAME}Test, AlwaysPasses) {
    SUCCEED();
}
TESTEOF
    info "tests/test_${PROJECT_SNAKE}.cpp: updated contents"
fi

# ── 6. Strip setup checklist from README.md ──────────────────────────────────

README="${REPO_ROOT}/README.md"
if [[ -f "$README" ]] && grep -q "## New repo setup checklist" "$README"; then
    # Remove everything from the checklist header up to and including the --- divider
    python3 - "$README" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()

out = []
skip = False
for line in lines:
    if line.strip() == "## New repo setup checklist":
        skip = True
        continue
    if skip and line.strip() == "---":
        skip = False
        continue  # drop the divider line too
    if not skip:
        out.append(line)

# Strip leading blank lines
while out and out[0].strip() == "":
    out.pop(0)

with open(path, "w") as f:
    f.writelines(out)
PYEOF
    info "README.md: removed setup checklist"
fi

# ── 7. Install git hooks ──────────────────────────────────────────────────────

info "Installing git hooks..."
bash "${SCRIPT_DIR}/install-hooks.sh"

# ── 8. Submodules ─────────────────────────────────────────────────────────────

if [[ -f "${REPO_ROOT}/.gitmodules" ]]; then
    info "Initialising git submodules..."
    bash "${SCRIPT_DIR}/update-submodules.sh"
else
    info "No .gitmodules found — skipping submodule init"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}✓ Project '${INPUT_NAME}' initialised.${NC}"
echo ""
echo "  Next steps:"
echo "    1. Add your source files to src/ and include/"
echo "    2. Register them in CMakeLists.txt add_library()"
echo "    3. Add test files and register them in tests/CMakeLists.txt"
echo "    4. Run: cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug"
echo "       Or:  Reopen in Dev Container (VS Code builds automatically)"
echo ""
