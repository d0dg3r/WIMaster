# Post-Install Vorlage
# Diese Datei kann nach der Windows-Installation ausgeführt werden

echo Post-Install Script
echo ===================

# Beispiel: Windows Updates aktivieren
echo Enabling Windows Updates...
sc config wuauserv start= auto
net start wuauserv

# Beispiel: Remote Desktop aktivieren
echo Enabling Remote Desktop...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

# Beispiel: Firewall konfigurieren
echo Configuring Windows Firewall...
netsh advfirewall set allprofiles state on

echo Post-Install completed.
pause
