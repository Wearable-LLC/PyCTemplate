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
│   ├── Dockerfile              # Base image + apt installs
│   ├── devcontainer.json       # VS Code Dev Container config
│   └── post-create.sh          # Auto submodule init + build + test on container start
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions: build & test on every push/PR
├── .vscode/
│   ├── extensions.json         # Recommended extensions (prompted on first open)
│   ├── launch.json             # GDB debug configs (project-name agnostic)
│   └── tasks.json              # CMake build / test / clean tasks
├── scripts/
│   ├── init-project.sh         # One-shot project initialisation (run once after clone)
│   ├── update-submodules.sh    # Idempotent submodule init + update
│   └── sync-template.sh        # Pull latest shared config from the template repo
├── include/                    # Public headers
├── src/                        # Library + executable sources
├── tests/                      # GoogleTest suites
├── .clang-format               # Code style (Google base, 4-space indent)
├── .gitignore
└── CMakeLists.txt
```

## Quick start — new project

```bash
# 1. Clone the repo
git clone <your-repo-url>
cd <your-repo>

# 2. Initialise — renames placeholder files and wires up CMake
bash scripts/init-project.sh MyProjectName

# 3. Open in VS Code and reopen in container, or build locally:
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

## Scripts

### `scripts/init-project.sh <ProjectName>`

Run once after creating a repo from this template. Automates everything in the setup checklist:
- Renames `my_project` → `your_project_name` in `CMakeLists.txt`
- Renames placeholder `.cpp`, `.hpp`, and test files
- Updates `tests/CMakeLists.txt` with the new test target
- Strips the setup checklist from `README.md`
- Runs `update-submodules.sh` if `.gitmodules` is present

```bash
bash scripts/init-project.sh TorqueController
# or
bash scripts/init-project.sh torque_controller
```

Both forms produce the CMake project name `torque_controller`.

### `scripts/update-submodules.sh [path]`

Idempotent submodule initialisation and update. Safe to run on a fresh clone, an existing checkout, or after adding new submodules. Called automatically by `post-create.sh` and `init-project.sh`.

```bash
bash scripts/update-submodules.sh           # update all submodules
bash scripts/update-submodules.sh deps/hal  # update one submodule
```

### `scripts/sync-template.sh`

Pulls the latest project-agnostic config files (Dockerfile, CI, clang-format, VS Code config) from the upstream template repo. Set `TEMPLATE_REPO` in the script to your template repo's raw GitHub URL before using.

```bash
bash scripts/sync-template.sh
git diff                                    # review changes
git add -p && git commit -m 'chore: sync template config'
```

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