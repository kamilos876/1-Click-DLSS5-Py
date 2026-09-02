@echo off
setlocal
title 1-Click DLSS 5
cd /d "%~dp0"
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0core\1-Click-DLSS5.ps1"
endlocal
