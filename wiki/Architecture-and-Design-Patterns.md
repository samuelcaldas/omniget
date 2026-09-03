# OmniGet Architecture & Design Patterns

OmniGet is engineered in pure PowerShell 7 following strict software engineering practices: **SOLID Principles**, **Object Calisthenics**, and the **Strategy and Factory Design Patterns**.

---

## 🏛️ High-Level Architectural Diagram

```mermaid
flowchart TD
    subgraph UI_Layer [User Interface & Entrypoints]
        CLI["OmniGet.ps1 (CLI Entrypoint / Subcommands)"]
        CMD["bin/og.cmd & bin/omniget.cmd (Path Launchers)"]
        TUI["TuiApp.ps1 (Interactive ANSI Curses Engine)"]
        SearchEngine["SearchEngine.ps1 (Fuzzy/Token Filter)"]
    end

    subgraph Core_Layer [Core Engine & Catalogs]
        ManifestReader["ManifestReader.ps1 (JSON Loader)"]
        Manifests["manifests/*.json (Declarative Catalogs)"]
        Engine["Engine.ps1 (Provider Factory & Orchestrator)"]
        Environment["Environment.ps1 (PATH & Shortcuts)"]
    end

    subgraph Provider_Layer [Providers (Strategy Pattern)]
        BaseProvider["BaseProvider.ps1 (Abstract Contract)"]
        Ninite["NiniteProvider.ps1"]
        GitHub["GitHubReleaseProvider.ps1"]
        Direct["DirectProvider.ps1"]
        Distro["DistroRecipeProvider.ps1"]
        Npm["NpmProvider.ps1"]
    end

    CMD --> CLI
    CLI --> ManifestReader
    CLI --> TUI
    TUI --> SearchEngine
    TUI --> Engine
    CLI --> Engine

    ManifestReader --> Manifests
    Engine --> BaseProvider

    BaseProvider <|-- Ninite
    BaseProvider <|-- GitHub
    BaseProvider <|-- Direct
    BaseProvider <|-- Distro
    BaseProvider <|-- Npm
```

---

## 🎯 Design Patterns Applied

### 1. Strategy Pattern (Pluggable Providers)
OmniGet needs to support vastly different installation mechanisms: dynamic multi-app web bundles (Ninite), GitHub release assets, silent MSI/EXE installers, PowerShell system configuration scripts, and Node.js global packages.

Rather than implementing sprawling `if/else` statements across the codebase, OmniGet defines the abstract `BaseProvider` contract:

```powershell
class BaseProvider {
    [string]$Name
    [string]$DisplayName
    [string]$Description

    [bool] CanHandle([PSCustomObject]$Package) { ... }
    [void] InstallSingle([PSCustomObject]$Package, [bool]$Silent) { ... }
    [void] InstallBatch([PSCustomObject[]]$Packages, [bool]$Silent) { ... }
}
```

Each source implements its own concrete strategy (`NiniteProvider`, `GitHubReleaseProvider`, `DirectProvider`, `DistroRecipeProvider`, `NpmProvider`). The core batch orchestrator simply invokes `$provider.InstallBatch($packages, $SilentMode)`.

---

### 2. Factory Pattern (Dynamic Provider Instantiation)
In [`src/Core/Engine.ps1`](file:///home/samuelcaldas/repos/windows-core/external/omniget/src/Core/Engine.ps1), the `Get-OmniProvider` factory resolves and returns provider singletons by their source identifier:

```powershell
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
```

---

## 📐 SOLID Principles Adherence

| Principle | Implementation in OmniGet |
| :--- | :--- |
| **Single Responsibility** | `ManifestReader` only parses JSON. `SearchEngine` only filters text. `TuiApp` only manages curses rendering. Providers only execute installations. |
| **Open / Closed** | Adding a new package source (e.g. Winget, Scoop, or Chocolatey) requires writing one new provider class extending `BaseProvider` without modifying existing providers or the TUI. |
| **Liskov Substitution** | Any provider can be substituted for `BaseProvider` in batch processing loops without breaking caller expectations. |
| **Interface Segregation** | The `BaseProvider` contract is minimal and focused, providing only `CanHandle`, `InstallSingle`, `InstallBatch`, `IsInstalled`, and `GetInstalledVersion`. |
| **Dependency Inversion** | Higher-level orchestration routines depend on the abstract provider contract, never on concrete implementation details. |

---

## 🧼 Clean Code & Object Calisthenics

OmniGet enforces strict code quality rules:
1. **One Indent Level per Method**: Nested control structures are extracted into helper methods.
2. **No Else Keywords**: Uses guard clauses and early returns (`return`, `throw`).
3. **Fail Fast**: Input parameters and prerequisites (such as network connectivity or `npm.cmd` availability) are validated immediately at function entrypoints.
4. **Clean Resource Management**: All transient downloads, staging directories, and temporary installers are guaranteed to be cleaned up in `finally` blocks.
5. **No Root `C:\` Application Directories**: In strict compliance with Windows standards, all installed utilities and runtimes reside under `C:\Program Files\<Vendor>` or `C:\ProgramData\<App>`, never in dirty root folders like `C:\Tools` or `C:\ReactShell`.
