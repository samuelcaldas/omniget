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
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }

                $stagingDir = "$targetDir.tmp_$([System.Guid]::NewGuid().ToString('N'))"
                New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

                try {
                    Write-Host "[GitHub] Extracting to staging area..." -ForegroundColor Cyan
                    Expand-Archive -Path $tempFile -DestinationPath $stagingDir -Force

                    Write-Host "[GitHub] Zero-downtime hot-swap: deploying files to $targetDir..." -ForegroundColor Cyan
                    $timestamp = [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss')

                    # Create directories
                    Get-ChildItem -Path $stagingDir -Recurse -Directory | ForEach-Object {
                        $rel = $_.FullName.Substring($stagingDir.Length).TrimStart('\', '/')
                        $destD = Join-Path $targetDir $rel
                        if (-not (Test-Path $destD)) { New-Item -ItemType Directory -Path $destD -Force | Out-Null }
                    }

                    # Deploy files with in-use rotation
                    Get-ChildItem -Path $stagingDir -Recurse -File | ForEach-Object {
                        $rel = $_.FullName.Substring($stagingDir.Length).TrimStart('\', '/')
                        $destF = Join-Path $targetDir $rel
                        if (Test-Path $destF) {
                            try {
                                Copy-Item -Path $_.FullName -Destination $destF -Force -ErrorAction Stop
                            }
                            catch {
                                # In-use locked binary or DLL: rotate to .old_<timestamp> and copy new
                                $oldF = "$destF.old_$timestamp"
                                Rename-Item -Path $destF -NewName (Split-Path -Leaf $oldF) -Force
                                Copy-Item -Path $_.FullName -Destination $destF -Force
                            }
                        }
                        else {
                            Copy-Item -Path $_.FullName -Destination $destF -Force
                        }
                    }

                    # Housekeeping: clean up old rotated files if no longer locked
                    Get-ChildItem -Path $targetDir -Recurse -Filter "*.old_*" -ErrorAction SilentlyContinue | ForEach-Object {
                        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                    }
                    Write-Host "[GitHub] Successfully deployed $targetDir without process disruption." -ForegroundColor Cyan
                }
                catch {
                    if (Test-Path $stagingDir) { Remove-Item -Path $stagingDir -Recurse -Force -ErrorAction SilentlyContinue }
                    throw
                }
                finally {
                    if (Test-Path $stagingDir) { Remove-Item -Path $stagingDir -Recurse -Force -ErrorAction SilentlyContinue }
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
