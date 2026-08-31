<#
.SYNOPSIS
    GitHub Releases Provider: Resolves release assets dynamically from GitHub.
#>

. "$PSScriptRoot\BaseProvider.ps1"

class GitHubReleaseProvider : BaseProvider {
    GitHubReleaseProvider() : base("github", "GitHub", "Official releases from GitHub repositories") {}

    [void] InstallSingle([PSCustomObject]$Package, [bool]$Silent) {
        Write-Host "`n[GitHub] Installing $($Package.Name) from $($Package.Repo)..." -ForegroundColor Blue
        $url = $Package.Url
        if (-not $url -and $Package.Repo) {
            # Fallback URL pattern if direct asset URL not pre-populated
            $tag = if ($Package.Version) { "v$($Package.Version)" } else { "latest" }
            $url = "https://github.com/$($Package.Repo)/releases/$tag"
        }

        $tempFile = "$env:TEMP\omniget_gh_$($Package.Id)_$([System.Guid]::NewGuid().ToString('N')).exe"
        if ($Package.Format -eq "zip" -or $url.EndsWith(".zip")) {
            $tempFile = "$env:TEMP\omniget_gh_$($Package.Id)_$([System.Guid]::NewGuid().ToString('N')).zip"
        } elseif ($Package.Format -eq "msi" -or $url.EndsWith(".msi")) {
            $tempFile = "$env:TEMP\omniget_gh_$($Package.Id)_$([System.Guid]::NewGuid().ToString('N')).msi"
        }

        $curl = "$env:WINDIR\System32\curl.exe"
        try {
            Write-Host "[GitHub] Downloading $url..." -ForegroundColor Gray
            if (Test-Path $curl) {
                & $curl -fSL "$url" -o "$tempFile"
            } else {
                (New-Object System.Net.WebClient).DownloadFile($url, $tempFile)
            }

            $silentArgs = if ($Package.SilentArgs) { $Package.SilentArgs } else { "/VERYSILENT /NORESTART /SP- /CLOSEAPPLICATIONS" }

            if ($tempFile.EndsWith(".msi")) {
                Write-Host "[GitHub] Installing MSI package..." -ForegroundColor Cyan
                $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempFile`" /qn /norestart" -Wait -PassThru
            }
            elseif ($tempFile.EndsWith(".zip")) {
                $targetDir = if ($Package.InstallPath) { $Package.InstallPath } else { "C:\Program Files\$($Package.Name)" }
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                Write-Host "[GitHub] Extracting to $targetDir..." -ForegroundColor Cyan
                Expand-Archive -Path $tempFile -DestinationPath $targetDir -Force
            }
            else {
                Write-Host "[GitHub] Executing installer..." -ForegroundColor Cyan
                $proc = Start-Process -FilePath $tempFile -ArgumentList "$silentArgs" -Wait -PassThru -NoNewWindow
            }

            Write-Host "[GitHub] Installed $($Package.Name) successfully." -ForegroundColor Green
        }
        finally {
            if (Test-Path $tempFile) {
                Remove-Item -Path $tempFile -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
