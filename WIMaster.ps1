#Requires -RunAsAdministrator
#Requires -Version 3.0

# WIMaster - Windows System Backup Tool
# This script may be flagged by antivirus software because it:
# - Requires administrator privileges
# - Creates system backups
# This is normal behavior for a backup tool.

# Zeichenkodierung fuer korrekte Umlaut-Darstellung setzen
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Parameter fuer unbeaufsichtigten Modus pruefen
$Unattended = $false

# Pruefe Kommandozeilenargumente
foreach ($arg in $args) {
    switch ($arg) {
        "-Unattended" { $Unattended = $true }
    }
}

<#
.SYNOPSIS
  WIMaster - Windows System-Backup mit Netzwerk-Support
.DESCRIPTION
  Erweiterte Version von WIMaster mit Netzwerk-Backup-Funktionalitaet und unbeaufsichtigtem Modus.
  Basierend auf dem urspruenglichen c't-WIMage von Axel Vahldiek.
.NOTES
  Version:        0.1
  Original Autor: Axel Vahldiek <axv@ct.de> (c't-WIMage)
  Weiterentwicklung: Joachim Mild <joe@devops-geek.net>
  Erweiterungen:  Netzwerk-Support, unbeaufsichtigter Modus, verbesserte Konfiguration
  Erstellungsdatum: 2025-01-27
 #>

# Hilfetext fuer Benutzer
$Hilfe = "WIMaster - Windows System Backup Tool`r`nEntwickelt von Joachim Mild <joe@devops-geek.net>`r`nBasierend auf c't-WIMage von Axel Vahldiek`r`n`r`n"

##############################
# Dateien, Ordner, Variablen #
##############################

# Ordner-Definitionen 

# Hauptverzeichnisse definieren
$Source = Join-Path (Split-Path $PSScriptRoot) "Sources"; If (-Not (Test-Path $Source)) { New-Item -Path $Source -ItemType Directory | Out-Null}
$ScratchDir = Join-Path $Source "\WIMaster_Scratch"

# Von WIMaster-Setup benötigte Dateien
$ExclusionsJson = Join-Path $PSScriptRoot "\WIMaster_Exclusions.json"  # Ausschlussliste (JSON)
$Icon = Join-Path $PSScriptRoot "\WIMaster_Ico.ico"         # Programm-Icon
$eicfg = Join-Path $Source "\ei.cfg"                        # Windows Setup-Konfiguration
$ShadowExe = Join-Path $PSScriptRoot "\vshadow.exe"          # Volume Shadow Copy Service
$Dism = Join-Path $env:windir "\system32\Dism.exe"          # Deployment Image Servicing and Management

# Konfigurationsdatei-Pfad
$ConfigFile = Join-Path $PSScriptRoot "WIMaster-Config.json"

# Netzwerk-Pfad-Variablen (aus Konfiguration geladen)
$Script:NetworkPath = ""           # UNC-Pfad fuer Netzwerk-Backup
$Script:NetworkUser = ""           # Benutzername fuer Netzwerk-Zugriff
$Script:NetworkPassword = ""       # Passwort fuer Netzwerk-Zugriff (entschluesselt)
$Script:EnableNetworkBackup = $false  # Netzwerk-Backup aktiviert/deaktiviert

# Backup-Speicherort-Auswahl
$Script:SelectedBackupPath = $null  # Vom Benutzer ausgewaehlter Backup-Pfad
$Script:DefaultBackupPath = ""      # Standard-Backup-Pfad aus Konfiguration


# Temporaere Dateien
$IniTemp = Join-Path $Source "\WIMaster_IniTemp.ini"           # Temporaere Ausschlussliste
$ShadowTemp = Join-Path $Source "\WIMaster_ShadowTemp.ini"     # Schattenkopie-Temp-Datei
$ShadowExeTemp = Join-Path $Source "\WIMaster_ShadowExeTemp.Ini" # Schattenkopie-Executable-Temp
$DismTemp = Join-Path $Source "\WIMaster_DismTemp.txt" ; If (Test-Path $DismTemp) {Remove-Item -Path $DismTemp}  # DISM-Ausgabe-Temp

# Protokoll-Dateien
$Liste = Join-Path (Split-Path $PSScriptRoot) "\WIMaster_Backupliste.txt"  # Backup-Liste
$LogREEnable = Join-Path $Source "\WIMaster_Log_RE_Enable.txt"           # Windows RE Aktivierung
$LogREDisable = Join-Path $Source "\WIMaster_Log_RE_Disable.txt"         # Windows RE Deaktivierung
$LogFile = Join-Path $Source "\WIMaster_Log_DISM.txt"                    # DISM-Protokoll
$LogLevel = "3"  # Protokollstufe (0=Fehler, 1=Warnung, 2=Info, 3=Debug)

# Backup-Optionen (aus Konfiguration geladen)
$Script:Shutdown = $False           # Nach Backup herunterfahren
$Script:NoWindowsold = $False       # Windows.old-Ordner ausschliessen
## Defender-Option entfernt

# System-Variablen
$Build = [int](Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild  # Windows Build-Nummer
$WinVer = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption -replace '^Microsoft\s+', ''  # Windows-Version
$Version = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion  # Windows-Anzeigeversion
$PCName = $Env:COMPUTERNAME  # Computer-Name
$Now = Get-Date -Format "dd.MM.yy HH:mm"  # Aktueller Zeitstempel
$ImageName = "$Now $PCName $WinVer $Version $Build"  # Image-Name mit Zeitstempel und Systeminfo

# Konfiguration wird nach Funktionsdefinitionen geladen

#######################
# GUI-Fenster vorbereiten # 
#######################

# Windows Forms und Drawing Assemblies laden
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Basisgroessen fuer GUI-Elemente
$Gap = 14        # Abstand zwischen Elementen
$FontSize = 12   # Grundschriftgroesse
$Width = 55      # Fensterbreite in Gap-Einheiten
$Height = 49     # Fensterhoehe in Gap-Einheiten

# Schriftarten definieren
$FontName = "Segoe UI"           # Standard-Schriftart
$FontNameBold = "Segoe UI Semibold"  # Fettschrift

# GUI-Groessen an Bildschirmaufloesung anpassen
$Ratio = [System.Math]::Max((($Width * $Gap) / ([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width)), (($Height * $Gap) / ([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height)))
If ($Ratio -gt 1) {
	$Gap = ($Gap / $Ratio)                    # Abstaende verkleinern
	$FontSize = [Math]::Round($FontSize / $Ratio)  # Schriftgroesse verkleinern
}

# Abgeleitete GUI-Groessen berechnen
$FontHeadSize = ($FontSize + 4)      # Ueberschrift-Schriftgroesse
$FontButtonSize = ($FontSize - 2)    # Button-Schriftgroesse

$WindowWidth = ($Width * $Gap)       # Fensterbreite in Pixeln
$WindowHeight = ($Height * $Gap)     # Fensterhoehe in Pixeln

$ButtonWidth = (8 * $Gap)            # Button-Breite
$ButtonHeight = (3 * $Gap)           # Button-Hoehe

#######################
# Dialog-Funktionen fuer Benutzer-Hinweise #
#######################

# Funktion fuer Nachrichten-Dialoge
Function Message {
	$Message = New-Object System.Windows.Forms.Form
	$Message.StartPosition = 'CenterScreen'
	If (Test-Path $Icon) {$Message.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)}
	$Message.Font = New-Object System.Drawing.Font($FontName, ($FontHeadSize))
	$Message.MinimumSize = New-Object System.Drawing.Size($Gap, $Gap)
	$Message.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
	$Message.Text = $HinweisArt
	$Message.AutoSizeMode = 'GrowAndShrink'
	$Message.AutoSize = $true
	$Message.Padding = New-Object System.Windows.Forms.Padding($Gap)
	$Message.ControlBox = $False
	
	$MessageText = New-Object System.Windows.Forms.LinkLabel
	$MessageText.Location = New-Object System.Drawing.Point($Gap, (2 * $Gap))
	$MessageText.MinimumSize  = New-Object System.Drawing.Size($Gap, $Gap)
	$MessageText.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
	$MessageText.Font = New-Object System.Drawing.Font($FontName, $FontSize)
	$MessageText.Text = $Hinweis.Trim()
	$MessageText.LinkArea = New-Object System.Windows.Forms.LinkArea($Hinweis.IndexOf("joe@devops-geek.net"), 19)
	$MessageText.Add_LinkClicked({Start-Process "mailto:joe@devops-geek.net"})
	$MessageText.AutoSize = $true
	$Message.Controls.Add($MessageText)
	
	$MessageOKButton = New-Object System.Windows.Forms.Button
	$MessageOKButton.Location = New-Object System.Drawing.Point(($Gap + $MessageText.Width - $ButtonWidth), ($Gap + $MessageText.Height + $ButtonHeight))
	$MessageOKButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
	$MessageOKButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
	$MessageOKButton.Text = 'OK'
	If ($OKText) {$MessageOKButton.Text = $OKText}
	$MessageOKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	
	$MessageCancelButton = New-Object System.Windows.Forms.Button
	$MessageCancelButton.Location = New-Object System.Drawing.Point(($Gap + $MessageText.Width - $ButtonWidth - $Gap - $ButtonWidth),($Gap + $MessageText.Height + $ButtonHeight))
	$MessageCancelButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
	$MessageCancelButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
	$MessageCancelButton.Text = 'Abbrechen'
	$MessageCancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	
	$MessageDetailButton = New-Object System.Windows.Forms.Button
	$MessageDetailButton.Location = New-Object System.Drawing.Point(($Gap),($Gap + $MessageText.Height + $ButtonHeight))
	$MessageDetailButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
	$MessageDetailButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
	$MessageDetailButton.Text = 'Dateien anzeigen'
	$MessageDetailButton.Add_Click({
		
		# Fenster für Liste der Cloud-Platzhalter
		
		$DetailWindow = New-Object System.Windows.Forms.Form
		$DetailWindow.Text = "Liste der Cloud-Platzhalter"
		$DetailWindow.Size = New-Object System.Drawing.Size((54 * $Gap), (41 * $Gap))
		$DetailWindow.StartPosition = 'CenterScreen'
		$DetailWindow.Font = New-Object System.Drawing.Font($FontName, $FontSize)
		$DetailWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)
		$DetailWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
		$DetailWindow.ControlBox = $False
		
		$DetailText = New-Object System.Windows.Forms.Label
		$DetailText.Location = New-Object System.Drawing.Point($Gap, $Gap)
		$DetailText.Size = New-Object System.Drawing.Size(($DetailWindow.Width), (5 * $Gap))
		$DetailText.Font = New-Object System.Drawing.Font($FontName, $FontSize)
		$DetailText.Text = "Liste der Cloud-Platzhalter.`r`n`r`nWIMaster muss die dazugehoerigen Dateien herunterladen, um Windows sichern zu koennen."
			
		$DetailList = New-Object System.Windows.Forms.RichTextBox
		$DetailList.Location = New-Object System.Drawing.Point($Gap, ($DetailText.Bottom + $Gap))
		$DetailList.Size = New-Object System.Drawing.Size(($DetailWindow.Width - (4 * $Gap)), (26 * $Gap))
		$DetailList.Multiline = $true
		$DetailList.ScrollBars =  [System.Windows.Forms.ScrollBars]::Both
		$DetailList.Font = New-Object System.Drawing.Font($FontName, ($FontSize - 1))
		$Script:CloudFiles | ForEach-Object {$CloudListe += " " + $_.FullName + "`r`n"}
		$DetailList.WordWrap = $False
		$DetailList.Text = $CloudListe
				
		$DetailNextButton = New-Object System.Windows.Forms.Button
		$DetailNextButton.Location = New-Object System.Drawing.Point(($DetailWindow.Width - $ButtonWidth - (2 * $Gap)), ($DetailWindow.Bottom - $ButtonHeight - (4 * $Gap)))
		$DetailNextButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
		$DetailNextButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
		$DetailNextButton.Text = "OK"
		$DetailNextButton.Add_Click({[System.Windows.Forms.Form]::ActiveForm.Close()})
		
		$DetailWindow.Controls.Add($DetailText)
		$DetailWindow.Controls.Add($DetailList)
		$DetailWindow.Controls.Add($DetailNextButton)
		$DetailWindow.Show() | Out-Null
		
	})		
	
	$Message.Controls.Add($MessageOKButton) 
	If ($Cancel) {$Message.Controls.Add($MessageCancelButton)}
	If ($ExitOnCancel) {$MessageCancelButton.Add_Click({[environment]::exit(0)})}
	If ($ExitOnOK) {$MessageOKButton.Add_Click({[environment]::exit(0)})}
	If ($Sure) {$MessageOKButton.Add_Click({$StartWindow.close()})}
	If ($Detail) {$Message.Controls.Add($MessageDetailButton)}
	$Message.ShowDialog() | Out-Null
}

# Funktion fuer kurze Nachrichten-Dialoge
Function ShortMessage {
		
	$ShortWindow = New-Object System.Windows.Forms.Form
	$ShortWindow.Text = $HinweisArt
	$ShortWindow.Size = New-Object System.Drawing.Size((28 * $Gap), (8 * $Gap))
	$ShortWindow.StartPosition = 'CenterScreen'
	If (Test-Path $Icon) {$ShortWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)}
	$ShortWindow.Font = New-Object System.Drawing.Font($FontName, ($FontHeadSize))
	$ShortWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
	$ShortWindow.ControlBox = $False
			
	$ShortText = New-Object System.Windows.Forms.Label
	$ShortText.Text = $Hinweis
	$ShortText.Location = New-Object System.Drawing.Point($Gap, $Gap)
	$ShortText.Size  = New-Object System.Drawing.Size(($ShortWindow.Width - (2 * $Gap)), ($ShortWindow.Height - (2 * $Gap)))
	$ShortText.Font = New-Object System.Drawing.Font($FontName, $FontSize)
			
	$ShortWindow.Controls.Add($ShortText)
	$ShortWindow.Show()
	$ShortWindow.Refresh()
	
	Return $ShortWindow
}
	

######################
# Weitere Hilfsfunktionen #
######################

# Funktion zum Entschluesseln von Passwoertern mit Windows DPAPI
Function Decrypt-Password {
	param([string]$EncryptedPassword)
	
	# Leere verschluesselte Passwoerter zurueckgeben
	If ([string]::IsNullOrEmpty($EncryptedPassword)) {
		Return ""
	}
	
	Try {
		# Verschluesseltes Passwort entschluesseln
		$SecureString = ConvertTo-SecureString -String $EncryptedPassword
		$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
		$PlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
		Return $PlainTextPassword
	} Catch {
		Write-Error "Fehler beim Entschluesseln des Passworts: $($_.Exception.Message)"
		Return ""
	}
}

# Funktion zum Lesen der Konfiguration aus der JSON-Datei
Function Read-Config {
	# Pruefen ob Konfigurationsdatei existiert
	If (-not (Test-Path $ConfigFile)) {
		Write-Warning "Konfigurationsdatei nicht gefunden: $ConfigFile"
		Return $null
	}
	
	Try {
		# JSON-Datei lesen und parsen
		$JsonContent = Get-Content $ConfigFile -Raw -Encoding UTF8
		$Config = $JsonContent | ConvertFrom-Json
		Return $Config
	} Catch {
		Write-Error "Fehler beim Lesen der JSON-Konfigurationsdatei: $($_.Exception.Message)"
		Return $null
	}
}

# Funktion zum Laden der Konfiguration
Function Load-Config {
	$Config = Read-Config
	
	If ($Config -ne $null) {
		# Netzwerk-Einstellungen laden
		If ($Config.Network) {
			$Script:EnableNetworkBackup = $Config.Network.EnableNetworkBackup
			$Script:NetworkPath = $Config.Network.NetworkPath
			$Script:NetworkUser = $Config.Network.NetworkUser
			
			# Passwort entschluesseln
			$EncryptedPassword = $Config.Network.NetworkPassword
			$Script:NetworkPassword = Decrypt-Password $EncryptedPassword
		}
		
		# Backup-Einstellungen laden
		If ($Config.Backup) {
			$Script:Shutdown = $Config.Backup.DefaultShutdown
			$Script:NoWindowsold = $Config.Backup.DefaultNoWindowsold
			$Script:DefaultBackupPath = $Config.Backup.DefaultBackupPath
		}
		
		# Erweiterte Einstellungen laden
		If ($Config.Advanced) {
			$Script:LogLevel = $Config.Advanced.LogLevel
		}
	}
}

# Konfiguration jetzt laden, da Funktionen definiert sind
Load-Config

# Funktionen fuer Ausgabe (muessen vor der Verwendung definiert werden)
function Ausgabe {
	param ([String]$JobAusgabeText, [Switch]$Replace)
	If ($Unattended) {
		Write-Host $JobAusgabeText
	} Else {
		If ($Replace) {
			$JobTicker.rtf = $JobSaveTickerText
			$JobTicker.AppendText("`r`n$JobAusgabeText")
			$JobTicker.SelectionStart = $JobTicker.Text.Length
			$JobTicker.ScrollToCaret()
			} else {
			$JobTicker.AppendText("${JobAusgabeText}`r`n")
			$JobWindow.Refresh()
		}
	}
}

function Fettdruck {
    param ([String]$JobFettText)
    If ($Unattended) {
        Write-Host $JobFettText -ForegroundColor Yellow
    } Else {
        $StartPos = $JobTicker.Text.Length
        $JobTicker.AppendText($JobFettText)
        $EndPos = $JobTicker.Text.Length
        $JobTicker.Select($StartPos, $EndPos - $StartPos)
        $JobTicker.SelectionFont = New-Object System.Drawing.Font($JobTicker.Font, [System.Drawing.FontStyle]::Bold)
        $JobTicker.Select($EndPos, 0)
        $JobTicker.ScrollToCaret()
    }
}

# Funktion zum Testen der Backup-Pfad-Erreichbarkeit
Function TestBackupPath {
	$TestPath = If ($Script:SelectedBackupPath) { $Script:SelectedBackupPath } ElseIf (-not [string]::IsNullOrEmpty($Script:DefaultBackupPath)) { $Script:DefaultBackupPath } Else { $Script:NetworkPath }
	
	Try {
		# For network paths, attempt to authenticate first
		If ($TestPath -like "\\*") {
			# Try to authenticate with network credentials
			Try {
				# Test path with credentials
				$PathTest = Test-Path $TestPath -ErrorAction Stop
				
				# If still not accessible, try to map temporarily for testing
				If (-not $PathTest) {
					$TempDrive = "Z:"
					# Remove any existing mapping
					net use $TempDrive /delete /y 2>$null
					# Map with credentials
					net use $TempDrive $TestPath /user:$Script:NetworkUser $Script:NetworkPassword | Out-Null
					If ($LASTEXITCODE -eq 0) {
						$PathTest = Test-Path $TempDrive -ErrorAction Stop
						# Clean up temporary mapping
						net use $TempDrive /delete /y 2>$null
					}
				}
			} Catch {
				# If credential authentication fails, try without credentials
				$PathTest = Test-Path $TestPath -ErrorAction Stop
			}
		} Else {
			# For local paths, just test directly
			$PathTest = Test-Path $TestPath -ErrorAction Stop
		}
		
		If ($PathTest) {
			If ($Unattended) {
				Write-Host "Backup path is accessible: $TestPath"
			}
			Return $True
		} Else {
			Throw "Backup-Pfad ist nicht erreichbar"
		}
	} Catch {
		If ($Unattended) {
			Write-Host "ERROR: Backup path not accessible: $TestPath"
			Write-Host "Error: $($_.Exception.Message)"
			[environment]::exit(1)
		} Else {
			$HinweisArt = "Pfadfehler"
			$Hinweis = "Fehler beim Verbinden mit dem Backup-Pfad:`r`n$($_.Exception.Message)`r`n`r`nBitte ueberpruefen Sie:`r`n- Backup-Pfad ist korrekt: $TestPath`r`n- Netzwerkverbindung ist verfuegbar`r`n- Benutzername und Passwort sind korrekt`r`n- Ausreichend Speicherplatz vorhanden"
			$Cancel = $False
			$ExitOnOK = $True
			$Sure = $False
			Message
		}
		Return $False
	}
}

# Funktion zum Abrufen verfuegbarer Laufwerke fuer Backup
Function GetAvailableDrives {
	$Drives = @()
	
	# Get local fixed and removable drives (C: ausblenden)
	Get-WmiObject -Class Win32_LogicalDisk | Where-Object { ($_.DriveType -in 2,3) -and $_.Size -gt 0 -and $_.DeviceID -ne "C:" } | ForEach-Object {
		$FreeSpaceGB = [math]::Round($_.FreeSpace / 1GB, 1)
		$TotalSpaceGB = [math]::Round($_.Size / 1GB, 1)
		$Drives += [PSCustomObject]@{
			Drive = $_.DeviceID
			Label = $_.VolumeName
			FreeSpace = $FreeSpaceGB
			TotalSpace = $TotalSpaceGB
			Type = $(if ($_.DriveType -eq 2) { "Removable Drive" } else { "Local Drive" })
			Path = $_.DeviceID
		}
	}
	
	# Add network drive option only if network backup is enabled
	If ($Script:EnableNetworkBackup -and -not [string]::IsNullOrEmpty($Script:NetworkPath)) {
		$Drives += [PSCustomObject]@{
			Drive = "Network"
			Label = "Network Share"
			FreeSpace = "Unknown"
			TotalSpace = "Unknown"
			Type = "Network Drive"
			Path = $Script:NetworkPath
		}
	}
	
	# Mark default backup path if set
	If (-not [string]::IsNullOrEmpty($Script:DefaultBackupPath)) {
		$Drives | ForEach-Object {
			If ($_.Path -eq $Script:DefaultBackupPath) {
				$_.Label = $_.Label + " (Standard)"
			}
		}
	}
	
	Return $Drives
}


# Funktion zum Herstellen der Netzwerkverbindung fuer UNC-Pfade
Function EstablishNetworkConnection {
	$BackupPath = If ($Script:SelectedBackupPath) { $Script:SelectedBackupPath } ElseIf (-not [string]::IsNullOrEmpty($Script:DefaultBackupPath)) { $Script:DefaultBackupPath } Else { $Script:NetworkPath }
	
	# Only attempt network connection for UNC paths
	If ($BackupPath -like "\\*") {
		Try {
			# Try to access the path directly first
			$PathTest = Test-Path $BackupPath -ErrorAction Stop
			
			If (-not $PathTest) {
				# If direct access fails, try to establish connection with credentials
				Ausgabe "   Verbinde mit Netzwerkpfad: $BackupPath"
				
				# Try to map the network path temporarily
				$TempDrive = "Z:"
				# Remove any existing mapping
				net use $TempDrive /delete /y 2>$null
				
				# Map with credentials
				net use $TempDrive $BackupPath /user:$Script:NetworkUser $Script:NetworkPassword /persistent:no | Out-Null
				
				If ($LASTEXITCODE -eq 0) {
					Ausgabe "   Netzwerkverbindung erfolgreich hergestellt"
					# Update the backup path to use the mapped drive
					$Script:SelectedBackupPath = $TempDrive
				} Else {
					Throw "Fehler beim Verbinden mit Netzwerkpfad (ExitCode $LASTEXITCODE)"
				}
			} Else {
				Ausgabe "   Netzwerkpfad bereits erreichbar: $BackupPath"
			}
		} Catch {
			Throw "Netzwerkverbindung fehlgeschlagen: $($_.Exception.Message)"
		}
	}
}

# Funktion zum Erstellen von WIM-Dateipfaden mit Computername und Datum
Function GetWimPaths {
	$DateString = Get-Date -Format "yyyy-MM-dd_HH-mm"
	$WimFileName = "Install_${PCName}_${DateString}.wim"
	$FreshWimFileName = "Fresh_${PCName}_${DateString}.wim"
	
	# Use selected backup path, default backup path, or network path
	$BackupPath = If ($Script:SelectedBackupPath) { $Script:SelectedBackupPath } ElseIf (-not [string]::IsNullOrEmpty($Script:DefaultBackupPath)) { $Script:DefaultBackupPath } Else { $Script:NetworkPath }
	
	$Script:Wim = Join-Path $BackupPath $WimFileName
	$Script:FreshWim = Join-Path $BackupPath $FreshWimFileName
	
	Write-Host "WIM file paths created:"
	Write-Host "Install WIM: $Script:Wim"
	Write-Host "Fresh WIM: $Script:FreshWim"
}

# Funktion zum Suchen und Herunterladen von Cloud-Platzhaltern
Function CloudLoad {
	If ($Unattended) {
		Write-Host "Checking for cloud placeholders..."
		$Script:CloudFiles = Get-ChildItem -Recurse -Path "${Env:SystemDrive}\" -Attributes Sparse+Offline -Force -ErrorAction SilentlyContinue
		If ($Script:CloudFiles) {
			$CloudSize = ([math]::Round(($Script:CloudFiles | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum) / 1MB, 1))
			Write-Host "Found $($Script:CloudFiles.Count) cloud placeholder files ($CloudSize MB) - downloading..."
			
			If (-not (Test-Connection heise.de -Quiet)) {
				Write-Host "ERROR: No internet connection found. Exiting."
				[environment]::exit(1)
			}
			
			$Script:CloudFiles | ForEach-Object {
				try {			
					$File = $_.Fullname
					Write-Host "Downloading $File"
					Get-Content $File -ErrorAction Stop | Out-Null
				} catch {
					Write-Host "ERROR: Failed to download $File - $($_.Exception.Message)"
					[environment]::exit(1)
				}
			}
			Write-Host "Cloud files downloaded successfully."
		} Else {
			Write-Host "No cloud placeholders found."
		}
	} Else {
		$Hinweis = "Bitte warten, suche nach Cloud-Platzhaltern ..."
		$HinweisArt = "Pruefe ..."
		$Show = ShortMessage
		$Script:CloudFiles = Get-ChildItem -Recurse -Path "${Env:SystemDrive}\" -Attributes Sparse+Offline -Force -ErrorAction SilentlyContinue
		$Show.Close()
		If ($Script:CloudFiles) {
			$CloudSize = ([math]::Round(($Script:CloudFiles | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum) / 1MB, 1))
			$HinweisArt = "Cloud-Platzhalter gefunden"
			$Hinweis = "Achtung: Cloud-Platzhalter gefunden!`r`n`r`nDiese symbolisieren Dateien, die nur auf dem Server eines Cloud-Anbieters liegen,`r`naber nicht auf dem internen Datentraeger.`r`n`r`nWIMaster muss die dazugehoerigen Dateien herunterladen,`r`num Windows sichern zu koennen.`r`n`r`nHerunterzuladen sind " + $($Script:CloudFiles.Count) + " Dateien mit einer Gesamtgroesse von " + $CloudSize + " MB`r`n"
			$Hinweis = "${Hinweis}`r`n`r`n$Hilfe"
			$Cancel = $True 
			$Detail = $True
			$ExitOnCancel = $True
			$ExitOnOK = $False
			$OKText = "Herunterladen und fortsetzen"		
			$Sure = $False
			Message
			$HinweisArt = "Lade ..."
			$Hinweis = "Bitte warten, lade Dateien aus der Cloud ..."
			$Show = ShortMessage
					
			If (-not (Test-Connection heise.de -Quiet)) {
				$Show.Close()
				$HinweisArt = "Keine Online-Verbindung gefunden."
				$Hinweis = "Bitte verbinden Sie den PC mit dem Internet.`r`n`r`nStarten Sie WIMaster anschliessend erneut."
				$Hinweis = "${Hinweis}`r`n`r`n$Hilfe"
				$Cancel = $False 
				$Detail = $False
				$ExitOnCancel = $False
				$ExitOnOK = $True
				$OKText = "WIMaster beenden"
				$Sure = $False
				Message
			}
			$Script:CloudFiles | ForEach-Object {
			try {			
				$File = $_.Fullname
				Write-Host "Lade " $File
				Get-Content $File -ErrorAction Stop | Out-Null
				} catch {
				$Show.Close()
				$HinweisArt = "Download-Problem"
				$Hinweis = "Fehler beim Download von " + $File + "`r`n`r`nWindows meldet:`r`n$($_.Exception.Message)`r`n`r`nPruefen Sie die Verbindung zum Cloud-Anbieter. Stellen Sie sicher, dass derzeit nichts`r`nsynchronisiert wird. Laden Sie die noetigen Dateien notfalls von Hand herunter.`r`n`r`nStarten Sie WIMaster anschliessend erneut."
				$Hinweis = "${Hinweis}`r`n`r`n$Hilfe"
				$Cancel = $False 
				$Detail = $False
				$ExitOnCancel = $False
				$ExitOnOK = $True
				$OKText = "WIMaster beenden"			
				$Sure = $False
				Message
				}
			}
			$Show.Close()
		}
	}
}


# Funktionen fuer RunOnce-Schluessel zum Reaktivieren von Windows RE
Function RunOnceCreate {
	Ausgabe "   RunOnce-Eintrag in die Registry schreiben"
	New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "enablewinre" -Value "reagentc /enable" -PropertyType "String" -Force >$null
}

Function RunOnceDelete {
	Ausgabe "   RunOnce-Eintrag wieder entfernen"
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "enablewinre" -Force >$null
}

# Funktionen fuer temporaere INI-Datei mit Ausnahmen
Function IniTempCreate {
	IniTempDelete
	# JSON-Datei laden und in INI-Format konvertieren
	$JsonData = Get-Content -Path $ExclusionsJson -Raw -Encoding UTF8 | ConvertFrom-Json
	
	# INI-Format erstellen
	$IniData = @()
	$IniData += "[ExclusionList]"
	$IniData += $JsonData.ExclusionList
	$IniData += ""
	$IniData += "[CompressionExclusionList]"
	$IniData += $JsonData.CompressionExclusionList
	
	# Windows.old hinzufuegen falls gewuenscht
	If ($Script:NoWindowsold) {
		$IniData[1] += "`n\Windows.old"
	}
	
	Set-Content -Path $IniTemp -Value $IniData -Encoding ASCII
}

Function IniTempDelete {
	If (Test-Path $IniTemp) {Remove-Item -Path $IniTemp}
}

# Funktionen fuer Schattenkopie-Erstellung
Function ShadowTempCreate {
	Ausgabe "   Schattenkopie erzeugen"
	ShadowTempDelete
	Start-Process $ShadowExe -ArgumentList "-p -script=${ShadowExeTemp} ${env:SystemDrive}" -NoNewWindow -Wait -RedirectStandardOutput "nul"
	$ShadowID = ((Get-Content ${ShadowExeTemp} | Select-String "SET SHADOW_ID").Line -split "=")[-1].Trim()
	$Script:ShadowPath = ((Get-Content ${ShadowExeTemp} | Select-String "SET SHADOW_DEVICE").Line -split "=")[-1].Trim()
	$ShadowID | Out-File $ShadowTemp ; Remove-Item $ShadowExeTemp
}

function ShadowTempDelete {
	If (Test-Path $ShadowTemp) {
		$ShadowID = Get-Content $ShadowTemp
		vssadmin delete shadows /Shadow=$ShadowID /quiet *> $null
		Remove-Item $ShadowTemp
	}
}

# Funktionen fuer DISM-Ausnahmen im Windows Defender
Function DismExclusionCreate {
	If (Get-Process MsMpEng -ErrorAction SilentlyContinue) {
		Ausgabe "   DISM-Ausnahme in Defender schreiben"
		Add-MpPreference -exclusionProcess $Dism 2>$null
	}
}

Function DismExclusionDelete {
	Ausgabe "   DISM-Ausnahme in Defender wieder entfernen"
	Remove-MpPreference -exclusionProcess $Dism 2>$null
}

# Defender-Funktionen entfernt

# Funktionen zum Erstellen/Loeschen des Scratch-Verzeichnisses
Function ScratchDirCreate {
	ScratchDirDelete
	$Scratch = $null
	If ((Get-PSDrive -Name $Env:SystemDrive[0]).Free -lt 20GB) {
		New-Item -Path $ScratchDir -ItemType Directory -Force
		$Scratch = "/ScratchDir:$ScratchDir"
	}
}

Function ScratchDirDelete {
	If (Test-Path $ScratchDir) {Remove-Item -Path $ScratchDir}
}

# Funktionen zum Deaktivieren/Aktivieren von Windows RE (Recovery Environment)
Function REDisable {
	Start-Process reagentc -ArgumentList '/disable' -NoNewWindow -Wait -RedirectStandardOutput ".\NUL" -RedirectStandardError $LogREDisable -ErrorAction SilentlyContinue *> $null
}
	
Function REEnable {
	Start-Process reagentc -ArgumentList '/enable' -NoNewWindow -Wait -RedirectStandardOutput ".\NUL" -RedirectStandardError $LogREEnable -ErrorAction SilentlyContinue *> $null
}

########################
# System-Anforderungen pruefen #
########################

$Hinweis = $Null

# Vollstaendigkeit der erforderlichen Dateien pruefen
$Missing = ForEach ($Item in @($Icon, $eicfg, $ShadowExe)) {
	If (-not (Test-Path $Item)) {Split-Path $Item -Leaf}}
If ($Missing) {$Hinweis = "Es fehlen erforderliche Dateien: " + ($Missing -join ', ')}
	
# System-Anforderungen pruefen
$Anforderung = "Skript funktioniert nur unter 64-Bit-Windows."
	If (-not [System.Environment]::Is64BitOperatingSystem) {If ($Hinweis) {$Hinweis = "${Hinweis}`r`n`r`n$Anforderung"} Else {$Hinweis = $Anforderung}}
	
$Anforderung = "Skript funktioniert nur mit x64-Prozessoren."
	If (-not ([System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE") -eq "AMD64")) {If ($Hinweis) {$Hinweis = "${Hinweis}`r`n`r`n$Anforderung"} Else {$Hinweis = $Anforderung}}
		
$Anforderung = "Skript erfordert Windows 10/11 Version 20H2 (Build 19042) oder neuer.`r`nIhre Version: $WinVer $Version (Build $Build)."
	If ($Build -lt 19042) {If ($Hinweis) {$Hinweis = "${Hinweis}`r`n`r`n$Anforderung"} Else {$Hinweis = $Anforderung}}
	
$Anforderung = "Es darf keine WSL-1-Distribution installiert sein."
	If (get-ItemProperty -path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss\*" -name flags -ErrorAction SilentlyContinue | Select-Object -Property flags | Where-Object {$_.flags -eq 7}) {If ($Hinweis) {$Hinweis = "${Hinweis}`r`n`r`n$Anforderung"} Else {$Hinweis = $Anforderung}}

If ($Hinweis){ 
	$HinweisArt = "Anforderung nicht erfuellt"
	$Hinweis = "${Hinweis}`r`n`r`n$Hilfe"
	$Cancel = $False
	$ExitOnOK = $True
	$Sure = $False
	Message
}

# Auf zusaetzliche Virenscanner pruefen
$Hinweis = $Null

# Alle installierten Antivirus-Produkte abrufen
$AV = (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct)
$AVCount = ($AV).Count
$AV | ForEach-Object {
	$AVExe = [Environment]::ExpandEnvironmentVariables($_.pathToSignedReportingExe)
	$AVPublisher = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$AVExe")
	# Microsoft Defender nicht als zusaetzlicher Scanner zaehlen
	If ($AVPublisher.companyname -Match "Microsoft") {$AVCount = $AVCount - 1} ELSE {$AVFund = $AVFund += "`n" + $_.displayname + "`n"}
}
If ($AVCount -gt 0) {$Hinweis = "Nicht-Microsoft-Virenscanner gefunden: " + "`n" + $AVFund + "`nWir empfehlen, Virenscanner vor dem Sichern voruebergehend zu deaktivieren.`nDas beschleunigt das Sichern enorm und vermeidet Probleme."}

If ($Hinweis){ 
	$HinweisArt = "Zusaetzlicher Virenscanner gefunden"
	$Hinweis = "${Hinweis}`r`n`r`n$Hilfe"
	$Detail = $False
	$Cancel = $True
	$ExitOnCancel = $True
	$OKText = "Alles klar, weitermachen"			
	$ExitOnOK = $False
	$Sure = $False
	Message
}


#####################
# Willkommen-Dialog und GUI-Setup #
#####################

$WindowTitle = "WIMaster v0.1"

# Unbeaufsichtigter Modus oder GUI-Modus
If ($Unattended) {
	Write-Host "Starte WIMaster im unbeaufsichtigten Modus..."
	$Script:Continue = $True
	# Use configuration values instead of hardcoded defaults
	# $Script:Shutdown und $Script:NoWindowsold sind bereits geladen
	Write-Host "Konfiguration geladen:"
	Write-Host "  Shutdown nach Backup: $Script:Shutdown"
	Write-Host "  Windows.old ausschliessen: $Script:NoWindowsold"
	
	# Automatisch den Standard-Backup-Pfad verwenden falls gesetzt
	If (-not [string]::IsNullOrEmpty($Script:DefaultBackupPath)) {
		$Script:SelectedBackupPath = $Script:DefaultBackupPath
		Write-Host "Verwende Standard-Backup-Pfad: $Script:DefaultBackupPath"
	}
} Else {
	$Script:Continue = $False
$StartWindow = New-Object System.Windows.Forms.Form
$StartWindow.Text = $WindowTitle
$StartWindow.Size = New-Object System.Drawing.Size($WindowWidth, ($WindowHeight))
$StartWindow.StartPosition = 'CenterScreen'
$StartWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)
$StartWindow.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$StartWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$StartWindow.ControlBox = $False

## Logo im Hauptfenster entfernt (wird im Info-Popup gezeigt)

$StartTitle = New-Object System.Windows.Forms.Label
$StartTitle.Location = New-Object System.Drawing.Point($Gap, (2 * $Gap))
$StartTitle.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)),(4 * $Gap))
$StartTitle.Font = New-Object System.Drawing.Font($FontNameBold, ($FontHeadSize * 2.4))
$StartTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$StartTitle.Text = "WIMaster"

$StartText = New-Object System.Windows.Forms.Label
$StartText.Location = New-Object System.Drawing.Point($Gap, (($StartTitle.Bottom + (1 * $Gap))))
$StartText.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)), (3 * $Gap))
$StartText.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$StartText.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$StartText.Text = "Empfehlung: Schliessen Sie vor dem Sichern alle anderen Anwendungen."

