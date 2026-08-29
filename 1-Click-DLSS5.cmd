@echo off
setlocal
cd /d "%~dp0"

title 1 Click DLSS 5 - Universal Neural Game Center

where powershell.exe >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] PowerShell was not found on your system.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp01-Click-DLSS5.ps1"

exit /b %ERRORLEVEL%
