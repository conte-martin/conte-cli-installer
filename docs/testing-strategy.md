# Testing Strategy

> **Status:** Reference document — describes the test suite as-is. No behavior changes.
> **Goal:** Identify where to move checks local and where CI minutes are being duplicated.

---

## 1. Test Suite Map

The suite is split across six suite runners and one fast-gate runner. `tests/run.sh` invokes all six sequentially.

```
tests/
  run.sh               ← master: runs all six suites below
  run-fast.sh          ← fast gate: syntax check + 9 unit tests (pre-commit target)
  run-unit.sh          ← 34 unit tests
  run-integration.sh   ← 13 integration tests
  run-hooks.sh         ← 6 hook integration tests  (cross-platform sensitive)
  run-release.sh       ← 7 release integration tests
  run-workspace.sh     ← 3 workspace integration tests
  run-regression.sh    ← 3 regression tests (draws from unit/, integration/, regression/)
```

### Suite contents at a glance

| Runner | Scripts | Parallelised by default |
|---|---|---|
| `run-fast.sh` | syntax check + 9 unit | yes (via runner.sh) |
| `run-unit.sh` | 34 unit | yes |
| `run-integration.sh` | 13 integration | yes |
| `run-hooks.sh` | 6 integration/hooks | yes |
| `run-release.sh` | 7 integration/release | yes |
| `run-workspace.sh` | 3 integration/workspace | yes |
| `run-regression.sh` | 3 mixed | yes |

Parallel job count is controlled by `CONTE_TEST_JOBS` (default varies; CI uses 2–4).

### Orphaned scripts

The following test files exist on disk but are not wired into any runner. They can be run directly but are not exercised by `tests/run.sh`.

**Unit (not in `run-unit.sh`):**

| Script | Notes |
|---|---|
| `tests/unit/branch-validation.sh` | Possible predecessor to split validation-branch-* files |
| `tests/unit/cli-output.sh` | CLI formatting; may be superseded by status/doctor format tests |
| `tests/unit/config-json-parsing.sh` | Low-level JSON parsing |
| `tests/unit/config-parser.sh` | Config parsing; may overlap config-single-parse |
| `tests/unit/config-single-parse.sh` | Config single-parse scenarios |
| `tests/unit/config-store-injection.sh` | Config store injection |
| `tests/unit/config-update-refactor.sh` | Refactor guard |
| `tests/unit/distribution-private-temp.sh` | Private temp dir handling |
| `tests/unit/git-lazy-cache.sh` | Git cache layer |
| `tests/unit/hook-tasks-cache.sh` | Hook task caching |
| `tests/unit/hooks-write-failure.sh` | Hook write error paths |
| `tests/unit/init-progress-messages.sh` | Init progress output |
| `tests/unit/release-rollback.sh` | Release rollback |
| `tests/unit/release-scope-strict-mode.sh` | Strict scope mode; may overlap release-scope-mode |
| `tests/unit/service-changelog.sh` | Service changelog generation |
| `tests/unit/validation.sh` | Top-level validation; may be superseded |

**Integration (not in any runner, but used directly in CI):**

| Script | Notes |
|---|---|
| `tests/integration/update.sh` | Network-dependent; invoked directly in `ci-main.yml` |
| `tests/integration/cli-ux.sh` | CLI UX scenarios; not wired anywhere |

---

## 2. Fast vs Slow Classification

### Fast (< 30 s locally, pure library sourcing or minimal git)

These tests source library files directly and create at most a few trivial git repos.

- `scripts/ci/check-bash-syntax.sh` — `bash -n` on all `.sh` files, ~2 s
- All tests in `tests/run-fast.sh` (9 unit tests):
  - `release-semver.sh`, `release-changelog.sh`, `windows-installer.sh`
  - `commit-scope-validation.sh`, `release-metadata.sh`
  - `status-output-format.sh`, `doctor-output-format.sh`
  - `release-engine.sh`, `merge-rules-main-develop.sh`
