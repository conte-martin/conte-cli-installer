# Conte CLI v1 Specification

## Scope

Conte CLI v1 provides workflow-driven validation, release management, changelog generation, hook enforcement, and CI/CD template generation for Git repositories.

## Supported Workflows

Exactly three workflows are supported:

- `trunk` — trunk-based development
- `kanban` — kanban-style continuous delivery
- `gitflow` — GitFlow with dedicated develop and release branches

## Unsupported Workflows (v1)

The following workflows are not supported in v1:

- `github-flow` — legacy, migrated to trunk
- `release-flow` — legacy, migrated to gitflow

`conte init` must not offer github-flow or release-flow as selectable workflows. Existing configurations using these values must be handled with a deprecation warning and automatic migration suggestion.

## Global Rules

| Rule | Value |
|---|---|
| Main branch | `main` or `master` only |
| Commit scope | Required on every commit |
| Breaking change | Manual `conte semver breaking` command only |
| Windows support | Git Bash (Git for Windows) required |
| Commit template | Conventional Commits with mandatory scope |

## Document References

- [Workflows](workflows.md) — trunk, kanban, gitflow definitions
- [Commits](commits.md) — commit message format, scope, types, SemVer
- [Branches](branches.md) — branch naming, prefix types, allowed patterns
