<#
.SYNOPSIS
    Installs OmniGet (og) - Universal Multi-Source Package Engine on Windows.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$InstallDir = "C:\Program Files\OmniGet"
Write-Host "[INFO] Installing OmniGet to $InstallDir..." -ForegroundColor Cyan

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$zipUrl = "https://github.com/samuelcaldas/omniget/archive/refs/heads/main.zip"
$tempZip = "$env:TEMP\omniget_main.zip"
$extractDir = "$env:TEMP\omniget_extract"

try {
    $curl = "$env:WINDIR\System32\curl.exe"
    if (Test-Path $curl) {
        & $curl -fSL "$zipUrl" -o "$tempZip"
    } else {
        (New-Object System.Net.WebClient).DownloadFile($zipUrl, $tempZip)
    }

    if (Test-Path $extractDir) { Remove-Item -Path $extractDir -Recurse -Force }
    Expand-Archive -Path $tempZip -DestinationPath $extractDir -Force

    $srcDir = Join-Path $extractDir "omniget-main"
    if (-not (Test-Path $srcDir)) { $srcDir = $extractDir }

    Copy-Item -Path "$srcDir\*" -Destination $InstallDir -Recurse -Force
    Write-Host "[SUCCESS] OmniGet files deployed." -ForegroundColor Green

    & "$InstallDir\src\OmniGet.ps1" -Deploy
}
finally {
    Remove-Item -Path $tempZip, $extractDir -Recurse -Force -ErrorAction SilentlyContinue
}
