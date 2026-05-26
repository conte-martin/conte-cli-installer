# Architecture

## Phase 6 Model

Conte CLI operates as a workflow-driven validation, release, CI/CD, Hook Tasks, and distribution platform.

```text
Config -> user input
Workflow -> rules
Validation -> enforcement
Hooks -> developer experience
CI/CD -> remote enforcement
Release -> changelog + version + tag
Hook Tasks -> explicit local commands
Distribution -> reliable delivery
CLI -> orchestration
```

## Core Modules

```text
lib/core/
  config/
    store.sh
  distribution/
    manager.sh
  workspace.sh
  git/
    branches.sh
    repository.sh
  hooks/
    install.sh
    tasks.sh
  cicd/
    engine.sh
  release/
    semver.sh
    commit-parser.sh
    changelog.sh
    release-engine.sh
  versioning/
    metadata.sh
  validation/
    config.sh
    engine.sh
  workflow-engine/
    catalog.sh
    lifecycle.sh
```

## Workflow Engine

The workflow engine is the single source of truth for derived rules.

It provides:

- current workflow lookup
- logical branch requirements
- allowed branch families
- derived branch regex
- internal branch lifecycle definitions
- derived commit regex
- release-branch rules
- SemVer mapping rules

The workflow engine never reads regex from config except `commit.scopePattern`, which is a user preference layered on top of Conte's canonical commit scope rule and not a workflow rule. Branch lifecycle rules are also internal workflow behavior and are not read from config.

## Branch Resolution

Conte validates logical names through repository mapping:

```text
main    -> config.git.mainBranch
develop -> config.git.developBranch
release -> release/*
```

All branch validation uses resolved branch names before building the final regex.

Example:

```json
{
  "git": {
    "mainBranch": "master",
    "developBranch": "dev",
    "mapping": {
      "main": "master",
      "develop": "dev"
    }
  }
}
```

## Validation Engine

The validation engine is the only enforcement layer.

It validates:

- config integrity
- branch names
- commit messages
- commit scopes
- current branch
- repository mapping state

Commit validation stays strict on type and scope, but the description text may use uppercase or lowercase letters. The description must still be present and must still be separated from the header by `: `.

Hooks and CLI commands both call the same validation functions.

The release engine also reuses the same commit validation contract before calculating a version.

Generated CI/CD pipelines call the same CLI commands instead of duplicating validation logic in YAML.

Config and git state are cached within a process to reduce repeated parsing and repository lookups during one CLI invocation.

## Hooks

Installed hooks are intentionally thin.

- `commit-msg` loads the validation engine and calls `conte::val_commit_message`
- `pre-commit` loads the validation engine, validates the current branch, and then runs enabled Hook Tasks for `pre-commit`
- `pre-push` loads the validation engine, validates the current branch, checks workflow-aware merge targets when Git supplies source and target refs, and then runs enabled Hook Tasks for `pre-push`
- `prepare-commit-msg` loads the shared hook runtime and runs enabled Hook Tasks for `prepare-commit-msg`
- `post-merge` runs enabled Hook Tasks for `post-merge`

The hooks do not duplicate rules.

Conte-managed hooks are written into `.conte/hooks` and activated through `git config core.hooksPath .conte/hooks`.
This keeps Conte-owned hook files separate from user-managed files under `.git/hooks`.

Hooks improve developer experience, but they are not the enforcement authority for teams.

Hook Tasks can target:

- `pre-commit`
- `commit-msg`
- `prepare-commit-msg`
- `pre-push`
- `post-merge`
- `manual`

Hook Tasks are not an extension system. They cannot register Conte commands, replace validation, or alter release and CI/CD engines.

## CI/CD Engine

The CI/CD engine generates provider-specific templates under:

- `.github/workflows/`
- `.gitlab-ci.yml`
- `azure-pipelines.yml`

Each template is workflow-aware and provider-aware, but intentionally thin in logic. The pipeline delegates enforcement to the CLI by running:

- `bash ./bin/conte status`
- `bash ./bin/conte doctor`
- `bash ./bin/conte release preview`
- `bash tests/run.sh` when present

That keeps branch validation, commit validation, config validation, and release validation inside one codebase.

## Release Engine