## StartHelp entfernt (nicht mehr verwendet)

# Kompakter integrierter Bereich: Optionen und Speicherort

$OptionsHeader = New-Object System.Windows.Forms.Label
$OptionsHeader.Location = New-Object System.Drawing.Point($Gap, ($StartText.Bottom + $Gap))
$OptionsHeader.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)), (2 * $Gap))
$OptionsHeader.Font = New-Object System.Drawing.Font($FontNameBold, $FontHeadSize)
$OptionsHeader.Text = "Optionen"

$OptionCheck1 = New-Object System.Windows.Forms.CheckBox
$OptionCheck1.Location = New-Object System.Drawing.Point(($Gap * 2), ($OptionsHeader.Bottom + $Gap))
$OptionCheck1.Size = New-Object System.Drawing.Size(($WindowWidth - (4 * $Gap)), (3 * $Gap))
$OptionCheck1.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$OptionCheck1.Text = "Herunterfahren nach Abschluss der Sicherung."
$OptionCheck1.Checked = $Script:Shutdown
$OptionCheck1.Add_CheckedChanged({$Script:Shutdown = $OptionCheck1.Checked})

$OptionCheck2 = New-Object System.Windows.Forms.CheckBox
$OptionCheck2.Location = New-Object System.Drawing.Point(($Gap * 2), ($OptionCheck1.Bottom))
$OptionCheck2.Size = New-Object System.Drawing.Size(($WindowWidth - (4 * $Gap)), (3 * $Gap))
$OptionCheck2.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$OptionCheck2.Text = "Den Ordner Windows.old nicht mitsichern."
$OptionCheck2.Checked = $Script:NoWindowsold
$OptionCheck2.Add_CheckedChanged({$Script:NoWindowsold = $OptionCheck2.Checked})

