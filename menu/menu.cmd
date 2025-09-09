@echo off
chcp 65001 >nul
title Windows Setup & Restore Menu
color 0B

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:MAIN_MENU
cls
echo.
echo ==========================================
echo        Windows Setup & Restore
echo ==========================================
echo.
echo  1. SMB Image Restore
echo  2. Network Tools
echo  3. Disk Tools
echo  4. System Information
echo  5. Command Prompt
echo  6. Reboot
echo  7. Shutdown
echo.
echo ==========================================
echo.
set /p choice="Select option [1-7]: "

if "%choice%"=="1" (
    echo Starting SMB Image Restore...
    if exist "%SCRIPT_DIR%\Scripts\smb-restore.cmd" (
        call "%SCRIPT_DIR%\Scripts\smb-restore.cmd"
    ) else (
        echo Error: %SCRIPT_DIR%\Scripts\smb-restore.cmd not found!
        pause
    )
    goto MAIN_MENU
)

if "%choice%"=="2" (
    echo Starting Network Tools...
    if exist "%SCRIPT_DIR%\Scripts\network-tools.cmd" (
        call "%SCRIPT_DIR%\Scripts\network-tools.cmd"
    ) else (
        echo Error: %SCRIPT_DIR%\Scripts\network-tools.cmd not found!
        pause
    )
    goto MAIN_MENU
)

if "%choice%"=="3" (
    echo Starting Disk Tools...
    if exist "%SCRIPT_DIR%\Scripts\disk-tools.cmd" (
        call "%SCRIPT_DIR%\Scripts\disk-tools.cmd"
    ) else (
        echo Error: %SCRIPT_DIR%\Scripts\disk-tools.cmd not found!
        pause
    )
    goto MAIN_MENU
)

if "%choice%"=="4" (
    echo Starting System Information...
    if exist "%SCRIPT_DIR%\Scripts\system-info.cmd" (
        call "%SCRIPT_DIR%\Scripts\system-info.cmd"
    ) else (
        echo Error: %SCRIPT_DIR%\Scripts\system-info.cmd not found!
        pause
    )
    goto MAIN_MENU
)

if "%choice%"=="5" (
    echo Starting Command Prompt...
    cmd
    goto MAIN_MENU
)

if "%choice%"=="6" (
    echo Rebooting system...
    wpeutil reboot
)

if "%choice%"=="7" (
    echo Shutting down system...
    wpeutil shutdown
)

if "%choice%"=="" goto MAIN_MENU
if "%choice%"=="0" goto MAIN_MENU

echo Invalid option. Please select 1-7.
pause
goto MAIN_MENU
