@echo off
setlocal
title 1 Click DLSS 5
cd /d "%~dp0"

if exist "%~dp01-Click-DLSS5.exe" (
    start "" "%~dp01-Click-DLSS5.exe"
    exit /b 0
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0core\1-Click-DLSS5.ps1"
endlocal
