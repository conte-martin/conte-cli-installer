# Workspace / Monorepo service releases

## Overview

Conte can release services independently in a workspace or monorepo. In service release mode, the Conventional Commit scope stays short and represents a ticket, story, issue, or short functional context. The service is detected from changed file paths.

Recommended:

```text
feat(us-12): agregar confirmación de pedido
fix(issue-89): corregir validación de saldo
```

Not recommended:

```text
feat(orders-api-us-12): agregar confirmación de pedido
feat(orders-api): agregar confirmación de pedido
```

Reason:

```text
scope = ticket/story/issue/short functional context
service = inferred by changed file path
```

Example:

```text
Branch: feature/us-12-confirm-order
Commit: feat(us-12): agregar confirmación de pedido
Files: services/orders-api/src/ConfirmOrder.cs
Command: conte release preview --service orders-api
Tag: orders-api@1.4.0
```

## Configuration

Workspace support is opt-in.

```bash
conte init --workspace --release-mode service --service orders-api --service-path services/orders-api
conte workspace add-service billing-api --path services/billing-api --version 0.8.2
```

Complete `.conte/config.json` workspace example:

```json
{
  "workspace": {
    "enabled": true,
    "releaseMode": "service",
    "serviceDetection": "path",
    "scopeMeaning": "ticket",
    "multiServicePolicy": "fail",
    "scopePathValidation": "off",
    "sharedScopes": ["repo", "docs", "ci", "build", "deps"],
    "services": [
      {
        "name": "orders-api",
        "path": "services/orders-api",
        "tagPrefix": "orders-api@",
        "changelogFile": "services/orders-api/CHANGELOG.md",
        "version": "1.3.0"
      },
      {
        "name": "billing-api",
        "path": "services/billing-api",
        "tagPrefix": "billing-api@",
        "changelogFile": "services/billing-api/CHANGELOG.md",
        "version": "0.8.2"
      }
    ]
  }
}
```

Workspace fields:

- `enabled`: turns workspace support on or off
- `releaseMode`: `repository` for one repository release, or `service` for independent service releases
- `serviceDetection`: currently `path`
- `scopeMeaning`: `ticket` means commit scope represents a ticket/story, not a service
- `multiServicePolicy`: controls commits touching multiple services
- `scopePathValidation`: controls optional scope/path validation; default is `off`
- `sharedScopes`: scopes allowed for repo-wide changes
- `services`: list of service definitions

Service fields:

- `name`: service identifier
- `path`: root path of the service
- `tagPrefix`: prefix used for service tags
- `changelogFile`: service changelog path
- `version`: current service version

## Commit scopes vs services

Workspace mode keeps the same Conventional Commit shape:

```text
<type>(<scope>): <description>
```

The scope is mandatory and should stay short. It is not parsed as the service name.

Valid examples:

```text
feat(us-12): agregar confirmación de pedido
fix(issue-89): corregir validación de saldo
perf(us-33): optimizar consulta de órdenes
docs(repo): actualizar README
ci(repo): actualizar workflow
chore(deps): actualizar dependencias compartidas
```

Invalid or discouraged examples:

```text
feat(orders-api-us-12): agregar confirmación de pedido
feat(orders-api): agregar confirmación de pedido
feat(US-12): agregar confirmación de pedido
fix(issue_89): corregir validación de saldo
```

The service is detected from changed file paths, not from the scope.

## Service detection by path

Path detection maps changed files to declared service paths:

```text
services/orders-api/src/ConfirmOrder.cs -> orders-api
services/billing-api/src/Invoice.cs -> billing-api
README.md -> no service / shared scope required
```

Example:

```text
Commit:
feat(us-12): agregar confirmación de pedido

Changed files:
services/orders-api/src/ConfirmOrder.cs
services/orders-api/tests/ConfirmOrderTests.cs

Detected:
service = orders-api
scope = us-12
bump = MINOR
```

Conte protects against false positive prefix matches. For example, `services/api-v2/file.cs` must not match a service whose path is `services/api`.

## Service tags

Recommended service tag format:

```text
<service>@<version>
```

Examples:

```text
orders-api@1.4.0
billing-api@0.8.3
identity-api@2.1.0
```

Repository-wide tags like `v1.4.0` are ambiguous in a service-release monorepo. Service tags allow each service to evolve independently.

Conte finds the last tag by service prefix:

```text
orders-api@ -> orders-api@1.3.0
billing-api@ -> billing-api@0.8.2
```

## Service changelogs

Each service has its own changelog:

```text
services/orders-api/CHANGELOG.md
services/billing-api/CHANGELOG.md
```

Recommended format:

```md
# orders-api Changelog

## orders-api@1.4.0

### Features

#### us-12
- agregar confirmación de pedido

### Fixes

#### issue-89
- corregir validación de saldo
```

Grouping is:

```text
type -> scope -> description
```

Default included release types:

```text
feat
fix
perf
breaking
```

Breaking entries are controlled by Conte's breaking-release workflow. Free-form breaking commits are not accepted for service releases.

Optional changelog types depending on configuration and release options:

```text
docs
build
ci
chore
refactor
test
style
revert
```

Commits that do not affect the service are not included in that service changelog.

## multiServicePolicy

Recommended configuration:

```json
"multiServicePolicy": "fail"
```

