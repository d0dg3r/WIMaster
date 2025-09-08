#Requires -Version 3.0

<#
.SYNOPSIS
  WIMaster Setup.exe Build Launcher

.DESCRIPTION
  Startet das eigentliche Build-Script aus dem build-tools Ordner

.NOTES
  Author: Joachim Mild <joe@devops-geek.net>
  Creation Date: 2025-01-27
#>

# Zeichenkodierung setzen
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "WIMaster Setup.exe Build Launcher" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Arbeitsverzeichnis auf Script-Pfad setzen
Set-Location $PSScriptRoot

# Pruefen ob build-tools Ordner vorhanden ist
if (-not (Test-Path "build-tools")) {
    Write-Host "ERROR: build-tools Ordner nicht gefunden!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Die Build-Scripts befinden sich im build-tools\ Verzeichnis." -ForegroundColor Yellow
    Write-Host "Bitte stellen Sie sicher, dass der build-tools Ordner existiert." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Druecken Sie Enter zum Beenden"
    return
}

# Pruefen ob Build-Script vorhanden ist
if (-not (Test-Path "build-tools\Build-Setup.ps1")) {
    Write-Host "ERROR: build-tools\Build-Setup.ps1 nicht gefunden!" -ForegroundColor Red
    Read-Host "Druecken Sie Enter zum Beenden"
    return
}

Write-Host "Starte Build-Script aus build-tools Ordner..." -ForegroundColor Green
Write-Host ""

try {
    # Build-Script aus build-tools starten
    Set-Location "build-tools"
    & ".\Build-Setup.ps1"
    
    # Zurueck ins Hauptverzeichnis
    Set-Location ".."
    
    Write-Host ""
    Write-Host "Build-Vorgang abgeschlossen." -ForegroundColor Green
    Write-Host ""
    
    # Setup.exe Status pruefen
    if (Test-Path "Setup.exe") {
        Write-Host "✅ Setup.exe wurde erfolgreich erstellt!" -ForegroundColor Green
        $FileInfo = Get-Item "Setup.exe"
        Write-Host "   Dateigroesse: $($FileInfo.Length) Bytes" -ForegroundColor Cyan
        Write-Host "   Erstellt am: $($FileInfo.CreationTime)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Setup.exe wurde nicht erstellt." -ForegroundColor Red
        Write-Host "   Pruefen Sie die Fehlermeldungen oben." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "ERROR: Fehler beim Ausfuehren des Build-Scripts!" -ForegroundColor Red
    Write-Host "Fehler: $($_.Exception.Message)" -ForegroundColor Red
    Set-Location $PSScriptRoot  # Sicherstellen, dass wir im richtigen Verzeichnis sind
}

Write-Host ""
Read-Host "Druecken Sie Enter zum Beenden"
