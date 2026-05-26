## Mental model

Conte separates repository setup from hook management and diagnostics:

- **`conte init`** — prepares the repository: creates `.conte/config.json`, selects the workflow and branch mapping, generates the commit template, and optionally installs hooks.
- **`conte hooks install`** — activates Git hook validations independently of `init`. Use this to enable or repair hooks without running the full configuration wizard.
- **`conte doctor`** — diagnoses the current repository state and suggests fixes.

**Interactive menus rule:** menus resolve decisions; they do not hide commands. When a complex command is run in an interactive terminal without arguments, it opens a menu. When flags or subcommands are provided, the command runs directly. In CI or non-interactive environments, menus are never shown.

Commands that open menus in interactive mode (without arguments):
- `conte init` — full onboarding wizard
- `conte hooks` — hook management menu
- `conte config` — configuration menu
- `conte release` — release management menu

Commands that are always direct (never open menus):
- `conte status`, `conte doctor`, `conte version`, `conte update`, `conte uninstall`, `conte self`

## `conte version`

Prints the installed Conte CLI version only.

Usage:

```bash
conte version
```

Project versioning is intentionally separate:

- `conte version` = installed Conte CLI version
- `conte semver *` = project version stored in `.conte/config.json`

Old project-version paths under `conte version`, such as `conte version current`, `conte version get`, `conte version next`, `conte version set`, and `conte version breaking`, have been removed. Use `conte semver` instead.

## `conte update`

Updates the installed Conte CLI only.

Usage:

```bash
conte update
conte update --check
conte update --version 1.2.3
```

## `conte init`

Initializes `.conte/config.json` using an interactive wizard or non-interactive defaults.

Usage:

```bash
conte init
conte init --yes
conte init --workflow trunk --yes
conte init --advanced
conte init --force
```

Behavior:

1. Detect repository root.
2. Warn if legacy `.conte/conte.conf` exists, but keep it untouched.
3. If `.conte/config.json` already exists and `--force` is not set:
   - **Interactive**: show the current configuration and offer:
     `View configuration`, `Reconfigure`, `Reinstall hooks`, `Exit`.
     Choosing `Exit` returns code 0.
   - **Non-interactive**: print a notice and exit 0, unless Conte can safely upgrade a legacy config with no `hooks` section or repair a broken install where `hooks.enabled=true`.
4. Run the wizard steps in order:
   - Select workflow (`kanban` preselected): `Trunk-Based`, `GitFlow`, `Kanban`.
   - Detect and confirm the logical `main` branch.
   - Detect and confirm the logical `develop` branch (gitflow only).
   - Configure commit rules: scope required (default `true`).
   - Configure hooks: install hooks now (default `true`).
   - Show a configuration summary.
   - Confirm before writing.
5. Write `.conte/config.json`.
6. Generate `.conte/templates/commit-template.txt` and set `git config commit.template .conte/templates/commit-template.txt` unless a user-managed local `commit.template` is already configured.
7. Install selected hooks into `.conte/hooks` and set `git config core.hooksPath .conte/hooks` when enabled — using the same internal logic as `conte hooks install`.
8. Verify the final repository state before reporting success.

Expected output after successful initialization:

```
Conte initialized successfully.

Repository:
  /path/to/repo

Workflow:
  kanban

Branches:
  main = main

Hooks:
  installed

Commit template:
  configured

Diagnostics:
  OK

Next:
  conte status
```

When hooks are skipped during `init`, the output shows:

```
Hooks:
  not installed

  Run 'conte hooks install' to activate validations.
```

Options:

- `--yes` / `-y`: run non-interactively using defaults. Exits 0 if already initialized (use `--force` to overwrite).
- `--force` / `-f`: overwrite an existing `.conte/config.json` without prompting.
- `--advanced`: show additional options during the wizard (scope pattern, individual hook selection, release command).
- `--workflow <name>` / `-w`: skip the workflow selection step.
- `--main-branch <name>`: skip the main branch prompt.
- `--develop-branch <name>`: skip the develop branch prompt.
- `--create-missing-branches`: create missing mapped branches when `HEAD` already points to a commit.
- `--track-remote-branches`: create local tracking branches from `origin/<branch>` when the selected branch exists only on the remote.