- Other unit tests of similar character:
  - `args-normalization.sh`, `workflow-normalization.sh`
  - All `validation-branch-*.sh` and `validation-commit-*.sh` files
  - `validation-config.sh`, `validation-git.sh`
  - `commit-parser-enriched.sh`, `release-internal-filter.sh`, `release-scope-mode.sh`
  - `workspace-services.sh`, `workspace-validation.sh`, `workspace-detection.sh`
  - `init-workspace-configuration.sh`

### Medium (30 s – 3 min, create temp repos, invoke conte CLI)

These create temporary git repos via `create_test_repo` and call `run_conte`.

**Unit (heavier setup):**
- `distribution.sh` — builds tar.gz and zip artifacts
- `history-adoption.sh` — requires commit history
- `uninstall-cleanup.sh` — exercises filesystem cleanup
- `service-release-preview.sh`, `service-release-all-services.sh`, `workspace-service-release.sh`

**Integration (all require temp repos):**
- `lifecycle.sh`, `validate.sh`, `interactive-menus.sh`, `semver.sh`
- `config-scope-mutation.sh`, `merge-rules-commands.sh`, `self-uninstall-compat.sh`
- `init-hooks-disabled.sh`, `doctor-fix.sh`, `init-default-validation.sh`
- `release-breaking-marker.sh`, `release-no-tag-idempotency.sh`, `release-validation.sh`
- `workspace.sh`, `workspace-validation.sh`, `workspace-status-doctor.sh`
- `hooks-install.sh`, `hooks-validation.sh`, `hooks-doctor.sh`

**CI scripts (medium, local-safe):**
- `scripts/ci/release-fixture-validation.sh` — creates repo, runs semver + preview
- `scripts/ci/workspace-fixture-validation.sh` — creates workspace repo, 3 commands

### Slow (> 3 min or special requirements)

- `tests/run-unit.sh` — full unit suite (~2–3 min on modern hardware)
- `tests/run-integration.sh` — 13 integration tests, sequential or low-parallelism
- `tests/run-hooks.sh` — 6 integration tests; slow on Windows due to hook file I/O
- `tests/run-release.sh` — 7 release scenarios with git history
- `tests/run-workspace.sh` — 3 workspace scenarios (multi-service repos)
- `tests/integration/command-hierarchy.sh` — largest single test (~325 assertions)
- `tests/integration/init.sh` — largest integration test (~352 assertions)
- `tests/integration/uninstall.sh` — extensive path-safety coverage
- `tests/integration/remove.sh` — 182 assertions
- `tests/integration/create-release.sh` — full release pipeline
- `tests/integration/workspace-service-release-create.sh` — complex workspace release
- `tests/integration/init-workspace-interactive.sh` — interactive TTY simulation
- `tests/run.sh` — everything, 15–30+ min

### Network-dependent (requires internet or GitHub API)

- `tests/integration/update.sh` — downloads release from GitHub; must remain CI-only
- `scripts/ci/release-notes-from-commits.sh` — uses `git log` against real refs; safe locally only when git history is deep enough (needs `fetch-depth: 0` checkout)

---

## 3. OS-Specific Tests

### Runs on all three OSes (ubuntu, macos, windows)

These must be validated on every platform because behavior diverges:

| Test | Why cross-platform |
|---|---|
| `tests/run-hooks.sh` (6 tests) | Hook file permissions, `core.hooksPath`, executable bits differ between OSes |
| `tests/integration/update.sh` | Self-update path detection and `.cmd` wrapper handling |
| `tests/unit/windows-installer.sh` | Tests `.cmd` wrapper path resolution; runs on all OSes to validate the bash detection logic |
| `tests/unit/distribution.sh` | Tests artifact creation including Windows zip; tar/zip behavior is platform-sensitive |

### Linux/macOS only

| Test | Why |
|---|---|
| `scripts/ci/release-fixture-validation.sh` | Uses `${TMPDIR:-/tmp}` with `mktemp`; run in CI on ubuntu only |
| `scripts/ci/workspace-fixture-validation.sh` | Same |
| `scripts/ci/workspace-validation.sh` | Same |

