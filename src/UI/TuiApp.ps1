<#
.SYNOPSIS
    Interactive Multi-Panel ANSI TUI Application for PowerShell 7.
#>

. "$PSScriptRoot\SearchEngine.ps1"

class TuiApp {
    [System.Collections.Generic.List[PSCustomObject]]$AllPackages
    [System.Collections.Generic.Dictionary[string, string[]]]$Presets
    [System.Collections.Generic.HashSet[string]]$Selected
    [int]$Cursor = 0
    [int]$ActiveTab = 1 # 1: Home/Featured, 2: All, 3: Ninite, 4: Developer, 5: Shells & UI, 6: Media & Utilities
    [string]$SearchQuery = ""
    [int]$PresetIndex = 0

    TuiApp([System.Collections.Generic.List[PSCustomObject]]$packages, [System.Collections.Generic.Dictionary[string, string[]]]$presets, [string[]]$initial) {
        $this.AllPackages = $packages
        $this.Presets = $presets
        $this.Selected = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        if ($initial) {
            foreach ($i in $initial) { [void]$this.Selected.Add($i) }
        }
    }

    [PSCustomObject[]] GetCurrentItems() {
        $items = $this.AllPackages
        if (-not [string]::IsNullOrWhiteSpace($this.SearchQuery)) {
            return [SearchEngine]::Filter($this.SearchQuery, $items)
        }

        switch ($this.ActiveTab) {
            1 { return @($items | Where-Object { $_.Featured -eq $true }) }
            2 { return $items.ToArray() }
            3 { return @($items | Where-Object { $_.Source -eq "ninite" }) }
            4 { return @($items | Where-Object { $_.Category -like "*Developer*" -or $_.Category -like "*.NET*" -or $_.Category -like "*Java*" }) }
            5 { return @($items | Where-Object { $_.Category -like "*Shell*" -or $_.Category -like "*Terminal*" -or $_.Category -like "*Imaging*" }) }
            6 { return @($items | Where-Object { $_.Category -like "*Media*" -or $_.Category -like "*Utilities*" -or $_.Category -like "*Compression*" }) }
            default { return $items.ToArray() }
        }
    }