Notes:

- Branch detection uses Git repository state, not guessed branch names:
  - local branch: `git show-ref --verify --quiet refs/heads/<branch>`
  - remote branch: `git show-ref --verify --quiet refs/remotes/origin/<branch>`
  - commits available: `git rev-parse --verify HEAD`
  - current branch: `git symbolic-ref --quiet --short HEAD`
- Empty repositories can be initialized without a first commit. Conte stores the intended mapping and warns that mapped branches become valid after the first commit.
- If a selected branch exists only on `origin`, interactive mode offers to create a local tracking branch.
- If a selected branch does not exist, interactive mode always offers recovery actions: retry, create the branch, use a detected branch when available, or exit cleanly.
- `gitflow` prompts for a `develop` branch mapping.
- `gitflow` creates `develop` from the mapped `main` branch when possible, or stores the mapping only in an empty repository.
- Hook config is stored in `.conte/config.json` under `hooks.enabled`, `hooks.path`, and `hooks.installed`.
- Conte also generates a repository-local commit template at `.conte/templates/commit-template.txt` with Conventional Commit guidance and mandatory scope examples.
- Conte-managed hooks are installed under `.conte/hooks`, not directly into `.git/hooks`.
- If local Git already has a user-managed `commit.template`, Conte preserves it, still generates its own template file, and prints a warning that activation was skipped.
- `--force` reinitializes from scratch without showing the already-initialized menu.
- `--yes --force` reinitializes non-interactively using defaults.
- A plain non-interactive rerun upgrades legacy initialized repos that predate the `hooks` section and repairs broken managed hook state when hooks are already expected to be enabled.
- Repos that explicitly store `hooks.enabled=false` are preserved as disabled on a non-interactive rerun.
- When hooks are enabled, `conte init` verifies `.conte/hooks`, the configured hook files, executability, runtime resolution, and `core.hooksPath`.
- If verification fails, `conte init` exits with an error and suggests `conte hooks reinstall --force`.
- Hook installation in `init` uses the same shared function as `conte hooks install` — no logic duplication.

## `conte config`

Reads `.conte/config.json`. In an interactive terminal with no arguments, opens a menu.

Usage:

```bash
conte config
conte config list
conte config --local
conte config --global
conte config get workflow
conte config get git.mainBranch
conte config get git.mapping.main
conte config set version.current 1.2.3
```

Interactive menu (shown when called without arguments in a TTY):

```
Conte config

  1. View current configuration
  2. Reconfigure (use: conte init)
  3. Exit

Choose [1]:
```

Menu options:

- `1. View current configuration` — equivalent to `conte config` (shows config JSON)
- `2. Reconfigure` — prints `Run: conte init` and exits
- `3. Exit` — exits with code 0

In CI or non-interactive environments, `conte config` with no arguments prints the config JSON directly.

Without `--local` or `--global`, `conte config get <key>` returns the effective value after applying workspace, local, and global config layering. `conte config set <key> <value>` writes one repository-local value and validates known boolean and SemVer fields before writing.

## `conte uninstall`

Removes only Conte-managed repository-local state for the current Git repository.

Usage:

```bash
conte uninstall
conte uninstall --yes
```

Behavior:

- requires a Git repository
- targets only `<repo>/.conte`
- asks for confirmation by default
- reads the configured `hooks.path` before removing managed files
- removes known Conte-managed paths only, including `.conte/config.json`, legacy `.conte/conte.conf`, Conte-managed hook files under the configured hooks path, and the Conte-managed commit template at `.conte/templates/commit-template.txt`
- preserves unmanaged files and directories under `.conte`, including `.conte/templates`, `.conte/projects`, and unknown paths
- removes empty managed directories after file cleanup and removes `.conte` only when it becomes empty
- removes local hook configuration by unsetting `git config --local core.hooksPath` only when it equals the configured managed hooks path
- removes local commit template configuration by unsetting `git config --local commit.template` only when it equals the Conte-managed template path and the file is Conte-managed
- preserves unrelated user-managed `core.hooksPath` values and reports what was removed versus preserved
- preserves unrelated or user-managed `commit.template` values and reports what was removed versus preserved
- never removes `~/.conte`, `%USERPROFILE%\.conte`, `.git`, source files, or global CLI installation files

