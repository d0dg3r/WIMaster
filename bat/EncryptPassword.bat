@echo off
REM EncryptPassword.bat - Starter für das Passwort-Verschlüsselungs-Tool
REM WIMaster - Windows System Backup Tool
REM Autor: Joachim Mild <joe@devops-geek.net>

title WIMaster - Passwort-Verschlüsselung

REM Prüfen ob PowerShell verfügbar ist
where powershell >nul 2>&1
if errorlevel 1 (
    echo.
    echo Fehler: PowerShell ist nicht verfügbar!
    echo Das Tool benötigt PowerShell um zu funktionieren.
    echo.
    pause
    exit /b 1
)

REM PowerShell-Skript starten
powershell -ExecutionPolicy Bypass -File "%~dp0WIMaster\ps1\EncryptPassword.ps1"

REM Fehlerbehandlung
if errorlevel 1 (
    echo.
    echo Das Passwort-Verschlüsselungs-Tool wurde mit Fehler beendet.
    echo Error Code: %errorlevel%
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo Passwort-Verschlüsselung erfolgreich abgeschlossen.
pause
