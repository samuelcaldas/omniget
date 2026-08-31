<#
.SYNOPSIS
    Provider Factory: Instantiates and maps providers dynamically.
#>

. "$PSScriptRoot\Providers\BaseProvider.ps1"
. "$PSScriptRoot\Providers\NiniteProvider.ps1"
. "$PSScriptRoot\Providers\DirectProvider.ps1"
. "$PSScriptRoot\Providers\GitHubReleaseProvider.ps1"
. "$PSScriptRoot\Providers\DistroRecipeProvider.ps1"
. "$PSScriptRoot\Providers\NpmProvider.ps1"

class ProviderFactory {
    static [System.Collections.Generic.Dictionary[string, BaseProvider]]$Providers = $null

    static [void] Initialize() {
        if ($null -eq [ProviderFactory]::Providers) {
            [ProviderFactory]::Providers = [System.Collections.Generic.Dictionary[string, BaseProvider]]::new([System.StringComparer]::OrdinalIgnoreCase)

            $ninite = [NiniteProvider]::new()
            $direct = [DirectProvider]::new()
            $github = [GitHubReleaseProvider]::new()
            $distro = [DistroRecipeProvider]::new()
            $npm    = [NpmProvider]::new()

            [ProviderFactory]::Providers.Add("ninite", $ninite)
            [ProviderFactory]::Providers.Add("direct", $direct)
            [ProviderFactory]::Providers.Add("github", $github)
            [ProviderFactory]::Providers.Add("distro", $distro)
            [ProviderFactory]::Providers.Add("npm", $npm)
        }
    }

    static [BaseProvider] GetProvider([string]$sourceName) {
        [ProviderFactory]::Initialize()
        if ([ProviderFactory]::Providers.ContainsKey($sourceName)) {
            return [ProviderFactory]::Providers[$sourceName]
        }
        return [ProviderFactory]::Providers["direct"]
    }
}
