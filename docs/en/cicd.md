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
- `bash tests/run.sh` when present

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

## Installer Repository Workflow

This repository (`conte-martin/conte-cli-installer`) contains a single workflow: `publish-release.yml`.

It is triggered exclusively by a `repository_dispatch` event of type `publish-release` sent by `conte-martin/conte-cli` after a successful private release build.

Workflow responsibilities:

- receives the `repository_dispatch` payload with the target version and private artifact URLs
- downloads private build artifacts from `conte-martin/conte-cli` using `CONTE_CLI_TOKEN`
- verifies SHA256 checksums for every artifact before publishing
- creates or updates the public GitHub Release with platform-specific artifacts, `checksums.txt`, and `latest.json`
- `latest.json` points to the public asset URLs so that `install.sh`, `install.ps1`, and `conte update` can resolve artifacts without a `GITHUB_TOKEN`

The end-to-end release path is:

```text
tag vX.Y.Z on conte-cli
  -> private release build (conte-cli)
  -> repository_dispatch to conte-cli-installer
  -> publish-release.yml downloads, verifies, and publishes public release
  -> latest.json available at the default CONTE_RELEASE_METADATA_URL
```

Required secrets:

- `conte-cli-installer`: `CONTE_CLI_TOKEN` — must have read access to private release assets on `conte-martin/conte-cli`.

Do not print token values in workflow logs.

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
