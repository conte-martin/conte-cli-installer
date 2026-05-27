# CI/CD

## Principle

Conte treats CI/CD as the remote enforcement authority:

```text
Local hooks -> developer experience
CI/CD -> enforcement
CLI -> single source of behavior
```

Local hooks are useful, but they are not sufficient for team-wide guarantees. A contributor can bypass local hooks. CI/CD cannot be skipped in the same way.

## Command

Generate templates with:

```bash
conte generate cicd
conte generate cicd --provider github
conte generate cicd --provider gitlab
conte generate cicd --provider azure
```

If no provider is supplied, Conte uses an existing CI/CD file when present, otherwise tries to detect the provider from `origin`, and finally falls back to `github`.

## Supported Providers

- GitHub Actions
- GitLab CI
- Azure DevOps Pipelines

Generated files:

- GitHub: `.github/workflows/conte.yml`
- GitLab: `.gitlab-ci.yml`
- Azure DevOps: `azure-pipelines.yml`

## What Templates Enforce

All generated templates run the CLI instead of duplicating validation rules:

- `bash ./bin/conte status`
- `bash ./bin/conte doctor`
- `bash ./bin/conte release preview`
- `bash tests/test_install.sh` when present

That means pipelines fail on:

- invalid branch names
- invalid commit messages
- invalid config state
- invalid release attempts

## Workflow-Aware Pipelines

Release job behavior is derived from the workflow engine:

- `trunk`: release from mapped `main`
- `kanban`: release from mapped `main`
- `gitflow`: release from mapped `develop`

Validation triggers include the branch families allowed by the workflow, while release jobs are narrowed to release-eligible branches only.

## Conte CLI Repository Workflows

The `conte-martin/conte-cli` repository uses separate GitHub Actions workflows by responsibility:

- `feature/*`, `bugfix/*`, `fix/*`, `chore/*`, and `hotfix/*` branches open PRs into `develop`.
- `pr-validation.yml` validates PRs targeting `develop` with syntax, fast tests, smoke integration, and conditional release or Windows-sensitive tests.
- `develop-integration.yml` runs full integration groups after a push lands in `develop`.
- `develop` opens PRs into `main`.
- `main-gate.yml` fails unless the PR source branch is exactly `develop`, then runs release-candidate Linux validation and a Windows package dry run.
- `main-smoke.yml` runs light validation after a push lands in `main`.
- In `conte-cli`, `release-from-tag.yml` is the only workflow that creates source CLI releases, and it runs only for tags matching `vX.Y.Z`.
- In this installer repository, `.github/workflows/publish-release.yml` republishes those assets as public releases.

The release path is:

```text
feature/*, bugfix/*, fix/*, chore/*, hotfix/* -> PR -> develop
develop -> PR -> main
main -> tag vX.Y.Z
tag vX.Y.Z -> private release in conte-cli
private release -> repository_dispatch -> public release in conte-cli-installer
```

Release tags must point to commits reachable from `origin/main`.

The private `conte-cli` release workflow uses `GITHUB_TOKEN` for the private GitHub Release and for the public `repository_dispatch` call. The public `conte-cli-installer` workflow requires `CONTE_CLI_TOKEN` to download private assets and publish the public release. Do not print token values in workflow logs.

## Release Automation

Each generated template includes:

1. a validation stage/job
2. a release stage/job
3. an actual `conte release create` invocation in the release job

The release job then:

- updates `.conte/config.json`
- updates `CHANGELOG.md`
- creates the Git tag
- commits release artifacts
- pushes the branch and tag

## Diagnostics

`conte status` reports whether CI/CD is configured, the provider, and the latest release version/tag.

`conte doctor` reports:

- whether CI/CD is configured
- which provider and template were detected
- whether the generated template still contains the required Conte enforcement commands

If CI/CD is missing, doctor warns. If a configured pipeline no longer contains the required enforcement steps, doctor fails.
