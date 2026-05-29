# Installation

## Platforms

Conte CLI runs on:

- Linux (x64, arm64)
- macOS (x64, arm64)
- Windows via Git Bash (x64)

Windows requires [Git for Windows](https://git-scm.com/download/win) / Git Bash.

## Public Tokenless Install

Linux/macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1 | iex
```

Windows CMD:

```cmd
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.cmd -o install.cmd && install.cmd && del install.cmd
```

Default install locations:

| Platform | Install root | Executable path |
|---|---|---|
| Linux/macOS | `~/.conte` | `~/.conte/bin` |
| Windows | `%USERPROFILE%\.conte` | `%USERPROFILE%\.conte\bin` |

Verify after install:

```bash
conte --version
conte doctor
```

Open a new terminal first if your shell has not picked up the updated `PATH`.

## This Repository

`conte-martin/conte-cli-installer` is the public distribution point for Conte CLI. It hosts tokenless install scripts and public release assets. No `GITHUB_TOKEN` is required for install or update.

The CLI source code, versioning, packaging, and build artifacts originate from the private `conte-martin/conte-cli` repository. On each new release, `conte-cli` triggers a `repository_dispatch` event to this repository, which downloads the private build artifacts, verifies their checksums, and publishes them publicly alongside the `latest.json` metadata file.

The `latest.json` contract and the self-update logic embedded in the CLI (`conte update`) are defined in `conte-cli`. This repository exposes the public endpoint that `conte update` resolves by default.

## Release Artifacts

Each release publishes the following artifacts:

| Artifact | Platform |
|---|---|
| `conte-cli-linux-x64.tar.gz` | Linux x64 |
| `conte-cli-linux-arm64.tar.gz` | Linux arm64 |
| `conte-cli-macos-x64.tar.gz` | macOS x64 |
| `conte-cli-macos-arm64.tar.gz` | macOS arm64 (Apple Silicon) |
| `conte-cli-windows-x64.zip` | Windows x64 (Git Bash) |
| `conte-cli-installer-windows-x64.exe` | Windows x64 installer |
| `checksums.txt` | SHA256 checksums for every artifact |
| `latest.json` | Public release metadata |

## Release Metadata

Conte resolves the release metadata URL in this order:

1. `CONTE_RELEASE_METADATA_URL` environment variable, if set
2. `https://github.com/conte-martin/conte-cli-installer/releases/latest/download/latest.json`

The `latest.json` contract is:

```json
{
  "version": "X.Y.Z",
  "linux_x64_url": "...",
  "linux_arm64_url": "...",
  "macos_x64_url": "...",
  "macos_arm64_url": "...",
  "windows_x64_url": "...",
  "windows_installer_x64_url": "...",
  "checksums_url": "..."
}
```

The version value is bare SemVer without the leading `v`. `checksums_url` points to a `checksums.txt` file with SHA256 entries for every artifact. Install and update fail before extraction if the artifact checksum is missing or invalid.

## Payload Installer Script

The CLI release tarball (`conte-cli-<platform>.tar.gz`) bundles its own `install.sh`. That script sources Conte libraries from the unpacked CLI tree and installs from local disk. It is not the public curl-pipe installer hosted in this repository.

It is useful when installing offline from a downloaded artifact:

```bash
./install.sh
./install.sh --prefix ~/.conte
./install.sh --version 1.2.3
```

Environment variables:

| Variable | Description |
|---|---|
| `CONTE_RELEASE_METADATA_URL` | Override release metadata URL or local file path |
| `CONTE_INSTALL_ROOT` | Override install destination directory |
| `CONTE_INSTALL_VERSION` | Pin to a specific version |

## Metadata Override

To install or update from a local or custom metadata source:

```bash
CONTE_RELEASE_METADATA_URL=file:///path/to/latest.json ./install.sh
CONTE_RELEASE_METADATA_URL=file:///path/to/latest.json conte update
```

This is useful for air-gapped environments or testing.

## Upgrading

```bash
conte update
conte update --version 1.2.3
conte self update
conte self update --version 1.2.3
```

`conte update` and `conte self update` are equivalent. Both use the public metadata URL by default, preserve `CONTE_RELEASE_METADATA_URL`, do not require `GITHUB_TOKEN`, and do not mutate repository-local `.conte/config.json`.

See [usage.md](usage.md) for update behavior details.

## Uninstalling the CLI

```bash
conte uninstall
conte uninstall --yes
```

`conte uninstall` removes the global CLI installation directory. It does not affect repository-local `.conte` configuration. Use `conte remove` inside a repository to remove repository-local Conte configuration.

`conte self uninstall` is a deprecated alias for `conte uninstall` and will print a deprecation warning.

## Windows (Git Bash)

Use the Windows installer when possible:

- install Git for Windows first
- run the public PowerShell or CMD installer command
- install into `%USERPROFILE%\.conte`
- keep `%USERPROFILE%\.conte\bin` on the user `PATH`
- open a new PowerShell terminal
- run `conte --version`
- run `conte doctor`

The installer adds `%USERPROFILE%\.conte\bin` to the user `PATH` and installs `conte.cmd`, which locates Git Bash and forwards CLI arguments.

If you use the ZIP artifact or install manually on Windows, use the same target directory:

- extract into `%USERPROFILE%\.conte`
- ensure `%USERPROFILE%\.conte\bin` is on the user `PATH`
- open a new terminal so the updated `PATH` is visible

Conte should not be installed into `%LOCALAPPDATA%\Programs\.conte`, `C:\Program Files\.conte`, or `C:\Program Files (x86)\.conte`.

See [Windows installation](../installation/windows.md) for the full Windows flow.

## Troubleshooting

- If metadata is unavailable, set `CONTE_RELEASE_METADATA_URL` to a reachable `latest.json`.
- If checksum validation fails, download the artifact and `checksums.txt` again from the same release.
- If `bash` is not found on Windows, install Git for Windows and run from Git Bash.
- If an artifact cannot be extracted, verify that `tar` (Linux/macOS) or `unzip`/PowerShell (Windows) is available.
- If the binary is not found after install, check that the install directory is on your `PATH`.
