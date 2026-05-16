#Requires -Version 5.0
# Conte CLI uninstaller for Windows PowerShell
# Usage: irm https://raw.githubusercontent.com/conte-martin/Conte.CLI.Installer/main/uninstall.ps1 | iex

& {
    $ErrorActionPreference = 'Stop'

    $ConteHome   = if ($env:CONTE_HOME) { $env:CONTE_HOME } else { Join-Path $env:USERPROFILE '.conte' }
    $ConteBinDir = Join-Path $ConteHome 'bin'

    function Write-Step($msg) { Write-Host $msg }
    function Fail($msg)       { Write-Error $msg; exit 1 }

    # Safety guards
    if (-not $ConteHome)                          { Fail "CONTE_HOME is empty. Refusing to uninstall." }
    if ($ConteHome -eq '/')                       { Fail "CONTE_HOME is set to /. Refusing to uninstall." }
    if ($ConteHome -eq $env:USERPROFILE)          { Fail "CONTE_HOME is set to USERPROFILE. Refusing to uninstall." }

    if (-not (Test-Path $ConteHome)) {
        Write-Step "Nothing to uninstall: $ConteHome does not exist."
        exit 0
    }

    Write-Step "Removing Conte CLI installation at $ConteHome..."
    Remove-Item -Path $ConteHome -Recurse -Force
    Write-Step "Removed: $ConteHome"

    # Remove ConteBinDir from user PATH if present
    $CurrentPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    if ($CurrentPath) {
        $PathEntries = $CurrentPath -split ';' | Where-Object { $_ -ne '' -and $_ -ne $ConteBinDir }
        $NewPath     = $PathEntries -join ';'
        if ($NewPath -ne $CurrentPath) {
            [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, 'User')
            Write-Step "Removed $ConteBinDir from user PATH."
        }
    }

    Write-Step ""
    Write-Step "Uninstall complete."
    Write-Step "Open a new terminal for PATH changes to take effect."
}