Notes:

- if the current repository has no `.conte` directory, Conte prints `Conte is not initialized in this repository.` and exits 0
- if `.conte` still contains unmanaged content after managed cleanup, Conte keeps the directory and reports the remaining top-level entries
- `conte uninstall` removes **repository-local** Conte configuration only; it does not uninstall the global CLI
- to uninstall the global CLI, use `conte self uninstall`

## `conte semver`

Manages repository-local Semantic Versioning state and manual release overrides.

Usage:

```bash
conte semver get-version
conte semver set-version 1.2.3
conte semver next-version
conte semver breaking
```

Aliases (old names, still supported):

```bash
conte semver get      # same as get-version
conte semver set      # same as set-version
conte semver next     # same as next-version
```

Notes:

- `conte version` shows the installed Conte CLI version.
- `conte semver get-version` shows only the current project version (script-friendly).
- `conte semver set-version <version>` sets the project version. Validates strict SemVer (`MAJOR.MINOR.PATCH`), updates `.conte/config.json` only (no tags, no changelog). Idempotent if version is already set.
- `conte semver next-version` analyzes conventional commits since the last release/tag and prints only the next project version. Never writes files.
- `conte semver breaking` marks the next release as MAJOR by setting `breakingChange.nextBump` to `major`. Does not change the version immediately. Idempotent.
- after `conte semver breaking`, commit `.conte/config.json` before running `conte release create`:

```bash
git add .conte/config.json
git commit -m "chore(release): mark next version as major"
conte release create
```

- `conte release create` consumes and clears `breakingChange.nextBump` on a successful release
- `conte release preview` (dry-run) never clears `breakingChange.nextBump`
- `conte status` shows the current `Next bump` value
- `conte doctor` validates `breakingChange.mode` and `breakingChange.nextBump`
- `!` in conventional commit messages is valid syntax, but does not trigger MAJOR without `conte semver breaking`; the release command warns when `!` commits are found without the manual marker
- repository tags use `vX.Y.Z` while config stores `X.Y.Z`

## `conte generate cicd`

Generates CI/CD templates for remote enforcement.

Usage:

```bash
conte generate cicd
conte generate cicd --provider github
conte generate cicd --provider gitlab
conte generate cicd --provider azure
```

The generated template always calls the CLI instead of re-implementing validation rules in the provider file.
The validation job runs `bash ./bin/conte status`, `bash ./bin/conte doctor`, `bash ./bin/conte release preview`, and `bash tests/run.sh` when present.

## `conte status`

Shows a brief health summary with key repository properties.

```
Conte Status

Initialized: yes
Workflow: kanban
Main branch: main
Current branch: main
Hooks: enabled
Commit scope: required
Breaking change mode: manual command
Next bump: none
```

When not initialized:

```
Conte Status

Initialized: no
Workflow: unknown
...
Run: conte init
```

`conte status` is fast and never performs repairs. Use it as a quick health check before committing or pushing.

Branch validity is determined by the workflow rules:

