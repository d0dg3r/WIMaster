#Requires -RunAsAdministrator
#Requires -Version 3.0

<#
.SYNOPSIS
  EncryptPassword - Passwort-Verschlüsselungs-Tool für WIMaster
.DESCRIPTION
  Ermöglicht das sichere Verschlüsseln von Passwörtern für die Verwendung in WIMaster-Konfigurationen.
.NOTES
  Autor: Joachim Mild <joe@devops-geek.net>
  Creation Date: 2025-01-27
  Basierend auf WIMaster - Windows System Backup Tool
#>

# Zeichenkodierung für korrekte Umlaut-Darstellung setzen
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "WIMaster - Passwort-Verschlüsselungs-Tool" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Dieses Tool ermöglicht es Ihnen, Passwörter sicher zu verschlüsseln" -ForegroundColor White
Write-Host "für die Verwendung in der WIMaster-Konfiguration." -ForegroundColor White
Write-Host ""

Write-Host "WICHTIG: Das verschlüsselte Passwort kann nur auf diesem Computer" -ForegroundColor Red
Write-Host "         und von diesem Benutzer entschlüsselt werden!" -ForegroundColor Red
Write-Host ""

# Passwort sicher einlesen
$SecurePassword = Read-Host -Prompt "Bitte geben Sie das zu verschlüsselnde Passwort ein" -AsSecureString

if ($SecurePassword.Length -eq 0) {
    Write-Host "Kein Passwort eingegeben. Vorgang abgebrochen." -ForegroundColor Red
    exit 1
}

try {
    # Passwort verschlüsseln
    $EncryptedPassword = $SecurePassword | ConvertFrom-SecureString
    
    Write-Host ""
    Write-Host "Passwort erfolgreich verschlüsselt!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verschlüsseltes Passwort:" -ForegroundColor Yellow
    Write-Host "=========================" -ForegroundColor Yellow
    Write-Host $EncryptedPassword -ForegroundColor Cyan
    Write-Host ""
    
    # In Zwischenablage kopieren (falls möglich)
    try {
        $EncryptedPassword | Set-Clipboard
        Write-Host "Das verschlüsselte Passwort wurde in die Zwischenablage kopiert." -ForegroundColor Green
    } catch {
        Write-Host "Hinweis: Verschlüsseltes Passwort konnte nicht in Zwischenablage kopiert werden." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Verwendung in WIMaster-Config.json:" -ForegroundColor White
    Write-Host '  "Network": {' -ForegroundColor Gray
    Write-Host '    "NetworkPassword": "' -NoNewline -ForegroundColor Gray
    Write-Host $EncryptedPassword -NoNewline -ForegroundColor Cyan
    Write-Host '"' -ForegroundColor Gray
    Write-Host '  }' -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host "Fehler beim Verschlüsseln des Passworts: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Drücken Sie eine beliebige Taste zum Beenden..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
