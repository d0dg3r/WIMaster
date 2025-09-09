#Requires -RunAsAdministrator

# Hilfetext fuer Benutzer
$Hilfe = " Anleitungen, Downloads, Forum, News: ct.de/wimage`n"

<#
.SYNOPSIS
  USB-Geschwindigkeits-Check fuer c't-WIMaster
.DESCRIPTION
  Dieses Skript testet die Geschwindigkeit von USB-Laufwerken fuer c't-WIMaster Backups.
  Lesen Sie unbedingt die Anleitungen zum Skript, siehe ct.de/wimage.
.NOTES
  Version:        1.00
  Autor:          Axel Vahldiek <axv@ct.de>
  Erstellungsdatum: 2025-04-23
#>

# Bildschirm loeschen
cls 

# Alle USB-Laufwerke finden
$USBLW = Get-Disk | Where-Object {$_.BusType -eq 'USB'}

If ($USBLW) {
	# Fuer jedes gefundene USB-Laufwerk
	$USBLW | ForEach-Object {
		# Laufwerksname und Groesse anzeigen
		Write-Host "`n" $_.FriendlyName $([math]::round($_.Size / 1GB, 1))"GB`n"
		
		# Windows System Assessment Tool (Winsat) fuer Geschwindigkeitstest verwenden
		# Nur sequentielle Lese-/Schreibgeschwindigkeit anzeigen
		Winsat Disk -Drive (Get-Partition -DiskNumber $_.Number |  Where-Object {$_.DriveLetter} | Select-Object -First 1 -ExpandProperty DriveLetter) | Where-Object {
			$_ -match "sequent"  # Nur Zeilen mit "sequent" (sequentielle Geschwindigkeit) anzeigen
		}
	}
} Else {
	# Keine USB-Laufwerke gefunden
	Write-Host "`nKein USB-Laufwerk gefunden."
}

# Hilfetext und Beenden anzeigen
Write-Host "`n`n" $Hilfe
Write-Host "`nEnter zum Beenden"
Read-Host