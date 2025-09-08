@echo off
REM WIMaster Setup.exe Build Script
REM Kompiliert WIMaster-Setup.cs zu einer ausfuehrbaren Setup.exe

echo.
echo ====================================
echo WIMaster Setup.exe Build Script
echo ====================================
echo.

REM Pruefen ob .NET Framework verfuegbar ist
echo Pruefe .NET Framework...
where csc >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: .NET Framework Compiler (csc.exe) nicht gefunden!
    echo.
    echo Bitte installieren Sie das .NET Framework Developer Pack oder
    echo Visual Studio Build Tools.
    echo.
    echo Download: https://dotnet.microsoft.com/download/dotnet-framework
    echo.
    pause
    goto :eof
)

REM Pruefen ob Quellcode vorhanden ist
if not exist "WIMaster-Setup.cs" (
    echo ERROR: WIMaster-Setup.cs nicht gefunden!
    echo.
    pause
    goto :eof
)

REM Pruefen ob PowerShell-Script vorhanden ist
if not exist "..\WIMaster-Setup.ps1" (
    echo ERROR: WIMaster-Setup.ps1 nicht im Hauptverzeichnis gefunden!
    echo Das PowerShell-Script muss eine Ebene hoeher liegen.
    echo.
    pause
    goto :eof
)

echo .NET Framework Compiler gefunden.

REM Icon-Ressource vorbereiten (falls vorhanden)
set ICON_PARAM=
if exist "..\WIMaster_Ico.ico" (
    echo Icon gefunden: ..\WIMaster_Ico.ico
    set ICON_PARAM=/win32icon:"..\WIMaster_Ico.ico"
) else (
    echo Kein Icon gefunden - Setup.exe wird ohne Icon erstellt.
)

echo.
echo Kompiliere Setup.exe...

REM C# Code kompilieren - Setup.exe ins Hauptverzeichnis
csc /target:winexe /platform:anycpu /optimize+ %ICON_PARAM% /reference:System.Windows.Forms.dll /reference:Microsoft.Win32.Registry.dll /out:"..\Setup.exe" "WIMaster-Setup.cs"

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Kompilierung fehlgeschlagen!
    echo.
    pause
    goto :eof
)

echo.
echo ====================================
echo Setup.exe erfolgreich erstellt!
echo ====================================
echo.

REM Dateigroesse anzeigen
for %%A in (..\Setup.exe) do echo Dateigroesse: %%~zA Bytes

echo.
echo Die Setup.exe kann jetzt verwendet werden um WIMaster-Setup.ps1
echo mit Administrator-Rechten auszufuehren.
echo.
echo Wichtig: Die Setup.exe muss im gleichen Verzeichnis wie die
echo WIMaster-Setup.ps1 Datei liegen!
echo.

pause
