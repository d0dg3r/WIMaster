# Netzwerk-Hilfsfunktionen
# Diese Funktionen können von anderen Scripts aufgerufen werden

REM Get the main directory (two levels up from utils)
set "SCRIPT_DIR=%~dp0..\.."
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:GET_NETWORK_ADAPTERS
# Listet alle aktiven Netzwerkadapter auf
echo Active Network Adapters:
echo =========================
netsh interface show interface
goto :eof

:CONFIGURE_DHCP
# Parameter: %1 = Adapter Name
set adapter_name=%1
if "%adapter_name%"=="" set adapter_name=Ethernet

echo Configuring DHCP for %adapter_name%...
netsh interface ip set address "%adapter_name%" dhcp
netsh interface ip set dns "%adapter_name%" dhcp
ipconfig /renew
echo DHCP configured successfully.
goto :eof

:CONFIGURE_STATIC_IP
# Parameter: %1 = Adapter Name, %2 = IP, %3 = Mask, %4 = Gateway, %5 = DNS
set adapter_name=%1
set static_ip=%2
set static_mask=%3
set static_gateway=%4
set static_dns=%5

if "%adapter_name%"=="" set adapter_name=Ethernet

echo Configuring static IP for %adapter_name%...
netsh interface ip set address "%adapter_name%" static %static_ip% %static_mask% %static_gateway%
netsh interface ip set dns "%adapter_name%" static %static_dns%
echo Static IP configured successfully.
goto :eof

:TEST_CONNECTIVITY
# Parameter: %1 = Target IP/Hostname
set test_target=%1
if "%test_target%"=="" set test_target=8.8.8.8

echo Testing connectivity to %test_target%...
ping -n 2 %test_target%
if %errorlevel%==0 (
    echo Connectivity test successful.
    set CONNECTIVITY_OK=1
) else (
    echo Connectivity test failed.
    set CONNECTIVITY_OK=0
)
goto :eof

:GET_IP_CONFIG
# Zeigt die aktuelle IP-Konfiguration an
echo Current IP Configuration:
echo ==========================
ipconfig /all
goto :eof

:SAVE_NETWORK_CONFIG
# Speichert die aktuelle Netzwerkkonfiguration
# Parameter: %1 = Dateiname (optional)
set config_file=%1
if "%config_file%"=="" set config_file=Scripts\config\current-network.txt

echo Saving network configuration to %config_file%...
ipconfig /all > %config_file%
echo Network configuration saved.
goto :eof

:LOAD_NETWORK_CONFIG
# Lädt eine gespeicherte Netzwerkkonfiguration
# Parameter: %1 = Dateiname (optional)
set config_file=%1
if "%config_file%"=="" set config_file=Scripts\config\current-network.txt

if exist %config_file% (
    echo Loading network configuration from %config_file%...
    type %config_file%
) else (
    echo Network configuration file not found: %config_file%
)
goto :eof
