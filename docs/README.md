# Conte CLI

Conte CLI is a Bash-first Git workflow, release, enforcement, and distribution platform.

Phase 6 hardens the CLI as a production-grade product:

- config stores user choices
- workflow derives branch and commit rules
- validation enforces those rules
- hooks delegate to the validation engine and live under `.conte/hooks`
- release derives SemVer, changelog entries, and tags from commits
- CI/CD templates call the CLI in GitHub, GitLab, and Azure DevOps
- remote pipelines become the enforcement source of truth
- Hook Tasks run explicit user-defined commands from selected Git hooks
- global, local, and workspace config layers support multi-project repos
- CLI versioning and self-update are built in
- install and update flows support multi-platform distribution
- config and git reads are cached for faster repeated access

## Commands

**Core CLI commands:**

```bash
conte help
conte help semver
conte --help
conte -h
conte --version
conte -v
conte version
conte update
conte self version
conte self update --check
conte self uninstall --yes
```

**Repository commands:**

```bash
conte init
conte uninstall
conte status
conte doctor
```

**Config commands:**

```bash
conte config list
conte config --local
conte config --global
conte config get version.current
conte config set version.current 1.2.3
```

**Hooks commands:**

```bash
conte hooks status
conte hooks install
conte hooks reinstall --force
conte hooks uninstall
conte hooks doctor
conte hooks test commit-msg "fix(auth): corregir token"
conte hooks test branch feat/add-login
conte hooks task
conte hooks task list
conte hooks task add dotnet-test --hook pre-push -- dotnet test
conte hooks task edit dotnet-test --disable
conte hooks task run dotnet-test
```

**Validation commands:**

```bash
conte validate commit "fix(auth): corregir token"
conte validate commit --file .git/COMMIT_EDITMSG
conte validate branch feat/add-login
conte validate branch
conte validate repo
conte workflow validate-merge --source feature/login --target develop
```

**Project SemVer, changelog, and release commands:**

```bash
conte semver get
conte semver next
conte semver set 1.2.3
conte semver breaking
conte changelog preview
conte changelog generate
conte release preview
conte release preview --scope us-12
conte release create
conte release sync-develop --preview
conte release create --allow-empty-release
conte release create --scope us-12 --scope-mode strict
conte release create --include-internal
conte release create --no-tag
conte release create --no-changelog
conte generate cicd
conte generate cicd github
conte generate cicd gitlab
conte generate cicd azure
conte generate cicd --provider github
conte generate cicd --provider gitlab
conte generate cicd --provider azure
```

Current command intent:

- `version` reports only the installed Conte CLI version
- `update` installs a newer Conte CLI release safely when release metadata is available; also available as `conte self update`
- `init` creates `.conte/config.json`, generates the repository-local commit template, can install repository-local hooks, verifies the final repo state, and warns explicitly when hooks are disabled
- `config list|get|set` inspects or safely updates one config value
- `uninstall` removes only Conte-managed repository-local state, preserves unmanaged `.conte` content, and cleans managed `core.hooksPath` and `commit.template` when they still belong to Conte
- `semver` reads, calculates, and updates repository-local project version state and manual release overrides
- `changelog` previews or writes the next changelog content without creating a release
- `generate cicd` creates workflow-aware CI/CD templates for GitHub, GitLab, or Azure DevOps
- `status` reports repository state, hook alignment/runtime, commit-template alignment, workflow and mapping health, release commit health, CI/CD state and provider, Hook Tasks, and the last release version/tag
- `doctor` validates config, mapping, branch, hook/runtime state, commit-template state, release commit history, Hook Tasks, and generated pipeline enforcement
- `hooks` installs, uninstalls, reinstalls, and diagnoses thin Git hooks and the repository commit template managed by Conte; `conte hooks reinstall --force` repairs broken or missing hooks and always sets `hooks.enabled=true`
- `release preview` shows the next release plan without writing files
- `release create` generates release artifacts, updates changelog/config, and creates the tag according to config
- `release sync-develop` merges the resolved production branch into the resolved develop branch for GitFlow repositories
- `workflow validate-merge` validates a source branch and target branch against derived workflow merge rules

`conte init` behavior:

- keeps `kanban` as the default workflow selection
- offers `Trunk-Based`, `GitFlow`, and `Kanban`
- supports `--workflow <name>`, `--main-branch <name>`, `--develop-branch <name>`, `--create-missing-branches`, `--track-remote-branches`, `--advanced`, and `--no-hooks`
- warns before re-initializing when `.conte/config.json` already exists
- accepts `--force` to skip the re-initialization prompt
- upgrades legacy initialized repos to the repository-local hooks contract on a non-interactive rerun and repairs broken enabled hook installs without changing explicit `hooks.enabled=false` repos
- detects legacy `.conte/conte.conf` without deleting it
- generates `.conte/templates/commit-template.txt` and activates `git commit.template` unless a user-managed local template is already configured
- prints whether commit and branch validation are active at the end of initialization
- warns explicitly when hooks are disabled because local validation will not run

Workflow rules are derived in code, not stored as generated regex in config:

- `trunk`: mapped `main` plus `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `chore/*`
- `kanban`: mapped `main` plus `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `release/*`, `chore/*`
- `gitflow`: mapped `main`, mapped `develop`, plus `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `release/*`, `hotfix/*`, `chore/*`

Branch suffixes are strict: lowercase letters, numbers, `-`, and `.`, with no spaces, underscores, uppercase letters, `--`, `..`, or leading/trailing separators.

## Core Principle

```text
Config -> user input
Workflow -> rules
Validation -> enforcement
Hooks -> developer experience
CI/CD -> remote enforcement
Release -> SemVer + changelog + tag
Hook Tasks -> explicit local commands
Distribution -> reliable delivery
CLI -> orchestration
```

## Configuration Contract

The repository-local config written by `conte init` is:

```json
{
  "version": "0.1.0",
  "workflow": "kanban",
  "git": {
    "mainBranch": "main",
    "mapping": {
      "main": "main"
    }
  },
  "commit": {
    "scopeRequired": true,
    "scopePattern": "^[a-z0-9]+(-[a-z0-9]+)*$"
  },
  "breakingChange": {
    "mode": "manual-command",
    "nextBump": null
  },
  "hooks": {
    "enabled": true,
    "path": ".conte/hooks",
    "installed": ["commit-msg", "pre-push", "prepare-commit-msg", "pre-commit"],
    "tasks": []
  },
  "release": {
    "tagPrefix": "v",
    "changelogFile": "CHANGELOG.md"
  }
}
```

Derived regex, workflow rules, branch lifecycle rules, and merge rules are not stored in config. `workflow: gitflow` automatically activates GitFlow merge validation; do not add `mergeRules` to `.conte/config.json`. The top-level `version` stores bare SemVer like `0.1.0`, `breakingChange.nextBump` stores the next-release major override, and Git tags use the `v` prefix like `v0.1.0`.

Conte only writes `.conte/config.json` for repository initialization. Legacy `.conte/conte.conf` is read for compatibility when present, but it is not created, deleted, or silently migrated by `conte init`.

## Hook Tasks

Strategic hooks are `commit-msg`, `pre-push`, and `prepare-commit-msg`; `pre-commit` is also supported. Use `conte hooks status` for visibility, `conte hooks doctor` for detailed diagnostics, `conte hooks reinstall --force` for repair, and `conte hooks test` for manual commit or branch validation without creating a commit or push.

On Windows, run Git operations from Git Bash so Conte-managed Bash-compatible hooks can execute. Local hooks are not the only enforcement layer; keep CI validation enabled for remote protection.

Hook Tasks are repository-local commands stored under `hooks.tasks`.
They do not register Conte commands, replace validation, or extend internal engines.

Manage them with:

```bash
conte hooks task list
conte hooks task add dotnet-test --hook pre-push -- dotnet test
conte hooks task add npm-lint --hook pre-commit -- npm run lint
conte hooks task add npm-install --hook post-merge -- npm install
conte hooks task run dotnet-test
```

## Multi-Repo Model

Conte now resolves configuration in layers:

1. workspace project config: `.conte/projects/<project>/config.json`
2. repository config: `.conte/config.json`
3. global config: `~/.conte/config.json`

Local config overrides global config. Workspace config overrides the repository config when the current directory is inside a configured subproject.
Inspection commands can use that effective layered view. Repo-mutating commands always read and write the repository-local `.conte/config.json`.

Use:

```bash
conte config --local
conte config --global
```

## Versioning And Updates

Conte now versions itself with SemVer:

```bash
conte version
conte update --check
conte update
```

The embedded CLI version is compared against release metadata. Update installs are designed to replace the current tree safely with rollback behavior if the new payload cannot be staged.

Conte also manages repository-local release versioning separately:

```bash
conte semver get
conte semver next
conte semver set 1.2.3
conte semver breaking
```

Use `conte version` for the installed CLI version only. Use `conte semver *` for the project version stored in `.conte/config.json`.

- `conte version` shows the installed Conte CLI version.
- `conte semver get` shows the current project version.
- `conte semver next` calculates and prints only the next project version.
- `conte semver set <version>` sets the project version.
- `conte semver breaking` marks the next release as MAJOR.

## Release Model

Repository release behavior is split cleanly:

- `conte semver` manages local version state and manual overrides
- `conte release preview` previews the release without writing files
- `conte release create` is the canonical release command

Migration:

- `conte version` is reserved for the installed Conte CLI version.
- Use `conte semver get`, `conte semver next`, `conte semver set <version>`, and `conte semver breaking` for project versioning.

`conte release create` is commit-driven:

- commits are the source of truth
- merge messages and PR titles are ignored
- invalid non-merge Conventional Commits since the last tag abort the release
- `feat(scope): ...` bumps minor
- `fix(scope): ...` and `perf(scope): ...` bump patch
- `conte semver breaking` forces the next successful release to bump major
- after `conte semver breaking`, commit `.conte/config.json` before running `conte release create`
- commit scope is required
- commit descriptions may use uppercase or lowercase letters
- `version.current` stays bare SemVer while Git tags use `vX.Y.Z`

Supported options:

```bash
conte release preview
conte release create --allow-empty-release
conte release create --scope us-12
conte release create --scope us-12 --scope-mode strict
conte release create --no-tag
conte release create --no-changelog
conte release sync-develop --preview
```

If no versionable commits exist, the command aborts unless `--allow-empty-release` is used. In that case Conte forces a patch release so the new tag stays deterministic.

When `--no-tag` is used, the Conte release commit becomes the durable release marker. Re-running `conte release create --no-tag` with no new versionable commits does not create another release commit or duplicate `CHANGELOG.md`.

Release eligibility comes from the workflow engine. Conte also restores config and changelog state if a later release step fails, so partial releases are not left behind.

Scoped release mode uses the parsed Conventional Commit scope as an exact match filter:

- `--scope us-12` matches `feat(us-12): ...`, `fix(us-12): ...`, and `perf(us-12): ...`
- it does not match `us-123`, `core-us-12`, or `us-12-extra`
- `conte release create --scope <scope>` creates `release/<scope>` from the workflow base branch
- scoped release branches are supported for `gitflow`
- scoped releases can fail when the selected commits depend on commits outside the requested scope

## CI/CD Model

Local hooks are not enough for team enforcement.

Conte installs local hooks into `.conte/hooks`, configures Git with `core.hooksPath=.conte/hooks`, and generates `.conte/templates/commit-template.txt` with `git commit.template=.conte/templates/commit-template.txt` unless a user-managed local template is already configured.
These hooks are local developer safeguards only. They can be bypassed with `--no-verify`, so CI/CD must still enforce the same validation remotely.

Standard Git hooks do not block branch creation (`git checkout -b`, `git branch`). Conte blocks commits and pushes from invalid branches via `pre-commit` and `pre-push`.

Conte now generates CI/CD templates that call the CLI directly:

- `bash ./bin/conte status`
- `bash ./bin/conte doctor`
- `bash ./bin/conte release preview`
- `bash tests/run.sh` when present

Supported providers:

- GitHub Actions
- GitLab CI
- Azure DevOps Pipelines

Generate templates with:

```bash
conte generate cicd
conte generate cicd github
conte generate cicd --provider github
conte generate cicd --provider gitlab
conte generate cicd --provider azure
```

Release jobs are workflow-aware:

- `trunk`: mapped `main` only
- `kanban`: mapped `main` only by default
- `gitflow`: mapped `develop`

Repository GitHub Actions are split by branch flow:

- `feature/*`, `bugfix/*`, `fix/*`, `chore/*`, and `hotfix/*` -> PR -> `develop`
- `develop` -> PR -> `main`
- `main` -> tag `vX.Y.Z`
- tag `vX.Y.Z` -> private release in `conte-cli`
- private release -> `repository_dispatch` -> public release in `conte-cli-installer`

Only `release-from-tag.yml` creates releases.

## Distribution

Conte uses a release-metadata-driven distribution model.

Supported artifacts:

- `conte-cli-linux-x64.tar.gz`
- `conte-cli-linux-arm64.tar.gz`
- `conte-cli-macos-x64.tar.gz`
- `conte-cli-macos-arm64.tar.gz`
- `conte-cli-windows-x64.zip`
- `conte-cli-installer-windows-x64.exe`

Quick install:

```bash
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1 | iex
```

Windows CMD:

```cmd
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.cmd -o install.cmd && install.cmd && del install.cmd
```

Self-update:

```bash
conte update
```

This repository remains the source of truth for CLI code, CLI versioning, packaging, release artifacts, self-update logic, and the `latest.json` metadata format. Public tokenless installers and public release metadata are exposed from `conte-martin/conte-cli-installer`, so users do not need `GITHUB_TOKEN`.

Hosted release flow:

1. Push tag `vX.Y.Z` to `conte-cli`.
2. `conte-cli` builds artifacts and creates the private GitHub Release.
3. `conte-cli` triggers `repository_dispatch` on `conte-martin/conte-cli-installer` using `GITHUB_TOKEN`.
4. `conte-cli-installer` downloads private assets using `CONTE_CLI_TOKEN`.
5. `conte-cli-installer` creates the public release with public assets and `latest.json`.

Required GitHub Actions secret in `conte-cli-installer` is `CONTE_CLI_TOKEN`. The private `conte-cli` workflow uses GitHub Actions `GITHUB_TOKEN`.

The root `install.sh` in this repository is payload-based and expects an already unpacked Conte tree with `lib/` available. It is included in release payloads for internal metadata-driven installs; use the public installer repository scripts for curl-pipe installation.

By default, `conte update` fetches public metadata from `https://github.com/conte-martin/conte-cli-installer/releases/latest/download/latest.json`. Set `CONTE_RELEASE_METADATA_URL` to override for air-gapped environments or testing.

The `latest.json` contract is:

```json
{
  "version": "X.Y.Z",
  "linux_x64_url": "https://...",
  "linux_arm64_url": "https://...",
  "macos_x64_url": "https://...",
  "macos_arm64_url": "https://...",
  "windows_x64_url": "https://...",
  "windows_installer_x64_url": "https://...",
  "checksums_url": "https://..."
}
```

`conte update` downloads `checksums.txt` and verifies the artifact SHA256 before extraction.

The default install root is `~/.conte`, with the executable under `~/.conte/bin` on Linux and macOS. On Windows, Conte installs into `%USERPROFILE%\.conte` and uses `%USERPROFILE%\.conte\bin`.

Windows users need Git for Windows / Git Bash. The Windows installer installs Conte into `%USERPROFILE%\.conte`, ensures `%USERPROFILE%\.conte\bin` is on the user `PATH`, and provides `conte.cmd` for PowerShell. ZIP or manual Windows installs should also use `%USERPROFILE%\.conte`, not `%LOCALAPPDATA%\Programs\.conte` or `Program Files`.

After install:

```powershell
conte --version
conte doctor
```

Open a new PowerShell terminal before running those commands.

## Documentation

- [Architecture](docs/en/architecture.md)
- [Repository State](docs/en/repository-state.md)
- [Workflows](docs/en/workflows.md)
- [Installation](docs/en/installation.md)
- [Windows Installation](docs/installation/windows.md)
- [Usage](docs/en/usage.md)
- [Configuration](docs/en/configuration.md)
- [Commands](docs/en/commands.md)
- [CI/CD](docs/en/cicd.md)
- [Release](docs/en/release.md)
- [Changelog](docs/en/changelog.md)

## Testing

```bash
bash tests/run.sh
```

Windows users can still invoke the CLI through:

```powershell
.\bin\conte.cmd --help
```
