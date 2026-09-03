<#
.SYNOPSIS
    OmniGet (og) — Universal Multi-Source Package Engine for Windows.
.DESCRIPTION
    Main CLI and TUI orchestrator executing package downloads, silent installs, batch presets,
    manifest self-updates, and environment deployment.
.EXAMPLE
    og
    og search git
    og install git nodejs -s
    og list github
    og preset DevStack -s
    og update
    og version
    og help
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "",

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @(),

    # Backward compatibility parameter switches
    [Alias('i')]
    [string[]]$Install = @(),

    [Alias('p')]
    [string]$Preset = "",

    [string]$Search = "",

    [Alias('l')]
    [string]$List = "",

    [Alias('s')]
    [switch]$Silent,

    [Alias('d')]
    [switch]$Deploy,

    [Alias('v')]
    [switch]$Version,

    [Alias('h')]
    [switch]$Help,

    [Alias('y')]
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OmniRoot  = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$ManifestsDir = Join-Path $OmniRoot "manifests"

. "$OmniRoot/src/UI/SearchEngine.ps1"
. "$OmniRoot/src/Core/Engine.ps1"
. "$OmniRoot/src/Core/ManifestReader.ps1"
. "$OmniRoot/src/UI/TuiApp.ps1"

function Deploy-OmniGetEnvironment {
    Write-Host "[INFO] Deploying OmniGet (og) to system environment..." -ForegroundColor Cyan
    $binDir = Join-Path $OmniRoot "bin"
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

    if ($machinePath -notlike "*$binDir*") {
        [System.Environment]::SetEnvironmentVariable('Path', "$binDir;$machinePath", [System.EnvironmentVariableTarget]::Machine)
        $env:Path = "$binDir;$env:Path"
        Write-Host "[SUCCESS] Added $binDir to Machine PATH." -ForegroundColor Green
    }

    # Clean up legacy Ninite and redundant shortcuts
    $desktops = @(
        [System.Environment]::GetFolderPath('CommonDesktopDirectory'),
        "C:\Users\samuelcaldas\Desktop",
        "C:\Users\Administrator\Desktop"
    )
    foreach ($d in $desktops) {
        if (Test-Path $d) {
            Get-ChildItem -Path $d -Filter "Ninite App Store*.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path $d -Filter "Server Configuration (sconfig).lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }

    # Deploy Desktop Shortcut in Public Desktop
    $publicDesktop = [System.Environment]::GetFolderPath('CommonDesktopDirectory')
    if (Test-Path $publicDesktop) {
        try {
            $wshShell = New-Object -ComObject WScript.Shell
            $shortcut = $wshShell.CreateShortcut((Join-Path $publicDesktop "OmniGet Store.lnk"))
            $pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
            $shortcut.TargetPath = if (Test-Path $pwsh) { $pwsh } else { "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" }
            $shortcut.Arguments = "-NoExit -ExecutionPolicy Bypass -File `"$OmniRoot\src\OmniGet.ps1`""
            $shortcut.WorkingDirectory = $OmniRoot
            $shortcut.Description = "OmniGet - Universal Package Engine"
            $shortcut.Save()
            Write-Host "[SUCCESS] Created Desktop Shortcut: OmniGet Store.lnk" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not create desktop shortcut: $_"
        }
    }
}

function Execute-PackageBatch {
    param(
        [string[]]$PackageIds,
        [System.Collections.Generic.List[PSCustomObject]]$Catalog,
        [bool]$SilentMode
    )

    if ($PackageIds.Count -eq 0) {
        Write-Host "[WARN] No packages selected for installation." -ForegroundColor Yellow
        return
    }

    $byId = [System.Collections.Generic.Dictionary[string, PSCustomObject]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($item in $Catalog) {
        if (-not $byId.ContainsKey($item.Id)) { $byId.Add($item.Id, $item) }
    }

    # Group by provider source
    $grouped = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[PSCustomObject]]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($id in $PackageIds) {
        if ($byId.ContainsKey($id)) {
            $pkg = $byId[$id]
            $src = $pkg.Source
            if (-not $grouped.ContainsKey($src)) {
                $grouped.Add($src, [System.Collections.Generic.List[PSCustomObject]]::new())
            }
            $grouped[$src].Add($pkg)
        }
        else {
            Write-Warning "Package '$id' not found in any catalog."
        }
    }

    Write-Host "`n==============================================================================" -ForegroundColor Cyan
    Write-Host "  OMNIGET BATCH EXECUTION ($($PackageIds.Count) packages)" -ForegroundColor White
    Write-Host "==============================================================================" -ForegroundColor Cyan

    foreach ($kv in $grouped) {
        $sourceName = $kv.Key
        $packages = $kv.Value.ToArray()
        $provider = Get-OmniProvider -SourceName $sourceName

        Write-Host "`n>>> Running Provider: $($provider.DisplayName) ($($packages.Count) packages)..." -ForegroundColor Cyan
        try {
            $provider.InstallBatch($packages, $SilentMode)
        }
        catch {
            Write-Host "[ERROR] Provider $($provider.DisplayName) error: $_" -ForegroundColor Red
        }
    }

    Write-Host "`n[SUCCESS] OmniGet batch installation completed." -ForegroundColor Green
}

function Show-UsageHelp {
    Write-Host @"

OmniGet (og) — Universal Multi-Source Package Engine for Windows
Version 1.0.0

USAGE:
    og [COMMAND] [OPTIONS] [ARGUMENTS...]

COMMANDS:
    (none)                          Launch interactive App Store (ANSI TUI)
    search, find <query>            Search for packages across all sources
    install, add, get <pkg...>      Install one or more packages
    list, ls [source]               List packages (ninite, github, direct, distro, all)
    preset <name>                   Install predefined package preset (e.g. DevStack)
    update, upgrade                 Update OmniGet engine and manifests to latest release
    deploy                          Register 'og' in system PATH and create shortcuts
    version, -v, --version          Display current OmniGet version
    help, -h, --help                Display this help documentation

OPTIONS:
    -s, --silent, -Silent           Run installations silently without prompts
    -y, --yes                       Assume 'yes' to all installation prompts

PRESETS:
    DevStack, Browsers, Minimal, Utilities, SystemShells, Media

EXAMPLES:
    og
    og search git
    og install git gh pwsh -s
    og list github
    og preset DevStack -s
    og update
"@ -ForegroundColor Cyan
}

function Update-OmniGetEngine {
    Write-Host "`n==============================================================================" -ForegroundColor Cyan
    Write-Host "  OMNIGET SELF-UPDATE & MANIFEST SYNCHRONIZATION" -ForegroundColor White
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host "[INFO] Checking for latest release from GitHub..." -ForegroundColor Cyan

    $zipUrl = "https://github.com/samuelcaldas/omniget/archive/refs/heads/main.zip"
    $tempZip = "$env:TEMP\omniget_update_$([System.Guid]::NewGuid().ToString('N')).zip"
    $extractDir = "$env:TEMP\omniget_extract_$([System.Guid]::NewGuid().ToString('N'))"
    $curl = "$env:WINDIR\System32\curl.exe"

    try {
        if (Test-Path $curl) {
            & $curl -fSL "$zipUrl" -o "$tempZip"
        } else {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
            (New-Object System.Net.WebClient).DownloadFile($zipUrl, $tempZip)
        }

        if (-not (Test-Path $tempZip) -or (Get-Item $tempZip).Length -eq 0) {
            throw "Failed to download update archive from $zipUrl"
        }

        Write-Host "[INFO] Extracting update files..." -ForegroundColor Cyan
        Expand-Archive -Path $tempZip -DestinationPath $extractDir -Force
        $srcRoot = Join-Path $extractDir "omniget-main"
        if (-not (Test-Path $srcRoot)) { $srcRoot = $extractDir }

        # Synchronize manifests, src, bin directories
        foreach ($sub in @("manifests", "src", "bin")) {
            $srcSub = Join-Path $srcRoot $sub
            $dstSub = Join-Path $OmniRoot $sub
            if (Test-Path $srcSub) {
                if (-not (Test-Path $dstSub)) { New-Item -ItemType Directory -Path $dstSub -Force | Out-Null }
                Copy-Item -Path "$srcSub\*" -Destination $dstSub -Recurse -Force
            }
        }

        foreach ($doc in @("README.md", "LICENSE")) {
            $srcDoc = Join-Path $srcRoot $doc
            if (Test-Path $srcDoc) { Copy-Item -Path $srcDoc -Destination $OmniRoot -Force }
        }

        Deploy-OmniGetEnvironment
        Write-Host "`n[SUCCESS] OmniGet core engine and manifests updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`n[ERROR] OmniGet update failed: $_" -ForegroundColor Red
    }
    finally {
        Remove-Item -Path $tempZip, $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Main {
    # 1. Version check
    if ($Version -or $Command -in @("version", "-v", "--version", "-version")) {
        Write-Host "OmniGet (og) version 1.0.0"
        return
    }

    # 2. Help check
    if ($Help -or $Command -in @("help", "-h", "--help", "-help", "?", "-?")) {
        Show-UsageHelp
        return
    }

    # 3. Deploy check
    if ($Deploy -or $Command -eq "deploy") {
        Deploy-OmniGetEnvironment
        return
    }

    # 4. Self-update check
    if ($Command -in @("update", "upgrade")) {
        Update-OmniGetEngine
        return
    }

    # Parse silent / yes flags from Arguments
    $isSilent = $Silent.IsPresent -or ($Arguments -contains "-s") -or ($Arguments -contains "--silent") -or ($Arguments -contains "-y") -or ($Arguments -contains "--yes")
    $cleanArgs = @($Arguments | Where-Object { $_ -notmatch '^-{1,2}(s|silent|y|yes)$' })

    $allPackages = [ManifestReader]::LoadAllPackages($ManifestsDir)
    $presets = [ManifestReader]::LoadPresets($ManifestsDir)

    # 5. CLI Search
    $searchQuery = if (-not [string]::IsNullOrWhiteSpace($Search)) { $Search } elseif ($Command -in @("search", "find") -and $cleanArgs.Count -gt 0) { $cleanArgs -join " " } else { "" }
    if (-not [string]::IsNullOrWhiteSpace($searchQuery)) {
        $results = [SearchEngine]::Filter($searchQuery, $allPackages)
        Write-Host "`nSearch results for '$searchQuery' ($($results.Count) matches):" -ForegroundColor Cyan
        foreach ($r in $results) {
            $line = "  • {0,-18} [{1,-6}] - {2}" -f $r.Id, $r.Source.ToUpper(), $r.Desc
            Write-Host $line -ForegroundColor White
        }
        return
    }

    # 6. CLI List
    $listFilter = if ($PSBoundParameters.ContainsKey('List')) { $List } elseif ($Command -in @("list", "ls")) { if ($cleanArgs.Count -gt 0) { $cleanArgs[0] } else { "all" } } else { $null }
    if ($null -ne $listFilter) {
        $filter = $listFilter.ToLower()
        $filtered = if ($filter -and $filter -ne "all") {
            @($allPackages | Where-Object { $_.Source -eq $filter })
        } else {
            $allPackages.ToArray()
        }
        Write-Host "`nOmniGet Package List ($($filtered.Count) packages):" -ForegroundColor Cyan
        foreach ($p in $filtered) {
            $line = "  • {0,-20} [{1,-6}] {2}" -f $p.Id, $p.Source.ToUpper(), $p.Name
            Write-Host $line -ForegroundColor White
        }
        return
    }

    # 7. Preset Installation
    $presetName = if (-not [string]::IsNullOrWhiteSpace($Preset)) { $Preset } elseif ($Command -eq "preset" -and $cleanArgs.Count -gt 0) { $cleanArgs[0] } else { "" }
    if (-not [string]::IsNullOrWhiteSpace($presetName)) {
        if ($presets.ContainsKey($presetName)) {
            $presetApps = $presets[$presetName]
            Write-Host "[INFO] Selected Preset '$presetName': $($presetApps -join ', ')" -ForegroundColor Cyan
            Execute-PackageBatch -PackageIds $presetApps -Catalog $allPackages -SilentMode $isSilent
            return
        } else {
            Write-Host "[ERROR] Unknown preset: '$presetName'. Available: $($presets.Keys -join ', ')" -ForegroundColor Red
            return
        }
    }

    # 8. Package Installation (install / add / get or -Install)
    $pkgsToInstall = [System.Collections.Generic.List[string]]::new()
    if ($Install.Count -gt 0) {
        $pkgsToInstall.AddRange($Install)
    } elseif ($Command -in @("install", "add", "get")) {
        $pkgsToInstall.AddRange($cleanArgs)
    }

    if ($pkgsToInstall.Count -gt 0) {
        Execute-PackageBatch -PackageIds $pkgsToInstall.ToArray() -Catalog $allPackages -SilentMode $isSilent
        return
    }

    # 9. If an unknown command was provided
    if (-not [string]::IsNullOrWhiteSpace($Command)) {
        # Check if the command matches a package ID directly (e.g. 'og git')
        $matching = @($allPackages | Where-Object { $_.Id -eq $Command.ToLower() })
        if ($matching.Count -gt 0) {
            Execute-PackageBatch -PackageIds @($Command) -Catalog $allPackages -SilentMode $isSilent
            return
        }
        Write-Host "[ERROR] Unknown command '$Command'. Run 'og help' for usage instructions." -ForegroundColor Red
        return
    }

    # 10. Interactive ANSI TUI Mode (default when no arguments)
    Deploy-OmniGetEnvironment
    $app = [TuiApp]::new($allPackages, $presets, @())
    $selected = $app.Run()

    if ($selected.Count -gt 0) {
        Execute-PackageBatch -PackageIds $selected -Catalog $allPackages -SilentMode $isSilent
    } else {
        Write-Host "`n[INFO] OmniGet session exited." -ForegroundColor Gray
    }
}

Main
