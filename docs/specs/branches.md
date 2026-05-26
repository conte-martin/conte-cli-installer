# Branches

Source of truth: `lib/core/workflow-engine/catalog.sh`.

## Main Branch

The main branch must be `main` or `master`. No other value is allowed.

## develop and release/\* Restrictions

| Feature | Allowed in |
|---|---|
| `develop` | `gitflow` only |
| `release/*` | `gitflow` only |
| `develop` | NOT allowed in `trunk`, `kanban` |
| `release/*` | NOT allowed in `trunk`, `kanban` |

## Branch Prefix Types

All workflows:

```
feature, feat, bugfix, fix, hotfix, chore
```

GitFlow only (additional):

```
release
```

## Branch Format

```
<prefix>/<description>
```

Where `<prefix>` is one of the allowed types above, and `<description>` follows the rules below.

## Description Rules

- Lowercase letters, numbers, and hyphen.
- Dot allowed when needed (e.g., version numbers like `v1.2.3`).
- No spaces, uppercase letters, underscores, or special characters.
- Cannot start or end with hyphen or dot.
- No repeated hyphens (`--`) or repeated dots (`..`).

Canonical pattern:

```
[a-z0-9]+([.-][a-z0-9]+)*
```

Valid examples:

```
feature/user-auth
feat/api-v2
bugfix/null-pointer
fix/login-123
hotfix/v1.2.3
chore/update-deps
release/v2.0.0
```

Invalid examples:

```
feature/USER-AUTH      # uppercase
bugfix/null_pointer    # underscore
feat/-login            # starts with hyphen
fix/login-             # ends with hyphen
chore/update..deps     # repeated dots
hotfix/v1--2           # repeated hyphens
feature/user auth      # space
```

## Workflow-Specific Branch Families

| Workflow | Root branches | Feature branches |
|---|---|---|
| `trunk` | `main` / `master` | `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `chore/*` |
| `kanban` | `main` / `master` | `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `chore/*` |
| `gitflow` | `main` / `master`, `develop` | `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `release/*`, `hotfix/*`, `chore/*` |

## Logical Mapping

Conte uses logical branch names internally:

- `main` — maps to the real main branch (`main` or `master`)
- `develop` — maps to the real develop branch (gitflow only)

Mapping is stored in `.conte/config.json` under `git.mapping`. The workflow engine resolves logical names before branch validation.
