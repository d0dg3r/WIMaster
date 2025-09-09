@echo off
REM WIMaster Unattended Starter Batch File
REM Startet WIMaster\ps1\WIMaster.ps1 im unbeaufsichtigten Modus mit Administrator-Rechten

echo Starting WIMaster in unattended mode...
echo.

REM Pruefen ob PowerShell verfuegbar ist
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell ist nicht verfuegbar!
    pause
    exit /b 1
)

REM WIMaster.ps1 im unbeaufsichtigten Modus starten (im WIMaster\ps1 Unterverzeichnis)
powershell -ExecutionPolicy Bypass -File "%~dp0WIMaster\ps1\WIMaster.ps1" -Unattended

REM Pause falls Fehler auftritt
if %errorlevel% neq 0 (
    echo.
    echo WIMaster wurde mit Fehler beendet. Error Code: %errorlevel%
    pause
)
