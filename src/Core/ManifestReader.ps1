<#
.SYNOPSIS
    Manifest Reader: Loads declarative JSON package catalogs & presets.
#>

class ManifestReader {
    static [System.Collections.Generic.List[PSCustomObject]] LoadAllPackages([string]$ManifestsDir) {
        $list = [System.Collections.Generic.List[PSCustomObject]]::new()
        if (-not (Test-Path $ManifestsDir)) { return $list }

        $files = Get-ChildItem -Path $ManifestsDir -Filter "*.json" | Where-Object { $_.Name -ne "presets.json" -and $_.Name -ne "featured.json" }
        foreach ($f in $files) {
            try {
                $content = Get-Content $f.FullName -Raw | ConvertFrom-Json
                foreach ($item in $content) {
                    $list.Add([PSCustomObject]@{
                        Id             = $item.id
                        Name           = $item.name
                        Category       = if ($item.category) { $item.category } else { "General" }
                        Source         = if ($item.source) { $item.source } else { "ninite" }
                        Desc           = if ($item.desc) { $item.desc } else { $item.name }
                        Version        = $item.version
                        Url            = $item.url
                        Repo           = $item.repo
                        Format         = $item.format
                        SilentArgs     = $item.silentArgs
                        InstallPath    = $item.installPath
                        Recipe         = $item.recipe
                        PackageName    = $item.packageName
                        CheckCommand   = $item.checkCommand
                        VersionCommand = $item.versionCommand
                        Featured       = if ($item.featured) { $true } else { $false }
                    })
                }
            }
            catch {
                Write-Warning "Failed to load manifest $($f.Name): $_"
            }
        }
        return $list
    }

    static [System.Collections.Generic.Dictionary[string, string[]]] LoadPresets([string]$ManifestsDir) {
        $dict = [System.Collections.Generic.Dictionary[string, string[]]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $presetFile = Join-Path $ManifestsDir "presets.json"
        if (Test-Path $presetFile) {
            $json = Get-Content $presetFile -Raw | ConvertFrom-Json
            foreach ($prop in $json.PSObject.Properties) {
                $dict.Add($prop.Name, @($prop.Value))
            }
        }
        return $dict
    }
}
