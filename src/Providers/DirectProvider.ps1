<#
.SYNOPSIS
    Direct Provider: Downloads official MSI, InnoSetup, and standalone executables.
#>

. "$PSScriptRoot\BaseProvider.ps1"

class DirectProvider : BaseProvider {
    DirectProvider() : base("direct", "Direct", "Official vendor installers (MSI / EXE / ZIP)") {}

    [void] InstallSingle([PSCustomObject]$Package, [bool]$Silent) {
        Write-Host "`n[Direct] Installing $($Package.Name) ($($Package.Id))..." -ForegroundColor Cyan
        $url = $Package.Url
        if (-not $url) { throw "No download URL specified for $($Package.Id)" }

        $ext = [System.IO.Path]::GetExtension($url)
        if (-not $ext -or $ext.Contains("?")) {
            $ext = if ($Package.Format) { ".$($Package.Format)" } else { ".exe" }
        }

        $tempFile = "$env:TEMP\omniget_direct_$($Package.Id)_$([System.Guid]::NewGuid().ToString('N'))$ext"
        $curl = "$env:WINDIR\System32\curl.exe"

        try {
            Write-Host "[Direct] Downloading from $url..." -ForegroundColor Gray
            if (Test-Path $curl) {
                & $curl -fSL "$url" -o "$tempFile"
            } else {
                (New-Object System.Net.WebClient).DownloadFile($url, $tempFile)
            }

            if (-not (Test-Path $tempFile) -or (Get-Item $tempFile).Length -lt 1024) {
                throw "Downloaded file is invalid or empty."
            }

            $silentArgs = if ($Package.SilentArgs) { $Package.SilentArgs } else { "/quiet /norestart" }

            if ($ext -eq ".msi") {
                Write-Host "[Direct] Executing msiexec installation..." -ForegroundColor Cyan
                $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempFile`" $silentArgs" -Wait -PassThru
            }
            elseif ($ext -eq ".zip") {
                $targetDir = if ($Package.InstallPath) { $Package.InstallPath } else { "C:\Program Files\$($Package.Name)" }
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                Write-Host "[Direct] Extracting archive to $targetDir..." -ForegroundColor Cyan
                Expand-Archive -Path $tempFile -DestinationPath $targetDir -Force
            }
            else {
                Write-Host "[Direct] Executing installer ($silentArgs)..." -ForegroundColor Cyan
                $proc = Start-Process -FilePath $tempFile -ArgumentList "$silentArgs" -Wait -PassThru -NoNewWindow
            }

            Write-Host "[Direct] Successfully installed $($Package.Name)." -ForegroundColor Green
        }
        finally {
            if (Test-Path $tempFile) {
                Remove-Item -Path $tempFile -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
