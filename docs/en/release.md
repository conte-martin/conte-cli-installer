# Release

## Command

```bash
conte release preview
conte release create
conte release sync-develop
```

Supported options:

```bash
conte release preview [--allow-empty-release] [--scope <scope>] [-s <scope>]
                      [--scope-mode <full|strict>] [-m <full|strict>]
                      [--include-internal] [--no-tag] [--no-changelog]
                      [--service <name>]
conte release create  [--allow-empty-release] [--scope <scope>] [-s <scope>]
                      [--scope-mode <full|strict>] [-m <full|strict>]
                      [--include-internal] [--no-tag] [--no-changelog]
                      [--service <name>]
conte release sync-develop [--preview]
```

## Command Model

Conte uses two different version surfaces:

- `conte version` reports only the installed CLI version
- `conte semver *` manages the project version state stored in `.conte/config.json`

Release creation is explicit:

- `conte release preview`: preview without writing files
- `conte release create`: create release artifacts, update changelog/config, and create the tag according to config

`conte semver` is intentionally separate from release execution:

- `conte semver get` shows the current project version.
- `conte semver next` calculates and prints only the next project version.
- `conte semver set <version>` sets the project version.
- `conte semver breaking` marks the next release as MAJOR.
- `conte release create` reads commits, calculates the release version, writes release state, creates the release commit, and creates the tag

For mutating release operations, Conte reads and writes the same repository-local `.conte/config.json`.
Workspace or global config can still affect inspection commands, but not `conte semver set`, `conte semver breaking`, or `conte release create`.

## Release Flow

The command performs these steps:

1. load `.conte/config.json`
2. resolve workflow rules from the workflow engine
3. resolve logical branch mapping from `git.mapping`
4. validate repo state and require a clean working tree
5. verify the current branch is eligible for release
6. find the latest `vX.Y.Z` tag
7. read non-merge commits since that tag
8. validate those commits
9. calculate the next SemVer version
10. update `version.current` and clear `breakingChange.nextBump`

...

- `breakingChange.nextBump` stores the next-release major override as `"major"` or `null`
- Git tags use `vX.Y.Z`
- release input is commit history since the latest release marker: the latest relevant `v*` tag, or the latest Conte release commit when a newer `--no-tag` release exists
- merge commits are ignored
- invalid non-merge Conventional Commits abort the release before version calculation
- commit scope is required
- commit descriptions may use uppercase or lowercase letters

When `--no-tag` is used, the release commit (`chore(release): cut vX.Y.Z`) is the durable marker. A second `conte release create --no-tag` run with no new versionable commits exits safely instead of creating a duplicate release commit or duplicate changelog section.

## Scoped Releases

`--scope <scope>` limits release calculation to commits whose parsed Conventional Commit scope matches exactly.

Examples:

- `feat(us-12): add endpoint`
- `fix(us-12): handle error`
- `perf(us-12): optimize query`

It does not match `us-123`, `core-us-12`, or `us-12-extra`.

Scoped commands:

```bash
conte release create --scope us-12
```

Scoped release creation:

1. validates the requested scope against Conte's canonical commit scope rule and `commit.scopePattern`
2. validates workflow and branch mapping before writing
3. for supported workflows, creates `release/<scope>` from the mapped workflow base branch
4. cherry-picks selected scoped commits in chronological order when the source branch is not the mapped workflow base branch
5. calculates the version and changelog from those scoped commits only
6. writes repository-local `.conte/config.json`, updates `CHANGELOG.md`, creates the release commit, and creates `vX.Y.Z`

Scoped release branches are supported for:

- `gitflow`: mapped `develop`

Scoped release branches are rejected for:

- `trunk`
- `kanban`

Scoped release creation can fail when the selected commits depend on commits outside the requested scope.

## Workflow-Specific Release Branches

- `trunk`: mapped `main` only
- `kanban`: mapped `main` only by default
- `gitflow`: mapped `develop` only

Example mapping:

```text
logical main -> master
logical develop -> dev
```

## SemVer Rules

- `feat(scope): <description>` -> minor
- `fix(scope): <description>` -> patch
- `perf(scope): <description>` -> patch
- `conte semver breaking` -> major on the next successful release
- other valid commit types do not bump version automatically