### Any OS

All remaining tests run identically on Linux, macOS, and Windows (Git Bash).

---

## 4. Tests Safe for Local Pre-commit

Recommended hook: runs in < 60 s, zero side effects outside `/tmp`.

```bash
# .git/hooks/pre-commit  (or via conte hooks with core.hooksPath)
bash scripts/ci/check-bash-syntax.sh
```

Optionally extended to the fast gate (adds ~30–60 s):

```bash
bash tests/run-fast.sh
```

`run-fast.sh` already includes the syntax check, so these two are equivalent at different granularities.

**Do not add to pre-commit:**
- Any integration test (temp repo creation adds latency)
- `run-unit.sh` (2–3 min; too slow for every commit)

---

## 5. Tests Safe for Local Pre-push

Recommended: run the full unit suite before pushing a feature branch.

```bash
bash tests/run-unit.sh
```

Optionally add a lightweight integration smoke:

```bash
bash tests/integration/lifecycle.sh
bash tests/integration/validate.sh
```

**Do not run locally before push:**
- `run-hooks.sh` — platform-sensitive; misleading on non-target OS
- `run-release.sh` — moderate cost; better delegated to CI
- `run-workspace.sh` — moderate cost
- `tests/integration/update.sh` — requires network

---

## 6. Tests That Must Remain CI-Only

| Test / Step | Reason |
|---|---|
| `tests/integration/update.sh` | Downloads GitHub release; requires network and authenticated token |
| `scripts/package/build-artifacts.sh` | Requires Inno Setup (Windows), native tar/gzip; CI-only toolchain |
| `scripts/ci/release-notes-from-commits.sh` | Requires `fetch-depth: 0` git history and real tag refs |
| Package dry-run jobs | Needs `chocolatey`, Inno Setup, Windows runner |
| Cross-platform matrix (3 OSes) | Local dev typically has one OS; correctness on all three requires CI matrix |
| `ci-scheduled.yml` full-cross-platform | Weekly complete suite across all three OSes |

---

## 7. Identified Duplication and Expensive Areas

### 7.1 Syntax check over-replicated

`bash scripts/ci/check-bash-syntax.sh` is platform-agnostic (pure `bash -n`) but runs on every OS in the cross-platform matrix.

| Workflow | Job | OS | Times per push-to-main |
|---|---|---|---|
| `ci-main.yml` | fast-baseline | ubuntu | 1 |
| `ci-main.yml` | cross-platform-sensitive | ubuntu + macos + windows | 3 |
| **Total** | | | **4 per main push** |

For PRs, it runs in `fast-gate` (ubuntu) and `windows-sensitive` (windows). Two platforms for a platform-agnostic check.

**Saving opportunity:** Run syntax check once (ubuntu-only) and skip it in the matrix jobs.

### 7.2 Hooks suite duplicated across push and PR paths

`run-hooks.sh` runs on a 3-OS matrix in both `ci-main.yml` (always) and `ci-pr.yml` (conditionally when hooks-sensitive files change). A PR that changes hook logic triggers 3 CI slots, then the merge to main triggers 3 more.

**Total OS-slots per hooks-change cycle: 6.**

### 7.3 `windows-installer.sh` and `distribution.sh` on wrong scope

In `ci-main.yml` these run on all 3 OSes (matrix). In `ci-pr.yml` they run only on `windows-latest` (conditional). This inconsistency means the main branch spends 3× the budget that PRs spend on the same tests.

### 7.4 Full suite runs twice on Linux per main push

`ci-main.yml` runs `tests/run.sh` (full suite, `CONTE_TEST_JOBS=4`) in `full-linux-validation`. The same tests are individually invoked in `cross-platform-sensitive` on ubuntu. There is partial overlap.

### 7.5 Orphaned unit tests not exercised

16 unit test files exist in `tests/unit/` but are not included in `run-unit.sh` or any other runner. They cannot catch regressions until wired in.

