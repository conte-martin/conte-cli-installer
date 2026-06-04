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
- `bash ./bin/conte validate workspace`
- `bash tests/run.sh` when present

Workspace-enabled repositories must also run a service release preview when service release mode is active:

```bash
bash ./bin/conte validate workspace
if bash ./bin/conte config get workspace.enabled 2>/dev/null | grep -qi true; then
  if [ "$(bash ./bin/conte config get workspace.releaseMode 2>/dev/null)" = "service" ]; then
    bash ./bin/conte release preview --all-services
  fi
fi
```

That means pipelines fail on:

- invalid branch names
- invalid commit messages
- invalid config state
- invalid workspace commit-to-service rules
- invalid release attempts

## Workflow-Aware Pipelines

Release job behavior is derived from the workflow engine:

- `trunk`: release from mapped `main`
- `kanban`: release from mapped `main`
- `gitflow`: release from mapped `develop`

Validation triggers include the branch families allowed by the workflow, while release jobs are narrowed to release-eligible branches only.

## Conte CLI Repository Workflows

The `conte-martin/conte-cli` repository uses separate GitHub Actions workflows by merge timing:

- `ci-pr.yml` validates pull requests into `main`, `master`, or `develop`. It checks source branch rules, every non-merge PR commit subject, Bash syntax, fast unit tests, smoke integration, and workspace validation for code changes. Release-sensitive, Windows-sensitive, package, and documentation path checks run only when matching files change.
- `ci-main.yml` validates the integrated state after a push to `main` or `master`. It runs the full Linux suite, cross-platform sensitive tests on Linux/macOS/Windows, release-history preview from real tags, and a Windows package dry run.
- `ci-scheduled.yml` runs weekly and on manual dispatch to catch platform, installer, package, and toolchain drift that does not need to block every PR.
- `ci-release.yml` is the only workflow that creates GitHub Releases. It runs only for tags matching `vX.Y.Z`, validates that the tag is reachable from `origin/main` or `origin/master`, builds artifacts, writes checksums and release metadata, and publishes the private release before dispatching the public installer release.

The release path is:

```text
feature/*, bugfix/*, fix/*, chore/*, hotfix/* -> PR -> develop
develop -> PR -> main
main -> tag vX.Y.Z
tag vX.Y.Z -> private release in conte-cli
private release -> repository_dispatch -> public release in conte-cli-installer
```

Release tags must point to commits reachable from `origin/main` or `origin/master`.

The private `conte-cli` release workflow uses `GITHUB_TOKEN` for the private GitHub Release and for the public `repository_dispatch` call. The public `conte-cli-installer` workflow requires `CONTE_CLI_TOKEN` to download private assets and publish the public release. Do not print token values in workflow logs.

## Branch Protection

Recommended required pull request checks:

- `Branch and commit validation`
- `Syntax and fast tests`
- `Workspace validation` for code changes
- `Integration smoke` for code changes

Conditional checks such as `Release-sensitive tests`, `Windows-sensitive tests`, and `Package dry run` should remain visible and should be required through rulesets only when the touched paths make them relevant. Documentation review stays part of normal code review instead of a separate required path-link job. `Main CI`, `Scheduled CI`, and `Release CI` are not pull request checks; they validate integrated history, drift, and release publishing respectively.

Merge queue is optional. If enabled, add a `merge_group` trigger to `ci-pr.yml` and require the same deterministic checks as pull requests without adding publishing or artifact upload steps.

Squash merge is safest for the changelog strategy when each PR title is rewritten to a valid scoped Conventional Commit. Rebase merge is also safe when every commit already passes Conte validation. Merge commits are acceptable only because Conte ignores merge commits, but they add noise and should not be used as the source for release notes.

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
