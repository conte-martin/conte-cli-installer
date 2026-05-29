# Workspace Feature Specification

## Overview

Conte supports repositories that contain multiple microservices via an optional workspace mode. When enabled, the root `.conte/config.json` becomes the source of truth for all declared services. Workspace mode is explicitly opt-in: repositories that do not set `workspace.enabled` continue to behave exactly as before.

## Configuration Model

The `workspace` section is optional in `.conte/config.json`:

```json
{
  "workspace": {
    "enabled": true,
    "releaseMode": "independent",
    "scopePathValidation": "warn",
    "sharedScopes": ["shared", "repo", "docs", "ci"],
    "services": [
      {
        "name": "auth",
        "path": "services/auth",
        "scope": "auth",
        "version": "0.1.0",
        "changelogFile": "services/auth/CHANGELOG.md",
        "tagPrefix": "auth/v",
        "releaseMode": "independent"
      }
    ]
  }
}
```

### Field Reference

| Field | Type | Required | Valid values | Default |
|---|---|---|---|---|
| `workspace.enabled` | bool | no | `true`, `false` | `false` |
| `workspace.releaseMode` | string | no | `single`, `independent` | `independent` |
| `workspace.scopePathValidation` | string | no | `off`, `warn`, `strict` | `off` |
| `workspace.sharedScopes` | string[] | no | scope pattern values | `[]` |
| `workspace.services` | object[] | no | — | `[]` |
| `service.name` | string | yes | `^[a-z0-9]+(-[a-z0-9]+)*$` | — |
| `service.path` | string | yes | relative path inside repo | — |
| `service.scope` | string | yes | must match `commit.scopePattern` | — |
| `service.version` | string | yes | SemVer `X.Y.Z` | — |
| `service.changelogFile` | string | no | relative path | `<path>/CHANGELOG.md` |
| `service.tagPrefix` | string | no | non-empty string | `<name>/v` |
| `service.releaseMode` | string | no | `single`, `independent` | `independent` |

### Uniqueness Constraints

The following fields must be unique across all declared services:
- `name`
- `scope`
- `path`
- `tagPrefix`

### Path Constraints

- `service.path` must be a relative path (no leading `/`)
- `service.path` must not escape the repository root (no `../` that escapes)
- `service.changelogFile` must not escape the repository root

## Behavioral Rules

### When `workspace.enabled` is `false` or absent

All commands behave as they did before this feature was introduced. No workspace section is shown, no service validation is performed, and `--service` flags are not accepted.

### When `workspace.enabled` is `true`

- `conte status` shows a **Workspace** section with enabled state, release mode, service count, and current service if the working directory is inside a service path.
- `conte doctor` validates the workspace section and all service declarations.
- `conte workspace status/list/doctor` provide workspace-specific views.
- `conte service list/status/doctor` provide service-specific views.
- `conte validate commit` additionally validates that the commit scope is declared in `services[].scope` or `sharedScopes`.
- `conte validate scope-paths` checks service scope/path consistency.
- `conte release preview --service <name>` previews a scoped release without writing files.
- `conte release create --service <name>` creates a scoped release.

## Service Detection

When the current working directory is inside a declared service path, Conte detects the active service using **longest-prefix path match**:

1. Normalize both the repo root and current directory to canonical paths.
2. Compute `relative_path = current_dir − repo_root`.
3. For each declared service, check whether `relative_path` equals `service.path` or starts with `service.path/`.
4. Return the service with the longest matching path (most specific match wins).

This supports nested service layouts such as `services/auth` inside a broader `services` service entry.

## Commit Scope Validation

When `workspace.enabled=true`, after the standard commit format check, Conte additionally checks that the scope is declared:

- **Pass**: scope matches a `service.scope` value
- **Pass**: scope is in `sharedScopes`
- **Fail**: scope is unknown → actionable error listing declared scopes

Commits without a scope (when `scopeRequired=false`) bypass the workspace scope check.

## Release Modes

### `single`

All services are released together with a single version bump and a shared tag. Intended for monorepos with tightly coupled services.

### `independent`

Each service is released independently with its own version, changelog, and tag. Use `conte release preview/create --service <name>` for per-service releases.