### 7.6 `cli-ux.sh` is not wired into any runner

`tests/integration/cli-ux.sh` exists but is neither in a suite runner nor directly invoked by any CI workflow.

### 7.7 `update.sh` bypasses the suite runner abstraction

`tests/integration/update.sh` is invoked directly in `ci-main.yml` without going through a `run-*.sh` wrapper, making it invisible to `tests/run.sh`. It is also network-dependent, which distinguishes it from all other tests.

---

## 8. Recommended Local Workflow

### Quick start for new developers

```bash
# 1. Clone and verify tools
git clone <repo>
make help          # see all available targets

# 2. On every commit — syntax check + fast unit tests (~60 s)
make fast

# 3. Before opening a PR (~5 min)
make pr

# 4. Full offline validation before merging (~15-30 min)
make ci-local
```

That is the entire local workflow for most changes. The sections below describe what each step does and when to go deeper.

---

### Every commit — fast gate

```bash
make check   # syntax + optional shellcheck/shfmt + fast tests (~60-90 s)
# OR, for the fast gate alone:
make fast    # bash -n syntax check + 9 fast unit tests (~60 s)
```

`make fast` is the minimum bar. It runs in under a minute and catches syntax errors and basic logic regressions. Run it before every commit or wire it into a pre-commit hook (see §4 and §5).

---

### Before opening a PR

```bash
make pr   # fast + full unit suite + integration smoke (~5 min)
```

Runs `run-fast.sh` → `run-unit.sh` (34 unit tests) → integration smoke (lifecycle, validate, command-hierarchy). This is the local equivalent of what CI runs on every PR.

---

### Feature-specific checks

Run the relevant suite when you touch feature code. These suites are conditionally triggered in CI; running them locally before pushing avoids a slow CI round-trip.

| Change type | Local command | Approx. time |
|---|---|---|
| Hooks code or tests | `make hooks` | ~2-3 min |
| Release code or tests | `make release` | ~3-4 min |
| Workspace code or tests | `make workspace` | ~2 min |
| Uninstall or regression | `make regression` | ~2 min |
| Any broad change | `make ci-local` | ~15-30 min |

```bash
# Examples
make hooks      # after touching lib/core/hooks/ or tests/integration/hooks-*.sh
make release    # after touching lib/core/release/ or tests/integration/release-*.sh
make workspace  # after touching lib/core/workspace/ or workspace tests
```

---

### Full offline validation

```bash
make ci-local
```

Runs: syntax check → `tests/run.sh` (all 6 suite runners) → workspace fixture validation → release fixture validation.

This mirrors `full-linux-validation` in main CI and covers all checks that can run offline on a single OS. Cross-platform tests (hooks on macOS/Windows) and network tests (`update.sh`, package builds) remain CI-only.

---

### Optional tooling

**`shellcheck` and `shfmt`** — static analysis and formatting for shell scripts. Both are optional; `make check` enables them when available, and `STRICT_LOCAL_CHECKS=1 make check` makes them required.

```bash
# Run shellcheck on all tracked shell files
bash scripts/local/lint-shell.sh

# Check formatting with shfmt
bash scripts/local/format-check.sh

# Both, plus fast tests
make check
```

**`pre-commit`** — automates the pre-commit/pre-push gates. Install once and forget; the hooks run automatically on `git commit` and `git push`. See §5 for installation and hook definitions.

**Dev Container** — a reproducible Linux environment for Windows developers or any machine where the local setup diverges from CI. See §10 for setup instructions.

**`act`** — runs specific GitHub Actions jobs locally in Docker, using the same runner image as CI. Useful for validating workflow file changes before pushing. See §11 for usage.

---

### What to delegate to CI

These tests are deliberately not in `make pr` or `make ci-local`:

| Test | Why it belongs in CI |
|---|---|
| Hooks suite on macOS + Windows | File permission and `core.hooksPath` behavior differs per OS |
| `tests/integration/update.sh` | Network-dependent; downloads a real GitHub release |
| Package builds (Inno Setup, tar/zip) | Requires CI-specific toolchain |
| Full cross-platform matrix | Local dev typically has one OS |