    [string] ReadSearchInput() {
        $buf = ""
        [Console]::Write("  Search across all sources: ")
        while ($true) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq [ConsoleKey]::Enter -or $k.Key -eq [ConsoleKey]::Escape) { break }
            if ($k.Key -eq [ConsoleKey]::Backspace) {
                if ($buf.Length -gt 0) {
                    $buf = $buf.Substring(0, $buf.Length - 1)
                    [Console]::Write("`b `b")
                }
            }
            elseif ($k.KeyChar -match '\S' -or $k.KeyChar -eq ' ') {
                $buf += $k.KeyChar
                [Console]::Write($k.KeyChar)
            }
        }
        [Console]::WriteLine()
        return $buf
    }

    [string[]] Run() {
        $canRawUI = $true
        try { $null = [Console]::KeyAvailable } catch { $canRawUI = $false }
        if (-not $canRawUI) { return $this.Selected.ToArray() }

        [Console]::CursorVisible = $false
        try {
            while ($true) {
                $visible = $this.GetCurrentItems()
                $total = $visible.Count
                if ($this.Cursor -ge $total -and $total -gt 0) { $this.Cursor = $total - 1 }
                if ($this.Cursor -lt 0) { $this.Cursor = 0 }

                Clear-Host
                Write-Host "================================================================================" -ForegroundColor Cyan
                Write-Host "  OMNIGET (og) — Universal Multi-Source Package Engine for Windows             " -ForegroundColor White
                Write-Host "================================================================================" -ForegroundColor Cyan

                # Top Tabs Bar
                $tabs = @("1:Featured", "2:All", "3:Ninite", "4:DevTools", "5:Shells&UI", "6:Media&Utils")
                $tabLine = "  Tabs: "
                for ($t = 0; $t -lt $tabs.Count; $t++) {
                    $tabNum = $t + 1
                    if ($tabNum -eq $this.ActiveTab) {
                        $tabLine += " [$($tabs[$t])] "
                    } else {
                        $tabLine += "  $($tabs[$t])  "
                    }
                }
                Write-Host $tabLine -ForegroundColor Yellow
                Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray

                # Render Visible Items
                $lastCat = ""
                for ($i = 0; $i -lt $total; $i++) {
                    $item = $visible[$i]
                    if ($item.Category -ne $lastCat) {
                        Write-Host "`n  :: $($item.Category)" -ForegroundColor DarkCyan
                        $lastCat = $item.Category
                    }

                    $isCursor   = ($i -eq $this.Cursor)
                    $isSelected = $this.Selected.Contains($item.Id)

                    $checkMark = if ($isSelected) { "[x]" } else { "[ ]" }
                    $pointer   = if ($isCursor)   { ">" }   else { " " }

                    $badge = switch ($item.Source) {
                        "ninite" { "[Ninite] " }
                        "github" { "[GitHub] " }
                        "distro" { "[Distro] " }
                        "direct" { "[Direct] " }
                        "npm"    { "[NPM]    " }
                        default  { "[Store]  " }
                    }

                    $lineText = "  $pointer $checkMark {0,-10} {1,-20} - {2}" -f $badge, $item.Id, $item.Desc

                    if ($isCursor) {
                        Write-Host $lineText -ForegroundColor Black -BackgroundColor Cyan
                    }
                    elseif ($isSelected) {
                        Write-Host $lineText -ForegroundColor Green
                    }
                    else {
                        Write-Host $lineText -ForegroundColor White
                    }
                }

                if ($total -eq 0) {
                    Write-Host "`n  (no packages matching current filter)" -ForegroundColor DarkGray
                }

                Write-Host "`n--------------------------------------------------------------------------------" -ForegroundColor DarkGray

                # Details Box for Focused Item
                if ($total -gt 0 -and $this.Cursor -lt $total) {
                    $curr = $visible[$this.Cursor]
                    Write-Host "  Focused: $($curr.Name) ($($curr.Id)) | Source: $($curr.Source.ToUpper())" -ForegroundColor Cyan
                }

                # Status Bar
                $selCount = $this.Selected.Count
                $selPreview = if ($selCount -gt 0) { ($this.Selected | Sort-Object) -join ' ' } else { "None" }
                Write-Host "  Selected ($selCount): " -NoNewline -ForegroundColor Cyan
                Write-Host "$selPreview" -ForegroundColor Green
                if (-not [string]::IsNullOrWhiteSpace($this.SearchQuery)) {
                    Write-Host "  Search Filter: `"$($this.SearchQuery)`" (press / to change, Esc to clear)" -ForegroundColor Magenta
                }
                Write-Host "  [Space] Toggle | [/] Search | [Tab/1-6] Tabs | [p] Preset | [Enter] Install | [q] Exit" -ForegroundColor Gray

                $keyInfo = [Console]::ReadKey($true)

                switch ($keyInfo.Key) {
                    ([ConsoleKey]::UpArrow)   { $this.Cursor = [Math]::Max(0, $this.Cursor - 1) }
                    ([ConsoleKey]::DownArrow) { $this.Cursor = [Math]::Min($total - 1, $this.Cursor + 1) }
                    ([ConsoleKey]::K)         { $this.Cursor = [Math]::Max(0, $this.Cursor - 1) }
                    ([ConsoleKey]::J)         { $this.Cursor = [Math]::Min($total - 1, $this.Cursor + 1) }
                    ([ConsoleKey]::Spacebar) {
                        if ($total -gt 0) {
                            $id = $visible[$this.Cursor].Id
                            if ($this.Selected.Contains($id)) { [void]$this.Selected.Remove($id) }
                            else { [void]$this.Selected.Add($id) }
                        }
                    }
                    ([ConsoleKey]::Tab) {
                        $this.ActiveTab = if ($this.ActiveTab -ge 6) { 1 } else { $this.ActiveTab + 1 }
                        $this.SearchQuery = ""
                        $this.Cursor = 0
                    }
                    ([ConsoleKey]::D1) { $this.ActiveTab = 1; $this.SearchQuery = ""; $this.Cursor = 0 }
                    ([ConsoleKey]::D2) { $this.ActiveTab = 2; $this.SearchQuery = ""; $this.Cursor = 0 }
                    ([ConsoleKey]::D3) { $this.ActiveTab = 3; $this.SearchQuery = ""; $this.Cursor = 0 }
                    ([ConsoleKey]::D4) { $this.ActiveTab = 4; $this.SearchQuery = ""; $this.Cursor = 0 }
                    ([ConsoleKey]::D5) { $this.ActiveTab = 5; $this.SearchQuery = ""; $this.Cursor = 0 }
                    ([ConsoleKey]::D6) { $this.ActiveTab = 6; $this.SearchQuery = ""; $this.Cursor = 0 }
                    ([ConsoleKey]::A) {
                        foreach ($it in $visible) { [void]$this.Selected.Add($it.Id) }
                    }
                    ([ConsoleKey]::N) {
                        $this.Selected.Clear()
                    }
                    ([ConsoleKey]::P) {
                        $keys = @($this.Presets.Keys)
                        if ($keys.Count -gt 0) {
                            $pName = $keys[$this.PresetIndex % $keys.Count]
                            $this.PresetIndex++
                            $this.Selected.Clear()
                            foreach ($pApp in $this.Presets[$pName]) { [void]$this.Selected.Add($pApp) }
                        }
                    }
                    ([ConsoleKey]::OemQuestion) {
                        [Console]::CursorVisible = $true
                        $this.SearchQuery = $this.ReadSearchInput()
                        [Console]::CursorVisible = $false
                        $this.Cursor = 0
                    }
                    ([ConsoleKey]::Escape) {
                        if (-not [string]::IsNullOrWhiteSpace($this.SearchQuery)) {
                            $this.SearchQuery = ""
                            $this.Cursor = 0
                        } else {
                            return @()
                        }
                    }
                    ([ConsoleKey]::Enter) {
                        return $this.Selected.ToArray()
                    }
                    ([ConsoleKey]::Q) {
                        return @()
                    }
                }
            }
        }
        finally {
            [Console]::CursorVisible = $true
        }
    }
}
