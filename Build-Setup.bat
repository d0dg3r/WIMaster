@echo off
REM WIMaster Setup.exe Build Launcher
REM Startet das eigentliche Build-Script aus dem build-tools Ordner

title WIMaster Setup.exe Build

echo.
echo ====================================
echo WIMaster Setup.exe Build Launcher
echo ====================================
echo.

REM Pruefen ob build-tools Ordner vorhanden ist
if not exist "build-tools" (
    echo ERROR: build-tools Ordner nicht gefunden!
    echo.
    echo Die Build-Scripts befinden sich im build-tools\ Verzeichnis.
    echo Bitte stellen Sie sicher, dass der build-tools Ordner existiert.
    echo.
    pause
    goto :eof
)

REM Pruefen ob Build-Script vorhanden ist
if not exist "build-tools\Build-Setup.bat" (
    echo ERROR: build-tools\Build-Setup.bat nicht gefunden!
    echo.
    pause
    goto :eof
)

echo Starte Build-Script aus build-tools Ordner...
echo.

REM Build-Script aus build-tools starten
cd build-tools
call Build-Setup.bat

REM Zurueck ins Hauptverzeichnis
cd ..

echo.
echo Build-Vorgang abgeschlossen.
echo.

REM Setup.exe Status pruefen
if exist "Setup.exe" (
    echo ✓ Setup.exe wurde erfolgreich erstellt!
    for %%A in (Setup.exe) do echo   Dateigroesse: %%~zA Bytes
) else (
    echo ✗ Setup.exe wurde nicht erstellt.
    echo   Pruefen Sie die Fehlermeldungen oben.
)

echo.
pause
