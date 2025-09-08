@echo off
REM Quick Build Script - Kompiliert Setup.exe schnell und einfach

title WIMaster Setup.exe Quick Build

echo.
echo WIMaster Setup.exe Quick Build
echo ==============================
echo.

REM Pruefen ob alle Dateien vorhanden sind
if not exist "WIMaster-Setup.cs" (
    echo ERROR: WIMaster-Setup.cs nicht gefunden!
    pause
    goto :eof
)

if not exist "..\WIMaster-Setup.ps1" (
    echo ERROR: WIMaster-Setup.ps1 nicht im Hauptverzeichnis gefunden!
    echo Das PowerShell-Script muss eine Ebene hoeher liegen.
    pause
    goto :eof
)

REM .NET Framework Compiler suchen (vereinfacht)
set CSC_PATH=
for %%P in (csc.exe) do set CSC_PATH=%%~$PATH:P
if not defined CSC_PATH (
    echo .NET Framework Compiler nicht im PATH gefunden.
    echo Suche in Visual Studio Verzeichnissen...
    
    REM Haeufigste VS-Pfade pruefen
    set "VS2022=%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\Roslyn\csc.exe"
    set "VS2019=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\Roslyn\csc.exe"
    
    if exist "%VS2022%" (
        set CSC_PATH=%VS2022%
    ) else if exist "%VS2019%" (
        set CSC_PATH=%VS2019%
    ) else (
        echo ERROR: .NET Framework Compiler nicht gefunden!
        echo Bitte installieren Sie Visual Studio oder .NET Framework SDK.
        pause
        goto :eof
    )
)

echo Compiler: %CSC_PATH%

REM Icon-Parameter
set ICON=
if exist "..\WIMaster_Ico.ico" (
    set ICON=/win32icon:"..\WIMaster_Ico.ico"
    echo Icon: ..\WIMaster_Ico.ico
)

echo.
echo Kompiliere...

REM Kompilierung - Setup.exe ins Hauptverzeichnis
"%CSC_PATH%" /target:winexe /platform:anycpu /optimize+ %ICON% /reference:System.Windows.Forms.dll /reference:Microsoft.Win32.Registry.dll /out:"..\Setup.exe" "WIMaster-Setup.cs"

if %errorlevel% equ 0 (
    echo.
    echo ✓ Setup.exe erfolgreich erstellt!
    echo.
    
    REM Dateiinfo anzeigen
    for %%A in (..\Setup.exe) do echo Groesse: %%~zA Bytes
    
    echo.
    echo Moechten Sie Setup.exe jetzt testen? (J/N)
    choice /c JN /n /m "Test starten: "
    if !errorlevel! equ 1 (
        echo.
        echo Starte Setup.exe...
        start "" "..\Setup.exe"
    )
    
) else (
    echo.
    echo ✗ Kompilierung fehlgeschlagen!
)

echo.
pause
