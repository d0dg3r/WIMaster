@echo off
echo.
echo ===============================================
echo   WIMaster Konfigurations-Manager
echo ===============================================
echo.

REM Administrator-Rechte pruefen
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Administrator-Rechte erkannt.
) else (
    echo FEHLER: Dieses Skript muss als Administrator ausgefuehrt werden!
    echo Bitte starten Sie die Eingabeaufforderung als Administrator und
    echo fuehren Sie dieses Skript erneut aus.
    echo.
    pause
    exit /b 1
)

echo Starte Konfigurations-Manager...
echo.

REM PowerShell-Skript mit umgangener Execution Policy starten
powershell.exe -ExecutionPolicy Bypass -File "%~dp0WIMaster\ps1\WIMaster-ConfigManager.ps1"

echo.
pause