- **Trunk-Based**: `main`, `master`, `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `chore/*` allowed. `develop` and `release/*` rejected.
- **Kanban**: Same as trunk plus `release/*` allowed. `develop` rejected.
- **GitFlow**: `main`, `master`, `develop`, `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `release/*`, `hotfix/*`, `chore/*` allowed.

For detailed diagnostics, run `conte doctor`.

## `conte doctor`

Performs full diagnostics with grouped sections. Each check shows a status value: `ok`, `error`, `missing`, `disabled`.

```
Conte doctor


Rules

  Main branch:                   main
  Commit scope:                  required
  Breaking change mode:          manual command
  Shell:                         Git Bash required on Windows

Git

  Repository:                    ok
  Current branch:                ok
  Branch convention:             error

Hooks

  core.hooksPath:                missing
  commit-msg:                    missing
  pre-push:                      missing
  prepare-commit-msg:            missing

Config

  .conte/config.json:            missing
```

The Rules section is always shown regardless of initialization status.

When issues are found, the output ends with:

```
Found issues.

Fix:
  conte init
```

`conte doctor --fix`:

- Prints `Will fix:` with a summary of changes before applying them.
- Applies only safe, deterministic repairs (reinstall Conte-managed hooks, set `core.hooksPath`).
- Prints `Rerunning diagnostics.` then reruns the full check on the repaired state.
- Does not overwrite user-managed files without `--force`.

Safe fixes applied by `--fix`:

- Reinstall missing or broken Conte-managed hooks
- Set `core.hooksPath=.conte/hooks`
- Reinstall missing Conte-managed commit template

Unsafe changes that require `--force` or manual action:

- Replacing non-Conte-managed hooks
- Overwriting config
- Changing branch mappings
- Creating missing branches

`conte doctor` diagnoses:

- Config presence and integrity
- `breakingChange.mode` is `manual-command`
- `breakingChange.nextBump` is `null` or `major`
- Hook enablement, `core.hooksPath`, and per-hook runtime health
- Commit template configuration and file state
- Mapped branch availability
- Develop branch requirement for GitFlow
- Current branch validity against workflow rules (format and type)
- Branch name format validation via base regex
- Branch type allowed check per workflow
- Unsupported or missing workflow configuration
- Commit validation: hook presence, runtime health, scope config, strict format enforcement
- Recent commit validity
- Invalid non-merge release commits since the last tag
- Scope rule presence
- CI/CD provider and pipeline validation
- Hook Tasks configuration

## `conte validate`

Runs explicit validation checks without going through Git hooks. Intended for QA, CI pipelines, support workflows, and debugging.

Usage:

```bash
conte validate commit "fix(auth): corregir token"
conte validate commit --file .git/COMMIT_EDITMSG
conte validate branch
conte validate branch feat/add-login
conte validate repo
```

Notes:

- `commit <message>` validates a Conventional Commit message passed as an argument, using the same rules as the `commit-msg` hook
- `commit --file <path>` validates a commit message read from a file; supports multi-line messages
- `branch` validates the current branch name against the configured workflow rules
- `branch <name>` validates the given branch name without checking it out
- `repo` validates repository configuration, workflow, branch mapping, and hook consistency
- All subcommands are non-interactive and exit non-zero on failure
- Does not modify repository state, install hooks, or run `conte doctor` automatically
- When `repo` finds issues, it suggests running `conte doctor` for detailed diagnostics

Exit codes:

- `0` — validation passed
- non-zero — validation failed; error details printed to stderr

## `conte hooks`

Manages repository Git hooks. In an interactive terminal with no arguments, opens a menu.

Usage:

```bash
conte hooks
conte hooks install
conte hooks install --force
conte hooks reinstall --force
conte hooks status
conte hooks doctor
conte hooks uninstall
conte hooks test commit-msg "fix(auth): corregir token"
conte hooks test branch feat/add-login
conte hooks task list
conte hooks task add dotnet-test --hook pre-push -- dotnet test
conte hooks task run dotnet-test
```

Interactive menu (shown when called without arguments in a TTY):

```
Conte hooks

  1. Show hooks status
  2. Install hooks
  3. Reinstall hooks
  4. Uninstall hooks
  5. Exit

Choose [1]:
```

Each menu option calls the same logic as the direct subcommand. In CI or non-interactive environments, `conte hooks` with no arguments defaults to `conte hooks status`.

Behavior:

- `conte init` installs hooks by default; `hooks.enabled=true` is stored in `.conte/config.json`
- hook files live under `.conte/hooks` — **never** under `.git/hooks`
- sets `git config core.hooksPath .conte/hooks`
- generates `.conte/templates/commit-template.txt`
- sets `git config commit.template .conte/templates/commit-template.txt` unless a user-managed local template is already configured
- stores hook state in `.conte/config.json`
- preserves user-managed `.git/hooks` files and warns when Git no longer uses them
- strategic hooks are `commit-msg`, `pre-push`, and `prepare-commit-msg`; `pre-commit` is also supported
- every Conte-managed hook includes the `# Managed by Conte CLI` marker
- `commit-msg` validates Conventional Commits with required scope and executes enabled Hook Tasks for `commit-msg`
- `prepare-commit-msg` loads the shared hook runtime and runs enabled Hook Tasks for `prepare-commit-msg`
- `pre-commit` and `pre-push` validate the current branch against workflow rules and execute enabled Hook Tasks for their hook
- `pre-push` blocks pushes when:
  - current branch name does not match the required format (base regex)
  - current branch type is not allowed by the configured workflow
  - workflow config is missing or unsupported
- `post-merge` executes enabled Hook Tasks for `post-merge`
- for GitFlow, `pre-push` also validates workflow-aware merge targets when Git provides source and target refs
- **Standard Git hooks do not block branch creation** (`git checkout -b`, `git branch`); Conte blocks commits and pushes from invalid branches

Diagnosis and repair:

- `conte hooks status` prints a short health summary for `core.hooksPath`, managed hooks, and the commit template; it never repairs
- `conte hooks doctor` prints detailed Issue, Current, Expected, Impact, and Fix blocks; exits non-zero when issues are found
- `conte hooks test commit-msg "<message>"` validates a message with the same commit rules used by `commit-msg`
- `conte hooks test branch [branch-name]` validates the current or provided branch with the same branch rules used by hooks
- missing managed hook diagnostics list the missing files, expected hook set, current `core.hooksPath`, repair command, and verification commands
- missing hook runtime diagnostic reports that `.conte-hook-runtime` is missing from the hooks directory and suggests `conte hooks reinstall --force`
- inactive hook diagnostics show the current `core.hooksPath`, the expected `.conte/hooks` value, and explain that Git will not run commit or push validation
- `conte doctor --fix` previews changes with `Will fix:`, applies safe repairs, then reruns diagnostics with `Rerunning diagnostics.`
- `conte hooks reinstall --force` repairs broken or missing hooks, restores all selected wrappers, and sets `hooks.enabled=true`; falls back to the default hook set when `installed` is empty

Notes:

- `conte hooks install --force` replaces conflicting non-Conte-managed files only under `.conte/hooks`
- `conte hooks status` exits non-zero when hooks are enabled in config but broken or missing, and also when the repository is in a partially configured state
- Windows hook execution requires Git Bash because Conte-managed hooks use Bash-compatible runtime scripts
- `git commit --no-verify` and `git push --no-verify` bypass local hooks
- local hooks can be bypassed with `git commit --no-verify`, so CI/CD remains required

Hook Tasks:

- `conte hooks task list` shows configured tasks
- `conte hooks task add <name> --hook <hook|manual> -- <command>` adds a task
- adding a task for a Git hook adds that hook to `hooks.installed`; if hooks are enabled, Conte writes the managed hook wrapper
- `conte hooks task edit <name>` updates a task
- `conte hooks task enable|disable|remove|run <name>` manages a task
- `conte hooks task menu` opens an interactive menu for long commands
- Hook Tasks cannot register Conte commands or replace internal validation

## `conte self`

Manages the installed Conte CLI lifecycle.

Usage:

```bash
conte self version
conte self update
conte self update --version 1.2.3
conte self uninstall
conte self uninstall --yes
```

Subcommands:

- `version` — show CLI version information (same as `conte version`)
- `update` — update the installed Conte CLI (same as `conte update`)
- `uninstall` — uninstall the global Conte CLI from `$CONTE_HOME`

Notes:

- `conte self uninstall` removes the global CLI installation directory (`$CONTE_HOME`).
  It does **not** affect repository-local `.conte` configuration.
- Use `conte uninstall` (inside a repository) to remove repository-local Conte configuration.
- `conte self uninstall` will prompt for confirmation unless `--yes` is passed.
- After running `conte self uninstall`, remove `$CONTE_HOME/bin` from your `PATH`.

## `conte changelog`

Previews or writes changelog content for the next release without creating release commits or tags.

Usage:

```bash
conte changelog preview
conte changelog generate
```

Notes:

- `preview` prints the changelog section that would be generated and does not write files
- `generate` writes `CHANGELOG.md` only
- release creation remains under `conte release create`

## `conte release`

Manages releases. In an interactive terminal with no arguments, opens a menu. Direct subcommands never open a menu.

Usage:

```bash
conte release preview
conte release create
conte release create --allow-empty-release
conte release create --scope us-12
conte release create -s us-12
conte release create --no-tag
conte release create --no-changelog
```

Behavior:

1. Loads `.conte/config.json`.
2. Resolves workflow and logical branch mapping.
3. Verifies repository cleanliness and release branch eligibility.
4. Finds the latest `vX.Y.Z` tag.
5. Reads non-merge commits since that tag.
6. Validates commits with the shared validation engine.
7. When `--scope` is set, filters those commits by exact Conventional Commit scope.
8. Calculates the next version from Conventional Commits.
9. In scoped mode for supported workflows, creates `release/<scope>` from the workflow base branch.
10. Updates `version.current` and clears `breakingChange.nextBump`.
11. Generates or updates `CHANGELOG.md`.
12. Creates the new tag unless `--no-tag` is set.

Notes:

- commits are the source of truth
- non-merge commits since the last tag must pass the shared Conventional Commit validation
- merge commits are ignored for release parsing because collection uses `git log --no-merges`
- `feat(scope): ...` bumps minor
- `fix(scope): ...` and `perf(scope): ...` bump patch
- `conte semver breaking` forces the next release to bump major
- `--scope <scope>` means an exact Conventional Commit scope match, not a substring match
- `conte release create --scope <scope>` creates `release/<scope>` from the workflow base branch
- the working tree must be clean; if `.conte/config.json` contains an uncommitted breaking marker, `conte release create` fails with instructions to commit it explicitly
- when `--no-tag` is used, the Conte release commit is used as the release marker so repeated runs with no new versionable commits do not duplicate release artifacts
- scoped releases are intended for ticket or user-story based releases
- scoped release branches are supported for `gitflow` only
- scoped release branches are not supported for `kanban` or `trunk`
- for GitFlow, `conte release create` must run from the resolved `develop` branch and rejects production, feature, fix, bugfix, hotfix, chore, and existing release branches
- for GitFlow, release branches may close into production and must be back-merged into the resolved `develop` branch; release branches cannot merge into feature, fix, chore, or hotfix branches
- for GitFlow, scoped release branches are created from the resolved `develop` branch
- scoped release creation can fail when the selected scope depends on commits outside that scope
- `preview` prints the release summary and changelog preview without writing files
- `--allow-empty-release` forces a patch release when commits are valid but non-versionable
- `version.current` stays bare SemVer while tags use `vX.Y.Z`
- if changelog or tag creation fails, Conte restores release state instead of leaving partial updates behind
- breaking syntax markers (`!` after scope, `BREAKING CHANGE` footer) are not part of the v1 commit format; only `conte semver breaking` activates a MAJOR release

Interactive menu (shown when called without arguments in a TTY):

```
Conte release

  1. Preview next release (--dry-run)
  2. Create release
  3. Create release without tag (--no-tag)
  4. Show current version
  5. Exit

Choose [1]:
```

Subcommands:

- `preview` — preview the next release without writing files
- `create [options]` — create release artifacts, update changelog/config, and create the tag according to config

Notes:

- `conte release preview` is always safe to run; it never writes files, updates config, or creates tags
- old project-version paths under `conte version` (`get`, `set`, `next`, `breaking`) have been removed; use `conte semver` instead
