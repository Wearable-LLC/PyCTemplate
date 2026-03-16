#!/usr/bin/env bash
set -euo pipefail

echo "── Installing git hooks ───────────────────────────────────────────────────"
bash scripts/install-hooks.sh

echo "── Initialising submodules ────────────────────────────────────────────────"
bash scripts/update-submodules.sh

# ── Python dependencies (opt-in) ──────────────────────────────────────────────
# If this repo has a pyproject.toml, sync the Python environment with uv.
# If not, uv is still available but nothing extra runs.
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
