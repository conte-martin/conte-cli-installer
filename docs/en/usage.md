# Usage

## Common Commands

```bash
conte help
conte menu
conte init
conte status
conte doctor
conte release preview
conte generate cicd
conte hooks task list
conte version
conte semver get
conte semver next
conte update
```

## Help

```bash
conte
conte help
conte help release
conte help semver
conte help hooks
```

Running `conte` with no arguments prints a dashboard. Outside Git it suggests `conte init` and `conte help`; inside an initialized repository it shows the Conte version, workflow, main branch, current branch, hooks summary, and suggested next commands.

Global help is grouped by intent:

- Getting started
- Daily workflow
- Release
- Workspace
- Configuration
- System

Unknown commands and unknown options keep non-zero exit codes and print a "Did you mean?" suggestion when Conte can infer a close match.

## Interactive Menus

```bash
conte menu
conte init --interactive
conte release --interactive
conte doctor --fix-interactive
```

Menus only appear when stdin and stdout are TTYs and CI is not detected. They are disabled by `--yes`, `--no-interactive`, `CI=true`, `GITHUB_ACTIONS`, `GITLAB_CI`, `TF_BUILD`, and `BUILD_BUILDID`.

Every menu prints or maps to a non-interactive command such as:

```bash
conte init --yes
conte status
conte doctor --fix
conte release preview
conte release create --yes
```

## Debug And Verbose Output

Global flags:

```bash
conte --debug doctor
conte --verbose status
```

- `--debug` enables internal diagnostic logging (writes to log file and stdout)
- `--verbose` enables additional user-facing detail without full debug output

Both flags apply before the command name and work with all commands:

```bash
conte --debug update --check
conte --verbose release preview
```

## Color Output

Conte uses semantic colors only for human TTY output:

- green for success
- yellow for warnings
- red for errors
- blue for info
- cyan for commands and paths
- gray for secondary text

Controls:

```bash
CONTE_COLOR=auto    # default: color on TTY only
CONTE_COLOR=always  # force color unless NO_COLOR is set
CONTE_COLOR=never   # disable color
NO_COLOR=1          # disable color
FORCE_COLOR=1       # force color, including CI
```

No ANSI color codes are emitted by default when output is redirected.

## Versioning

```bash
conte version
conte --version
conte semver get
conte semver next
```

`conte version` outputs the installed CLI version only:

```text
Conte CLI v1.2.3
```

`conte update --check` compares the embedded version against release metadata and outputs:

```text
current version 1.2.3
latest version 1.3.0
update available yes
```

When already up to date:

```text
current version 1.3.0
latest version 1.3.0
update available no
```

## Updating

```bash
conte update
conte update --check
conte update --version 1.2.3
conte self update
conte self update --version 1.2.3
```

`conte update` and `conte self update` are equivalent.

`conte update` fetches public release metadata from `https://github.com/conte-martin/conte-cli-installer/releases/latest/download/latest.json` by default, compares SemVer, downloads the appropriate platform artifact, verifies its SHA256 from `checksums.txt`, and installs only after extraction and payload validation succeed. If download, checksum validation, extraction, or payload validation fails, the previous installation is preserved.

The command prints the current version, latest version, whether the update was skipped, or the installed version. It does not require `GITHUB_TOKEN` and does not mutate repository-local `.conte/config.json`.

Set `CONTE_RELEASE_METADATA_URL` to override the default release source.

## Update Notifications

Conte performs a best-effort update notification for:

```bash
conte
conte help
conte version
conte status
conte doctor
```

The notification uses existing release metadata logic, caches the latest version result for 24 hours under `CONTE_HOME/cache`, and never fails the original command if the check fails. Disable it with:

```bash
CONTE_UPDATE_CHECK=0
conte config set update.check false
```

`conte update` remains explicit and is the only command that installs an update.

## Versioning Policy

Conte CLI versions itself with SemVer:

- compatible bug fixes increment patch
- backward-compatible features increment minor
- breaking CLI changes increment major

## Troubleshooting

- Run `conte --debug doctor` for detailed diagnostics.
- Run `conte config --local` or `conte config --global` to inspect the active config layers.
- If a Hook Task causes unexpected behavior, use `conte hooks task list` and disable the task to isolate the issue.
- If `conte update` fails, check network connectivity or set `CONTE_RELEASE_METADATA_URL` to a reachable metadata source.
