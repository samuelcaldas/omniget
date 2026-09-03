# Manifest Authoring Guide

OmniGet uses a completely declarative, modular **JSON Manifest Catalog** system. Adding new software, packages, or custom enterprise recipes does not require modifying the core PowerShell engine—you simply add or edit JSON manifests in the [`manifests/`](file:///home/samuelcaldas/repos/windows-core/external/omniget/manifests/) directory.

---

## 📁 Manifest Directory Layout

```
manifests/
├── github.json     # Packages sourced directly from GitHub Releases
├── direct.json     # Official vendor direct downloads (MSI / EXE / ZIP)
├── distro.json     # Distro recipes, system configurations, and desktop shells
├── ninite.json     # 140+ curated desktop applications powered by Ninite
└── presets.json    # Curated toolchain bundles
```

---

## 📋 Package Schema & Field Reference

Each manifest file contains a JSON array of package objects. The table below lists all supported fields:

| Field Name | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| **`id`** | `string` | **Yes** | Unique identifier used for CLI commands (`og install <id>`). Must be lowercase alphanumeric with hyphens. |
| **`name`** | `string` | **Yes** | Human-readable application title shown in the TUI. |
| **`category`** | `string` | **Yes** | Category tab grouping (e.g. `Developer Tools`, `Web Browsers`, `Media`, `Shells & UI`, `Security & Network`). |
| **`source`** | `string` | **Yes** | Provider identifier: `github`, `direct`, `distro`, `ninite`, or `npm`. |
| **`desc`** | `string` | **Yes** | Concise summary of the application displayed in search results and the TUI. |
| **`featured`** | `bool` | No | If `true`, the package appears in the primary **1:Featured** home tab of the TUI. |
| **`version`** | `string` | No | Software version string. |
| **`url`** | `string` | Conditional | Download URL (required for `direct` and direct-link `github` packages). |
| **`repo`** | `string` | Conditional | GitHub repository in `owner/repo` format (for `github` provider). |
| **`format`** | `string` | No | Archive/installer format: `msi`, `exe`, or `zip`. |
| **`silentArgs`** | `string` | No | Custom command-line arguments for silent/unattended installation. |
| **`installPath`** | `string` | No | Target extraction folder for `.zip` packages (defaults to `C:\Program Files\<name>`). |
| **`recipe`** | `string` | Conditional | Name of the PowerShell script block in `DistroRecipeProvider` (required for `distro` source). |
| **`packageName`**| `string` | Conditional | Package name on registry (required for `npm` source). |
| **`checkCommand`**| `string` | No | PowerShell command to check if software is already installed (exit code 0 = installed). |
| **`versionCommand`**| `string`| No | PowerShell command to extract the current installed version string. |

---

## 🛠️ Step-by-Step Examples by Provider

### Example 1: GitHub Release Package (`manifests/github.json`)

To add an application distributed via GitHub Releases:

```json
{
  "id": "ripgrep",
  "name": "Ripgrep (rg)",
  "category": "Developer Tools",
  "source": "github",
  "version": "14.1.0",
  "repo": "BurntSushi/ripgrep",
  "url": "https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-pc-windows-msvc.zip",
  "format": "zip",
  "installPath": "C:\\Program Files\\ripgrep",
  "desc": "Ultra-fast line-oriented search tool and grep replacement",
  "featured": true
}
```

---

### Example 2: Official Direct Installer (`manifests/direct.json`)

To add a vendor installer (e.g. InnoSetup or standard MSI) from an official CDN:

```json
{
  "id": "gitkraken",
  "name": "GitKraken Client",
  "category": "Developer Tools",
  "source": "direct",
  "version": "10.0.0",
  "url": "https://release.gitkraken.com/win64/GitKrakenSetup.exe",
  "format": "exe",
  "silentArgs": "--silent",
  "desc": "Intuitive Git GUI client with merge conflict resolution",
  "featured": false
}
```

---

### Example 3: Distro System Recipe (`manifests/distro.json`)

For complex tasks requiring system configuration or custom PowerShell logic:

1. Add the package entry to `manifests/distro.json`:
```json
{
  "id": "virtio-drivers",
  "name": "VirtIO Windows Guest Drivers",
  "category": "Drivers & Hypervisor",
  "source": "distro",
  "desc": "Red Hat KVM/QEMU VirtIO network, balloon, and storage drivers",
  "recipe": "Install-VirtIoDrivers",
  "featured": true
}
```

2. Implement the recipe in [`src/Providers/DistroRecipeProvider.ps1`](file:///home/samuelcaldas/repos/windows-core/external/omniget/src/Providers/DistroRecipeProvider.ps1):
```powershell
"Install-VirtIoDrivers" {
    Write-Host "[Distro] Installing VirtIO Guest Tools..." -ForegroundColor Cyan
    & pnputil /add-driver "D:\*.inf" /subdirs /install | Out-Null
    Write-Host "[Distro] VirtIO drivers installed." -ForegroundColor Green
}
```

---

### Example 4: Global NPM Tool (`manifests/distro.json` or custom manifest)

```json
{
  "id": "claude-code",
  "name": "Claude Code CLI",
  "category": "AI Agents & Remoting",
  "source": "npm",
  "packageName": "@anthropic-ai/claude-code",
  "desc": "Anthropic Claude Code agentic CLI assistant",
  "featured": true
}
```

---

## 🛡️ Best Practices for Authors

1. **Strict Path Compliance**: Never set `installPath` to the root drive (`C:\<tool>`). Always use `C:\Program Files\<VendorOrTool>` for 64-bit applications.
2. **Unattended First**: Always verify that `silentArgs` prevents any interactive GUI dialogs, reboot prompts, or popups.
3. **No Telemetry / No Adware**: Never add installers bundled with adware or bundled third-party trialware.
4. **Idempotency**: Ensure that running an installer multiple times does not corrupt settings or duplicate PATH entries.
