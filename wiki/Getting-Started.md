# Getting Started with OmniGet

This guide walks you through system requirements, installation methods, system environment deployment, and your very first steps with OmniGet (`og`).

---

## 💻 System Requirements

OmniGet is designed to be lightweight, portable, and cross-edition compatible:

| Requirement | Minimum Specification | Recommended |
| :--- | :--- | :--- |
| **Operating System** | Windows 10 (1809+) or Windows Server 2019+ | Windows 11 / Windows Server Core 2022+ |
| **PowerShell Runtime** | PowerShell 7.0+ (`pwsh.exe`) | PowerShell 7.4+ or 7.6+ |
| **Privileges** | Standard user (for user tools) / Administrator (for system tools) | Elevated Administrator (`Run as Administrator`) |
| **Network Tools** | `curl.exe` (built-in on Windows 10+) or .NET WebClient | Built-in `curl.exe` |
| **Terminal** | ConHost, Windows Terminal, or WezTerm | Windows Terminal or WezTerm (ANSI color support) |

> [!NOTE]
> While OmniGet's interactive ANSI TUI requires PowerShell 7+ for curses escape sequences, the underlying batch engine and helper scripts include automatic fallbacks to Windows PowerShell 5.1 when run in minimal recovery or boot environments.

---

## 🚀 Installation Methods

### Method 1: Web One-Liner (Recommended for Workstations)

Open PowerShell 7 as Administrator and execute:

```powershell
irm https://raw.githubusercontent.com/samuelcaldas/omniget/main/install.ps1 | iex
```

#### What this one-liner does:
1. Validates the execution environment and PowerShell version.
2. Clones or extracts the latest OmniGet repository into `C:\Program Files\OmniGet`.
3. Registers `C:\Program Files\OmniGet\bin` in the **Machine `PATH`** environment variable.
4. Generates an `OmniGet Store.lnk` shortcut on the Public Desktop (`C:\Users\Public\Desktop`).
5. Makes the `og` and `omniget` CLI commands available immediately across all current and future command shells.

---

### Method 2: Manual Clone & System Registration

If you prefer full control over repository locations and git submodules:

```powershell
# 1. Clone to standard 64-bit application path
git clone https://github.com/samuelcaldas/omniget.git "C:\Program Files\OmniGet"

# 2. Deploy environment shortcuts and Machine PATH
& "C:\Program Files\OmniGet\src\OmniGet.ps1" deploy
```

---

### Method 3: Unattended Setup & ISO Packaging (Windows Server Core)

For enterprise automation, headless servers, and customized Windows ISO builds:

1. **Packaging Offline Media**:
   Compress the `external/omniget` directory into `packages/omniget.zip` on your installation media (e.g. secondary OEMDRV drive or installer ISO):
   ```bash
   cd external/omniget && zip -rq /path/to/oemdrv/packages/omniget.zip .
   ```

2. **Unattended Execution (`autounattend.xml` or `Specialize.ps1`)**:
   During FirstLogon or system specialization, run `Install-OmniGet.ps1 -DeployOnly`:
   ```powershell
   # Automatically discovers offline packages\omniget.zip from any drive letter
   & "C:\Provisioning\scripts\Install-OmniGet.ps1" -DeployOnly
   ```

3. **Machine PATH Out-of-the-Box**:
   OmniGet will automatically be registered in `%PATH%`, allowing immediate headless orchestration over OpenSSH or WinRM on first boot.

---

## 🔍 Verifying the Installation

After installation, open a new command prompt, PowerShell window, or SSH session:

```powershell
# Verify version
og version
# Output: OmniGet (og) version 1.0.0

# Verify help and syntax
og help
```

If `og` is not recognized, refresh your active shell's environment path without restarting your terminal:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
```

---

## 🎮 First Steps: Running the TUI Store

Simply type `og` and press `Enter`:

```powershell
og
```

```text
================================================================================
  OMNIGET (og) — Universal Multi-Source Package Engine for Windows             
================================================================================
  Tabs:  [1:Featured]   2:All   3:Ninite   4:DevTools   5:Shells&UI   6:Media&Utils  
--------------------------------------------------------------------------------

  :: Developer Tools
  > [ ] [GitHub]   git                  - Distributed version control system configured with long paths and LF line endings
    [ ] [GitHub]   gh                   - Official command line tool for GitHub repos, issues, PRs, and workflows
    [ ] [GitHub]   pwsh                 - Modern cross-platform automation and scripting shell engine
    [ ] [Direct]   nodejs               - JavaScript runtime built on Chrome's V8 engine with npm package manager
    [ ] [Direct]   python               - Official Python programming language runtime with pip package manager

--------------------------------------------------------------------------------
  Focused: Git for Windows (git) | Source: GITHUB
  Selected (0): None
  [Space] Toggle | [/] Search | [Tab/1-6] Tabs | [p] Preset | [Enter] Install | [q] Exit
```

- Use **Up/Down** or **Vim keys (`j`/`k`)** to navigate.
- Press **Space** to toggle packages you want to install.
- Press **Enter** to batch install your selection.
- Press **q** to exit.

---

## 🔄 Updating OmniGet

OmniGet can self-update its manifests, providers, and UI directly from the upstream GitHub repository:

```powershell
og update
```

This fetches the latest release archive, updates `manifests/`, `src/`, and `bin/`, while preserving any local configurations or custom presets.

---

## 📖 Next Steps

- Explore the **[CLI Reference](CLI-Reference)** for scripting, unattended automation, and advanced flags.
- Learn keyboard shortcuts in the **[TUI User Guide](TUI-User-Guide)**.
- Read about the **[Zero-Downtime Updates](Zero-Downtime-Updates)** engine.
