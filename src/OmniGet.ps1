<#
.SYNOPSIS
    OmniGet (og) — Universal Multi-Source Package Engine for Windows.
.DESCRIPTION
    Main CLI and TUI orchestrator executing package downloads, silent installs, and batch recipes.
.PARAMETER Install
    Array of package IDs to install directly.
.PARAMETER Preset
    Predefined preset name to execute (e.g. DevStack, Browsers, Minimal, Utilities).
.PARAMETER Search
    Search query to execute from the command line.
.PARAMETER List
    Lists packages optionally filtered by source (ninite, github, direct, distro, all).
.PARAMETER Silent
    Suppresses interactive confirmation prompts.
.PARAMETER Deploy
    Deploys og/omniget CLI shortcuts and environment PATH.
#>
[CmdletBinding()]
param(
    [string[]]$Install = @(),
    [string]$Preset = "",
    [string]$Search = "",
    [string]$List = "",
    [switch]$Silent,
    [switch]$Deploy,
    [switch]$Version
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OmniRoot  = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$ManifestsDir = Join-Path $OmniRoot "manifests"

. "$OmniRoot\src\Core\Engine.ps1"
. "$OmniRoot\src\Core\ManifestReader.ps1"
. "$OmniRoot\src\UI\TuiApp.ps1"

function Deploy-OmniGetEnvironment {
    Write-Host "[INFO] Deploying OmniGet (og) to system environment..." -ForegroundColor Cyan
    $binDir = Join-Path $OmniRoot "bin"
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

    if ($machinePath -notlike "*$binDir*") {
        [System.Environment]::SetEnvironmentVariable('Path', "$binDir;$machinePath", [System.EnvironmentVariableTarget]::Machine)
        $env:Path = "$binDir;$env:Path"
        Write-Host "[SUCCESS] Added $binDir to Machine PATH." -ForegroundColor Green
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
        $provider = [ProviderFactory]::GetProvider($sourceName)

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

function Main {
    if ($Version) {
        Write-Host "OmniGet (og) version 1.0.0"
        return
    }

    if ($Deploy) {
        Deploy-OmniGetEnvironment
        return
    }

    $allPackages = [ManifestReader]::LoadAllPackages($ManifestsDir)
    $presets = [ManifestReader]::LoadPresets($ManifestsDir)

    # 1. CLI Search
    if (-not [string]::IsNullOrWhiteSpace($Search)) {
        $results = [SearchEngine]::Filter($Search, $allPackages)
        Write-Host "`nSearch results for '$Search' ($($results.Count) matches):" -ForegroundColor Cyan
        foreach ($r in $results) {
            Write-Host "  • {0,-18} [{1,-6}] - {2}" -f $r.Id, $r.Source.ToUpper(), $r.Desc -ForegroundColor White
        }
        return
    }

    # 2. CLI List
    if ($PSBoundParameters.ContainsKey('List')) {
        $filter = $List.ToLower()
        $filtered = if ($filter -and $filter -ne "all") {
            @($allPackages | Where-Object { $_.Source -eq $filter })
        } else {
            $allPackages.ToArray()
        }
        Write-Host "`nOmniGet Package List ($($filtered.Count) packages):" -ForegroundColor Cyan
        foreach ($p in $filtered) {
            Write-Host "  • {0,-20} [{1,-6}] {2}" -f $p.Id, $p.Source.ToUpper(), $p.Name -ForegroundColor White
        }
        return
    }

    # 3. Direct Package Installation
    if ($Install.Count -gt 0) {
        Execute-PackageBatch -PackageIds $Install -Catalog $allPackages -SilentMode $Silent
        return
    }

    # 4. Preset Installation
    if (-not [string]::IsNullOrWhiteSpace($Preset)) {
        if ($presets.ContainsKey($Preset)) {
            $presetApps = $presets[$Preset]
            Write-Host "[INFO] Selected Preset '$Preset': $($presetApps -join ', ')" -ForegroundColor Cyan
            Execute-PackageBatch -PackageIds $presetApps -Catalog $allPackages -SilentMode $Silent
            return
        } else {
            Write-Host "[ERROR] Unknown preset: '$Preset'. Available: $($presets.Keys -join ', ')" -ForegroundColor Red
            return
        }
    }

    # 5. Interactive ANSI TUI Mode
    Deploy-OmniGetEnvironment
    $app = [TuiApp]::new($allPackages, $presets, @())
    $selected = $app.Run()

    if ($selected.Count -gt 0) {
        Execute-PackageBatch -PackageIds $selected -Catalog $allPackages -SilentMode $Silent
    } else {
        Write-Host "`n[INFO] OmniGet session exited." -ForegroundColor Gray
    }
}

Main
