<#
.SYNOPSIS
    Synchronizes the local wiki/ folder to the GitHub Wiki repository for OmniGet.
#>

[CmdletBinding()]
param(
    [string]$WikiRemote = "git@github.com:samuelcaldas/omniget.wiki.git"
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$WikiDir   = Join-Path $RepoRoot "wiki"
$TempDir   = Join-Path $env:TEMP "omniget-wiki-sync-$([System.Guid]::NewGuid().ToString('N'))"

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "  OmniGet GitHub Wiki Synchronizer (PowerShell)" -ForegroundColor White
Write-Host "==============================================================================" -ForegroundColor Cyan

if (-not (Test-Path $WikiDir)) {
    throw "Wiki directory not found at $WikiDir"
}

try {
    Write-Host "[INFO] Cloning or initializing wiki repository: $WikiRemote..." -ForegroundColor Gray
    $cloneSuccess = $false
    try {
        & git clone $WikiRemote $TempDir 2>$null
        if ($LASTEXITCODE -eq 0) { $cloneSuccess = $true }
    } catch {}

    if (-not $cloneSuccess) {
        Write-Host "[INFO] Initializing new repository..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        & git -C $TempDir init -b master
        & git -C $TempDir remote add origin $WikiRemote
    }

    Write-Host "[INFO] Copying markdown pages..." -ForegroundColor Cyan
    Copy-Item -Path "$WikiDir\*" -Destination $TempDir -Recurse -Force

    & git -C $TempDir add -A
    & git -C $TempDir diff --staged --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Wiki repository is already up-to-date." -ForegroundColor Green
    } else {
        & git -C $TempDir commit -m "docs(wiki): synchronize omniget documentation and guides"
        Write-Host "[INFO] Pushing changes to GitHub Wiki..." -ForegroundColor Cyan
        & git -C $TempDir push origin master
        Write-Host "[SUCCESS] Successfully synchronized OmniGet Wiki!" -ForegroundColor Green
    }
}
finally {
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
