# my_project

> **Generated from the project C++11 template.**
> Follow the checklist below, then delete everything above the horizontal rule.

## New repo setup checklist

- [ ] Run `bash scripts/init-project.sh <ProjectName>` — renames everything automatically
- [ ] Set `TEMPLATE_REPO` URL in `scripts/sync-template.sh` to your template repo
- [ ] Add your source files to `src/` and `include/`
- [ ] Register them in `CMakeLists.txt` `add_library()`
- [ ] Add test files and register them in `tests/CMakeLists.txt`

---

## Project layout

```
.
├── .devcontainer/
│   ├── Dockerfile              # Base image + apt installs + uv + Python 3.13
│   ├── devcontainer.json       # VS Code Dev Container config
│   └── post-create.sh          # Auto: line endings, hooks, submodules, uv sync, cmake, tests
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions: build & test on every push/PR
├── .vscode/
│   ├── extensions.json         # Recommended extensions (prompted on first open)
│   ├── launch.json             # GDB debug configs (project-name agnostic)
│   └── tasks.json              # CMake build / test / clean tasks
├── scripts/
│   ├── hooks/
│   │   ├── post-checkout       # Auto submodule sync on branch switch
│   │   ├── post-merge          # Auto submodule + uv sync on git pull
│   │   └── post-rewrite        # Auto submodule sync after rebase
│   ├── init-project.sh         # One-shot project initialisation (run once after clone)
│   ├── install-hooks.sh        # Symlinks scripts/hooks/ into .git/hooks/
│   ├── update-submodules.sh    # Idempotent submodule init + update
│   └── sync-template.sh        # Pull latest shared config from the template repo
├── deps/                       # Git submodules go here (created when first submodule is added)
├── include/                    # Public headers
├── src/                        # Library + executable sources
├── tests/                      # GoogleTest suites
├── .clang-format               # Code style (Google base, 4-space indent)
├── .gitattributes              # Enforces LF line endings on all platforms
├── .gitignore
└── CMakeLists.txt
```

---

## Setting up a new C++ project

