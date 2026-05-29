# Conte CLI

Conte CLI is a pure-Bash, Git-native workflow enforcement, release automation, and CI/CD generation tool. It targets teams who want deterministic, commit-driven version management without external runtime dependencies.

**Key capabilities:**

- Workflow enforcement via Git hooks (branch and commit validation)
- Semantic versioning derived from Conventional Commits
- Release automation: CHANGELOG generation, SemVer bump, Git tag
- CI/CD template generation for GitHub Actions, GitLab CI, and Azure DevOps Pipelines
- Hook Tasks: explicit user-defined commands attached to Git hooks
- Workspace (monorepo) support with per-service versioning and scope/path validation
- CLI self-update with SHA256-verified artifact distribution
- Three-layer config resolution: workspace → repository → global

**Platforms:** Linux (x64, arm64), macOS (x64, arm64), Windows (Git Bash + `bin/conte.cmd`)  
**Runtime:** pure Bash and POSIX utilities — no Node.js, Python, or package managers required

## Installation

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1 | iex
```

**Windows (CMD):**

```cmd
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.cmd -o install.cmd && install.cmd && del install.cmd
```

After install, open a new terminal and run:

```bash
conte --version
conte doctor
```

Windows users must run Git operations from Git Bash. `conte.cmd` is provided for PowerShell compatibility.

## Quick Start

```bash
# Initialize repository
conte init

# Check repository health
conte status
conte doctor

# Install or repair hooks
conte hooks install

# Preview the next release
conte release preview

