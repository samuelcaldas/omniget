# OmniGet (`og`) — Universal Multi-Source Package Engine for Windows

[![PowerShell 7](https://img.shields.io/badge/PowerShell-7%2B-blue.svg?logo=powershell)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20%7C%20Server%20%7C%20Core-0078D6?logo=windows)](https://microsoft.com/windows)

**OmniGet** (`og`) is an ultra-fast, multi-source package manager and interactive terminal store for Windows. It seamlessly aggregates and automates software installations across **Ninite**, **GitHub Releases**, **Official Direct Packages**, **Distro Recipes**, and **Global Runtimes** with zero bloatware and zero telemetry.

---

## ⚡ Highlights

- **Multi-Source Aggregation**: Install software across multiple ecosystems using a single command:
  - 🌐 **Ninite Engine**: Generates dynamic multi-app bundles on-the-fly from 142+ curated applications.
  - 🐙 **GitHub Releases**: Fetches and installs latest releases for modern developer tools (PowerShell, GitHub CLI, WezTerm, etc.).
  - 📦 **Direct Official Installers**: Silently executes official MSI, EXE, and ZIP installers (.NET SDK, Node.js, Python, Docker CLI).
  - 🛠️ **Distro System Recipes**: Installs desktop shells (WinXShell, ReactShell, WinFile, Explorer++), VirtIO drivers, and zero-route DNS hosts blocklists.
- **Modern ANSI Curses TUI**: Interactive Terminal User Interface for PowerShell 7 with live incremental search (`/`), category tabs, provider badges, preset selector, and batch execution.
- **Universal & Lightweight**: Works natively on **Windows 10, Windows 11, Windows Server, and Windows Server Core** (including headless and WinPE environments).
- **Fast CLI & Automation**: Support for presets (`og preset DevStack -Silent`), search, and non-interactive batch deployment.

---

## 🚀 Quick Start & Installation

### One-Liner Install (PowerShell 7+)
```powershell
irm https://raw.githubusercontent.com/samuelcaldas/omniget/main/install.ps1 | iex
```

### Manual / Git Submodule Clone
```powershell
git clone https://github.com/samuelcaldas/omniget.git "C:\Program Files\OmniGet"
& "C:\Program Files\OmniGet\src\OmniGet.ps1" -Deploy
```

---

## 🎮 Interactive TUI Store

Simply run `og` or `omniget` in your terminal to launch the interactive experience:

```powershell
og
```

```text
+====================================================================================+
|  OMNIGET v1.0.0 — Universal Package Engine           [Tabs: 1-Home 2-All 3-Ninite] |
+====================================================================================+
|  Search: [/] filter...                       Selected: 3 packages (Ninite:2, Direct:1)|
+------------------------------------------------------------------------------------+
|  > [x] vscode         [Ninite]   Visual Studio Code (Microsoft)                    |
|    [ ] cursor         [Ninite]   AI Code Editor (Anysphere)                        |
|    [x] docker-cli     [Distro]   Standalone Docker CLI & Compose v27.5             |
|    [x] git            [GitHub]   Git for Windows (Distributed VCS)                 |
|    [ ] winxshell      [Distro]   WinXShell Light Win32 Shell & Start Menu          |
+------------------------------------------------------------------------------------+
| [Space] Toggle | [Tab] Switch Source | [p] Presets | [Enter] Install | [q] Exit    |
+====================================================================================+
```

---

## 🛠️ CLI Usage Examples

```powershell
# Search for packages across all sources
og search python

# Install specific packages silently
og install vscode git nodejs docker-cli -Silent

# Run predefined curated presets
og preset DevStack -Silent
og preset Browsers
og preset SystemShells

# List available packages by provider
og list --source ninite
og list --source distro
og list --source all
```

---

## 📂 Architecture & Providers

OmniGet implements the **Strategy and Factory Design Patterns** in PowerShell 7:

```
src/
├── OmniGet.psm1               # Core PowerShell Module entrypoint
├── OmniGet.ps1                # Self-contained CLI launcher
├── Core/
│   ├── Engine.ps1             # Provider resolution & batch dependency orchestrator
│   ├── Downloader.ps1         # Fast curl.exe / WebClient downloader
│   └── Environment.ps1        # Machine PATH & desktop shortcut manager
├── Providers/
│   ├── BaseProvider.ps1       # IProvider abstract contract
│   ├── NiniteProvider.ps1     # 142-app dynamic bundle builder
│   ├── GitHubReleaseProvider.ps1 # GitHub Release asset resolution & extraction
│   ├── DirectProvider.ps1     # Official MSI/InnoSetup silent executor
│   ├── DistroRecipeProvider.ps1 # Shells, drivers, hosts, and system recipes
│   └── NpmProvider.ps1        # Global npm runner (@anthropic-ai/claude-code)
└── UI/
    ├── TuiApp.ps1             # Main ANSI multi-panel interactive loop
    └── SearchEngine.ps1       # Fuzzy filter engine across all fields
```

---

## 📄 License

Distributed under the **MIT License**. Created by [Samuel Caldas](https://github.com/samuelcaldas).
