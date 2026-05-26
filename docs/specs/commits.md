# Commits

## Format

Every commit message must follow Conventional Commits with mandatory scope:

```
<type>(<scope>): <description>
```

Scope is required. There is no optional-scope mode in v1.

## Allowed Types

```
feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
```

## Scope Rules

- Lowercase letters, numbers, and hyphen only.
- Cannot start or end with a hyphen.
- No consecutive hyphens.
- Canonical pattern: `[a-z0-9]+(-[a-z0-9]+)*`

## Description Rules

- Must be non-empty.
- Must follow `: ` (colon + space).
- Casing is free (uppercase or lowercase allowed).

## SemVer Mapping

| Type | Bump |
|---|---|
| `feat` | MINOR |
| `fix` | PATCH |
| `perf` | PATCH |
| `docs`, `style`, `refactor`, `test`, `build`, `ci`, `chore`, `revert` | No automatic bump |

## Breaking Changes

Breaking changes must NOT be activated by:

- Writing `!` after the scope (e.g., `feat(scope)!: description`).
- Including `BREAKING CHANGE` in the commit body or footer.

The only way to mark a release as MAJOR is the explicit manual command:

```
conte semver breaking
```

This sets `breakingChange.nextBump: "major"` in `.conte/config.json`. The config change must be committed before `conte release create` runs. On a successful release, `breakingChange.nextBump` is cleared automatically.

## Commit Pattern

The internal validation pattern is:

```
^(<type>)\((<scope>)\): .+$
```

The `!` indicator and `BREAKING CHANGE` footer are not part of the v1 commit format.

## Validation

- All non-merge commits since the last release tag are validated before release.
- Invalid commits abort `conte release create` before version calculation.
- Merge commits are ignored (release collection uses `git log --no-merges`).