Run `make hooks` locally as a sanity check on Linux; rely on CI for macOS and Windows validation.

---

## 9. Makefile Targets

A `Makefile` at the repo root exposes short `make <target>` commands for local development. All targets delegate to existing scripts — no test lists are duplicated.

`CONTE_TEST_JOBS` defaults to 4 inside the Makefile. Override with `CONTE_TEST_JOBS=2 make <target>`.

Run `make` or `make help` to see the full list.

### Quick-reference

| Target | Delegates to | Approx. time | Notes |
|---|---|---|---|
| `make check` | `scripts/local/check.sh` | ~60-90 s | Syntax + optional shellcheck/shfmt + fast tests |
| `make fast` | `tests/run-fast.sh` | ~60 s | Syntax check + 9 fast unit tests. Pre-commit gate. |
| `make unit` | `tests/run-unit.sh` | ~2-3 min | Full unit suite (34 tests) |
| `make integration` | `tests/run-integration.sh` | ~3-5 min | Integration suite (13 tests) |
| `make hooks` | `tests/run-hooks.sh` | ~2-3 min | Hook tests (6). Cross-platform sensitive — run in CI for all 3 OSes. |
| `make release` | `tests/run-release.sh` | ~3-4 min | Release integration (7 tests) |
| `make workspace` | `tests/run-workspace.sh` | ~2 min | Workspace integration (3 tests) |
| `make regression` | `tests/run-regression.sh` | ~2 min | Regression suite (3 tests) |
| `make pr` | `scripts/local/test-pr.sh` | ~5 min | Local PR gate: fast + unit + integration smoke |
| `make ci-local` | syntax + `tests/run.sh` + fixtures | ~15-30 min | Full offline suite. Mirrors `full-linux-validation` in CI. |
| `make all` | same as `ci-local` | ~15-30 min | Alias |
| `make help` | — | instant | Lists all targets with descriptions |

### Typical usage patterns

```bash
# Every commit — fast gate
make fast

# Before opening a PR
make pr

# After touching release or workspace code
make release
make workspace

# Full local validation before merging
make ci-local
```

### What `make ci-local` runs

1. `bash scripts/ci/check-bash-syntax.sh` — `bash -n` on all tracked `.sh` files
2. `CONTE_TEST_JOBS=4 bash tests/run.sh` — all 6 suite runners (unit, integration, hooks, release, workspace, regression)
3. `bash scripts/ci/workspace-fixture-validation.sh` — creates a workspace repo and runs validation commands
4. `bash scripts/ci/release-fixture-validation.sh` — creates a release repo and runs semver + preview

This covers all checks that can be run offline on a single OS. Cross-platform validation and network-dependent tests (`update.sh`, package builds) remain CI-only.

---

## 10. Dev Container

A Dev Container definition in `.devcontainer/` provides a reproducible Linux environment for running Bash tests. It is useful when developing on Windows (outside Git Bash), macOS with non-standard tool versions, or any machine where the local environment differs from CI.

### Included tools

| Tool | Source |
|---|---|
| bash, git, make, curl, jq, tar, gzip, zip, unzip | `debian:bookworm-slim` apt |
| ca-certificates | apt |
| shellcheck | apt (`shellcheck` package) |
| shfmt | GitHub releases binary (pinned via `SHFMT_VERSION` build arg) |

### Prerequisites

- Docker Desktop (or compatible runtime)
- VS Code with the **Dev Containers** extension (`ms-vscode-remote.remote-containers`), **or** GitHub Codespaces

### Opening the container

In VS Code: open the repo folder, then choose **Reopen in Container** from the command palette. VS Code builds the image, mounts the repo at `/workspaces/conte-cli`, and runs the `postCreateCommand` (`bash scripts/ci/check-bash-syntax.sh`) as a build verification.

### Quick start inside the container

