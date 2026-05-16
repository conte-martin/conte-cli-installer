@echo off
:: Conte CLI installer for Windows CMD
:: Delegates to install.ps1 via PowerShell
:: Usage: curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.cmd -o install.cmd && install.cmd && del install.cmd
setlocal

set "INSTALLER_URL=https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1"

where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PowerShell is not available. Please install PowerShell and try again.
    echo Download: https://aka.ms/powershell
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "irm '%INSTALLER_URL%' | iex"
if %errorlevel% neq 0 (
    echo.
    echo Installation failed. See the errors above.
    exit /b %errorlevel%
)

endlocal
