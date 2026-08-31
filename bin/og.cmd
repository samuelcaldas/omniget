@echo off
rem ==============================================================================
rem OmniGet CLI Entrypoint Launcher (og)
rem ==============================================================================
setlocal
set "SCRIPT_DIR=%~dp0.."
set "PWSH_EXE=C:\Program Files\PowerShell\7\pwsh.exe"

if exist "%PWSH_EXE%" (
    "%PWSH_EXE%" -NoLogo -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\src\OmniGet.ps1" %*
) else (
    powershell.exe -NoLogo -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\src\OmniGet.ps1" %*
)
