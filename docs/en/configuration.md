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
    "changelogFile": "CHANGELOG.md"
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

Conte uses the latest release tag as the release baseline when one exists. If no release tag exists yet, it uses the stored version as the baseline.

## Release Settings

The config stores the tag prefix and changelog file path:

```json
"release": {
  "tagPrefix": "v",
  "changelogFile": "CHANGELOG.md"
}
```

`tagPrefix` is prepended to the bare SemVer to produce the Git tag (e.g. `v0.2.0`).
`changelogFile` names the file written by `conte release create`.

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
    "releaseMode": "independent",
    "scopePathValidation": "strict",
    "sharedScopes": ["chore", "deps"],
    "services": [
      {
        "name": "api",
        "path": "services/api",
        "scope": "api",
        "version": "1.0.0",
        "changelogFile": "services/api/CHANGELOG.md",
        "tagPrefix": "api-v",
        "releaseMode": "independent"
      },
      {
        "name": "worker",
        "path": "services/worker",
        "scope": "worker",
        "version": "0.3.1",
        "changelogFile": "services/worker/CHANGELOG.md",
        "tagPrefix": "worker-v",
        "releaseMode": "independent"
      }
    ]
  }
}
```

Fields:

- `enabled` — `true` when workspace mode is active
- `releaseMode` — `"single"` (one shared release for the whole repository) or `"independent"` (each service releases independently)
- `scopePathValidation` — `"off"` (disabled), `"warn"` (report mismatches), or `"strict"` (block commits whose scope does not match the file paths changed)
- `sharedScopes` — list of commit scopes that are exempt from scope/path validation (e.g. `chore`, `deps`)
- `services[]` — list of declared services

Service fields:

| Field | Required | Description |
|---|---|---|
| `name` | yes | Unique service identifier; must match `^[a-z0-9]+(-[a-z0-9]+)*$` |
| `path` | yes | Relative path to the service root inside the repository |
| `scope` | yes | Conventional Commit scope assigned to this service; must match `^[a-z0-9]+(-[a-z0-9]+)*$` |
| `version` | yes | Current service version; strict SemVer `X.Y.Z` |
| `changelogFile` | recommended | Relative path to the service changelog; defaults to repository-level `CHANGELOG.md` when absent |
| `tagPrefix` | recommended | Git tag prefix for service releases (e.g. `api-v` produces `api-v1.0.0`) |
| `releaseMode` | optional | Per-service override for `releaseMode` |

Rules:

- service `name`, `path`, `scope`, and `tagPrefix` values must be unique across all declared services
- `path` and `changelogFile` must be relative paths that do not escape the repository root
- workspace configuration is repository-local and always written to `.conte/config.json`; it is not a global or layered concern
- `conte workspace doctor` validates all of these constraints and reports `[ok]`, `[warn]`, or `[error]` per field

Inspect workspace state:

```bash
conte workspace status
conte workspace list
conte workspace doctor
conte service status <name>
conte service doctor <name>
```