$DriveHeader = New-Object System.Windows.Forms.Label
$DriveHeader.Location = New-Object System.Drawing.Point(($Gap * 1), ($OptionCheck2.Bottom + $Gap))
$DriveHeader.Size = New-Object System.Drawing.Size(($WindowWidth - (4 * $Gap)), (2 * $Gap))
$DriveHeader.Font = New-Object System.Drawing.Font($FontNameBold, $FontHeadSize)
$DriveHeader.Text = "Speicherort fuer Backup waehlen"

$StartDriveList = New-Object System.Windows.Forms.ListView
$StartDriveList.Location = New-Object System.Drawing.Point(($Gap * 2), ($DriveHeader.Bottom + ($Gap/2)))
$StartDriveList.Size = New-Object System.Drawing.Size(($WindowWidth - (4 * $Gap)), (15 * $Gap))
$StartDriveList.View = [System.Windows.Forms.View]::Details
$StartDriveList.FullRowSelect = $True
$StartDriveList.GridLines = $True
$StartDriveList.Font = New-Object System.Drawing.Font($FontName, ($FontSize - 1))

[void]$StartDriveList.Columns.Add("Laufwerk", 8 * $Gap)
[void]$StartDriveList.Columns.Add("Name", 14 * $Gap)
[void]$StartDriveList.Columns.Add("Typ", 10 * $Gap)
[void]$StartDriveList.Columns.Add("Freier Speicher", 8 * $Gap)

