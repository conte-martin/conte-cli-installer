# Service Release Process

## Overview

When `workspace.releaseMode` is `independent`, each service is released separately using `conte release preview --service <name>` or `conte release create --service <name>`. This page documents the full service release lifecycle.

## Commands

### Preview a service release (read-only)

```bash
conte release preview --service <name>
```

Prints:
- Current version and latest tag
- Commits since the last service tag, filtered by service scope
- Calculated bump level (patch / minor)
- Next version and tag
- Changelog preview

Does **not** write any files or create any tags.

### Create a service release

```bash
conte release create --service <name>
```

Performs:
1. Collects commits since the last `<tagPrefix>*` tag, filtered by `service.scope`
2. Calculates the next SemVer version
3. Updates `service.version` in `.conte/config.json`
4. Updates `service.changelogFile` (prepends new section)
5. Creates a release commit
6. Creates a Git tag `<tagPrefix><version>`

On failure, rolls back all changes (config, changelog, tag).

### Options

| Option | Description |
|---|---|
| `--no-tag` | Create release without a Git tag |
| `--no-changelog` | Create release without updating the changelog |

## Version Calculation

Bump level is determined from commit messages since the last service tag:

| Commit pattern | Bump level |
|---|---|
| `feat(<scope>):` | **minor** |
| `fix(<scope>):` or any other type | **patch** |

Commits are filtered by `service.scope` only. Commits with other scopes are ignored for this service's version calculation.

Free-form breaking markers (`BREAKING CHANGE` or `type(scope)!:`) do not automatically create service major releases. Service major releases must be controlled by a Conte command.

## Tag Format

Tags follow `<service.tagPrefix><version>`, for example:
- `auth/v1.2.0` with `tagPrefix: auth/v`
- `billing/v0.9.4` with `tagPrefix: billing/v`

The tag prefix must be unique across all declared services.

## Rollback

If any step fails, the service release engine rolls back:
1. Deletes the created tag (if any)
2. Restores the original service version in `.conte/config.json`
3. Restores the original changelog content

## Integration with CI/CD

For automated releases in CI, use:

```yaml
- name: Release auth service
  run: conte release create --service auth
  env:
    CONTE_ASSUME_YES: "true"
```

## Scope Filtering

Only commits whose scope exactly matches `service.scope` are included. Commits with shared scopes (e.g., `docs`, `ci`) are excluded from service-specific releases.

## See Also

- [docs/specs/workspace.md](workspace.md) — Workspace configuration
- [docs/specs/monorepo.md](monorepo.md) — Monorepo overview