`conte semver breaking` writes the breaking marker to `.conte/config.json`. Commit that file before creating the release:

```bash
git add .conte/config.json
git commit -m "chore(release): mark next version as major"
conte release create
```

`<description>` may contain uppercase or lowercase letters. Conte does not enforce description casing, but it still requires the `type(scope): ` header and a non-empty description. Breaking syntax markers (`!` after scope, `BREAKING CHANGE` footer) are not part of the v1 commit format. Only `conte semver breaking` activates a MAJOR release. Merge commit subjects are ignored because release commit collection uses `git log --no-merges`.

If no versionable commits exist, Conte aborts unless `--allow-empty-release` is used. In that override case Conte forces a patch release so the result still produces a unique deterministic tag.

## Version vs Tag

Config stores bare SemVer:

```json
"version": "0.2.0"
```

Git tags use the `v` prefix:

```text
v0.2.0
```

If no release tag exists yet, Conte uses `version.current` as the release baseline.

## Service Releases

In workspace mode with `releaseMode: independent`, each service releases independently using its declared commit scope.

Usage:

```bash
conte release preview --service <name>
conte release create --service <name>
```

Behavior:

1. resolves the named service from `workspace.services[]` in `.conte/config.json`
2. uses the service's `scope` field as the commit filter (equivalent to `--scope <service.scope>`)
3. reads commits since the last tag matching the service's `tagPrefix` pattern
4. calculates the next version for that service
5. writes the service changelog to `changelogFile` when configured
6. creates a tag using the service `tagPrefix` (e.g. `api-v1.2.0`)
7. updates the service `version` field in `.conte/config.json`

Notes:

- `--service <name>` and `--scope <scope>` are mutually exclusive; `--service` derives the scope from the service declaration
- workspace mode must be enabled and the named service must be declared; unknown service names exit with an error
- `conte release preview --service <name>` is always safe; it never writes files or tags
- service releases respect all standard release options: `--allow-empty-release`, `--no-tag`, `--no-changelog`, `--include-internal`
- for `releaseMode: single`, omit `--service`; the release uses the shared repository version and changelog

## Rollback Guarantees

Conte avoids partial release state:

- if `version.current` update fails, no changelog or tag is written
- if changelog generation or write fails, `version.current` is restored
- if tag creation fails, both config and changelog are restored

## CI/CD Recommendation

CI/CD should run releases only from branches that the workflow permits: mapped `main` for `trunk` and default `kanban`; mapped `develop` for `gitflow`.

Generated CI/CD templates automate the same `conte release create` path remotely. The templates validate the repository first, then run the release command only on release-eligible branches.

The generated release jobs rely on `conte release create` to write the release state, create the release commit, and create `vX.Y.Z`, then push the resulting branch head and tag.

## Hosted Release Artifacts

Release artifact production is owned by the private `conte-martin/conte-cli` repository. Its tag workflow runs on `vX.Y.Z`, builds platform artifacts, generates `checksums.txt`, and produces `latest.json` with bare SemVer and public download URLs.

`conte-martin/conte-cli-installer` is the public distribution endpoint. It receives a `repository_dispatch` event from `conte-cli`, downloads the private artifacts, verifies checksums, and publishes the public GitHub Release. `latest.json` in this public release is the file that `install.sh`, `install.ps1`, and `conte update` resolve by default.

End-to-end release flow:

1. Push tag `vX.Y.Z` to `conte-cli`.
2. `conte-cli` builds artifacts and creates the private GitHub Release.
3. `conte-cli` triggers `repository_dispatch` on `conte-martin/conte-cli-installer` with event type `publish-release` using `GITHUB_TOKEN`.
4. `conte-cli-installer` downloads private assets using `CONTE_CLI_TOKEN`.
5. `conte-cli-installer` creates the public release with platform artifacts, `checksums.txt`, and `latest.json`.

Required GitHub Actions secrets:

- `conte-cli`: no custom secret; uses the built-in `GITHUB_TOKEN`
- `conte-cli-installer`: `CONTE_CLI_TOKEN` — must have read access to private release assets on `conte-martin/conte-cli`

The private workflow does not print token values in logs.