$Drives = GetAvailableDrives
$Drives | ForEach-Object {
	$Item = New-Object System.Windows.Forms.ListViewItem($_.Drive)
	[void]$Item.SubItems.Add($(if ([string]::IsNullOrEmpty($_.Label)) {"(kein Name)"} else {$_.Label}))
	[void]$Item.SubItems.Add($_.Type)
	[void]$Item.SubItems.Add("$($_.FreeSpace) GB")
	$Item.Tag = $_.Path
	[void]$StartDriveList.Items.Add($Item)
}

# List-Hoehe kompakt und inhaltsabhaengig halten
$minRows = 4
$maxRows = 8
$rowHeight = [int](1.8 * $Gap)
$headerHeight = [int](3 * $Gap)
$rows = [math]::Min($maxRows, [math]::Max($minRows, $StartDriveList.Items.Count))
$StartDriveList.Size = New-Object System.Drawing.Size(($StartWindow.ClientSize.Width - (3 * $Gap)), ($headerHeight + ($rows * $rowHeight)))

If ($StartDriveList.Items.Count -gt 0) {
	$DefaultSelected = $False
	If (-not [string]::IsNullOrEmpty($Script:DefaultBackupPath)) {
		For ($i = 0; $i -lt $StartDriveList.Items.Count; $i++) {
			If ($StartDriveList.Items[$i].Tag -eq $Script:DefaultBackupPath -and $StartDriveList.Items[$i].Text -ne "C:") {
				$StartDriveList.Items[$i].Selected = $True
				$Script:SelectedBackupPath = $Script:DefaultBackupPath
				$DefaultSelected = $True
				Break
			}
		}
	}
	If (-not $DefaultSelected) {
		$StartDriveList.Items[0].Selected = $True
		$Script:SelectedBackupPath = $StartDriveList.Items[0].Tag
	}
}

