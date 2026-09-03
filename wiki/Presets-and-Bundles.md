# OmniGet Presets & Bundles

Presets in OmniGet represent **curated, declarative software stacks** that allow administrators and developers to set up a complete workstation, server, or container environment with a single command.

---

## 📦 Built-In Presets Reference

All presets are declaratively defined in [`manifests/presets.json`](file:///home/samuelcaldas/repos/windows-core/external/omniget/manifests/presets.json):

```json
{
  "DevStack": [
    "vscode", "git", "nodejs", "python", "docker-cli",
    "pwsh", "gh", "gitea-cli", "7zip", "putty", "winscp", "terminal"
  ],
  "Browsers": [
    "chrome", "firefox", "edge", "brave"
  ],
  "Minimal": [
    "7zip", "notepadplusplus", "chrome"
  ],
  "Utilities": [
    "7zip", "windirstat", "wiztree", "everything", "teracopy", "ccleaner"
  ],
  "SystemShells": [
    "winxshell", "winfile", "terminal", "hosts-adblock"
  ],
  "Media": [
    "vlc", "foobar", "audacity", "greenshot", "spotify"
  ]
}
```

---

## 🛠️ Detailed Breakdown of Each Preset

### 1. `DevStack` (Complete Developer Workstation)
Designed for software engineers, systems programmers, and DevOps administrators.

- **`vscode`**: Visual Studio Code editor by Microsoft.
- **`git`**: Git for Windows with LongPaths and LF line endings enabled.
- **`nodejs`**: Node.js LTS with npm package manager.
- **`python`**: Python 3.12 with pip package manager.
- **`docker-cli`**: Standalone Docker CLI & Docker Compose (connects to remote daemon contexts without Docker Desktop).
- **`pwsh`**: PowerShell 7 modern automation shell.
- **`gh`**: Official GitHub command-line client.
- **`gitea-cli`**: Official Gitea CLI (`tea`) for self-hosted git instances.
- **`7zip`**: High-performance archive utility.
- **`putty`**: SSH and Telnet terminal client.
- **`winscp`**: SFTP and SCP graphical file transfer tool.
- **`terminal`**: WezTerm multi-tab terminal emulator with OpenGL software rendering.

#### Run Command:
```powershell
og preset DevStack -s
```

---

### 2. `Browsers` (Multi-Engine Web Browser Suite)
Installs all leading web browsers for cross-browser testing and development.

- **`chrome`**: Google Chrome (Blink / V8).
- **`firefox`**: Mozilla Firefox (Gecko / SpiderMonkey).
- **`edge`**: Microsoft Edge (Blink / V8).
- **`brave`**: Brave Privacy Browser (Blink with built-in ad/tracker shields).

#### Run Command:
```powershell
og preset Browsers -s
```

---

### 3. `Minimal` (Lean Base Workstation)
The bare essentials for any newly provisioned Windows machine:

- **`7zip`**: Fast compression & extraction.
- **`notepadplusplus`**: Tabbed source code and text editor.
- **`chrome`**: Google Chrome browser.

#### Run Command:
```powershell
og preset Minimal -s
```

---

### 4. `Utilities` (System Maintenance & Diagnostic Tools)
A suite of diagnostic tools for IT support, disk space analysis, and file operations:

- **`7zip`**: File compression manager.
- **`windirstat`**: Visual disk usage treemap visualizer.
- **`wiztree`**: Ultra-fast MFT-based disk space analyzer.
- **`everything`**: Instant filename search engine.
- **`teracopy`**: High-speed file copy and transfer utility.
- **`ccleaner`**: System cleaner and registry maintenance tool.

#### Run Command:
```powershell
og preset Utilities -s
```

---

### 5. `SystemShells` (Windows Server Core Desktop Suite)
Transforms a headless or stripped-down Windows Server Core system into an operational desktop environment:

- **`winxshell`**: Ultra-lightweight Win32 desktop shell, start menu, and taskbar.
- **`winfile`**: Microsoft Windows File Manager.
- **`terminal`**: Hardware/software accelerated terminal emulator.
- **`hosts-adblock`**: Dan Pollock's zero-route DNS blocklist (13,000+ ad, telemetry, and tracking domains blocked).

#### Run Command:
```powershell
og preset SystemShells -s
```

---

### 6. `Media` (Audio, Video & Media Processing)
A curated collection of media players and creators:

- **`vlc`**: The universal media player.
- **`foobar`**: Lightweight customizable audio player.
- **`audacity`**: Multi-track audio recorder and editor.
- **`greenshot`**: Screenshot and annotation tool.
- **`spotify`**: Music streaming service.

#### Run Command:
```powershell
og preset Media -s
```

---

## 🎨 Creating Custom Presets

You can easily define your own organizational or project-specific presets:

1. Open [`manifests/presets.json`](file:///home/samuelcaldas/repos/windows-core/external/omniget/manifests/presets.json).
2. Add a new key with an array of valid package IDs:

```json
{
  "DataScience": [
    "python",
    "vscode",
    "git",
    "7zip"
  ]
}
```

3. Your new preset is immediately available via the CLI and the visual TUI store:

```powershell
og preset DataScience -s
```

In the TUI, pressing **`p`** will now cycle through your newly defined preset as well.