The release engine is commit-driven and workflow-aware.

High-level flow:

1. Load `.conte/config.json`.
2. Resolve logical branch mapping.
3. Validate repo state.
4. Check whether the current branch is eligible for release.
5. Find the latest `vX.Y.Z` tag.
6. Read non-merge commits since that tag.
7. Validate commits. `!` syntax markers do not force MAJOR. Only `breakingChange.nextBump=major` activates a MAJOR bump.
8. Derive the next SemVer version.
9. Generate the new release block for `CHANGELOG.md`.
10. Update `version.current` and clear `breakingChange.nextBump`.
11. Create the Git tag.

In CI/CD, release automation uses the same command path and then commits `.conte/config.json` and `CHANGELOG.md` before pushing the new tag.

## Release Branch Rules

Release eligibility is derived by workflow:

- `trunk`: release from mapped `main` only
- `kanban`: release from mapped `main` only by default
- `gitflow`: release from mapped `develop`

Mapped branches always come from config:

```text
logical main -> git.mapping.main
logical develop -> git.mapping.develop
```

The CI/CD engine uses the same workflow-derived release eligibility when building provider-specific release jobs.

## Branch Rule Shape

Workflow branch families are fixed in code, not config:

- `trunk` and `kanban`: `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `chore/*`
- `gitflow`: mapped `develop`, plus `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `release/*`, `hotfix/*`, `chore/*`

Branch suffixes are validated with a strict reusable pattern:

```regex
[a-z0-9]+([.-][a-z0-9]+)*
```

That forbids spaces, underscores, uppercase letters, trailing separators, and repeated `--` or `..`.

## SemVer Rules

Conte derives bumps from commit subjects only:

- `feat(scope): ...` -> minor
- `fix(scope): ...` -> patch
- `perf(scope): ...` -> patch
- `docs|style|refactor|test|build|ci|chore|revert` -> no automatic bump

Breaking syntax markers (`!` after scope, `BREAKING CHANGE` footer) are not part of the v1 commit format. MAJOR is promoted only after the explicit manual override command marks `version.breaking=true`:

```bash
conte semver breaking
```

## Changelog Source of Truth

`CHANGELOG.md` is generated at release time from commits only.

Conte does not use:

- PR titles
- merge commit subjects
- manual changelog fragments as release input

That keeps release derivation deterministic and auditable.

## Hook Tasks

Hook Tasks are stored in `.conte/config.json` under `hooks.tasks`.
Each task has a name, target hook, command, and enabled flag.

The runner executes enabled tasks after Conte's core hook validation succeeds. Manual tasks never run from Git hooks; users run them with `conte hooks task run <name>`.

## Config Resolution

Conte resolves configuration in layers:

1. workspace project config
2. repository config
3. global config

This allows:

- organization defaults in the global config
- repository overrides in `.conte/config.json`
- subproject overrides in `.conte/projects/<project>/config.json`

Workspace detection is boundary-aware. A directory named `api2` does not match a project named `api`, and invalid project names are ignored.

## Distribution Layer

Phase 6 ships the full distribution layer:

- embedded `CONTE_VERSION` in `bin/conte`
- default public installer-repository metadata URL with `CONTE_RELEASE_METADATA_URL` override
- metadata-driven install and self-update via `install.sh` and `conte update`
- SHA256 verification through `checksums.txt` before extraction
- atomic replacement with rollback on payload validation failure
- per-platform artifact selection: linux/macos/windows × x64/arm64
- packaging scripts under `scripts/package/`

The distribution model remains intentionally lightweight: the CLI is Bash-first, and package-manager integrations such as Homebrew or npm are design targets rather than mandatory runtime dependencies.

### Metadata Format

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

The default metadata URL is resolved from `CONTE_RELEASE_METADATA_URL` if set, otherwise from `https://github.com/conte-martin/conte-cli-installer/releases/latest/download/latest.json`. The core repository still owns the CLI code, packaging, release artifacts, update logic, and metadata contract; the public installer repository exposes tokenless install scripts and public release metadata/assets.

## Telemetry Design

Conte does not implement telemetry in this phase.

The intended future design is:

- anonymous only
- opt-in only
- no repo content or commit message capture