$StartDriveList.Add_SelectedIndexChanged({
	If ($StartDriveList.SelectedItems.Count -gt 0) {
		# C: darf nicht gewählt werden
		If ($StartDriveList.SelectedItems[0].Text -eq "C:") { return }
		$Script:SelectedBackupPath = $StartDriveList.SelectedItems[0].Tag
		If ([string]::IsNullOrEmpty($Script:SelectedBackupPath)) {
			$Script:SelectedBackupPath = $StartDriveList.SelectedItems[0].Text
		}
	}
})

# "Info"-Knopf (About)
$StartAboutButton = New-Object System.Windows.Forms.Button
$StartAboutButton.Location = New-Object System.Drawing.Point(($WindowWidth - $ButtonWidth - $ButtonWidth - $ButtonWidth - (3 * $Gap)), ($StartDriveList.Bottom + $Gap))
$StartAboutButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$StartAboutButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$StartAboutButton.Text = "Info"
$StartAboutButton.Add_Click({
	$HinweisArt = "WIMaster"
	# Info-Dialog mit Logo
	$Hinweis = $Hilfe
	$Cancel = $False
	$ExitOnOK = $False
	$Sure = $False

	# Eigenen Info-Dialog mit Logo anzeigen (Logo links, Text rechts; gleiche Hoehe)
	$InfoWindow = New-Object System.Windows.Forms.Form
	$InfoWindow.StartPosition = 'CenterScreen'
	If (Test-Path $Icon) {$InfoWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)}
	$InfoWindow.Text = $HinweisArt
	$InfoWindow.Font = New-Object System.Drawing.Font($FontName, ($FontHeadSize))
	$InfoWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
	$InfoWindow.AutoSize = $false
	$InfoWindow.Padding = New-Object System.Windows.Forms.Padding($Gap)
	$InfoWindow.ControlBox = $False

	# Text rechts mit fester Maximalbreite, damit Zeilen umbrechen
	$maxTextWidth = (36 * $Gap)

	$InfoText = New-Object System.Windows.Forms.LinkLabel
	$InfoText.Font = New-Object System.Drawing.Font($FontName, $FontSize)
	$InfoText.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
	$InfoText.Text = $Hilfe.Trim()
	$InfoText.LinkArea = New-Object System.Windows.Forms.LinkArea($Hilfe.IndexOf("joe@devops-geek.net"), 19)
	$InfoText.Add_LinkClicked({Start-Process "mailto:joe@devops-geek.net"})
	$InfoText.MaximumSize = New-Object System.Drawing.Size($maxTextWidth, 0)
	$InfoText.AutoSize = $true
	$pref = $InfoText.GetPreferredSize((New-Object System.Drawing.Size($maxTextWidth, 0)))
	$InfoText.Size = $pref
	$InfoText.Location = New-Object System.Drawing.Point((2 * $Gap + (8 * $Gap)), $Gap) # vorlaeufig, Logo folgt

	# Logo links, Hoehe = Text-Hoehe, Breite proportional (quadratisch)
	$Logo = New-Object System.Windows.Forms.PictureBox
	$Logo.Location = New-Object System.Drawing.Point($Gap, $Gap)
	$Logo.Size = New-Object System.Drawing.Size($InfoText.Height, $InfoText.Height)
	$Logo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
	$Logo.Image = [System.Drawing.Image]::Fromfile($Icon)

	# Endgueltige Text-Position rechts neben dem Logo
	$InfoText.Location = New-Object System.Drawing.Point(($Logo.Right + $Gap), $Logo.Top)

	$OK = New-Object System.Windows.Forms.Button
	$OK.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
	$OK.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
	$OK.Text = 'OK'
	$OK.Location = New-Object System.Drawing.Point(($InfoText.Left), ($Logo.Bottom + (2 * $Gap)))
	$OK.Add_Click({$InfoWindow.Close()})

	$InfoWindow.Controls.Add($Logo)
	$InfoWindow.Controls.Add($InfoText)
	$InfoWindow.Controls.Add($OK)

	# Fenster passend setzen
	$width = $InfoText.Right + (2 * $Gap)
	$height = $OK.Bottom + (2 * $Gap)
	$InfoWindow.ClientSize = New-Object System.Drawing.Size([int]$width, [int]$height)

	$InfoWindow.ShowDialog() | Out-Null
})

