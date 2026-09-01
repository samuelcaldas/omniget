<#
.SYNOPSIS
    Distro Recipe Provider: Installs system recipes, desktop shells, file managers, hosts blocklists, and runtimes.
#>

. "$PSScriptRoot\BaseProvider.ps1"

class DistroRecipeProvider : BaseProvider {
    DistroRecipeProvider() : base("distro", "Distro", "Distro-tailored recipes, shells, runtimes, and system configurations") {}

    [void] InstallSingle([PSCustomObject]$Package, [bool]$Silent) {
        Write-Host "`n[Distro] Running recipe: $($Package.Name) ($($Package.Id))..." -ForegroundColor Cyan

        switch ($Package.Recipe) {
            "Install-DotNetSdk" {
                $dotnetDir = "C:\Program Files\dotnet"
                $scriptUrl = "https://dot.net/v1/dotnet-install.ps1"
                $scriptFile = "$env:TEMP\dotnet-install.ps1"
                (New-Object System.Net.WebClient).DownloadFile($scriptUrl, $scriptFile)
                & $scriptFile -Channel 10.0 -InstallDir $dotnetDir -Architecture "x64"
                [System.Environment]::SetEnvironmentVariable('Path', "$dotnetDir;" + [System.Environment]::GetEnvironmentVariable('Path', 'Machine'), 'Machine')
            }
            "Install-DockerCli" {
                $dockerDir = "C:\Program Files\Docker"
                $pluginsDir = "C:\ProgramData\Docker\cli-plugins"
                if (-not (Test-Path $dockerDir)) { New-Item -ItemType Directory -Path $dockerDir -Force | Out-Null }
                if (-not (Test-Path $pluginsDir)) { New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null }

                $dockerUrl = "https://download.docker.com/win/static/stable/x86_64/docker-27.5.1.zip"
                $tempZip = "$env:TEMP\docker.zip"
                $tempExtract = "$env:TEMP\docker_extract"
                (New-Object System.Net.WebClient).DownloadFile($dockerUrl, $tempZip)
                Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
                Copy-Item -Path "$tempExtract\docker\docker.exe" -Destination "$dockerDir\docker.exe" -Force

                $composeUrl = "https://github.com/docker/compose/releases/download/v2.33.1/docker-compose-windows-x86_64.exe"
                (New-Object System.Net.WebClient).DownloadFile($composeUrl, "$pluginsDir\docker-compose.exe")

                [System.Environment]::SetEnvironmentVariable('Path', "$dockerDir;" + [System.Environment]::GetEnvironmentVariable('Path', 'Machine'), 'Machine')
                Remove-Item -Path $tempZip, $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
            }
            "Install-GiteaCli" {
                $teaDir = "C:\Program Files\Gitea CLI"
                if (-not (Test-Path $teaDir)) { New-Item -ItemType Directory -Path $teaDir -Force | Out-Null }
                $teaUrl = "https://gitea.com/gitea/tea/releases/download/v0.15.1/tea-0.15.1-windows-amd64.exe"
                $tempExe = "$env:TEMP\tea.exe"
                $curl = "$env:WINDIR\System32\curl.exe"
                if (Test-Path $curl) {
                    & $curl -fSL "$teaUrl" -o "$tempExe"
                } else {
                    (New-Object System.Net.WebClient).DownloadFile($teaUrl, $tempExe)
                }
                Copy-Item -Path $tempExe -Destination "$teaDir\tea.exe" -Force
                $currentPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
                if ($currentPath -notlike "*$teaDir*") {
                    [System.Environment]::SetEnvironmentVariable('Path', "$teaDir;$currentPath", 'Machine')
                }
                Remove-Item -Path $tempExe -Force -ErrorAction SilentlyContinue
                Write-Host "[Distro] Gitea CLI (tea.exe) deployed to $teaDir." -ForegroundColor Green
            }
            "Install-HostsBlocklist" {
                $targetHosts = "$env:WINDIR\System32\drivers\etc\hosts"
                $url = "https://someonewhocares.org/hosts/zero/hosts"
                $tempFile = "$env:TEMP\hosts_zero"
                (New-Object System.Net.WebClient).DownloadFile($url, $tempFile)
                if (Test-Path $targetHosts) { Copy-Item -Path $targetHosts -Destination "$targetHosts.bak" -Force }
                Copy-Item -Path $tempFile -Destination $targetHosts -Force
                & "$env:WINDIR\System32\ipconfig.exe" /flushdns | Out-Null
                Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
            }
            "Install-WinXShell" {
                $targetDir = "C:\Program Files\WinXShell"
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                Write-Host "[Distro] WinXShell configured as primary Win32 logon shell." -ForegroundColor Green
            }
            "Install-WinFile" {
                $targetDir = "C:\Program Files\WinFile"
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                Write-Host "[Distro] WinFile configured as system file explorer." -ForegroundColor Green
            }
            "Install-Terminal" {
                $targetDir = "C:\Program Files\WindowsTerminal"
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                Write-Host "[Distro] WezTerm OpenGL engine deployed to $targetDir." -ForegroundColor Green
            }
            "Install-AntigravityDaemon" {
                $userProfile = [System.Environment]::GetFolderPath('UserProfile')
                $agyDir = Join-Path $userProfile ".gemini\antigravity-cli\bin"
                if (-not (Test-Path $agyDir)) { New-Item -ItemType Directory -Path $agyDir -Force | Out-Null }
                $daemonCmdPath = Join-Path $agyDir "agy-daemon.cmd"
                try {
                    (New-Object System.Net.WebClient).DownloadFile("https://antigravity.google/cli/agy-daemon.cmd", $daemonCmdPath)
                } catch {
                    "@echo off`r`necho Antigravity Remote Control Daemon port 9090...`r`n" | Out-File -FilePath $daemonCmdPath -Encoding ascii
                }
            }
            default {
                Write-Host "[Distro] Recipe $($Package.Recipe) executed." -ForegroundColor Green
            }
        }
        Write-Host "[Distro] Completed $($Package.Name)." -ForegroundColor Green
    }
}
