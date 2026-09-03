# OmniGet CLI Reference

The OmniGet Command-Line Interface (`og`) provides a modern, fast, and composable terminal experience designed for both interactive shell workflows and automated unattended scripting.

---

## 📜 Syntax & Usage

```powershell
og [COMMAND] [OPTIONS] [ARGUMENTS...]
```

When invoked without commands or arguments, `og` automatically launches the visual **Interactive ANSI TUI Store**.

---

## 📌 Subcommands Reference

### 1. `search` / `find`
Performs an instant fuzzy and incremental search across package IDs, names, descriptions, categories, and provider sources.

```powershell
og search <query>
og find <query>
```

#### Examples:
```powershell
# Search for git-related tools
og search git

# Search for browsers
og search browser

# Search across descriptions (e.g. video editors or players)
og search "video player"
```

#### Output Format:
```text
Search results for 'git' (6 matches):
  • gitea-cli          [DISTRO] - Official command-line client for Gitea git servers (tea)
  • git                [GITHUB] - Distributed version control system configured with long paths and LF line endings
  • gh                 [GITHUB] - Official command line tool for GitHub repos, issues, PRs, and workflows
  • pwsh               [GITHUB] - Modern cross-platform automation and scripting shell engine
  • openssh            [GITHUB] - Official Win32 OpenSSH server and client tools
  • git-ninite         [NINITE] - Version Control System
```

---

### 2. `install` / `add` / `get`
Installs one or more packages by ID. OmniGet intelligently groups packages by provider to optimize download batching and multi-app bundling.

```powershell
og install <package_id> [package_id2...] [flags]
og add <package_id...> [flags]
og get <package_id...> [flags]
```

#### Supported Flags:
- `-s`, `--silent`, `-Silent`: Suppresses interactive dialogs and runs installers silently in non-interactive mode.
- `-y`, `--yes`: Assumes "yes" to all installation confirmations.

#### Examples:
```powershell
# Install a single developer tool
og install git

# Install multiple cross-provider packages silently
og install vscode git nodejs docker-cli 7zip -s

# Install PowerShell 7 with zero-downtime hot-swapping
og install pwsh -s
```

---

### 3. `list` / `ls`
Lists all available packages registered in OmniGet's JSON manifests.

```powershell
og list [source]
og ls [source]
```

#### Available Source Filters:
- `all` (default): Lists all packages across all catalog manifests.
- `ninite`: Lists apps provided by the Ninite dynamic bundle engine (140+ applications).
- `github`: Lists packages installed directly from GitHub Releases.
- `direct`: Lists official direct vendor packages (MSI, EXE, ZIP).
- `distro`: Lists system recipes, customized shells, runtimes, and drivers.
- `npm`: Lists global Node.js CLI packages.

#### Examples:
```powershell
# List all GitHub release packages
og list github

# List all distro system recipes
og list distro

# List all 140+ Ninite catalog items
og list ninite
```

---

### 4. `preset`
Installs a predefined, curated application stack with a single command.

```powershell
og preset <preset_name> [flags]
```

#### Built-in Presets:
| Preset Name | Included Tools & Applications | Target Audience |
| :--- | :--- | :--- |
| **`DevStack`** | `vscode`, `git`, `nodejs`, `python`, `docker-cli`, `pwsh`, `gh`, `gitea-cli`, `7zip`, `putty`, `winscp`, `terminal` | Software developers & DevOps engineers |
| **`Browsers`** | `chrome`, `firefox`, `edge`, `brave` | Multi-browser workstation setup |
| **`Minimal`** | `7zip`, `notepadplusplus`, `chrome` | Lightweight core essentials |
| **`Utilities`** | `7zip`, `windirstat`, `wiztree`, `everything`, `teracopy`, `ccleaner` | System administration & file management |
| **`SystemShells`**| `winxshell`, `winfile`, `terminal`, `hosts-adblock` | Windows Server Core desktop enablement |
| **`Media`** | `vlc`, `foobar`, `audacity`, `greenshot`, `spotify` | Audio, video, and screenshot tools |

#### Examples:
```powershell
# Install complete developer stack silently
og preset DevStack -s

# Deploy Windows Core desktop environment
og preset SystemShells -s
```

---

### 5. `update` / `upgrade`
Updates the OmniGet engine, manifest catalogs, and launcher scripts directly from the official upstream repository.

```powershell
og update
og upgrade
```

#### How it works:
1. Downloads the latest release archive (`main.zip`) from `https://github.com/samuelcaldas/omniget`.
2. Extracts and synchronizes files in `manifests/`, `src/`, and `bin/`.
3. Preserves your custom user presets and configurations.
4. Outputs the newly active OmniGet version.

---

### 6. `deploy`
Configures system environment integration:
- Permanently registers `C:\Program Files\OmniGet\bin` in the **Machine `PATH`**.
- Creates the `OmniGet Store.lnk` desktop shortcut on the Public Desktop.

```powershell
og deploy
```

---

### 7. `version`
Displays the current installed version of OmniGet.

```powershell
og version
og -v
og --version
```

---

### 8. `help`
Displays built-in usage instructions, available subcommands, flags, and practical examples.

```powershell
og help
og -h
og --help
```

---

## 🔄 Backward Compatibility: PowerShell Parameter Switches

In addition to POSIX-style subcommands (`og install <app>`), OmniGet provides 100% backward compatibility with native PowerShell cmdlet parameters:

| Parameter Switch | Equivalent Subcommand | Example |
| :--- | :--- | :--- |
| `-Install <string[]>` | `og install <app...>` | `og -Install git,vscode -Silent` |
| `-Preset <string>` | `og preset <name>` | `og -Preset DevStack -Silent` |
| `-Search <string>` | `og search <query>` | `og -Search python` |
| `-List <string>` | `og list <source>` | `og -List github` |
| `-Silent` | `-s`, `--silent` | `og -Install pwsh -Silent` |
| `-Deploy` | `og deploy` | `og -Deploy` |
| `-Version` | `og version` | `og -Version` |
| `-Help` | `og help` | `og -Help` |

---

## 🤖 Automation & CI/CD Examples

### Automated Windows Server Core Bootstrap
```powershell
# Silent unattended setup script
Write-Host "Configuring developer node..."
og preset DevStack -s
og install hosts-adblock -s
Write-Host "Developer workstation ready."
```

### GitHub Actions / Azure DevOps Agent Setup
```yaml
- name: Setup Developer Stack via OmniGet
  shell: pwsh
  run: |
    og install git gh pwsh nodejs -s
    og version
```
