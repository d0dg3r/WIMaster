@echo off
title Network Tools
color 0C

REM Get the main directory (one level up from Scripts)
set "SCRIPT_DIR=%~dp0.."
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:NET_MENU
cls
echo ==========================================
echo             Network Tools
echo ==========================================
echo.
echo 1. Show Current IP Configuration
echo 2. Configure DHCP
echo 3. Configure Static IP
echo 4. Ping Test
echo 5. Test SMB Connection
echo 6. Save Network Profile
echo 7. Load Network Profile
echo 8. Network Diagnostics
echo 9. Back to Main Menu
echo.
set /p choice="Select option [1-9]: "

if "%choice%"=="1" goto SHOW_IP
if "%choice%"=="2" goto DHCP_CONFIG
if "%choice%"=="3" goto STATIC_CONFIG
if "%choice%"=="4" goto PING_TEST
if "%choice%"=="5" goto SMB_TEST
if "%choice%"=="6" goto SAVE_PROFILE
if "%choice%"=="7" goto LOAD_PROFILE
if "%choice%"=="8" goto NET_DIAG
if "%choice%"=="9" exit /b

:SHOW_IP
cls
echo Current Network Configuration:
echo ==========================================
ipconfig /all
echo.
echo Network Adapters:
netsh interface show interface
pause
goto NET_MENU

:DHCP_CONFIG
echo Configuring DHCP...
netsh interface ip set address "Ethernet" dhcp
netsh interface ip set dns "Ethernet" dhcp
ipconfig /renew
echo DHCP configured successfully.
pause
goto NET_MENU

:STATIC_CONFIG
echo Static IP Configuration:
set /p ip="IP Address: "
set /p mask="Subnet Mask (e.g., 255.255.255.0): "
set /p gateway="Gateway: "
set /p dns="DNS Server: "

netsh interface ip set address "Ethernet" static %ip% %mask% %gateway%
netsh interface ip set dns "Ethernet" static %dns%
echo Static IP configured successfully.
pause
goto NET_MENU

:PING_TEST
set /p target="Target IP/Hostname to ping: "
ping -t %target%
goto NET_MENU

:SMB_TEST
set /p server="SMB Server IP/Name: "
echo Testing SMB connection to %server%...
ping -n 2 %server%
telnet %server% 445
pause
goto NET_MENU

:SAVE_PROFILE
echo Saving current network configuration...
ipconfig > "%SCRIPT_DIR%\config\current-network.txt"
echo Network profile saved.
pause
goto NET_MENU

:LOAD_PROFILE
if exist "%SCRIPT_DIR%\config\network-profiles.txt" (
    type "%SCRIPT_DIR%\config\network-profiles.txt"
) else (
    echo No saved profiles found.
)
pause
goto NET_MENU

:NET_DIAG
cls
echo Network Diagnostics:
echo ==========================================
echo Testing connectivity...
ping -n 2 8.8.8.8
echo.
echo DNS Resolution test...
nslookup google.com
echo.
echo Network adapters status...
netsh interface show interface
echo.
echo Network adapter details:
netsh interface ip show config
pause
goto NET_MENU
