@echo off
echo.
echo ===============================================
echo   c't-WIMaster Passwort-Verschluesseler
echo ===============================================
echo.

# Administrator-Rechte pruefen
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

echo Starte PowerShell-Skript...
echo.

# PowerShell-Skript mit umgangener Execution Policy ausfuehren
powershell.exe -ExecutionPolicy Bypass -File "%~dp0EncryptPassword.ps1"

echo.
pause
