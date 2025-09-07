@echo off

# Hilfetext und Skript-Pfad definieren
set Hilfe=Anleitungen, Downloads, Forum, News: ct.de/wimage
set Skript="%~d0%~p0\ct-WIMaster-USBSpeedCheck.ps1"

# Windows-Version pruefen (mindestens Windows 10 20H2 Build 19042)
for /f "tokens=3" %%a in ('reg query ^"HKLM^\SOFTWARE^\Microsoft^\Windows NT^\CurrentVersion^" /v ^"currentbuild^"') do set version=%%a
if %version% lss 19042 echo. && echo Fehler: Dieses Skript erfordert Windows 10 20H2 oder neuer. && echo. && echo %Hilfe% && echo. && pause && goto :eof

# Existenz des PowerShell-Skripts pruefen
if not exist %Skript% echo. && echo Fehler: Es fehlt mindestens eine Datei. && echo. && echo %Hilfe% && echo. && pause && goto :eof

# Administrator-Rechte pruefen (S-1-16-12288 = High Mandatory Level)
whoami /groups | find "S-1-16-12288" > nul && Goto Start
echo. && echo Fehler: Dieses Skript funktioniert nur mit Administratorrechten. && echo. && echo %Hilfe% && echo. && pause && goto :eof

# PowerShell-Skript mit umgangener Execution Policy starten
:Start
powershell -EP Bypass -File %Skript%