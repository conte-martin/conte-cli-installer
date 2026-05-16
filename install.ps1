#Requires -Version 5.0
# Conte CLI public installer for Windows PowerShell
# Usage: irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1 | iex
#
# Conte CLI is Bash-first. The Windows ZIP payload contains:
#   bin/conte      (Bash entry-point)
#   bin/conte.cmd  (Windows CMD/PowerShell wrapper that invokes Bash)
#   lib/           (runtime libraries, if any)
#   docs/          (documentation, if any)
# This installer installs the full payload and does NOT require conte.exe.

& {
    $ErrorActionPreference = 'Stop'

    $ConteHome   = if ($env:CONTE_HOME) { $env:CONTE_HOME } else { Join-Path $env:USERPROFILE '.conte' }
    $ConteBinDir = Join-Path $ConteHome 'bin'
    $MetadataUrl = if ($env:CONTE_RELEASE_METADATA_URL) { $env:CONTE_RELEASE_METADATA_URL } `
                   else { 'https://github.com/conte-martin/conte-cli-installer/releases/latest/download/latest.json' }
    $ConteVersion = $env:CONTE_VERSION

    function Write-Step($msg) { Write-Host $msg }
    function Fail($msg)       { Write-Error $msg; exit 1 }

    # Adjust metadata URL when a specific version is requested
    if ($ConteVersion) {
        $MetadataUrl = $MetadataUrl -replace '/releases/latest/download/', "/releases/download/$ConteVersion/"
    }

    Write-Step "Fetching release metadata..."
    try {
        $Metadata = Invoke-RestMethod -Uri $MetadataUrl -UseBasicParsing
    } catch {
        Fail "Failed to fetch release metadata from $MetadataUrl. Check your internet connection. Error: $_"
    }

    $ReleaseVersion = $Metadata.version
    $AssetUrl       = $Metadata.windows_x64_url
    $ChecksumsUrl   = $Metadata.checksums_url

    if (-not $ReleaseVersion) { Fail "Invalid release metadata: could not parse version field from $MetadataUrl" }
    if (-not $AssetUrl)       { Fail "windows_x64_url not found in release metadata" }
    if (-not $ChecksumsUrl)   { Fail "checksums_url not found in release metadata" }

    $AssetName = Split-Path $AssetUrl -Leaf

    Write-Step "Installing Conte CLI $ReleaseVersion..."

    $TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "conte-install-$([System.Guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $TmpDir | Out-Null

    try {
        $ArchivePath   = Join-Path $TmpDir $AssetName
        $ChecksumsPath = Join-Path $TmpDir 'checksums.txt'
        $ExtractDir    = Join-Path $TmpDir 'extracted'

        Write-Step "Downloading $AssetName..."
        try {
            Invoke-WebRequest -Uri $AssetUrl -OutFile $ArchivePath -UseBasicParsing
        } catch {
            Fail "Failed to download $AssetName from $AssetUrl. Error: $_"
        }

        Write-Step "Downloading checksums.txt..."
        try {
            Invoke-WebRequest -Uri $ChecksumsUrl -OutFile $ChecksumsPath -UseBasicParsing
        } catch {
            Fail "Failed to download checksums.txt from $ChecksumsUrl. Error: $_"
        }

        # Verify SHA256 checksum
        $ChecksumLine = Get-Content $ChecksumsPath |
                        Where-Object { $_ -match "\s\*?$([regex]::Escape($AssetName))$" }
        if (-not $ChecksumLine) { Fail "Checksum entry not found for $AssetName in checksums.txt" }
        $ExpectedHash = ($ChecksumLine -split '\s+')[0].Trim().ToLower()

        $ActualHash = (Get-FileHash $ArchivePath -Algorithm SHA256).Hash.ToLower()
        if ($ExpectedHash -ne $ActualHash) {
            Fail "Checksum mismatch for $AssetName`n  Expected: $ExpectedHash`n  Got:      $ActualHash"
        }
        Write-Step "Checksum verified."

        # Extract archive
        New-Item -ItemType Directory -Path $ExtractDir | Out-Null
        Expand-Archive -Path $ArchivePath -DestinationPath $ExtractDir -Force

        # Locate the payload root by finding bin/conte (the Bash entry-point).
        # The ZIP may contain a single top-level directory or extract flat:
        #   Case A: extracted/<name>/bin/conte  ->  PayloadRoot = extracted/<name>
        #   Case B: extracted/bin/conte         ->  PayloadRoot = extracted/
        $ConteBash = Get-ChildItem -Path $ExtractDir -Recurse -File -ErrorAction SilentlyContinue |
                     Where-Object { $_.Name -eq 'conte' -and $_.Directory.Name -eq 'bin' } |
                     Select-Object -First 1

        if (-not $ConteBash) {
            Fail "ZIP payload is invalid: bin/conte not found in $AssetName.`nThe packaging script in conte-cli must include bin/conte."
        }

        $PayloadBinDir = $ConteBash.DirectoryName          # …/bin
        $PayloadRoot   = $ConteBash.Directory.Parent.FullName  # … (one level up from bin/)

        # Verify the Windows CMD wrapper is present
        $PayloadCmdWrapper = Join-Path $PayloadBinDir 'conte.cmd'
        if (-not (Test-Path $PayloadCmdWrapper)) {
            Fail "Windows wrapper is missing: bin/conte.cmd not found in $AssetName.`nThe packaging script in conte-cli must include bin/conte.cmd for Windows support."
        }

        # Install: copy the full payload into ConteHome, preserving directory structure.
        # Using robocopy for reliability; fall back to Copy-Item if not available.
        Write-Step "Installing to $ConteHome..."
        New-Item -ItemType Directory -Path $ConteHome -Force | Out-Null

        if (Get-Command robocopy -ErrorAction SilentlyContinue) {
            # /E = include subdirs, /IS = overwrite same files, /IT = overwrite tweaked files
            # /NFL /NDL /NJH /NJS = suppress verbose output; exit codes 0-7 are success for robocopy
            $rc = (robocopy $PayloadRoot $ConteHome /E /IS /IT /NFL /NDL /NJH /NJS)
            if ($LASTEXITCODE -ge 8) {
                Fail "robocopy failed with exit code $LASTEXITCODE while installing to $ConteHome"
            }
        } else {
            Copy-Item -Path (Join-Path $PayloadRoot '*') -Destination $ConteHome -Recurse -Force
        }

        # Confirm the key files landed correctly
        $InstalledBash = Join-Path $ConteBinDir 'conte'
        $InstalledCmd  = Join-Path $ConteBinDir 'conte.cmd'

        if (-not (Test-Path $InstalledBash)) { Fail "Installation error: $InstalledBash is missing after copy" }
        if (-not (Test-Path $InstalledCmd))  { Fail "Installation error: $InstalledCmd is missing after copy"  }

        # Add ConteBinDir to user PATH if not already present
        $CurrentPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
        $PathEntries = if ($CurrentPath) {
            $CurrentPath -split ';' | Where-Object { $_ -ne '' }
        } else { @() }

        if ($ConteBinDir -notin $PathEntries) {
            $NewPath = ($PathEntries + $ConteBinDir) -join ';'
            [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, 'User')
            Write-Step ""
            Write-Step "Added $ConteBinDir to your user PATH."
        } else {
            Write-Step "$ConteBinDir is already in your PATH."
        }

        # Check for Git for Windows / Git Bash (required to run the Bash entry-point)
        $GitBash = @(
            "$env:ProgramFiles\Git\bin\bash.exe",
            "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
            "$env:LocalAppData\Programs\Git\bin\bash.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1

        if (-not $GitBash) {
            Write-Step ""
            Write-Warning "Git for Windows (Git Bash) was not detected."
            Write-Warning "Conte CLI requires Git for Windows to run on Windows."
            Write-Warning "Install Git for Windows: https://git-scm.com/download/win"
            Write-Warning "After installing Git, open a new terminal and run: conte --version"
        } else {
            # Verify installation via the CMD wrapper (which invokes Bash)
            try {
                $VersionOutput = cmd /c "`"$InstalledCmd`" --version" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Step "Installed: $VersionOutput"
                } else {
                    Write-Step "Installed Conte CLI $ReleaseVersion to $ConteHome"
                    Write-Warning "Verification returned exit code $LASTEXITCODE -- run 'conte --version' after opening a new terminal"
                }
            } catch {
                Write-Step "Installed Conte CLI $ReleaseVersion to $ConteHome"
                Write-Warning "Could not verify with 'conte --version': $_"
            }
        }

    } finally {
        Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Step ""
    Write-Step "Conte CLI $ReleaseVersion installed to $ConteHome"
    Write-Step "Open a new terminal and run: conte --version"
}