# "Cancel"-Knopf
$StartCancelButton = New-Object System.Windows.Forms.Button
$StartCancelButton.Location = New-Object System.Drawing.Point(($WindowWidth - $ButtonWidth - $ButtonWidth - (2 * $Gap)), ($StartDriveList.Bottom + $Gap))
$StartCancelButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$StartCancelButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$StartCancelButton.Text = "Abbrechen"
$StartCancelButton.Add_Click({$StartWindow.Close();[environment]::exit(0)})

# "Weiter"-Knopf
$StartNextButton = New-Object System.Windows.Forms.Button
$StartNextButton.Location = New-Object System.Drawing.Point(($WindowWidth - $ButtonWidth - $Gap), ($StartDriveList.Bottom + $Gap))
$StartNextButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$StartNextButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$StartNextButton.Text = "Weiter"
$StartNextButton.Add_Click({$Script:Continue = $True ; $StartWindow.Close()})

# Fenster anzeigen
	$StartWindow.Controls.Add($StartTitle)
	$StartWindow.Controls.Add($StartText)
	$StartWindow.Controls.Add($OptionsHeader)
	$StartWindow.Controls.Add($OptionCheck1)
	$StartWindow.Controls.Add($OptionCheck2)
	# Defender-Option entfernt
	$StartWindow.Controls.Add($DriveHeader)
	$StartWindow.Controls.Add($StartDriveList)
	$StartWindow.Controls.Add($StartAboutButton)
	$StartWindow.Controls.Add($StartCancelButton)
	$StartWindow.Controls.Add($StartNextButton)

	# Fensterhoehe dynamisch an Inhalt anpassen: kompakter unteren Rand
	$ButtonsBottom = [math]::Max([math]::Max($StartAboutButton.Bottom, $StartCancelButton.Bottom), $StartNextButton.Bottom)
	$BottomY = $ButtonsBottom + (1.5 * $Gap)
	$StartWindow.ClientSize = New-Object System.Drawing.Size($StartWindow.ClientSize.Width, [int]$BottomY)
	$StartWindow.ShowDialog() | Out-Null
}

