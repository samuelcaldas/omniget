<#
.SYNOPSIS
    Provider Factory: Instantiates and maps providers dynamically.
#>

$srcRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
. "$srcRoot/Providers/BaseProvider.ps1"
. "$srcRoot/Providers/NiniteProvider.ps1"
. "$srcRoot/Providers/DirectProvider.ps1"
. "$srcRoot/Providers/GitHubReleaseProvider.ps1"
. "$srcRoot/Providers/DistroRecipeProvider.ps1"
. "$srcRoot/Providers/NpmProvider.ps1"

$script:GlobalProviders = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)

function Get-OmniProvider {
    param([string]$SourceName)
    if ($script:GlobalProviders.Count -eq 0) {
        $script:GlobalProviders["ninite"] = [NiniteProvider]::new()
        $script:GlobalProviders["direct"] = [DirectProvider]::new()
        $script:GlobalProviders["github"] = [GitHubReleaseProvider]::new()
        $script:GlobalProviders["distro"] = [DistroRecipeProvider]::new()
        $script:GlobalProviders["npm"]    = [NpmProvider]::new()
    }
    if ($script:GlobalProviders.ContainsKey($SourceName)) {
        return $script:GlobalProviders[$SourceName]
    }
    return $script:GlobalProviders["direct"]
}
