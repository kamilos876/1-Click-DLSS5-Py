@echo off
setlocal
cd /d "%~dp0"
title 1 Click DLSS 5 - Universal Neural Game Center

where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Python was not found. Install Python 3.10 or newer.
    pause
    exit /b 1
)

python -c "import PySide6" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installing PySide6...
    python -m pip install -r requirements.txt
)

python main.py %*
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] 1 Click DLSS 5 exited with code %ERRORLEVEL%.
    pause
)
exit /b %ERRORLEVEL%
