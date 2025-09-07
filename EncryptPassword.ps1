#Requires -RunAsAdministrator
#Requires -Version 3.0

<#
.SYNOPSIS
  c't-WIMaster Passwort-Verschluesseler
.DESCRIPTION
  Dieses Skript verschluesselt ein Passwort mit Windows DPAPI fuer die sichere Speicherung in der c't-WIMaster Konfiguration.
.NOTES
  Version:        1.0
  Autor:          Enhanced c't-WIMaster
  Erstellungsdatum: 2025-01-15
 #>

Write-Host "=== c't-WIMaster Passwort-Verschluesseler ===" -ForegroundColor Cyan
Write-Host ""

# Passwort vom Benutzer abfragen (sicher)
$SecurePassword = Read-Host "Geben Sie das zu verschluesselnde Passwort ein" -AsSecureString

# SecureString in Klartext umwandeln fuer Verarbeitung
$PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))

# Passwort mit Windows DPAPI verschluesseln
$EncryptedPassword = ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String $PlainPassword -AsPlainText -Force)

# SecureString-Speicher sicher freigeben
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))

# Ergebnis anzeigen
Write-Host ""
Write-Host "Verschluesseltes Passwort:" -ForegroundColor Green
Write-Host $EncryptedPassword -ForegroundColor Yellow
Write-Host ""
Write-Host "Kopieren Sie diese Zeile in Ihre INI-Datei:" -ForegroundColor Cyan
Write-Host "NetworkPassword=$EncryptedPassword" -ForegroundColor White
Write-Host ""
