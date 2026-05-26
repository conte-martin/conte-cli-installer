# Workflows

Source of truth: `lib/core/workflow-engine/catalog.sh`.

## Supported Workflows

### trunk

- **Purpose**: Continuous integration on a single main line with short-lived feature branches.
- **Allowed branches**: `main` (or `master`), `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `chore/*`.
- **Merge direction**: All branches merge into `main` (or `master`).
- **Release behavior**: Release from mapped `main` only. Scoped releases not supported.
- **Unsupported**: `develop`, `release/*`.

### kanban

- **Purpose**: Continuous delivery with task-based branches, no dedicated release branches.
- **Allowed branches**: Same as trunk: `main` (or `master`), `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `chore/*`.
- **Merge direction**: All branches merge into `main` (or `master`).
- **Release behavior**: Release from mapped `main` only. Scoped releases not supported. Kanban must not create `release/*` branches by default.
- **Unsupported**: `develop`, `release/*`, scoped release branches.

### gitflow

- **Purpose**: Structured branching with dedicated develop and release branches.
- **Allowed branches**: `main` (or `master`), `develop`, `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `release/*`, `hotfix/*`, `chore/*`.
- **Merge rules**:

| Source | Target |
|---|---|
| `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `chore/*` | `develop` |
| `release/*` | `main` (or `master`), then `develop` |
| `hotfix/*` | `main` (or `master`), then `develop` |

- **Release behavior**: Release from mapped `develop` only. Scoped releases supported.
- **Required**: `develop` branch must exist.

## Unsupported Workflows

- `github-flow`: Not supported in v1. Users on github-flow should migrate to `trunk`.
- `release-flow`: Not supported in v1. Users on release-flow should migrate to `gitflow`.

## Unsupported Branch Actions

- Merging `feature/*`, `bugfix/*`, `fix/*`, or `chore/*` directly into `main` in gitflow.
- Merging `develop` into `main` without a `release/*` branch in gitflow.
- Creating `develop` or `release/*` branches in trunk or kanban.
