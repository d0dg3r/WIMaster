@echo off
REM WIMaster Starter Batch File
REM Startet WIMaster\ps1\WIMaster.ps1 mit Administrator-Rechten

echo Starting WIMaster...
echo.

REM Pruefen ob PowerShell verfuegbar ist
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell ist nicht verfuegbar!
    pause
    exit /b 1
)

REM WIMaster.ps1 mit Administrator-Rechten starten (im WIMaster\ps1 Unterverzeichnis)
powershell -ExecutionPolicy Bypass -File "%~dp0WIMaster\ps1\WIMaster.ps1"

REM Pause falls Fehler auftritt
if %errorlevel% neq 0 (
    echo.
    echo WIMaster wurde mit Fehler beendet. Error Code: %errorlevel%
    pause
)
