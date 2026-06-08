# Configuration

## Resolution Order

Conte resolves config in this order:

1. active workspace project config
2. repository config
3. global config

Repository config overrides global config. Workspace config overrides repository config for the current subproject.
Workspace detection only matches direct child project directories under `.conte/projects/<project>/config.json`.
Project names must use lowercase letters, numbers, and hyphens.

Inspection commands can use that effective layered view.
Repo-mutating commands always read and write the repository-local `.conte/config.json` so they do not inspect one layer and persist to another.
If `.conte/config.json` is missing, mutating commands fail before changing repository state.

## Repository Contract

Conte stores repository choices in `.conte/config.json`.

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
    "changelogFile": "CHANGELOG.md",
    "baselineRef": "9f2c1d0...",
    "baselineVersion": "0.1.0",
    "historyPolicy": "ignore-before-baseline",
    "invalidCommitPolicy": "fail-after-baseline"
  }
}
```

`breakingChange.nextBump` is `null` by default and becomes `"major"` after `conte semver breaking` is run.

`conte init` creates `.conte/config.json` only. It does not create `.conte/conte.conf`.
If a legacy `.conte/conte.conf` file already exists, Conte warns and continues without deleting or migrating it automatically.

## What Config Stores

Config stores:

- selected workflow
- current project version (bare SemVer)
- next-release major override (`breakingChange.nextBump`)
- logical-to-real branch mapping
- scope validation preference
- release tag prefix and changelog file path
- release adoption baseline and history policy
- hook enforcement state
- hook installation path
- selected installed hooks
- Hook Tasks

## What Config Does Not Store

Config does not store:

- branch regex
- branch lifecycle rules
- merge rules
- commit regex
- derived workflow rules
- validation outcomes
- external command extension points
- workflow overrides from external scripts

Those are derived at runtime by the workflow and validation engines.

This means branch validation patterns remain in `lib/core/workflow-engine/` and are not persisted in JSON.
Branch lifecycle and merge rules are derived internally from the selected workflow and cannot be overridden from configuration.

## Workflow Selection

`conte init` records the selected workflow and preserves the contract for runtime rule derivation.

The workflow is a label in config.
The rule set comes from the workflow engine, not from JSON.

Supported workflow ids:

- `trunk`
- `gitflow`
- `kanban`

The interactive workflow picker keeps `kanban` as the default selection.

## Branch Mapping

Conte uses logical branch names internally.

- `main`
- `develop`
- `release`

The config maps logical names to repository branches where needed.

Examples:

```json
{
  "mapping": {
    "main": "master"
  }
}
```

```json
{
  "mapping": {
    "main": "main",
    "develop": "dev"
  }
}
```

GitFlow example:

```json
{
  "workflow": "gitflow",
  "git": {
    "mainBranch": "main",
    "developBranch": "develop",
    "mapping": {
      "main": "main",
      "develop": "develop"
    }
  }
}
```

The workflow engine resolves those mappings first and then derives the effective branch validation pattern.
Generated branch regex is never stored in config.
Do not configure `branchLifecycle` or `mergeRules`; lifecycle and merge rules are application-owned behavior. `workflow: GitFlow` automatically activates GitFlow merge validation.

Workflow requirements:

- `trunk`: mapped `main` plus `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `chore/*`
- `kanban`: same as `trunk` plus `release/*`
- `gitflow`: mapped `main`, mapped `develop`, plus `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `release/*`, `hotfix/*`, `chore/*`

`gitflow` requires `git.developBranch`.

## Scope Rules

Scope presence is enforced by the workflow engine.
Scope format is validated against `commit.scopePattern`, with Conte's canonical minimum rule always enforced: `[a-z0-9]+(-[a-z0-9]+)*`.
Scopes must use lowercase letters, numbers, and hyphen only; they cannot start or end with hyphen or contain consecutive hyphens.
The commit description is not constrained by casing; only the `type(scope): ` header remains strict.

## Version Storage

The project version is stored as a bare SemVer string at the top level of the config:

```json
"version": "0.1.0"
```

The next-release major override is stored separately:

```json
"breakingChange": {
  "mode": "manual-command",
  "nextBump": null
}
```

`nextBump` is `null` by default. After `conte semver breaking` it is set to `"major"` and cleared after a successful `conte release create`.

Git tags are derived from the version value with a `v` prefix:

```text
v0.1.0
```

Conte uses the latest release tag as the release baseline when one exists. Existing repositories can also store an adoption baseline so old non-conventional history is ignored.

## Release Settings

The config stores the tag prefix, changelog file path, and adoption baseline:

```json
"release": {
  "tagPrefix": "v",
  "changelogFile": "CHANGELOG.md",
  "baselineRef": "9f2c1d0...",
  "baselineVersion": "0.1.0",
  "historyPolicy": "ignore-before-baseline",
  "invalidCommitPolicy": "fail-after-baseline"
}
```

`tagPrefix` is prepended to the bare SemVer to produce the Git tag (e.g. `v0.2.0`).
`changelogFile` names the file written by `conte release create`.
`baselineRef` is the commit where Conte starts release tracking for an existing repository.
`baselineVersion` is the version used when the baseline is the active marker.
`historyPolicy=ignore-before-baseline` prevents full-history scans by default.
`invalidCommitPolicy=fail-after-baseline` means old invalid commits are ignored, while invalid commits after adoption still fail releases.

`conte init --yes` writes `release.baselineRef=HEAD` when the repository already has commits. Empty repositories do not get a baseline until the first commit exists. To adopt manually or repair an older config, run:

```bash
conte history adopt --from HEAD
```

Conte does not store changelog text, branch regex, branch lifecycle rules, merge rules, commit regex, or SemVer bump rules in config. Those remain derived behavior.

## Hook Configuration

Conte stores hook preferences and installation state under:

```json
"hooks": {
  "enabled": true,
  "path": ".conte/hooks",
  "installed": ["commit-msg", "pre-push", "prepare-commit-msg", "pre-commit"],
  "tasks": []
}
```

Rules:

- `hooks.enabled` controls whether Conte expects hook enforcement to be active in the repository
- `hooks.path` defaults to `.conte/hooks`
- `hooks.installed` stores the selected hook names
- `hooks.tasks` stores explicit user-defined commands assigned to `commit-msg`, `prepare-commit-msg`, `pre-commit`, `pre-push`, `post-merge`, or `manual`
- older configs without a `hooks` section stay readable and default to disabled hooks unless Conte-managed hooks are detected

Conte writes hook files into `.conte/hooks` and configures Git with `core.hooksPath=.conte/hooks`.
Hooks are local safeguards only and can be bypassed with `--no-verify`, so CI/CD remains the enforcement authority for teams.

## Hook Tasks

Hook Tasks are configured under:

```json
"tasks": [
  { "name": "dotnet-test", "hook": "pre-push", "command": "dotnet test", "enabled": true }
]
```

Rules:

- Hook Tasks are repository-local commands
- Hook Tasks run only after Conte core hook validation succeeds
- `manual` tasks run only through `conte hooks task run <name>`
- Hook Tasks cannot register Conte commands, replace validation, or extend internal engines

## Global and Local Config

Global config lives at:

```text
~/.conte/config.json
```

Repository config lives at:

```text
.conte/config.json
```

Use:

```bash
conte config --global
conte config --local
```

Without a scope flag, `conte config get <key>` returns the effective value after applying config layering.
`conte config --local` always reads `.conte/config.json` directly.

## Workspace Projects

Conte can also resolve subproject config from:

```text
.conte/projects/<project>/config.json
```

When the current working directory is inside a configured subproject, Conte uses that config layer first.

## Workspace Configuration

Workspace mode enables monorepo support. It is activated by `conte init --workspace` and stored under the `workspace` key in `.conte/config.json`.

```json
{
  "workspace": {
    "enabled": true,
    "releaseMode": "service",
    "serviceDetection": "path",
    "scopeMeaning": "ticket",
    "multiServicePolicy": "fail",
    "scopePathValidation": "off",
    "sharedScopes": ["repo", "docs", "ci", "build", "deps"],
    "services": [
      {
        "name": "orders-api",
        "path": "services/orders-api",
        "tagPrefix": "orders-api@",
        "changelogFile": "services/orders-api/CHANGELOG.md",
        "version": "1.3.0"
      },
      {
        "name": "billing-api",
        "path": "services/billing-api",
        "tagPrefix": "billing-api@",
        "changelogFile": "services/billing-api/CHANGELOG.md",
        "version": "0.8.2"
      }
    ]
  }
}
```

Fields:

- `enabled` — `true` when workspace mode is active
- `releaseMode` — `"repository"` (one shared release for the whole repository) or `"service"` (each service releases independently). Older configs may still use `"single"` or `"independent"`.
- `serviceDetection` — currently `"path"`; services are resolved by their declared repository-relative paths.
- `scopeMeaning` — `"ticket"` means Conventional Commit scope remains ticket/story/issue context and does not represent a service name.
- `multiServicePolicy` — `"fail"`, `"warn"`, or `"allow"` for commits that touch multiple services.
- `scopePathValidation` — `"off"` by default for compatibility. Accepted values are `"off"`, `false`, `"warn"`, `"strict"`, and `true`.
- `sharedScopes` — list of repository-wide Conventional Commit scopes such as `repo`, `docs`, `ci`, `build`, and `deps`.
- `services[]` — list of declared services

Service fields:

| Field | Required | Description |
|---|---|---|
| `name` | yes | Unique service identifier; must match `^[a-z0-9]+(-[a-z0-9]+)*$` |
| `path` | yes | Relative path to the service root inside the repository |
| `tagPrefix` | yes | Git tag prefix for service releases (e.g. `orders-api@`) |
| `changelogFile` | yes | Relative path to the service changelog |
| `version` | yes | Current service version; strict SemVer `X.Y.Z` |

Rules:

- service `name`, `path`, and `tagPrefix` values must be unique across all declared services
- service paths must exist, be unique, and be non-overlapping for `conte doctor` to pass
- `path` and `changelogFile` must be safe relative paths that do not escape the repository root
- changelog files do not need to exist before release creation, but their parent directories must exist for diagnostics to pass
- workspace configuration is repository-local and always written to `.conte/config.json`; it is not a global or layered concern
- `conte status` shows `Workspace: disabled` when workspace config is missing or disabled. When enabled, it shows release mode, service detection, service count, and service name/path/version rows.
- `conte doctor` treats missing workspace config as disabled, not as an error. When enabled, it validates release mode, service detection, services config, service paths, tag prefixes, changelog files, multi-service policy, and shared scopes.
- `conte workspace doctor` validates workspace-specific constraints and reports `[ok]`, `[warn]`, or `[error]` per field

Inspect workspace state:

```bash
conte workspace status
conte workspace list
conte workspace doctor
conte service status <name>
conte service doctor <name>
```
