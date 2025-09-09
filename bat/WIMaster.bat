@echo off
echo.
echo WIMaster - Windows System Backup Tool
echo Entwickelt von Joachim Mild ^<joe@devops-geek.net^>
echo.

set Hilfe=WIMaster - Windows System Backup Tool
set Skript="%~d0%~p0WIMaster\ps1\WIMaster.ps1"

REM Version pruefen
for /f "tokens=3" %%a in ('reg query ^"HKLM^\SOFTWARE^\Microsoft^\Windows NT^\CurrentVersion^" /v ^"currentbuild^"') do set version=%%a
if %version% lss 19042 (
    echo.
    echo Fehler: Dieses Skript erfordert Windows 10 20H2 oder neuer.
    echo Ihre Version: Build %version%
    echo.
    echo %Hilfe%
    echo.
    pause
    goto :eof
)

REM PowerShell Verfuegbarkeit pruefen
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo Fehler: PowerShell ist nicht verfuegbar!
    echo.
    echo %Hilfe%
    echo.
    pause
    goto :eof
)

REM Existenz des Skripts pruefen
if not exist %Skript% (
    echo.
    echo Fehler: WIMaster\ps1\WIMaster.ps1 nicht gefunden!
    echo Erwarteter Pfad: %Skript%
    echo.
    echo Bitte stellen Sie sicher, dass alle Dateien korrekt kopiert wurden.
    echo.
    echo %Hilfe%
    echo.
    pause
    goto :eof
)

REM Admin-Rechte pruefen
whoami /groups | find "S-1-16-12288" > nul && Goto Start
echo.
echo Fehler: Dieses Skript funktioniert nur mit Administratorrechten.
echo Rechtsklick -^> "Als Administrator ausfuehren"
echo.
echo %Hilfe%
echo.
pause
goto :eof

REM Skript starten
:Start
echo.
echo Starte WIMaster...
echo.
powershell -ExecutionPolicy Bypass -File %Skript%

REM Fehlerbehandlung
if %errorlevel% neq 0 (
    echo.
    echo WIMaster wurde mit Fehler beendet. Error Code: %errorlevel%
    echo.
    pause
)