@echo off
:: Conte CLI uninstaller for Windows CMD
:: Delegates to uninstall.ps1 via PowerShell
setlocal

set "UNINSTALLER_URL=https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/uninstall.ps1"

where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PowerShell is not available.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "irm '%UNINSTALLER_URL%' | iex"
if %errorlevel% neq 0 (
    echo.
    echo Uninstall failed. See the errors above.
    exit /b %errorlevel%
)

endlocal
