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
                Write-Host "[GitHub] Installing MSI package (Restart Manager disabled)..." -ForegroundColor Cyan
                $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempFile`" /qn /norestart MSIRESTARTMANAGERCONTROL=Disable" -Wait -PassThru
            }
            elseif ($tempFile.EndsWith(".zip")) {
                $targetDir = if ($Package.InstallPath) { $Package.InstallPath } else { "C:\Program Files\$($Package.Name)" }
                $parentDir = Split-Path -Parent $targetDir
                if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }

                $stagingDir = "$targetDir.tmp_$([System.Guid]::NewGuid().ToString('N'))"
                New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

                try {
                    Write-Host "[GitHub] Extracting to staging area..." -ForegroundColor Cyan
                    Expand-Archive -Path $tempFile -DestinationPath $stagingDir -Force

                    if (Test-Path $targetDir) {
                        $timestamp = [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss')
                        $targetLeaf = Split-Path -Leaf $targetDir
                        $oldDirName = "$targetLeaf.old_$timestamp"
                        Write-Host "[GitHub] Zero-downtime rotation: rotating active directory to $oldDirName..." -ForegroundColor Cyan
                        Rename-Item -Path $targetDir -NewName $oldDirName -Force
                    }

                    Rename-Item -Path $stagingDir -NewName (Split-Path -Leaf $targetDir) -Force
                    Write-Host "[GitHub] Successfully activated $targetDir." -ForegroundColor Cyan

                    # Housekeeping: attempt to remove old rotated directories if no longer locked
                    if (Test-Path $parentDir) {
                        $targetLeaf = Split-Path -Leaf $targetDir
                        Get-ChildItem -Path $parentDir -Directory -Filter "$targetLeaf.old_*" -ErrorAction SilentlyContinue | ForEach-Object {
                            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
                catch {
                    if (Test-Path $stagingDir) { Remove-Item -Path $stagingDir -Recurse -Force -ErrorAction SilentlyContinue }
                    throw
                }
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
