<#
.SYNOPSIS
    Search Engine: Incremental and fuzzy search across multiple fields.
#>

class SearchEngine {
    static [PSCustomObject[]] Filter([string]$Query, [System.Collections.Generic.List[PSCustomObject]]$Items) {
        if ([string]::IsNullOrWhiteSpace($Query)) {
            return $Items.ToArray()
        }

        $terms = $Query.ToLower().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)

        return @($Items | Where-Object {
            $item = $_
            $id   = if ($item.Id) { $item.Id.ToLower() } else { "" }
            $name = if ($item.Name) { $item.Name.ToLower() } else { "" }
            $desc = if ($item.Desc) { $item.Desc.ToLower() } else { "" }
            $cat  = if ($item.Category) { $item.Category.ToLower() } else { "" }
            $src  = if ($item.Source) { $item.Source.ToLower() } else { "" }

            $matchesAll = $true
            foreach ($t in $terms) {
                if (-not ($id.Contains($t) -or $name.Contains($t) -or $desc.Contains($t) -or $cat.Contains($t) -or $src.Contains($t))) {
                    $matchesAll = $false
                    break
                }
            }
            $matchesAll
        })
    }
}
