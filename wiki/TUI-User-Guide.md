# OmniGet TUI User Guide

OmniGet features an ultra-responsive, full-featured **ANSI Terminal User Interface (TUI)** built with pure PowerShell 7. It provides an intuitive visual software store right inside your console, complete with instant keyboard navigation, live search, tabs, and multi-provider batch selection.

---

## 🎮 Launching the Store

To launch the interactive TUI, run `og` or `omniget` with no arguments:

```powershell
og
```

---

## 🖥️ Screen Layout & Components

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
    [ ] [Distro]   docker-cli           - Standalone native Docker and Compose CLI client for remote daemon contexts

  :: Web Browsers
    [ ] [Ninite]   chrome               - Fast Browser by Google
    [ ] [Ninite]   firefox              - Extensible Browser
    [ ] [Ninite]   brave                - Privacy Browser

--------------------------------------------------------------------------------
  Focused: Git for Windows (git) | Source: GITHUB
  Selected (0): None
  [Space] Toggle | [/] Search | [Tab/1-6] Tabs | [p] Preset | [Enter] Install | [q] Exit
```

### 1. Top Header & Tab Navigation Bar
Displays the active category tab. Pressing `Tab` or number keys `1` through `6` instantly filters the package view.

### 2. Package List View
- **Cursor Pointer (`>`)**: Highlighted in cyan; tracks your current position.
- **Checkbox (`[ ]` / `[x]`)**: Displays whether a package is queued for installation (turns green when checked).
- **Source Badges**:
  - `[Ninite]`: Ninite bundle engine.
  - `[GitHub]`: GitHub Releases asset provider.
  - `[Direct]`: Vendor MSI/EXE installer.
  - `[Distro]`: System recipes and shell scripts.
  - `[NPM]`: Global Node.js package.
- **Category Dividers (`:: Developer Tools`)**: Organizes items cleanly by category.

### 3. Focused Package Details
Displays detailed metadata for the package currently under the cursor, including its full official name, unique ID, and upstream provider.

### 4. Selection Counter & Dynamic Preview Bar
Shows the exact count and list of selected package IDs in real-time.

---

## ⌨️ Complete Keybindings Reference

| Key / Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`↓`** / **`j`** | **Move Down** | Moves cursor down by one item (supports Vim navigation). |
| **`↑`** / **`k`** | **Move Up** | Moves cursor up by one item (supports Vim navigation). |
| **`Space`** | **Toggle Selection** | Selects or deselects the highlighted package (`[x]`). |
| **`Tab`** | **Next Tab** | Cycles forward through category tabs. |
| **`1` – `6`** | **Direct Tab Switch** | Jump directly to tab: 1 (Featured), 2 (All), 3 (Ninite), 4 (DevTools), 5 (Shells&UI), 6 (Media&Utils). |
| **`/`** / **`?`** / **`f`** | **Search Filter** | Opens real-time prompt to filter by keyword across all fields. |
| **`Esc`** | **Clear Search / Back** | Clears the active search filter, or exits if no filter is active. |
| **`p`** | **Cycle Presets** | Iterates through curated presets (`DevStack`, `Browsers`, `Minimal`, `Utilities`, etc.) and pre-selects all corresponding packages. |
| **`a`** | **Select All** | Selects all packages currently visible on the screen. |
| **`n`** | **Deselect All** | Clears the current package selection entirely. |
| **`Enter`** | **Execute Batch** | Confirms selection and initiates sequential multi-provider installation. |
| **`q`** | **Quit / Cancel** | Exits the TUI without installing any packages. |

---

## 🔍 Interactive Search Tips

Press `/` or `f` at any time while browsing the catalog:

```text
  Search across all sources: python
```

- **Multi-Word Filtering**: Type `code editor` to match items containing both words in their ID, title, or description.
- **Source Filtering**: Type `github` to only show packages hosted on GitHub Releases.
- **Immediate Navigation**: Press `Enter` to apply the filter. Navigation arrows and `Space` will immediately operate on the filtered subset.
- **Reset**: Press `Esc` to instantly clear the filter and restore the full catalog view.

---

## ⚡ Batch Execution Flow

Once you press **`Enter`**, OmniGet transitions into **Batch Execution Mode**:

```text
==============================================================================
  OMNIGET BATCH EXECUTION (3 packages)
==============================================================================

>>> Running Provider: Ninite (2 packages)...
[Ninite] Preparing dynamic bundle for (2 apps): chrome, 7zip
[Ninite] Executing silent installation...
[Ninite] Bundle installation completed successfully.

>>> Running Provider: GitHub (1 packages)...
[GitHub] Installing Git for Windows from git-for-windows/git...
[GitHub] Installed Git for Windows successfully.

[SUCCESS] OmniGet batch installation completed.
```

- Ninite applications are grouped into a **single, unified download** to eliminate redundant installer overhead.
- Direct and GitHub packages are executed with verified silent flags.
- Distro recipes are invoked in sequence.
- All temporary installers and staging archives are cleaned up automatically upon exit.
