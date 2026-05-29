# Monorepo Support in Conte CLI

## Overview

A monorepo is a single Git repository containing multiple independently deployable services. Conte supports monorepo workflows through its workspace feature.

## Enabling Monorepo Support

```bash
conte init --workspace \
  --workspace-release-mode independent \
  --scope-path-validation warn \
  --service auth:services/auth:auth \
  --service billing:services/billing:billing
```

Or interactively:
```bash
conte init --workspace
# Follow the prompts
```

## Typical Monorepo Layout

```
repo/
  services/
    auth/          # service: auth, scope: auth
      src/
      CHANGELOG.md
    billing/       # service: billing, scope: billing
      src/
      CHANGELOG.md
  shared/          # shared library (not a service)
  .conte/
    config.json    # source of truth for all services
```

## Configuration Example

```json
{
  "version": "0.0.0",
  "workflow": "gitflow",
  "workspace": {
    "enabled": true,
    "releaseMode": "independent",
    "scopePathValidation": "warn",
    "sharedScopes": ["shared", "docs", "ci", "repo"],
    "services": [
      {
        "name": "auth",
        "path": "services/auth",
        "scope": "auth",
        "version": "1.2.0",
        "changelogFile": "services/auth/CHANGELOG.md",
        "tagPrefix": "auth/v",
        "releaseMode": "independent"
      },
      {
        "name": "billing",
        "path": "services/billing",
        "scope": "billing",
        "version": "0.9.3",
        "changelogFile": "services/billing/CHANGELOG.md",
        "tagPrefix": "billing/v",
        "releaseMode": "independent"
      }
    ]
  }
}
```

## Commit Conventions in a Monorepo

Use the service scope in every commit:

```
feat(auth): add OAuth2 login endpoint
fix(billing): correct tax calculation
docs(shared): update API reference
chore(ci): upgrade Node version
```

Commits with undeclared scopes are rejected:
```
feat(payments): add Stripe → ERROR: 'payments' is not a declared scope
```

## Day-to-Day Workflow

### Check workspace status
```bash
conte workspace status
conte workspace list
```

### Check which service you are in
```bash
cd services/auth
conte status   # shows "Current service: auth"
```

### Preview a service release
```bash
conte release preview --service auth
```

### Create a service release
```bash
conte release create --service auth
```

### Validate commit scopes
```bash
conte validate commit "feat(auth): add 2FA"
```

### Diagnose workspace
```bash
conte workspace doctor
conte doctor              # includes workspace diagnostics
```

## Supported Service Layouts

Conte detects the active service using longest-path matching. All of these layouts are supported:

```
services/auth              → service "auth"
src/services/billing       → service "billing"
apps/gateway               → service "gateway"
packages/ui/components     → service "ui" (path: packages/ui)
```

## See Also

- [docs/specs/workspace.md](workspace.md) — Configuration reference
- [docs/specs/service-release.md](service-release.md) — Service release process
