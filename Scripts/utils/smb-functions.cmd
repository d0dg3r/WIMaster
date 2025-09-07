# SMB-Hilfsfunktionen
# Diese Funktionen können von anderen Scripts aufgerufen werden

REM Get the main directory (two levels up from utils)
set "SCRIPT_DIR=%~dp0..\.."
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:TEST_SMB_CONNECTION
# Parameter: %1 = Server, %2 = Share, %3 = User, %4 = Pass
set test_server=%1
set test_share=%2
set test_user=%3
set test_pass=%4

echo Testing SMB connection to \\%test_server%\%test_share%...
net use Z: \\%test_server%\%test_share% /user:%test_user% %test_pass%
if %errorlevel%==0 (
    echo Connection successful!
    set SMB_CONNECTION_OK=1
    net use Z: /delete
) else (
    echo Connection failed!
    set SMB_CONNECTION_OK=0
)
goto :eof

:MAP_SMB_SHARE
# Parameter: %1 = Server, %2 = Share, %3 = User, %4 = Pass, %5 = Drive Letter
set map_server=%1
set map_share=%2
set map_user=%3
set map_pass=%4
set map_drive=%5

echo Mapping SMB share to %map_drive%:...
net use %map_drive%: \\%map_server%\%map_share% /user:%map_user% %map_pass%
if %errorlevel%==0 (
    echo Share mapped successfully to %map_drive%:
    set SMB_MAPPED=1
) else (
    echo Failed to map share!
    set SMB_MAPPED=0
)
goto :eof

:UNMAP_SMB_SHARE
# Parameter: %1 = Drive Letter
set unmap_drive=%1

echo Unmapping SMB share %unmap_drive%:...
net use %unmap_drive%: /delete
if %errorlevel%==0 (
    echo Share unmapped successfully.
    set SMB_UNMAPPED=1
) else (
    echo Failed to unmap share!
    set SMB_UNMAPPED=0
)
goto :eof

:LIST_SMB_SHARES
# Listet verfügbare SMB-Shares auf einem Server auf
# Parameter: %1 = Server, %2 = User, %3 = Pass
set list_server=%1
set list_user=%2
set list_pass=%3

echo Listing shares on %list_server%...
net view \\%list_server% /user:%list_user% %list_pass%
goto :eof
