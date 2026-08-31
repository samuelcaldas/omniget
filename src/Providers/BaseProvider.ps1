<#
.SYNOPSIS
    Base Provider Contract (Strategy Pattern) for OmniGet.
#>

class BaseProvider {
    [string]$Name
    [string]$DisplayName
    [string]$Description

    BaseProvider([string]$name, [string]$displayName, [string]$description) {
        $this.Name = $name
        $this.DisplayName = $displayName
        $this.Description = $description
    }

    [bool] CanHandle([PSCustomObject]$Package) {
        return ($Package.Source -eq $this.Name)
    }

    [bool] IsInstalled([PSCustomObject]$Package) {
        if ($Package.CheckCommand) {
            try {
                $null = & powershell.exe -Command $Package.CheckCommand 2>$null
                return ($LASTEXITCODE -eq 0)
            } catch { return $false }
        }
        if ($Package.CheckPath) {
            return (Test-Path $Package.CheckPath)
        }
        return $false
    }

    [string] GetInstalledVersion([PSCustomObject]$Package) {
        if ($Package.VersionCommand) {
            try {
                $ver = (& powershell.exe -Command $Package.VersionCommand 2>$null | Select-Object -First 1).ToString().Trim()
                if ($ver) { return $ver }
            } catch {}
        }
        return ""
    }

    [void] InstallSingle([PSCustomObject]$Package, [bool]$Silent) {
        throw "InstallSingle must be implemented by derived provider."
    }

    [void] InstallBatch([PSCustomObject[]]$Packages, [bool]$Silent) {
        foreach ($pkg in $Packages) {
            $this.InstallSingle($pkg, $Silent)
        }
    }
}
