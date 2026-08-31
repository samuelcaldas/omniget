<#
.SYNOPSIS
    Global NPM Provider: Installs global CLI tools (like @anthropic-ai/claude-code).
#>

. "$PSScriptRoot\BaseProvider.ps1"

class NpmProvider : BaseProvider {
    NpmProvider() : base("npm", "NPM", "Node Package Manager global CLI tools") {}

    [void] InstallSingle([PSCustomObject]$Package, [bool]$Silent) {
        Write-Host "`n[NPM] Installing global package: $($Package.PackageName)..." -ForegroundColor Red
        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            throw "npm command not found. Please install Node.js first."
        }

        $proc = Start-Process -FilePath "npm.cmd" -ArgumentList "install -g $($Package.PackageName)" -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -eq 0) {
            Write-Host "[NPM] Successfully installed $($Package.PackageName)." -ForegroundColor Green
        } else {
            Write-Host "[NPM] npm install exited with code $($proc.ExitCode)." -ForegroundColor Yellow
        }
    }
}
