@echo off
title Disk Management Tools
color 0E

REM Get the main directory (one level up from Scripts)
set "SCRIPT_DIR=%~dp0.."
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:DISK_MENU
cls
echo ==========================================
echo           Disk Management Tools
echo ==========================================
echo.
echo 1. Show Disk Information
echo 2. Interactive Diskpart
echo 3. Quick Format Disk
echo 4. Create Windows Partitions (MBR)
echo 5. Create Windows Partitions (UEFI)
echo 6. Check Disk Health
echo 7. Back to Main Menu
echo.
set /p choice="Select option [1-7]: "

if "%choice%"=="1" goto DISK_INFO
if "%choice%"=="2" goto DISKPART_INTERACTIVE
if "%choice%"=="3" goto QUICK_FORMAT
if "%choice%"=="4" goto CREATE_MBR
if "%choice%"=="5" goto CREATE_UEFI
if "%choice%"=="6" goto DISK_HEALTH
if "%choice%"=="7" exit /b

:DISK_INFO
cls
echo Disk Information:
echo ==========================================
echo list disk | diskpart
echo.
echo Detailed disk info:
echo Using diskpart to list disks...
echo list disk | diskpart
pause
goto DISK_MENU

:DISKPART_INTERACTIVE
echo Starting interactive Diskpart...
echo Type 'exit' to return to menu.
diskpart
goto DISK_MENU

:QUICK_FORMAT
echo Available disks:
echo list disk | diskpart
set /p disknum="Disk number to format: "
set /p label="Volume label: "

echo WARNING: This will erase all data on disk %disknum%!
set /p confirm="Type 'YES' to confirm: "
if not "%confirm%"=="YES" goto DISK_MENU

(
echo select disk %disknum%
echo clean
echo create partition primary
echo active
echo format fs=ntfs quick label="%label%"
echo assign
echo exit
) | diskpart

echo Disk formatted successfully.
pause
goto DISK_MENU

:CREATE_MBR
call "%SCRIPT_DIR%\templates\diskpart-mbr.txt"
goto DISK_MENU

:CREATE_UEFI
call "%SCRIPT_DIR%\templates\diskpart-uefi.txt"
goto DISK_MENU

:DISK_HEALTH
echo Checking disk health...
echo Using diskpart to check disk status...
echo list disk | diskpart
echo.
echo For detailed health info, use 'chkdsk' in command prompt.
pause
goto DISK_MENU
