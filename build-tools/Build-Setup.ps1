#Requires -Version 3.0

<#
.SYNOPSIS
  WIMaster Setup.exe Build Script

.DESCRIPTION
  Kompiliert WIMaster-Setup.cs zu einer ausfuehrbaren Setup.exe mit .NET Framework

.NOTES
  Author: Joachim Mild <joe@devops-geek.net>
  Creation Date: 2025-01-27
#>

# Zeichenkodierung setzen
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "WIMaster Setup.exe Build Script" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Arbeitsverzeichnis auf Script-Pfad setzen (build-tools Ordner)
Set-Location $PSScriptRoot

# .NET Framework Compiler suchen
Write-Host "Suche .NET Framework Compiler..." -ForegroundColor Yellow

$CscPaths = @(
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\csc.exe",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\Roslyn\csc.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\Roslyn\csc.exe",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\Roslyn\csc.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\Roslyn\csc.exe",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\Roslyn\csc.exe"
)

# Zuerst im PATH suchen
$CscExe = Get-Command "csc.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source

# Falls nicht im PATH, in VS-Installationen suchen
if (-not $CscExe) {
    foreach ($Path in $CscPaths) {
        if (Test-Path $Path) {
            $CscExe = $Path
            break
        }
    }
}

# Falls immer noch nicht gefunden, .NET Framework SDK Pfade durchsuchen
if (-not $CscExe) {
    $NetFxPaths = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows" -Directory -ErrorAction SilentlyContinue | 
                  ForEach-Object { Join-Path $_.FullName "bin\NETFX*\Tools\csc.exe" }
    
    foreach ($Path in $NetFxPaths) {
        $ResolvedPaths = Resolve-Path $Path -ErrorAction SilentlyContinue
        if ($ResolvedPaths) {
            $CscExe = $ResolvedPaths[0].Path
            break
        }
    }
}

if (-not $CscExe -or -not (Test-Path $CscExe)) {
    Write-Host "ERROR: .NET Framework Compiler (csc.exe) nicht gefunden!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Bitte installieren Sie eines der folgenden:" -ForegroundColor Yellow
    Write-Host "- .NET Framework Developer Pack"
    Write-Host "- Visual Studio Build Tools" 
    Write-Host "- Visual Studio Community/Professional/Enterprise"
    Write-Host ""
    Write-Host "Download: https://dotnet.microsoft.com/download/dotnet-framework" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Druecken Sie Enter zum Beenden"
    return
}

Write-Host "Compiler gefunden: $CscExe" -ForegroundColor Green

# Pruefen ob Quellcode vorhanden ist
if (-not (Test-Path "WIMaster-Setup.cs")) {
    Write-Host "ERROR: WIMaster-Setup.cs nicht gefunden!" -ForegroundColor Red
    Read-Host "Druecken Sie Enter zum Beenden"
    return
}

# Pruefen ob PowerShell-Script vorhanden ist
if (-not (Test-Path "..\WIMaster-Setup.ps1")) {
    Write-Host "ERROR: WIMaster-Setup.ps1 nicht im Hauptverzeichnis gefunden!" -ForegroundColor Red
    Write-Host "Das PowerShell-Script muss eine Ebene hoeher liegen." -ForegroundColor Yellow
    Read-Host "Druecken Sie Enter zum Beenden"
    return
}

Write-Host "Quellcode gefunden: WIMaster-Setup.cs" -ForegroundColor Green

# Icon-Parameter vorbereiten
$IconParam = ""
if (Test-Path "..\WIMaster_Ico.ico") {
    Write-Host "Icon gefunden: ..\WIMaster_Ico.ico" -ForegroundColor Green
    $IconParam = '/win32icon:"..\WIMaster_Ico.ico"'
} else {
    Write-Host "Kein Icon gefunden - Setup.exe wird ohne Icon erstellt." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Kompiliere Setup.exe..." -ForegroundColor Yellow

# Kompilierung starten
$Arguments = @(
    "/target:winexe",
    "/platform:anycpu", 
    "/optimize+",
    "/reference:System.Windows.Forms.dll",
    "/reference:Microsoft.Win32.Registry.dll",
    "/out:..\Setup.exe",
    "WIMaster-Setup.cs"
)

if ($IconParam) {
    $Arguments = @($IconParam) + $Arguments
}

try {
    $Process = Start-Process -FilePath $CscExe -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
    
    if ($Process.ExitCode -eq 0) {
        Write-Host ""
        Write-Host "====================================" -ForegroundColor Green
        Write-Host "Setup.exe erfolgreich erstellt!" -ForegroundColor Green
        Write-Host "====================================" -ForegroundColor Green
        Write-Host ""
        
        if (Test-Path "..\Setup.exe") {
            $FileInfo = Get-Item "..\Setup.exe"
            Write-Host "Dateigroesse: $($FileInfo.Length) Bytes" -ForegroundColor Cyan
            Write-Host "Erstellt am: $($FileInfo.CreationTime)" -ForegroundColor Cyan
        }
        
        Write-Host ""
        Write-Host "Die Setup.exe kann jetzt verwendet werden um WIMaster-Setup.ps1" -ForegroundColor Yellow
        Write-Host "mit Administrator-Rechten auszufuehren." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Wichtig: Die Setup.exe muss im gleichen Verzeichnis wie die" -ForegroundColor Red
        Write-Host "WIMaster-Setup.ps1 Datei liegen!" -ForegroundColor Red
        
    } else {
        Write-Host ""
        Write-Host "ERROR: Kompilierung fehlgeschlagen!" -ForegroundColor Red
        Write-Host "Exit Code: $($Process.ExitCode)" -ForegroundColor Red
    }
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Kompilierung fehlgeschlagen!" -ForegroundColor Red
    Write-Host "Fehler: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Read-Host "Druecken Sie Enter zum Beenden"