############################
# Cloud-Platzhalter suchen und herunterladen # 
############################

CloudLoad

###########################
# Backup-Pfad konfigurieren und testen #
###########################

If (TestBackupPath) {
	GetWimPaths
} Else {
	[environment]::exit(1)
}

#####################
# Sicherungs-Dialog und Backup-Prozess # 
#####################

# Backup-Prozess starten
If ($Unattended) {
	Write-Host "Starte Backup-Prozess..."
	$BackupLocation = If ($Script:SelectedBackupPath) { $Script:SelectedBackupPath } ElseIf (-not [string]::IsNullOrEmpty($Script:DefaultBackupPath)) { $Script:DefaultBackupPath } Else { $Script:NetworkPath }
	Write-Host "Sichere ${Env:SystemDrive} nach: $BackupLocation"
} Else {
	$JobWindow = New-Object System.Windows.Forms.Form
$JobWindow.Text = $WindowTitle
$JobWindow.Size = New-Object System.Drawing.Size($WindowWidth, $WindowHeight)
$JobWindow.StartPosition = 'CenterScreen'
$JobWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)
$JobWindow.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$JobWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$JobWindow.ControlBox = $False

$JobPicture = New-Object System.Windows.Forms.PictureBox
$JobPicture.Location = New-Object System.Drawing.Point(($JobWindow.Width - $ButtonWidth - (2 * $Gap)), $Gap) 
$JobPicture.Size = New-Object System.Drawing.Size(($ButtonWidth), ($ButtonWidth))
$JobPicture.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$JobPicture.Image = [System.Drawing.Image]::Fromfile($Icon)

$JobHead = New-Object System.Windows.Forms.Label
$JobHead.Location = New-Object System.Drawing.Point($Gap, $Gap)
$JobHead.Size = New-Object System.Drawing.Size(($JobWindow.Width - $JobPicture.Width - (4 * $Gap)), (3 * $Gap))
$JobHead.Font = New-Object System.Drawing.Font($FontNameBold, $FontHeadSize)
$JobHead.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$JobHead.Text = "WIMaster sichert nun ${Env:SystemDrive}"

$JobTicker = New-Object System.Windows.Forms.RichTextBox
$JobTicker.Location = New-Object System.Drawing.Point($Gap, $JobHead.Bottom)
$JobTicker.Size = New-Object System.Drawing.Size(($JobWindow.Width - $JobPicture.Width - (4 * $Gap)), ($JobWindow.Height - $JobHead.Bottom - (4 * $Gap)))
$JobTicker.Multiline = $true
$JobTicker.ScrollBars =  [System.Windows.Forms.ScrollBars]::Vertical
$JobTicker.Font = New-Object System.Drawing.Font($FontName, ($FontSize - 1))

$JobReadyButton = New-Object System.Windows.Forms.Button
$JobReadyButton.Location = New-Object System.Drawing.Point(($JobWindow.Width - $ButtonWidth - (2 * $Gap)),($JobTicker.Bottom - $ButtonHeight))
$JobReadyButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$JobReadyButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$JobReadyButton.Text = "Fertig!"
$JobReadyButton.Enabled = $false
$JobReadyButton.Add_Click({$JobWindow.Close()})

	# Fenster anzeigen

	$JobWindow.Controls.Add($JobHead)
	$JobWindow.Controls.Add($JobTicker)
	$JobWindow.Controls.Add($JobPicture)
	$JobWindow.Controls.Add($JobReadyButton)
	$JobWindow.Show() | Out-Null
}

###########
# Haupt-Backup-Prozess #
###########

Fettdruck "  Sicherung vorbereiten ...`r`n"

# Starte Stoppuhr

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Vorbereitungsfunktionen

RunOnceCreate 
DismExclusionCreate 
IniTempCreate 
REDisable 
ShadowTempCreate 
ScratchDirCreate

# Establish network connection if needed
EstablishNetworkConnection


