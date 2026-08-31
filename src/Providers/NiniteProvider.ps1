<#
.SYNOPSIS
    Ninite Bundle Provider: Creates dynamic single-binary installer from multiple app slugs.
#>

. "$PSScriptRoot\BaseProvider.ps1"

class NiniteProvider : BaseProvider {
    NiniteProvider() : base("ninite", "Ninite", "Dynamic bundle installer from ninite.com") {}

    [void] InstallBatch([PSCustomObject[]]$Packages, [bool]$Silent) {
        if ($Packages.Count -eq 0) { return }

        $slugs = @($Packages | ForEach-Object { $_.Id } | Sort-Object -Unique)
        $slugString = ($slugs -join "-")
        $installerUrl = "https://ninite.com/${slugString}/ninite.exe"
        $tempPath = "$env:TEMP\omniget_ninite_$([System.Guid]::NewGuid().ToString('N')).exe"

        Write-Host "`n[Ninite] Preparing dynamic bundle for ($($slugs.Count) apps): $($slugs -join ', ')" -ForegroundColor Magenta
        Write-Host "[Ninite] Generated Bundle URL: $installerUrl" -ForegroundColor Gray

        $curl = "$env:WINDIR\System32\curl.exe"
        try {
            if (Test-Path $curl) {
                & $curl -fSL "$installerUrl" -o "$tempPath"
            } else {
                (New-Object System.Net.WebClient).DownloadFile($installerUrl, $tempPath)
            }

            if (-not (Test-Path $tempPath) -or (Get-Item $tempPath).Length -lt 1024) {
                throw "Ninite installer download failed or returned invalid response."
            }

            Write-Host "[Ninite] Executing silent installation..." -ForegroundColor Cyan
            $proc = Start-Process -FilePath $tempPath -Wait -PassThru -NoNewWindow
            if ($proc.ExitCode -eq 0) {
                Write-Host "[Ninite] Bundle installation completed successfully." -ForegroundColor Green
            } else {
                Write-Host "[Ninite] Process exited with code $($proc.ExitCode)." -ForegroundColor Yellow
            }
        }
        finally {
            if (Test-Path $tempPath) {
                Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
            }
        }
    }

    [void] InstallSingle([PSCustomObject]$Package, [bool]$Silent) {
        $this.InstallBatch(@($Package), $Silent)
    }
}
