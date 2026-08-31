<#
.SYNOPSIS
    OmniGet PowerShell 7 Module
#>
function Invoke-OmniGet {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    $script = Join-Path $PSScriptRoot "OmniGet.ps1"
    & $script @Arguments
}

Set-Alias -Name og -Value Invoke-OmniGet -Scope Global
Set-Alias -Name omniget -Value Invoke-OmniGet -Scope Global
Export-ModuleMember -Function Invoke-OmniGet -Alias og, omniget