### Prerequisites (host machine)

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) running
- [VS Code](https://code.visualstudio.com/) with the
  [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Git

### Step 1 — Create the repo from the template

On GitHub, open the template repo and click **"Use this template" → "Create a new
repository"**. Fill in the name, choose your org, click **Create repository**.

### Step 2 — Clone

```bash
git clone git@github.com:YOUR_ORG/your-repo-name.git
cd your-repo-name
```

### Step 3 — Initialise the project

```bash
bash scripts/init-project.sh YourProjectName
```

This script:
- Renames `my_project` → `your_project_name` throughout `CMakeLists.txt`
- Renames placeholder source, header, and test files
- Updates `tests/CMakeLists.txt` with the correct test target name
- Strips the setup checklist from `README.md`
- Installs git hooks via `install-hooks.sh`
- Runs `update-submodules.sh` if `.gitmodules` is present

Both `YourProjectName` (CamelCase) and `your_project_name` (snake_case) are accepted
— the CMake project name is always normalised to snake_case.

### Step 4 — Set the template sync URL

Open `scripts/sync-template.sh` and set `TEMPLATE_REPO` to the raw GitHub URL of
the template repo:

```bash
TEMPLATE_REPO="https://raw.githubusercontent.com/YOUR_ORG/cpp-project-template/main"
```

Commit the change:

```bash
git add scripts/sync-template.sh
git commit -m "chore: set template sync URL"
git push
```

### Step 5 — Open in Dev Container

Open VS Code in the repo directory:

```bash
code .
```

VS Code will detect `.devcontainer/devcontainer.json` and show a notification in
the bottom-right corner: **"Reopen in Container"**. Click it.

If the notification does not appear, open the Command Palette
(`Ctrl+Shift+P` / `Cmd+Shift+P`) and run:
**Dev Containers: Reopen in Container**

### Step 6 — Wait for post-create to complete

The first open builds the Docker image and runs `post-create.sh`. Watch the
**Terminal** panel — it runs through these steps automatically:

```
── Normalising line endings
── Installing git hooks
── Initialising submodules        ← no-op if no .gitmodules yet
── No pyproject.toml found — skipping uv sync
── Configuring CMake
── Building
── Running tests
── Done ✓
```

The placeholder test (`PlaceholderTest.AlwaysPasses`) should pass. If the
terminal closes before you see **Done ✓**, click **Terminal → New Terminal** and
check the output with:

```bash
cat /tmp/post-create.log 2>/dev/null || echo "log not found"
```

### Step 7 — Verify the environment

In the container terminal:

```bash
# Compiler and build tools
g++ --version
cmake --version
ninja --version

# Python (always available even without pyproject.toml)
uv --version
python3 --version          # Python 3.13.x

# Git hooks installed
ls -la .git/hooks/         # post-checkout, post-merge, post-rewrite → symlinks

# Build output
./build/your_project_name  # runs the placeholder executable
```

---

## Setting up a new C++ + Python project

Follow **all steps above**, then continue with the steps below before opening
the Dev Container (Step 5).

### Step 3b — Initialise Python tooling

After running `init-project.sh`, add Python tooling:

```bash
# Creates pyproject.toml — the signal that activates uv sync in post-create.sh
uv init --no-workspace

# Pin Python version explicitly (committed to the repo)
uv python pin 3.13
```

### Step 3c — Add dependencies

```bash
uv add numpy scipy              # runtime dependencies
uv add --dev pytest             # development-only dependencies
```

### Step 3d — Commit Python config before opening the container

`post-create.sh` checks for `pyproject.toml` at container start — it must be
present before the container opens. Also remove `uv.lock` from `.gitignore`
since lockfiles should be committed for reproducibility in mixed projects:

```bash
# Remove or comment out the uv.lock line in .gitignore

git add pyproject.toml uv.lock .python-version .gitignore
git commit -m "chore: initialise Python tooling"
git push
```

Now open the Dev Container (Step 5 above). The `post-create.sh` output will
include the uv sync step:

```
── Normalising line endings
── Installing git hooks
── Initialising submodules
── Installing Python dependencies (uv sync)   ← runs because pyproject.toml exists
── Configuring CMake
── Building
── Running tests
── Done ✓
```

### Step 7b — Configure VS Code Python interpreter

Create `.vscode/settings.json` in the container (this file is gitignored —
each developer does this once locally):

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python"
}
```

Or use the Command Palette: **Python: Select Interpreter** → choose the entry
showing `.venv`.

### Step 7c — Verify Python environment

```bash
uv run python --version            # Python 3.13.x
uv run python -c "import numpy; print(numpy.__version__)"
uv run pytest --version
```

---

## Rebuilding the Dev Container

If you change `Dockerfile`, `devcontainer.json`, or add new apt packages,
rebuild the container to pick up the changes:

**Command Palette → Dev Containers: Rebuild Container**

This re-runs `post-create.sh` from scratch. Use **Rebuild and Reopen in
Container** if you also want to clear the container's filesystem.

> **Note:** `cmake --build` output lives inside the container at
> `${workspaceFolder}/build/`. The `build/` directory is bind-mounted from
> your host so it survives container rebuilds.

---

## Scripts

### `scripts/init-project.sh <ProjectName>`

Run once after creating a repo from this template. Automates everything in the
setup checklist:
- Renames `my_project` → `your_project_name` in `CMakeLists.txt`
- Renames placeholder `.cpp`, `.hpp`, and test files
- Updates `tests/CMakeLists.txt` with the new test target
- Strips the setup checklist from `README.md`
- Installs git hooks via `install-hooks.sh`
- Runs `update-submodules.sh` if `.gitmodules` is present

```bash
bash scripts/init-project.sh TorqueController
# or
bash scripts/init-project.sh torque_controller
```

Both forms produce the CMake project name `torque_controller`.

### `scripts/install-hooks.sh [--force]`

Symlinks the tracked hooks from `scripts/hooks/` into `.git/hooks/`. Idempotent
— safe to re-run. Called automatically by `init-project.sh` and `post-create.sh`.

```bash
bash scripts/install-hooks.sh           # install / refresh hooks
bash scripts/install-hooks.sh --force   # overwrite existing non-symlink hooks
```

### `scripts/update-submodules.sh [path]`

Idempotent submodule initialisation and update. Safe to run on a fresh clone,
an existing checkout, or after adding new submodules. Called automatically by
`post-create.sh`, `init-project.sh`, and the `post-merge`/`post-checkout` hooks.

```bash
bash scripts/update-submodules.sh           # update all submodules
bash scripts/update-submodules.sh deps/hal  # update one submodule
```

### `scripts/sync-template.sh`

Pulls the latest project-agnostic config files (Dockerfile, CI, clang-format,
VS Code config) from the upstream template repo. Set `TEMPLATE_REPO` in the
script to your template repo's raw GitHub URL before using.

```bash
bash scripts/sync-template.sh
git diff                                    # review changes
git add -p && git commit -m 'chore: sync template config'
```

---

## VS Code tasks (`Ctrl+Shift+B`)

| Task | Action |
|---|---|
| `CMake: Build (Debug)` | Configure + build with debug symbols |
| `CMake: Build (Release)` | Configure + build optimised |
| `CMake: Build Tests` | Build all test targets |
| `CTest: Run All` | Build tests then run via ctest |
| `CTest: Run Verbose` | Full per-test output |
| `CMake: Clean` | Remove compiled artefacts |
| `CMake: Clean All` | Delete `build/` and `build-release/` |

## Debug (`F5`)

Select the active CMake target in the status bar, then press `F5`:

- **Debug: Active CMake Target** — run the selected binary under GDB
- **Debug: All Tests** — run the selected test binary with `--gtest_color=yes`
- **Debug: Single Test** — prompt for a `--gtest_filter` pattern before launching

---

## Adding code

**New library source file:**
1. Create `src/my_feature.cpp` and `include/my_feature.hpp`
2. Add `src/my_feature.cpp` to `add_library()` in `CMakeLists.txt`

**New test suite:**
1. Create `tests/test_my_feature.cpp`
2. Add to `tests/CMakeLists.txt`:
   ```cmake
   add_gtest(${PROJECT_NAME}_my_feature_tests test_my_feature.cpp)
   ```

**New Python dependency:**
```bash
uv add requests
git add pyproject.toml uv.lock
git commit -m "chore: add requests"
# Teammates get it automatically on next git pull via the post-merge hook
```

---

## Git submodules

Submodules are tracked via `scripts/update-submodules.sh` and the
`post-checkout`, `post-merge`, and `post-rewrite` git hooks installed by
`install-hooks.sh`. Once the hooks are in place, most submodule updates happen
automatically — the workflows below cover the cases that still require a manual step.

### Convention

Keep all submodules under `deps/` so they are easy to locate and `.gitignore`
rules can target them precisely:

```
deps/
  shared-headers/     ← git submodule
  hal/                ← git submodule
```

### Adding a submodule

```bash
# Add the submodule — pins it to the current HEAD of the default branch
git submodule add git@github.com:YOUR_ORG/shared-headers.git deps/shared-headers

git add .gitmodules deps/shared-headers
git commit -m "chore: add shared-headers submodule"
git push
```

Teammates get it automatically on their next `git pull` — the `post-merge` hook
calls `update-submodules.sh` which inits and clones any uninitialised submodules.

### Pinning a submodule to a specific commit or tag

Submodules record a specific SHA, not a branch. To move the pin:

```bash
cd deps/shared-headers
git fetch
git checkout v2.1.0          # or a specific SHA
cd ../..

git add deps/shared-headers
git commit -m "chore: bump shared-headers to v2.1.0"
git push
```

### Updating a submodule to its remote latest

```bash
git submodule update --remote deps/shared-headers
git add deps/shared-headers
git commit -m "chore: update shared-headers to latest"
git push
```

### Checking submodule status

```bash
git submodule status --recursive              # SHA, path, up-to-date status
git diff HEAD~1 HEAD -- deps/shared-headers   # what SHA changed
git log HEAD~1..HEAD -- deps/shared-headers   # commit that changed it
```

### Removing a submodule

Git has no single remove command — four steps are required:

```bash
# 1. Remove from .gitmodules
git config --file .gitmodules --remove-section submodule.deps/shared-headers

# 2. Remove from .git/config
git config --remove-section submodule.deps/shared-headers

# 3. Remove the tracked directory and cache entry
git rm --cached deps/shared-headers
rm -rf deps/shared-headers

# 4. Remove the submodule data directory
rm -rf .git/modules/deps/shared-headers

# 5. Commit
git add .gitmodules
git commit -m "chore: remove shared-headers submodule"
git push
```

### Using a submodule in CMake

```cmake
# If the submodule is a CMake project
add_subdirectory(deps/shared-headers)
target_link_libraries(${PROJECT_NAME}_lib PRIVATE shared_headers)

# If it is header-only
target_include_directories(${PROJECT_NAME}_lib PUBLIC deps/shared-headers/include)
```

### Manual sync (if hooks are not yet installed)

```bash
bash scripts/update-submodules.sh           # all submodules
bash scripts/update-submodules.sh deps/hal  # one submodule
```