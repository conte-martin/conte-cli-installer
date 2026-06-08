# Testing Strategy

Conte CLI tests stay Bash-first and Git-native. They use local temporary repositories created by `tests/testlib.sh`; Testcontainers is not the primary strategy for this repository.

## Runners

- `tests/run-fast.sh` runs syntax checks plus the fastest unit smoke set.
- `tests/run-unit.sh` runs unit coverage.
- `tests/run-integration.sh` runs general integration coverage.
- `tests/run-hooks.sh` runs hook installation, validation, and doctor coverage.
- `tests/run-release.sh` runs release and service-release coverage.
- `tests/run-workspace.sh` runs workspace behavior coverage.
- `tests/run-regression.sh` runs focused regressions, including uninstall/remove QA.
- `tests/run.sh` runs all suites.

All suite runners use `tests/helpers/runner.sh`. The runner prints one line per test with elapsed time, for example:

```text
PASS: tests/unit/release-semver.sh (0.421s)
```

Failures print the test log after the failing duration line so CI keeps both timing and diagnosis together.

## Parallelism

Set `CONTE_TEST_JOBS` to limit concurrent test scripts:

```sh
CONTE_TEST_JOBS=1 bash tests/run.sh
CONTE_TEST_JOBS=4 bash tests/run.sh
```

The default is `2`, which avoids unbounded repository creation while still giving CI useful parallelism. Use `CONTE_TEST_JOBS=1` when investigating order-sensitive failures.

## Fixtures

Common fixtures live under `tests/helpers/`:

- `workspace-fixtures.sh` builds reusable workspace repositories and service commits.
- `release-fixtures.sh` centralizes release command diagnostics and multi-service release repositories.
- `hook-fixtures.sh` exposes hook setup and assertions.

`tests/testlib.sh` also provides initialized repository helpers for common workflow baselines:

- `create_initialized_kanban_repo`
- `create_initialized_trunk_repo`
- `create_initialized_gitflow_repo`
- `create_initialized_workspace_repo`

Prefer these helpers over repeating `conte init` setup in new tests.

## CI Selection

GitHub Actions uses path filters to run focused suites for sensitive areas:

- `hooks-sensitive`
- `release-sensitive`
- `workspace-sensitive`
- `uninstall-sensitive`

Main and scheduled CI still validate Linux, macOS, and Windows for cross-platform-sensitive behavior. Pull request CI keeps fast checks unconditional and adds focused suites when changed paths require them.
