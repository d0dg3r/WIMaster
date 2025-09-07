@echo off
chcp 65001 >nul
title WIMaster Menu - GUI Version

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo.
echo ==========================================
echo        WIMaster Menu - GUI Version
echo ==========================================
echo.
echo Starting WIMaster Menu GUI...
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PowerShell is not available on this system.
    echo Please install PowerShell or use the original menu.cmd instead.
    pause
    exit /b 1
)

REM Start the PowerShell GUI menu
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\WIMaster-Menu.ps1"

REM If we get here, the GUI was closed
echo.
echo WIMaster Menu GUI closed.
pause
