@echo off

set Hilfe=WIMaster - Windows System Backup Tool Setup
set Skript="%~d0%~p0WIMaster-Setup.ps1"

REM Version pruefen

for /f "tokens=3" %%a in ('reg query ^"HKLM^\SOFTWARE^\Microsoft^\Windows NT^\CurrentVersion^" /v ^"currentbuild^"') do set version=%%a
if %version% lss 19042 echo. && echo Fehler: Dieses Skript erfordert Windows 10 20H2 oder neuer. && echo. && echo %Hilfe% && echo. && pause && goto :eof

REM Existenz des Skripts pruefen

if not exist %Skript% echo. && echo Fehler: Es fehlt mindestens eine Datei. && echo. && echo %Hilfe% && echo. && pause && goto :eof

REM Admin-Rechte pruefen

whoami /groups | find "S-1-16-12288" > nul && Goto Start
echo. && echo Fehler: Dieses Skript funktioniert nur mit Administratorrechten. && echo. && echo %Hilfe% && echo. && pause && goto :eof

REM Skript starten

:Start
powershell -EP Bypass -File %Skript%
