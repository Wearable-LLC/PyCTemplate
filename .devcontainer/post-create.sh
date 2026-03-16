#!/usr/bin/env bash
set -euo pipefail

# ── Normalise line endings ─────────────────────────────────────────────────────
# Converts any CRLF scripts to LF so they run correctly regardless of whether
# the repo was cloned or extracted on Windows.
echo "── Normalising line endings ───────────────────────────────────────────────"
find . \
    \( -name "*.sh" \
    -o -path "*/scripts/hooks/*" \) \
    -not -path "./.git/*" \
    -not -path "./build/*" \
    | xargs dos2unix --quiet 2>/dev/null || true

echo "── Installing git hooks ───────────────────────────────────────────────────"
bash scripts/install-hooks.sh

echo "── Initialising submodules ────────────────────────────────────────────────"
bash scripts/update-submodules.sh

# ── Python dependencies (opt-in) ──────────────────────────────────────────────
if [[ -f "pyproject.toml" ]]; then
    echo "── Installing Python dependencies (uv sync) ───────────────────────────────"
    uv sync
else
    echo "── No pyproject.toml found — skipping uv sync ─────────────────────────────"
fi

echo "── Configuring CMake ──────────────────────────────────────────────────────"
cmake -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DBUILD_TESTS=ON

echo "── Building ───────────────────────────────────────────────────────────────"
cmake --build build --parallel "$(nproc)"

echo "── Running tests ──────────────────────────────────────────────────────────"
ctest --test-dir build --output-on-failure

echo "── Done ✓ ─────────────────────────────────────────────────────────────────"