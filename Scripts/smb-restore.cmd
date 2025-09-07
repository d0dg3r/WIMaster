@echo off
title SMB Image Restore
color 0D

REM Get the main directory (one level up from Scripts)
set "SCRIPT_DIR=%~dp0.."
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:MAIN_RESTORE
cls
echo ==========================================
echo           SMB Image Restore
echo ==========================================
echo.
echo 1. Quick Restore (Use Default Settings)
echo 2. Custom Restore (Configure Settings)
echo 3. Test SMB Connection
echo 4. Load Saved Configuration
echo 5. Save Current Configuration
echo 6. Back to Main Menu
echo.
set /p choice="Select option [1-6]: "

if "%choice%"=="1" goto QUICK_RESTORE
if "%choice%"=="2" goto CUSTOM_RESTORE
if "%choice%"=="3" goto TEST_SMB
if "%choice%"=="4" goto LOAD_CONFIG
if "%choice%"=="5" goto SAVE_CONFIG
if "%choice%"=="6" exit /b

:QUICK_RESTORE
echo Loading default settings...
if exist "%SCRIPT_DIR%\config\default-settings.txt" (
    call "%SCRIPT_DIR%\config\default-settings.txt"
) else (
    echo Default settings not found. Please configure first.
    pause
    goto MAIN_RESTORE
)
goto START_RESTORE

:CUSTOM_RESTORE
echo SMB Server Configuration:
set /p SMB_SERVER="SMB Server IP/Name: "
set /p SMB_SHARE="SMB Share Name: "
set /p SMB_USER="Username: "
set /p SMB_PASS="Password: "
set /p WIM_FILE="WIM File Name: "
set /p WIM_INDEX="WIM Index (usually 1): "
set /p DISK_NUM="Target Disk Number: "

:START_RESTORE
cls
echo ==========================================
echo Starting SMB Image Restore...
echo ==========================================
echo Server: %SMB_SERVER%
echo Share: %SMB_SHARE%
echo User: %SMB_USER%
echo WIM File: %WIM_FILE%
echo Index: %WIM_INDEX%
echo Target Disk: %DISK_NUM%
echo.
echo WARNING: This will erase all data on disk %DISK_NUM%!
set /p confirm="Type 'YES' to continue: "
if not "%confirm%"=="YES" goto MAIN_RESTORE

echo.
echo Step 1: Preparing target disk...
(
echo select disk %DISK_NUM%
echo clean
echo convert gpt
echo create partition efi size=100
echo format fs=fat32 quick
echo assign letter=S
echo create partition msr size=128
echo create partition primary
echo format fs=ntfs quick label="Windows"
echo assign letter=C
echo exit
) | diskpart

echo.
echo Step 2: Mapping SMB share...
net use Z: \\%SMB_SERVER%\%SMB_SHARE% /user:%SMB_USER% %SMB_PASS%

echo.
echo Step 3: Applying WIM image...
dism /apply-image /imagefile:Z:\%WIM_FILE% /index:%WIM_INDEX% /applydir:C:\

echo.
echo Step 4: Installing boot files...
bcdboot C:\Windows /s S: /f UEFI

echo.
echo Step 5: Cleaning up...
net use Z: /delete

echo.
echo ==========================================
echo SMB Image Restore completed successfully!
echo ==========================================
pause
goto MAIN_RESTORE

:TEST_SMB
set /p test_server="SMB Server IP/Name: "
set /p test_share="SMB Share Name: "
set /p test_user="Username: "
set /p test_pass="Password: "

echo Testing SMB connection...
net use Z: \\%test_server%\%test_share% /user:%test_user% %test_pass%
if %errorlevel%==0 (
    echo Connection successful!
    dir Z:\
    net use Z: /delete
) else (
    echo Connection failed!
)
pause
goto MAIN_RESTORE

:LOAD_CONFIG
if exist "%SCRIPT_DIR%\config\last-restore.txt" (
    echo Loading last restore configuration...
    call "%SCRIPT_DIR%\config\last-restore.txt"
    echo Configuration loaded.
) else (
    echo No saved configuration found.
)
pause
goto MAIN_RESTORE

:SAVE_CONFIG
echo Saving current configuration...
echo SMB_SERVER=%SMB_SERVER% > "%SCRIPT_DIR%\config\last-restore.txt"
echo SMB_SHARE=%SMB_SHARE% >> "%SCRIPT_DIR%\config\last-restore.txt"
echo SMB_USER=%SMB_USER% >> "%SCRIPT_DIR%\config\last-restore.txt"
echo SMB_PASS=%SMB_PASS% >> "%SCRIPT_DIR%\config\last-restore.txt"
echo WIM_FILE=%WIM_FILE% >> "%SCRIPT_DIR%\config\last-restore.txt"
echo WIM_INDEX=%WIM_INDEX% >> "%SCRIPT_DIR%\config\last-restore.txt"
echo DISK_NUM=%DISK_NUM% >> "%SCRIPT_DIR%\config\last-restore.txt"
echo Configuration saved.
pause
goto MAIN_RESTORE