# Create a release
conte release create
```

## Commands

**CLI management:**

```bash
conte version
conte update
conte update --check
conte update --version 1.2.3
conte self version
conte self update --check
conte uninstall
conte uninstall --yes
```

**Repository setup and diagnostics:**

```bash
conte init
conte init --workflow gitflow --main-branch main --develop-branch develop --yes
conte init --workspace
conte remove
conte status
conte doctor
conte doctor --fix
```

**Configuration:**

```bash
conte config list
conte config --local
conte config --global
conte config get workflow
conte config get version.current
conte config set version.current 1.2.3
```

**Hooks:**

```bash
conte hooks status
conte hooks install
conte hooks reinstall --force
conte hooks uninstall
conte hooks doctor
conte hooks test commit-msg "fix(auth): resolve token expiry"
conte hooks test branch feat/add-login
```

**Hook Tasks:**

```bash
conte hooks task list
conte hooks task add dotnet-test --hook pre-push -- dotnet test
conte hooks task add npm-lint --hook pre-commit -- npm run lint
conte hooks task add npm-install --hook post-merge -- npm install
conte hooks task add slow-check --hook manual --disabled -- ./check.sh
conte hooks task edit dotnet-test --disable
conte hooks task run dotnet-test
```

**Validation:**

```bash
conte validate commit "fix(auth): resolve token expiry"
conte validate commit --file .git/COMMIT_EDITMSG
conte validate branch feat/add-login
conte validate branch
conte validate repo
conte validate scope-paths
conte workflow validate-merge --source feature/login --target develop
```

**SemVer, changelog, and release:**

```bash
conte semver get
conte semver next
conte semver set 1.2.3
conte semver breaking
conte changelog preview
conte changelog generate
conte release preview
conte release preview --scope us-12
conte release preview --service api
conte release create
conte release create --allow-empty-release
conte release create --scope us-12 --scope-mode strict
conte release create --service api
conte release create --include-internal
conte release create --no-tag
conte release create --no-changelog
conte release sync-develop
conte release sync-develop --preview
```

**CI/CD template generation:**

```bash
conte generate cicd
conte generate cicd github
conte generate cicd gitlab
conte generate cicd azure
conte generate cicd --provider github
```

**Workspace (monorepo):**

```bash
conte workspace status
conte workspace list
conte workspace doctor
conte service list
conte service status <name>
conte service doctor <name>
```

## Core Principle

```text
Config    -> user input
Workflow  -> rules
Validation -> enforcement
Hooks     -> developer experience
CI/CD     -> remote enforcement
Release   -> SemVer + changelog + tag
Hook Tasks -> explicit local commands
Workspace -> monorepo service management
Distribution -> reliable delivery
CLI       -> orchestration
```

## Configuration Contract

The repository-local config written by `conte init` is:

```json
{
  "version": "0.1.0",
  "workflow": "kanban",
  "git": {
    "mainBranch": "main",
    "mapping": {
      "main": "main"
    }
  },
  "commit": {
    "scopeRequired": true,
    "scopePattern": "^[a-z0-9]+(-[a-z0-9]+)*$"
  },
  "breakingChange": {
    "mode": "manual-command",
    "nextBump": null
  },
  "hooks": {
    "enabled": true,
    "path": ".conte/hooks",
    "installed": ["commit-msg", "pre-push", "prepare-commit-msg", "pre-commit"],
    "tasks": []
  },
  "release": {
    "tagPrefix": "v",
    "changelogFile": "CHANGELOG.md"
  }
}
```

Key invariants:

- Derived regex, workflow rules, branch lifecycle rules, and merge rules are never stored in config — they are always derived at runtime from the workflow engine
- `version` stores bare SemVer (`0.1.0`); Git tags use the configured `tagPrefix` (e.g. `v0.1.0`)
- `breakingChange.nextBump` is `null` by default and becomes `"major"` after `conte semver breaking`; it is cleared automatically after a successful `conte release create`
- `workflow: gitflow` automatically activates GitFlow merge validation; do not add `mergeRules` to `.conte/config.json`
- Legacy `.conte/conte.conf` is detected and warned about but never created, deleted, or migrated automatically

## Workflow Rules

Workflow branch families are fixed in code, not config:

| Workflow | Allowed branches |
|---|---|
| `trunk` | mapped `main`, `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `chore/*` |
| `kanban` | mapped `main`, `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `release/*`, `chore/*` |
| `gitflow` | mapped `main`, mapped `develop`, `feature/*`, `feat/*`, `bugfix/*`, `fix/*`, `release/*`, `hotfix/*`, `chore/*` |

Branch suffixes are strict: lowercase letters, numbers, `-`, and `.` — no spaces, underscores, uppercase, `--`, `..`, or leading/trailing separators.

## Commit Rules

Conte enforces strict Conventional Commits across all workflows:

```
<type>(<scope>): <description>
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`  
Scope: required by default; must match `^[a-z0-9]+(-[a-z0-9]+)*$`

SemVer mapping:

- `feat(scope): ...` → minor bump
- `fix(scope): ...` → patch bump
- `perf(scope): ...` → patch bump
- All other valid types → no automatic bump
- `conte semver breaking` → forces major on the next release

Breaking syntax markers (`!`, `BREAKING CHANGE` footer) are valid syntax but do not trigger a MAJOR bump automatically. Only `conte semver breaking` activates a MAJOR release.

## Release Model

```bash
# Preview without writing files
conte release preview

# Create release artifacts, update config/changelog, create tag
conte release create
```

`conte release create` is commit-driven:

1. validates all non-merge commits since the last `vX.Y.Z` tag
2. calculates the next SemVer from commit types
3. updates `version` in `.conte/config.json` and clears `breakingChange.nextBump`
4. generates or prepends to `CHANGELOG.md`
5. creates the Git tag

Release eligibility is workflow-driven: `trunk` and `kanban` release from mapped `main`; `gitflow` releases from mapped `develop`.

Conte restores config and changelog state if a later release step fails — partial releases are never left behind.

**Scoped releases** filter commits by exact Conventional Commit scope:

```bash
conte release create --scope us-12       # ticket-based release
conte release create --service api       # workspace service release
```

`--scope us-12` matches `feat(us-12): ...` exactly; it does not match `us-123` or `core-us-12`. Scoped release branches (`release/<scope>`) are supported for `gitflow` only.

**`--no-tag`:** when used, the Conte release commit (`chore(release): cut vX.Y.Z`) becomes the durable release marker. Re-running with no new versionable commits exits safely without creating duplicate artifacts.

**`--allow-empty-release`:** forces a patch release when commits are valid but non-versionable.

## Hook Tasks

Hook Tasks are repository-local commands stored in `hooks.tasks` and run after Conte's core hook validation succeeds.

```bash
conte hooks task add dotnet-test --hook pre-push -- dotnet test
conte hooks task add npm-lint --hook pre-commit -- npm run lint
conte hooks task add slow-check --hook manual --disabled -- ./check.sh
conte hooks task run slow-check          # run manual tasks explicitly
```

Supported hook targets: `commit-msg`, `prepare-commit-msg`, `pre-commit`, `pre-push`, `post-merge`, `manual`.

Hook Tasks cannot register Conte commands, replace internal validation, or extend release or CI/CD engines.

## Workspace (Monorepo) Support

Workspace mode enables per-service versioning and scope/path validation within a single repository.

```bash
conte init --workspace
```

This extends `.conte/config.json` with a `workspace` block:

```json
{
  "workspace": {
    "enabled": true,
    "releaseMode": "independent",
    "scopePathValidation": "strict",
    "sharedScopes": ["chore", "deps"],
    "services": [
      {
        "name": "api",
        "path": "services/api",
        "scope": "api",
        "version": "1.0.0",
        "changelogFile": "services/api/CHANGELOG.md",
        "tagPrefix": "api-v"
      }
    ]
  }
}
```

Release modes:

- `single` — one shared version and changelog for the whole repository
- `independent` — each service releases independently via `conte release create --service <name>`

Inspect workspace state:

```bash
conte workspace status
conte workspace list
conte workspace doctor
conte service status api
conte service doctor api
```

## Config Resolution

Conte resolves configuration in layers, from highest to lowest priority:

1. **Workspace project config**: `.conte/projects/<project>/config.json`
2. **Repository config**: `.conte/config.json`
3. **Global config**: `~/.conte/config.json`

Inspection commands use the effective layered view. Repo-mutating commands always read and write `.conte/config.json` directly.

```bash
conte config --local
conte config --global
conte config get workflow
```

## CI/CD Model

Local hooks are developer safeguards only and can be bypassed with `--no-verify`. CI/CD pipelines are the enforcement authority for teams.

Conte generates provider-specific templates that call the CLI directly — no validation logic is duplicated in YAML:

```bash
conte generate cicd github
conte generate cicd gitlab
conte generate cicd azure
```

Each generated template runs:

```bash
bash ./bin/conte status
bash ./bin/conte doctor
bash ./bin/conte release preview
bash tests/run.sh    # when present
```

Release jobs are workflow-aware: `trunk` and `kanban` release from mapped `main`; `gitflow` releases from mapped `develop`.

## Distribution

Conte uses a metadata-driven distribution model with SHA256 artifact verification.

Supported artifacts:

| Platform | Format |
|---|---|
| Linux x64 | `conte-cli-linux-x64.tar.gz` |
| Linux arm64 | `conte-cli-linux-arm64.tar.gz` |
| macOS x64 | `conte-cli-macos-x64.tar.gz` |
| macOS arm64 | `conte-cli-macos-arm64.tar.gz` |
| Windows x64 | `conte-cli-windows-x64.zip` |
| Windows x64 installer | `conte-cli-installer-windows-x64.exe` |

Self-update:

```bash
conte update               # install latest
conte update --check       # check without installing
conte update --version 1.2.3
```

Update installs are atomic: the current tree is replaced only after the new payload passes SHA256 verification. On failure, the previous installation is restored.

The default metadata URL is `https://github.com/conte-martin/conte-cli-installer/releases/latest/download/latest.json`. Set `CONTE_RELEASE_METADATA_URL` to override for air-gapped environments or custom mirrors.

**Hosted release flow:**

1. Push tag `vX.Y.Z` to `conte-cli`
2. `conte-cli` builds artifacts and creates the private GitHub Release
3. `conte-cli` triggers `repository_dispatch` on `conte-martin/conte-cli-installer` via `GITHUB_TOKEN`
4. `conte-cli-installer` downloads private assets using `CONTE_CLI_TOKEN`
5. `conte-cli-installer` publishes public assets and `latest.json`

Required secret in `conte-cli-installer`: `CONTE_CLI_TOKEN`. The `conte-cli` workflow uses the built-in `GITHUB_TOKEN`.

**`latest.json` contract:**

```json
{
  "version": "X.Y.Z",
  "linux_x64_url": "https://...",
  "linux_arm64_url": "https://...",
  "macos_x64_url": "https://...",
  "macos_arm64_url": "https://...",
  "windows_x64_url": "https://...",
  "windows_installer_x64_url": "https://...",
  "checksums_url": "https://..."
}
```

Default install root: `~/.conte` on Linux/macOS, `%USERPROFILE%\.conte` on Windows.

## Documentation

| Document | Description |
|---|---|
| [Architecture](en/architecture.md) | Module design, engines, and invariants |
| [Workflows](en/workflows.md) | Branch rules, commit rules, GitFlow merge validation |
| [Configuration](en/configuration.md) | Config schema, resolution order, workspace config |
| [Commands](en/commands.md) | Full command reference with options and examples |
| [Release](en/release.md) | Release flow, scoped releases, service releases, rollback |
| [CI/CD](en/cicd.md) | Generated pipeline templates and enforcement model |
| [Changelog](en/changelog.md) | Changelog generation rules |
| [Repository State](en/repository-state.md) | Valid and invalid repository states |
| [Usage](en/usage.md) | Common usage patterns |
| [Installation](en/installation.md) | Installation instructions |
| [Windows Installation](installation/windows.md) | Windows-specific setup guide |

## Testing

```bash
# Full suite
bash tests/run.sh

# Individual suites
bash tests/unit/validation.sh
bash tests/unit/release-semver.sh
bash tests/integration/create-release.sh

# Syntax check
bash scripts/ci/check-bash-syntax.sh
```

Windows:

```powershell
.\bin\conte.cmd --help
```
