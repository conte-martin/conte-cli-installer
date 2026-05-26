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
  "workflow": "kanban",
  "version": {
    "current": "0.1.0",
    "breaking": false
  },
  "git": {
    "mainBranch": "main",
    "developBranch": null,
    "mapping": {
      "main": "main"
    }
  },
  "commit": {
    "scopeRequired": true,
    "scopePattern": "^[a-z0-9]+(-[a-z0-9]+)*$"
  },
  "release": {
    "command": "conte release create"
  },
  "hooks": {
    "enabled": true,
    "path": ".conte/hooks",
    "installed": ["commit-msg", "pre-push", "prepare-commit-msg", "pre-commit"],
    "tasks": []
  }
}
```

`conte init` creates `.conte/config.json` only. It does not create `.conte/conte.conf`.
If a legacy `.conte/conte.conf` file already exists, Conte warns and continues without deleting or migrating it automatically.

## What Config Stores

Config stores:

- selected workflow
- current version
- next-release major override
- logical-to-real branch mapping
- scope validation preference
- release command name
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
  "workflow": "GitFlow",
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
- `kanban`: same as `trunk` by default
- `gitflow`: mapped `main`, mapped `develop`, plus `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `release/*`, `hotfix/*`, `chore/*`

`gitflow` requires `git.developBranch`.

## Scope Rules

Scope presence is enforced by the workflow engine.
Scope format is validated against `commit.scopePattern`, with Conte's canonical minimum rule always enforced: `[a-z0-9]+(-[a-z0-9]+)*`.
Scopes must use lowercase letters, numbers, and hyphen only; they cannot start or end with hyphen or contain consecutive hyphens.
The commit description is not constrained by casing; only the `type(scope): ` header remains strict.

## Version Storage

`version.current` stores bare SemVer only, and `breakingChange.nextBump` stores the next-release major override:

```json
"version": {
  "current": "0.1.0",
  "breaking": false
}
```

Git tags are derived from that value with a `v` prefix:

```text
v0.1.0
```

Conte uses the latest release tag as the release baseline when one exists. If no release tag exists yet, it uses `version.current` as the baseline.

## Release Command

The config stores the command name:

```json
"release": {
  "command": "conte release create"
}
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
