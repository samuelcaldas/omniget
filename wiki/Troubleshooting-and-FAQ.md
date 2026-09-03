# Troubleshooting & FAQ

This document addresses common questions, troubleshooting scenarios, and error recovery procedures for OmniGet (`og`).

---

## ❓ Frequently Asked Questions (FAQ)

### How is OmniGet different from Winget, Chocolatey, or Scoop?
- **Winget & Chocolatey** rely on centralized community repositories that frequently break, run bloated background services, or trigger intrusive UAC prompts.
- **Scoop** focuses on portable user-space command-line utilities but cannot easily manage system-wide runtimes, drivers, or desktop shells.
- **OmniGet** is an ultra-lightweight, multi-source engine designed for both desktop power users and headless Windows Server Core instances. It leverages **Ninite's multi-app bundling**, **GitHub Releases**, **direct vendor packages**, and **PowerShell system recipes** with zero background daemons and zero telemetry.

### Does OmniGet require Administrator privileges?
- **For viewing and searching**: No. Any user can run `og`, browse the catalog, and search for packages.
- **For system-wide installations**: Yes. Software installed into `C:\Program Files` or modifying Machine `PATH` requires an elevated administrative token (`Run as Administrator` or elevated OpenSSH session).

### Can OmniGet be used offline?
Yes! OmniGet supports offline air-gapped environments:
- The base engine can be packaged as `packages/omniget.zip` and deployed offline via `Install-OmniGet.ps1 -DeployOnly`.
- Packages with cached local installer files can be installed without internet connectivity.

---

## 🔧 Troubleshooting Guide

### 1. `'og' is not recognized as an internal or external command`

**Cause**: The current command prompt or PowerShell session has not refreshed its environment variables since OmniGet was deployed.

**Solution**:
1. Run the environment refresh command in your active shell:
   ```powershell
   $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
   ```
2. Or invoke the deploy subcommand explicitly:
   ```powershell
   & "C:\Program Files\OmniGet\src\OmniGet.ps1" deploy
   ```

---

### 2. `File cannot be loaded because running scripts is disabled on this system`

**Cause**: Windows PowerShell default execution policy is set to `Restricted`.

**Solution**:
Enable unrestricted or remote-signed script execution for the local machine:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
```

---

### 3. `Parameter cannot be processed because the parameter name 's' is ambiguous`

**Cause**: In older PowerShell scripts, passing `-s` caused ambiguity between `-Search` and `-Silent`.

**Solution**:
OmniGet 1.0.0+ resolves this by implementing explicit parameter aliases:
```powershell
# Both forms work identically:
og install git -s
og install git --silent
```
Ensure your OmniGet installation is updated via `og update`.

---

### 4. `npm command not found. Please install Node.js first.`

**Cause**: An attempt was made to install an NPM package (such as `claude-code`) before Node.js and npm were available in the system PATH.

**Solution**:
Install Node.js first via OmniGet:
```powershell
og install nodejs -s
```
Close and reopen your terminal to register `npm`, then retry the package installation.

---

### 5. `Access to the path '...' is denied` during installation

**Cause**: The installer was executed from a non-elevated command prompt, or another process is holding an exclusive handle to an external resource.

**Solution**:
1. Open PowerShell 7 with elevated privileges (`Run as Administrator`).
2. If connecting via SSH, ensure your user account belongs to the local `Administrators` group.
3. If upgrading PowerShell 7 itself, OmniGet's zero-downtime hot-swap engine handles in-use files automatically.

---

### 6. `Ninite installer download failed or returned invalid response`

**Cause**: The machine cannot reach `ninite.com`, or network DNS is blocking access.

**Solution**:
1. Test connectivity to Ninite:
   ```powershell
   curl.exe -I https://ninite.com
   ```
2. Verify that your DNS settings are properly configured. If using a hosts blocklist, ensure `ninite.com` is not blocked.
