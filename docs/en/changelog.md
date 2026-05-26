# Changelog

## Source of Truth

`CHANGELOG.md` is generated when `conte release create` runs, or explicitly with `conte changelog generate`.

The source of truth is always commit history:

- Conventional Commit subjects
- only commits since the last release tag
- no merge commits

Conte does not derive changelog entries from PR titles, merge summaries, or manual notes.

## Generation Rules

On each release Conte:

1. reads non-merge commits since the latest `vX.Y.Z` tag
2. validates every commit against the shared commit rules
3. groups entries by type and scope
4. inserts the newest release at the top of `CHANGELOG.md`
5. preserves older release sections unchanged

If changelog composition or write fails, the release aborts and restores config state instead of leaving a partial release behind.

## Format

```md
# Changelog

## v0.2.0 - 2026-04-28

### Features

#### auth
- agregar login de usuario

### Fixes

#### api
- corregir error 500
```

## Type Mapping

- `feat` -> `Features`
- `fix` -> `Fixes`
- `perf` -> `Performance`
- `docs` -> `Documentation`
- `style` -> `Style`
- `refactor` -> `Refactoring`
- `test` -> `Tests`
- `build` -> `Build`
- `ci` -> `CI/CD`
- `chore` -> `Maintenance`
- `revert` -> `Reverts`

## Operational Notes

- `conte changelog preview` prints a changelog preview without writing the file
- `conte release preview` prints the release plan and changelog preview without writing files
- `conte release create --no-changelog` skips the file update entirely
- invalid commits abort the release instead of being silently omitted
- PR titles and merge messages are never used as changelog input
