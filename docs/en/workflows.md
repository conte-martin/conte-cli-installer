# Workflows

The workflow engine in `lib/core/workflow-engine/catalog.sh` is the source of truth for branch rules.

Conte does not store generated branch regex in config.
It stores workflow selection and branch mapping, then derives the real rules at runtime.

## Shared Branch Suffix Rule

Branch suffixes after `feature/`, `fix/`, `release/`, and similar prefixes must follow a strict pattern:

- lowercase letters only
- numbers allowed
- `-` allowed
- `.` allowed
- no spaces
- no underscores
- no uppercase
- no consecutive `--`
- no consecutive `..`
- cannot start with `-` or `.`
- cannot end with `-` or `.`

Conceptually:

```regex
[a-z0-9]+([.-][a-z0-9]+)*
```

## Trunk-Based

Allowed:

- mapped `main` such as `main` or `master`
- `feature/*`
- `feat/*`
- `bugfix/*`
- `fix/*`
- `hotfix/*`
- `chore/*`

Not allowed:

- `develop`
- `release/*`

## Kanban

Allowed:

- mapped `main` such as `main` or `master`
- `feature/*`
- `feat/*`
- `bugfix/*`
- `fix/*`
- `hotfix/*`
- `release/*`
- `chore/*`

Not allowed:

- `develop`

Release behavior:

- `conte release create` may run from the mapped `main` branch
- Kanban allows `release/*` branches
- scoped release branches with `--scope` are not supported unless a future explicit config option adds them

## GitFlow

Allowed:

- mapped `main` such as `main` or `master`
- mapped `develop` such as `develop` or `dev`
- `feature/*`
- `feat/*`
- `bugfix/*`
- `fix/*`
- `release/*`
- `hotfix/*`
- `chore/*`

GitFlow requires `develop`.

### Internal Branch Lifecycle

GitFlow branch lifecycle and merge rules are determined by the selected workflow. The rules are internal to Conte CLI and are not user-editable configuration. Setting `workflow: GitFlow` or `workflow: gitflow` activates GitFlow lifecycle and merge validation.

Do not add `branchLifecycle` or `mergeRules` to `.conte/config.json`. Conte ignores user-defined lifecycle or merge-rule data and derives enforcement from the workflow engine.

| Branch type | Created from | Merges into | Delete after merge |
|---|---|---|---|
| `feature/*` / `feat/*` | `develop` | `develop` | yes |
| `bugfix/*` / `fix/*` | `develop` | `develop` | yes |
| `chore/*` | `develop` | `develop` | yes |
| `release/*` | `develop` | `main` or `master`, then `develop` | yes |
| `hotfix/*` | `main` or `master` | `main` or `master`, then `develop` | yes |

Logical names are resolved through repository mapping before validation. If `main` maps to `master` and `develop` maps to `dev`, feature branches must merge into `dev`, release branches may merge into `master` and `dev`, and hotfix branches may merge into `master` and `dev`.

Conte validates branch origin on a best-effort basis using Git history. If Git cannot confidently prove the origin, `conte doctor` warns instead of blocking.

### Merge Rules

| Source branch | Allowed target branch |
|---|---|
| `feature/*` / `feat/*` | `develop` |
| `bugfix/*` / `fix/*` | `develop` |
| `chore/*` | `develop` |
| `release/*` | `main` or `master`, then `develop` |
| `hotfix/*` | `main` or `master`, then `develop` |

Blocked examples:

| Source branch | Blocked target | Reason |
|---|---|---|
| `feature/*` | `main` / `master` | Features must integrate through `develop` |
| `bugfix/*` / `fix/*` | `main` / `master` | Non-production fixes must integrate through `develop` |
| `develop` | `main` / `master` | Production releases must go through `release/*` |
| `release/*` | `feature/*` | Release branches only close into production and back into develop |
| `hotfix/*` | `feature/*` | Hotfixes only close into production and back into develop |