```bash
# Verify tools
shellcheck --version
shfmt --version
make --version

# Syntax gate (~2 s)
make fast

# Full unit suite (~2-3 min)
make unit

# Check with shellcheck + shfmt + fast tests (~90 s)
make check

# Full offline suite (~15-30 min)
make ci-local
```

### Customising the shfmt version

The shfmt binary is downloaded at image-build time. To pin a different version, edit `.devcontainer/Dockerfile`:

```dockerfile
ARG SHFMT_VERSION=3.8.0
```

Rebuild the container after changing this value (**Dev Containers: Rebuild Container**).

---

## 11. Local act Support

[act](https://nektosact.com) runs GitHub Actions jobs locally inside Docker containers, using the same runner image as CI. It is useful for validating workflow configuration changes and reproducing CI failures without a round-trip push.

### Installation

| Platform | Command |
|---|---|
| macOS (Homebrew) | `brew install act` |
| Linux | See https://nektosact.com for the installer script |
| Windows | Chocolatey: `choco install act-cli`, or download from the releases page |

Docker Desktop (or a compatible runtime) must be running before invoking act.

### Runner image

`.actrc` at the repo root configures the default runner image and pull policy for all developers:

```
-P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04
--pull=missing
```

`catthehacker/ubuntu:act-22.04` (~500 MB) includes git, bash, curl, jq, and standard Unix tools. The image is pulled once and cached; subsequent runs reuse the cached layer.

On Apple Silicon (M1/M2/M3), if you see an "image platform does not match" error, uncomment the following line in `.actrc`:

```
--container-architecture linux/amd64
```

### Scripts

Three scripts in `scripts/local/` wrap specific CI jobs:

| Script | CI job | Workflow file | Fallback (no act) |
|---|---|---|---|
| `scripts/local/act-fast.sh` | `fast-gate` | `ci-pr.yml` | `scripts/local/test-fast.sh` |
| `scripts/local/act-pr.sh` | `fast-gate` (default) | `ci-pr.yml` | exits 1 with usage |
| `scripts/local/act-release.sh` | `release-history-preview` | `ci-main.yml` | `tests/run-release.sh` |

`act-fast.sh` and `act-release.sh` degrade gracefully: if act is not installed they run the equivalent test script directly with a warning. `act-pr.sh` requires act and prints usage if it is missing.

#### act-fast.sh

Reproduces `fast-gate` (syntax check + 9 fast unit tests). No dependencies on `detect-changes`, so it always runs in act without being silently skipped.

```bash
bash scripts/local/act-fast.sh
# Pass extra act flags:
bash scripts/local/act-fast.sh --verbose
```

#### act-pr.sh

Reproduces any PR CI job. Accepts `--job <id>`:

```bash
bash scripts/local/act-pr.sh                          # fast-gate (default)
bash scripts/local/act-pr.sh --job hooks-sensitive
bash scripts/local/act-pr.sh --job release-sensitive
bash scripts/local/act-pr.sh --job workspace-sensitive
```

#### act-release.sh

Reproduces `release-history-preview` from `ci-main.yml`. This job validates release note rendering from commit history:

- `scripts/ci/release-notes-from-commits.sh` — renders release notes from Conventional Commits using `git log` with `fetch-depth: 0`

The release integration test suite (`tests/run-release.sh`) runs separately in `full-linux-validation` via `tests/run.sh`. Use `make release` to run the release tests locally without act.

```bash
bash scripts/local/act-release.sh

# For the release test suite (not the notes step):
make release
```

Fallback without act: falls back to `tests/run-release.sh` for release test coverage, but does not validate release note rendering.

### Limitations

**detect-changes dependency.** PR jobs `hooks-sensitive`, `release-sensitive`, and `workspace-sensitive` depend on `dorny/paths-filter` to check which files changed. If no relevant files are staged or committed in the local git history, the job is silently skipped in act. Use the corresponding `make` target as a fallback:

| Skipped job | Make fallback |
|---|---|
| `hooks-sensitive` | `make hooks` |
| `release-sensitive` | `make release` |
| `workspace-sensitive` | `make workspace` |

**Cross-platform matrix.** act runs only the `ubuntu-latest` runner image. macOS and Windows runners are not available locally. Cross-platform validation for hooks, the Windows installer, and distribution artifacts belongs in CI.

### When to use act vs. make

| Situation | Recommended tool |
|---|---|
| Quick iteration on test logic | `make fast`, `make unit` |
| Verify a workflow file change | `bash scripts/local/act-fast.sh` |
| Reproduce a CI failure with exact environment | `bash scripts/local/act-pr.sh --job <id>` |
| Run release tests (no workflow changes) | `make release` |
| Validate release note rendering end-to-end | `bash scripts/local/act-release.sh` |

---

## 12. CI Strategy

Three tiers balance feedback speed against coverage cost. Each tier is designed so the tiers below it can be cheaper.

### Overview

| Tier | Workflow | Trigger | Philosophy |
|---|---|---|---|
| PR | `ci-pr.yml` | pull_request | Selective — only what changed |
| Main | `ci-main.yml` | push to main/master | Balanced — full Linux + targeted platform jobs |
| Scheduled | `ci-scheduled.yml` | weekly + `workflow_dispatch` | Exhaustive — full suite on all three OSes |

### PR CI — selective

Every PR always runs `fast-gate` (syntax check + 9 fast unit tests). All other jobs are conditional on `dorny/paths-filter`: they fire only when relevant files changed. A documentation-only PR runs 1 job; a hooks PR runs `fast-gate` + `hooks-sensitive` (3-OS matrix). CI minutes scale with the scope of the change.

| Job | Condition |
|---|---|
| `fast-gate` | always |
| `workspace-validation` | any `code` file changed |
| `integration-smoke` | any `code` file changed |
| `release-sensitive` | release-related files changed |
| `hooks-sensitive` | hooks-related files changed (3-OS matrix) |
| `workspace-sensitive` | workspace-related files changed |
| `uninstall-sensitive` | uninstall/distribution files changed |
| `windows-sensitive` | `conte.cmd`, distribution, or installer files changed |
| `package-dry-run` | package-related files changed |

### Main CI — balanced

Every push to `main` or `master` runs the full suite on Linux via `full-linux-validation` (`tests/run.sh` with 4 parallel jobs). Platform-specific jobs run targeted tests only — macOS validates hooks and self-update; Windows validates the installer, distribution artifacts, hooks, and self-update. The ubuntu cross-platform leg was removed because `full-linux-validation` already covers it.

`package-dry-run` is always-on: every merge to main is a release candidate and the package must build cleanly before a tag is pushed.

```
fast-baseline  →  full-linux-validation  ─┐
               →  macos-portability      ─┤→  package-dry-run
               →  windows-validation     ─┤
               →  release-history-preview┘
```

### Scheduled CI — exhaustive

Runs every Monday at 06:17 UTC and on demand via `workflow_dispatch`. This is the full safety net: `tests/run.sh` on all three OSes, fixture validations, the self-update test (`update.sh`) on all three OSes, and package/installer drift checks. PR and main CI can be cheaper specifically because scheduled CI provides this exhaustive cross-platform guarantee.

### How this reduces GitHub Actions runner minutes

| Optimization | Saving |
|---|---|
| PR path-filtering | 60-80% fewer slots on doc/config-only PRs |
| Removed ubuntu leg from cross-platform matrix (main CI) | –1 runner slot per main push |
| Removed redundant syntax check from platform matrix (main CI) | –2 runner-minutes per main push |
| Removed duplicate `run-release.sh` from `release-history-preview` (main CI) | –1 ubuntu runner per main push |
| Hooks suite de-duplicated: removed from `windows-sensitive` (PR CI) | –1 Windows runner slot when hooks files change |

---

## 13. Timing Reporting

Set `CONTE_TEST_TIMINGS=1` to print a formatted timing table after each suite and write TSV logs to `storage/timings/` for CI artifact collection.

### Local usage

```bash
CONTE_TEST_TIMINGS=1 make unit
CONTE_TEST_TIMINGS=1 make pr
CONTE_TEST_TIMINGS=1 bash tests/run.sh
```

After each suite, a timing table prints immediately below the suite's `PASS/FAIL` line:

```
--- hooks tests (jobs=2) ---
PASS: tests/integration/hooks-install.sh (12.340s)
PASS: tests/integration/hooks-validation.sh (8.120s)
...
PASS: hooks tests

=== Timing: hooks (6 tests) ===
STATUS  DURATION   SCRIPT
PASS    12.340s    tests/integration/hooks-install.sh
PASS     8.120s    tests/integration/hooks-validation.sh
...
```

When running `tests/run.sh` directly, a cross-suite summary prints at the end:

```
=== Suite timing summary ===
STATUS  DURATION   SUITE
PASS    45.230s    unit
PASS   120.450s    integration
PASS    38.000s    hooks
PASS    95.100s    release
PASS    22.400s    workspace
PASS    18.300s    regression
```

### CI artifacts

PR CI and main CI always run with `CONTE_TEST_TIMINGS=1` (set at the workflow level). Timing data is written to `storage/timings/<suite>.tsv` and uploaded as a GitHub Actions artifact after each test job (retained 7 days). Download the artifact from the Actions run summary to identify slow tests without scrolling through logs.

TSV columns: `STATUS`, `SUITE`, `DURATION`, `SCRIPT`.

Artifact names: `timings-fast-gate`, `timings-release`, `timings-hooks-<os>`, `timings-workspace`, `timings-uninstall`, `timings-full-linux`, `timings-macos`, `timings-windows`.

---

## 14. Known Limitations

### act does not replace real macOS or Windows

act runs only the `ubuntu-latest` runner image locally. macOS-specific behavior (filesystem case sensitivity, older bash, `date` format differences) and Windows Git Bash behavior cannot be reproduced with act. Cross-platform correctness requires CI.

For hooks tests specifically: `make hooks` validates Linux behavior; the macOS and Windows legs only run in CI (`hooks-sensitive` matrix) and scheduled CI.

### Windows requires Git Bash

All shell scripts in this repository must run under Git Bash on Windows. PowerShell is not the primary shell. `bin/conte.cmd` is a thin wrapper that locates Git Bash at two well-known paths (`C:\Program Files\Git\bin\bash.exe` and `C:\Program Files\Git\usr\bin\bash.exe`); non-standard Git Bash installations may not be detected automatically.

### Hooks are enforced in CI, not locally

Local Git hooks can be bypassed with `git commit --no-verify` or `git push --no-verify`. The hook files themselves are developer guardrails, not enforcement. CI/CD is the enforcement authority. Generated CI templates (via `conte generate cicd`) call `conte validate` commands that cannot be skipped with `--no-verify`.

### Fixture scripts are Linux/macOS only

`scripts/ci/workspace-fixture-validation.sh` and `scripts/ci/release-fixture-validation.sh` use `mktemp` and `${TMPDIR:-/tmp}`. They run on ubuntu in scheduled CI and in `full-linux-validation` on main CI. They are not safe to run on Windows outside Git Bash and are not in `make ci-local` for Windows developers.

### `update.sh` is not in `tests/run.sh`

`tests/integration/update.sh` is network-dependent and invoked directly in CI rather than through a suite runner. It is not exercised by `tests/run.sh`, `make ci-local`, or any `make` target. It runs in `macos-portability`, `windows-validation` (main CI), and `full-cross-platform` (scheduled CI). There is no local equivalent without act or a real GitHub release to download.

### Syntax check runs multiple times in scheduled CI

`bash -n` is platform-agnostic but runs on all three OSes in `ci-scheduled.yml`'s `full-cross-platform` matrix. This is intentional — scheduled CI is the exhaustive safety net and does not optimize for cost. PR CI and main CI run the syntax check once (`fast-baseline` on ubuntu only).