Fettdruck "`n  Sicherung erzeugen ...`r`n"
If (Test-Path $Wim) {
			Ausgabe "   Was nun passiert: Pruefe WIM-Datei mit bisherigen Sicherungen ($([math]::Round((Get-Item $Wim).Length /1GB, 0)) GByte), erstelle"
	Ausgabe "    neue Sicherung (erkennbar an Fortschrittsanzeige), verifiziere die neue Sicherung."
	} Else {
	Ausgabe "   Was nun passiert: Neue Sicherung erstellen (erkennbar an Fortschrittsanzeige)"
	Ausgabe "    und verifizieren."
}

# Falls Erstsicherung aus welchem Grund auch immer abgebrochen wurde: Ueberbleibsel loeschen

If (Test-Path $FreshWim) {Remove-Item $FreshWim}

# DISM-Befehl zusammenstellen und ausfuehren

$Action = If (Test-Path $Wim) {"/Append-Image /ImageFile:$Wim"} else {"/Capture-Image /ImageFile:$FreshWim /Compress:max"}  

$ActionAll = "/CaptureDir:$Script:ShadowPath\ /Name:""$ImageName"" /Description:""$ImageName"" /ConfigFile:$IniTemp /EA /Verify /CheckIntegrity /LogPath:$LogFile /LogLevel:$LogLevel" 

$Process = Start-Process -FilePath $Dism -ArgumentList "$Action $ActionAll $Scratch" -NoNewWindow -PassThru -RedirectStandardOutput $DismTemp

# Bisherige Meldungen retten (nur im GUI-Modus)
If (-not $Unattended) {
	$JobSaveTickerText = $JobTicker.rtf
}

# Function to handle process completion and cleanup
Function ProcessCompletion {
	param([int]$Code)
	
	If (-not ($Code -eq 0)) {
		If ($Unattended) {
			Write-Host "ERROR: Backup failed with exit code $Code"
			If (($Lost) -or (-not (Test-Path $PSScriptRoot))) {
				Write-Host "ERROR: USB drive was disconnected during backup"
			} else {
				Write-Host "ERROR: DISM reported the following:"
				Write-Host ((Get-Content $DismTemp -Encoding OEM | Select-Object -Last 5)[0])
				Write-Host ((Get-Content $DismTemp -Encoding OEM | Select-Object -Last 5)[2])
				Write-Host "Log file: $LogFile"
			}
			[environment]::exit(1)
		} Else {
			$HinweisArt = "Etwas ist schief gegangen"
			If (($Lost) -or (-not (Test-Path $PSScriptRoot))) {
				$Hinweis = "Das Sichern hat nicht geklappt: Das USB-Laufwerk ist oder war getrennt.`r`n`r`n" + 
					"Klicken Sie auf OK, damit das Skript hinter sich aufraeumen kann`r`n`r`n" + $Hilfe
			} else {
				$Hinweis = "Das Sichern hat nicht geklappt. DISM meldet folgendes:`r`n`r`n" +
				((Get-Content $DismTemp -Encoding OEM | Select-Object -Last 5)[0]) + "`r`n`r`n" +
				((Get-Content $DismTemp -Encoding OEM | Select-Object -Last 5)[2]) + "`r`n`r`n" +
				"Log-Datei: " + $LogFile + "`r`n`r`n" + 
				"Klicken Sie auf OK, damit das Skript hinter sich aufraeumen kann`r`n`r`n" + $Hilfe
			}	
			$Cancel = $False
			$ExitOnOK = $False
			$Sure = $False
			Message
		}
	}
	
	Fettdruck "`r`n`r`n  Nachbereitungen ...`r`n"
	ScratchDirDelete 
	DismExclusionDelete 
	RunOnceDelete 
	REEnable
	# Defender-Reaktivierung entfernt
	
	# Clean up temporary network mapping if used
	If ($Script:SelectedBackupPath -eq "Z:") {
		net use Z: /delete /y 2>$null
		Ausgabe "   Temporaere Netzwerkverbindung entfernt"
	}

	# Stoppe Stoppuhr
	$stopwatch.Stop()
	$Dauer = "$($stopwatch.Elapsed.Hours):$(('{0:D2}' -f $stopwatch.Elapsed.Minutes)):$(('{0:D2}' -f $stopwatch.Elapsed.Seconds))"

	If (-not ($Lost) -and ($Code -eq 0)) {
		ShadowTempDelete ; Ausgabe "   Schattenkopie wieder entfernen"
		If (Test-Path $FreshWim) {Rename-Item -Path $FreshWim -NewName (Split-Path -Leaf $Wim)}
		Ausgabe "   Backupliste.txt schreiben"
		& $Dism /Get-ImageInfo /ImageFile:$Wim /LogPath:$LogFile /LogLevel:$LogLevel > $Liste
		$ImageIndex = (Get-WindowsImage -ImagePath $Wim | Sort-Object ImageIndex -Descending | Select-Object -First 1).ImageIndex
		$ImageSize = ([math]::Round((Get-WindowsImage -ImagePath $Wim -Index $ImageIndex).ImageSize / 1GB, 1))
		$ImageDirs = "{0:N0}" -f (Get-WindowsImage -ImagePath $Wim -Index $ImageIndex).DirectoryCount
		$ImageFiles = "{0:N0}" -f (Get-WindowsImage -ImagePath $Wim -Index $ImageIndex).FileCount
		Fettdruck "`r`n  Zusammenfassung:`r`n"
		Ausgabe "   Die Sicherung enthaelt $ImageFiles Dateien und $ImageDirs Ordner, zusammen $ImageSize GByte."
		Ausgabe "   Dauer der Sicherung: $Dauer (mit Verify und Integritaetspruefung)."
		Ausgabe "`r`n   Gesichert wurde die Sicherung als Image Nr. $ImageIndex in der Datei`r`n   $Wim."
		Ausgabe "`r`n   Liste aller Images in der Datei ${Wim}:`r`n   $Liste"
	}
	Fettdruck "`r`n Fertig!"

	# Falls Shutdown gewuenscht: Countdown starten
	If ($Script:Shutdown) {shutdown /s /t 60}
	
	If (-not $Unattended) {
		# "Fertig"-Knopf
		$JobReadyButton.Enabled = $true
	}
}

If ($Unattended) {
	# Unattended mode: Simple process monitoring with single-line progress
	Write-Host "Waiting for backup process to complete..."
	$LastProgress = ""
	While (-not $Process.HasExited) {
		Start-Sleep -Milliseconds 1000
		# Show progress by reading the last line of DISM output
		If (Test-Path $DismTemp) {
			Try {
				$Zeile = Get-Content -Encoding oem $DismTemp -Tail 1 -ErrorAction Stop
				If ($Zeile -and $Zeile.Trim() -ne "" -and $Zeile -ne $LastProgress) {
					# Use carriage return to overwrite the same line
					Write-Host "`r$Zeile" -NoNewline
					$LastProgress = $Zeile
				}
			} Catch {
				# Ignore errors when reading the temp file
			}
		}
	}
	# Add a newline after the progress is complete
	Write-Host ""
	
	$Process.WaitForExit()
	$Code = $Process.exitcode
	ProcessCompletion $Code
} Else {
	# GUI mode: Use timer for real-time updates
	$Timer = New-Object System.Windows.Forms.Timer
	$Timer.Interval = 1000
	$Timer.Add_Tick({
		If (-not (Test-Path $PSScriptRoot)) {$Lost = $True}
		$Zeile = Get-Content -Encoding oem $DismTemp -Tail 1 -ErrorAction Stop
		if ($Zeile) { Ausgabe "  $Zeile" -Replace }
		If ($Process -and $Process.HasExited) {
			$Process.WaitForExit()
			$Code = $Process.exitcode
			
			$Timer.Stop()
			$Timer.Dispose()
			
			ProcessCompletion $Code
		}
	})

	If (-not (Test-Path $PSScriptRoot)) {$Lost = $True}
	$Timer.Start()
	$JobWindow.Show()
	[System.Windows.Forms.Application]::Run($JobWindow)
}