`main` and `develop` in the table are logical names. Conte resolves them through `.conte/config.json` before validating a merge. With `main -> master` and `develop -> dev`, `feature/* -> dev`, `release/* -> master`, `release/* -> dev`, `hotfix/* -> master`, and `hotfix/* -> dev` are valid, while `dev -> master` is blocked.

Release behavior:

- `conte release create` must run from the resolved `develop` branch.
- Scoped GitFlow releases create `release/<scope>` from the resolved `develop` branch.
- GitFlow releases are rejected from production, feature, fix, bugfix, hotfix, chore, and existing release branches.

## Logical Mapping

Conte validates logical branches through config mapping first:

```text
main    -> master
develop -> dev
```

That mapping is resolved before the final branch validation pattern is built.

## Base Branch Format

Every branch name must match the base format before workflow rules are applied:

```regex
^(main|master|develop)$|^(feature|feat|bugfix|fix|hotfix|release|chore)\/[a-z0-9]+([.-]?[a-z0-9]+)*(-[a-z0-9]+([.-]?[a-z0-9]+)*)*$
```

Valid examples:

- `main`, `master`, `develop` — exact branch names
- `feature/add-login`, `feat/auth-login` — feature branches
- `fix/email-validation`, `bugfix/api.2` — fix branches
- `release/v1.2.0` — release branches
- `hotfix/security-patch` — hotfix branches

Invalid examples:

- `feature/Add-Login` — uppercase not allowed
- `feature/add_login` — underscore not allowed
- `feature/-add-login` — leading hyphen not allowed
- `feature/add-login-` — trailing hyphen not allowed
- `feature/add--login` — consecutive hyphens not allowed
- `release/v1..2.0` — consecutive dots not allowed
- `task/add-login` — unknown prefix not allowed

## Commit Rules

Conte enforces a strict Conventional Commits format for all commit messages:

```regex
^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)\([a-z0-9]+(-[a-z0-9]+)*\)!?: .+$
```

Required elements:

- **Type**: one of `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- **Scope**: mandatory, wrapped in parentheses — lowercase letters, numbers, and hyphens only; no leading/trailing/consecutive hyphens
- **Separator**: `:` followed by a space
- **Description**: non-empty message body
- **Breaking marker** (optional): `!` before the `:` — only allowed after explicit declaration via `conte semver breaking`

Valid examples:

- `feat(auth): add login flow`
- `fix(api): handle null response`
- `docs(api-v1): update contract`
- `test(us-12): add assertions`
- `chore(deps): update dependencies`
- `feat(api)!: change response contract` (only after `conte semver breaking`)

Invalid examples:

- `feat: add login flow` — missing scope
- `feature(auth): add login flow` — invalid type (use `feat`)
- `feat(API): add endpoint` — uppercase in scope
- `feat(api_core): add endpoint` — underscore in scope
- `feat(-qa): message` — leading hyphen in scope
- `feat(auth):` — empty description
- `fix(api) Fix timeout` — missing colon/space separator

The pattern is centralized in `conte::wf_commit_pattern()` and validated by:
- `commit-msg` hook (local enforcement)
- `conte doctor` (recent commit validation)
- `conte status` (commit rules health)
- `conte validate commit` (CI/review)

## Branch Detection During `conte init`

`conte init` resolves repository state before it validates logical mappings.

Resolution order for the logical `main` suggestion:

- current branch when it is a local `main` or `master`
- local `main`
- local `master`
- first local branch
- first `origin/*` branch

Detached HEAD is never used as a branch name.

If a selected branch exists only on `origin`, Conte can create a local tracking branch.
If a selected branch does not exist but `HEAD` has commits, Conte can create the branch from `HEAD`.
If the repository has no commits, Conte stores the intended mapping and waits for the first commit before the branch can exist locally.

For `gitflow`, the mapped `develop` branch follows the same rules, except that a missing local `develop` branch is created from the mapped `main` branch when possible.
