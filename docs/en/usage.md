# Usage

## Common Commands

```bash
conte help
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
conte help
conte help release
conte help semver
conte help hooks
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