Default recommendation: `fail`.

If one commit touches two services:

```text
services/orders-api/src/Foo.cs
services/billing-api/src/Bar.cs
```

Conte fails workspace validation when policy is `fail`:

```text
Commit affects multiple services:
- orders-api
- billing-api

Policy: multiServicePolicy=fail

Fix:
- split the commit
- use a shared scope if this is a repository-wide change
- change multiServicePolicy only if your team accepts multi-service releases
```

Policy values:

- `fail`: block ambiguous multi-service commits
- `warn`: planned warning mode
- `allow`: planned allow mode

Currently recommended and supported mode: `fail`.

## sharedScopes

Repository-wide commits that affect no service path are allowed only when the scope is shared.

```json
"sharedScopes": ["repo", "docs", "ci", "build", "deps"]
```

Allowed examples:

```text
docs(repo): actualizar README
ci(repo): actualizar workflow
chore(deps): actualizar dependencias compartidas
```

Rejected example:

```text
feat(us-12): actualizar README
```

Reason:

```text
The commit does not affect any service path and the scope us-12 is not shared.
```

## Commands

Preview one service:

```bash
conte release preview --service orders-api
```

Expected summary:

```text
Service: orders-api
Current version: 1.3.0
Next version: 1.4.0
Bump: MINOR

Tag to create:
  orders-api@1.4.0

No changes were written.
```

Create one service release:

```bash
conte release create --service orders-api
conte release create --service orders-api --yes
```

Expected effects:

```text
updates services/orders-api/CHANGELOG.md
updates .conte/config.json service version
creates commit chore(release): orders-api 1.4.0
creates tag orders-api@1.4.0
```

Preview all services:

```bash
conte release preview --all-services
```

Expected summary:

```text
Workspace release preview

Services with releasable changes:

orders-api
  Current version: 1.3.0
  Next version: 1.4.0
  Bump: MINOR
  Tag: orders-api@1.4.0

billing-api
  Current version: 0.8.2
  Next version: 0.8.3
  Bump: PATCH
  Tag: billing-api@0.8.3

No changes were written.
```

Create all services. Default mode creates one release commit per service:

```bash
conte release create --all-services
```

Expected commits:

```text
chore(release): orders-api 1.4.0
chore(release): billing-api 0.8.3
```

Global mode creates one commit for all changed services:

```bash
conte release create --all-services --global
conte release create --all-services -g
```

Expected commit:

```text
chore(release): publish workspace services
```

Expected tags:

```text
orders-api@1.4.0
billing-api@0.8.3
```

Use `--global` to reduce release commit noise when publishing several services together.

Validate workspace:

```bash
conte validate workspace
conte validate workspace --range main..HEAD
```

It checks service definitions, non-overlapping paths, commit scope format, multi-service commits, and shared-scope commits outside service paths.

Status and doctor:

```bash
conte status
conte doctor
```

They show workspace status and diagnose service config, path, tag, and changelog issues.

Init:

```bash
conte init
conte init --workspace --release-mode service --service orders-api --service-path services/orders-api
```

Workspace is opt-in.

Add a service:

```bash
conte workspace add-service orders-api --path services/orders-api
```

`conte workspace add-service` is implemented. It writes a path-detected service to `.conte/config.json` with default `tagPrefix`, `changelogFile`, and `version` unless those options are provided.

## Validation

Run workspace validation locally or in CI:

```bash
conte validate workspace
```

Use an explicit range in CI:

```bash
conte validate workspace --range origin/main..HEAD
```

Validation covers service definitions, required fields, unique and non-overlapping service paths, commit scope format, multi-service commits under `multiServicePolicy=fail`, and shared scopes for commits outside service paths.

## Hooks and CI/CD

Local `commit-msg` validation enforces Conventional Commit shape. It does not detect services from changed files.

When `workspace.enabled=true`, `pre-push` validates pushed commit ranges with the same workspace commit-to-service rules as `conte validate workspace --range`.

CI/CD should run:

```bash
conte status
conte doctor
conte validate workspace
conte release preview --all-services
```

The changelog is generated at release time from Conventional Commits.

## Examples

One-service change:

```text
Branch:
feature/us-12-confirm-order

Commit:
feat(us-12): agregar confirmación de pedido

Files:
services/orders-api/src/ConfirmOrder.cs

Command:
conte release preview --service orders-api

Tag:
orders-api@1.4.0
```

Shared repository change:

```text
Commit:
docs(repo): actualizar README

Files:
README.md
docs/en/workspace.md

Detected:
service = none
scope = repo
```

## Troubleshooting

`Unknown workspace service: orders-api`

The service is not declared under `workspace.services[]`, or the command uses a different name. Run `conte workspace list`.

`Commit affects multiple services`

A single commit changed paths under more than one service and `multiServicePolicy=fail` is active. Split the commit or use a shared scope for a repository-wide change.

`Commit does not affect any workspace service`

The commit changed only shared paths and its scope is not in `sharedScopes`. Use a shared scope such as `repo`, `docs`, `ci`, `build`, or `deps` when the change is repository-wide.

`Workspace service path does not exist`

The configured service path is missing or incorrect. Fix `workspace.services[].path` or create the service directory.

`No service changes detected`

No changed commits affect configured service paths with releasable commit types. Check the service paths, latest service tag, and commit types.
