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
                    $id       = if ($item.PSObject.Properties['id']) { $item.id } else { "" }
                    $name     = if ($item.PSObject.Properties['name']) { $item.name } else { $id }
                    $category = if ($item.PSObject.Properties['category']) { $item.category } else { "General" }
                    $source   = if ($item.PSObject.Properties['source']) { $item.source } else { "ninite" }
                    $desc     = if ($item.PSObject.Properties['desc']) { $item.desc } else { $name }
                    $version  = if ($item.PSObject.Properties['version']) { $item.version } else { "" }
                    $url      = if ($item.PSObject.Properties['url']) { $item.url } else { "" }
                    $repo     = if ($item.PSObject.Properties['repo']) { $item.repo } else { "" }
                    $format   = if ($item.PSObject.Properties['format']) { $item.format } else { "" }
                    $silent   = if ($item.PSObject.Properties['silentArgs']) { $item.silentArgs } else { "" }
                    $path     = if ($item.PSObject.Properties['installPath']) { $item.installPath } else { "" }
                    $recipe   = if ($item.PSObject.Properties['recipe']) { $item.recipe } else { "" }
                    $pkgName  = if ($item.PSObject.Properties['packageName']) { $item.packageName } else { "" }
                    $check    = if ($item.PSObject.Properties['checkCommand']) { $item.checkCommand } else { "" }
                    $verCmd   = if ($item.PSObject.Properties['versionCommand']) { $item.versionCommand } else { "" }
                    $feat     = if ($item.PSObject.Properties['featured']) { [bool]$item.featured } else { $false }

                    $list.Add([PSCustomObject]@{
                        Id             = $id
                        Name           = $name
                        Category       = $category
                        Source         = $source
                        Desc           = $desc
                        Version        = $version
                        Url            = $url
                        Repo           = $repo
                        Format         = $format
                        SilentArgs     = $silent
                        InstallPath    = $path
                        Recipe         = $recipe
                        PackageName    = $pkgName
                        CheckCommand   = $check
                        VersionCommand = $verCmd
                        Featured       = $feat
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
