# Windows Installation

Conte CLI requires Git for Windows / Git Bash on Windows. Repository-local hooks and release flows run through Git Bash on Windows even when users launch `conte.cmd` from PowerShell.

## Install

1. Install [Git for Windows](https://git-scm.com/download/win) if it is not already present.
2. Run one of the public tokenless installer commands.

PowerShell:

```powershell
irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1 | iex
```

CMD:

```cmd
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.cmd -o install.cmd && install.cmd && del install.cmd
```

The public installer repository is `conte-martin/conte-cli-installer`. Users do not need `GITHUB_TOKEN`.

The installer:

- installs Conte CLI into `%USERPROFILE%\.conte`
- ensures `%USERPROFILE%\.conte\bin` exists
- installs `conte.cmd` into `%USERPROFILE%\.conte\bin`
- adds `%USERPROFILE%\.conte\bin` to the user `PATH`
- installs without administrator privileges
- supports uninstall
- does not install under `%LOCALAPPDATA%\Programs\.conte`
- does not install under `C:\Program Files\.conte`
- does not install under `C:\Program Files (x86)\.conte`

If Git Bash is missing, the installer shows a warning with the expected Git for Windows paths.

`conte update` uses public metadata from `https://github.com/conte-martin/conte-cli-installer/releases/latest/download/latest.json` by default. Set `CONTE_RELEASE_METADATA_URL` to override the metadata source for testing or air-gapped environments.

## ZIP Or Manual Install

If you use the ZIP artifact instead of the Windows installer:

1. Extract Conte CLI into `%USERPROFILE%\.conte`.
2. Ensure `%USERPROFILE%\.conte\bin` is on the user `PATH`.
3. Open a new terminal so the updated `PATH` is loaded.

## Verify

Open a new PowerShell terminal, then run:

```powershell
conte --version
conte doctor
```

## Uninstall

Uninstall Conte CLI from the Windows installed apps list.

The uninstaller removes:

- the installed Conte CLI files under `%USERPROFILE%\.conte`
- the `%USERPROFILE%\.conte\bin` user `PATH` entry
