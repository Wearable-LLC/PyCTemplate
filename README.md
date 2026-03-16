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

**New submodule:**
```bash
git submodule add <url> deps/<name>
git commit -m 'chore: add <name> submodule'
# Teammates run:
bash scripts/update-submodules.sh
```
