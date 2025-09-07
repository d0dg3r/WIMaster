#Requires -RunAsAdministrator
#Requires -Version 3.0

# Zeichenkodierung fuer korrekte Umlaut-Darstellung setzen
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$HilfeGUI = " Entwickelt von Joachim Mild <joe@devops-geek.net>`nBasierend auf c't-WIMage von Axel Vahldiek`n"

<#
.SYNOPSIS
  WIMaster-Setup
.DESCRIPTION
  Setup-Skript fuer WIMaster - Windows System Backup Tool mit Netzwerk-Support.
  Lesen Sie unbedingt die Anleitungen zum Skript.
.NOTES
  Version:        1.0
  Original Autor: Axel Vahldiek <ctwimage@ct.de> (c't-WIMage)
  Weiterentwicklung: Joachim Mild <joe@devops-geek.net>
  Creation Date:  2025-01-27
#>

##############################
# Dateien, Ordner, Variablen #
##############################

# Von WIMaster-Setup benoetigt

$Batch = Join-Path $PSScriptRoot "\WIMaster.bat"
$Skript = Join-Path $PSScriptRoot "\WIMaster.ps1"
$ConfigJson = Join-Path $PSScriptRoot "\WIMaster-Config.json"
$ExclusionsJson = Join-Path $PSScriptRoot "\WIMaster_Exclusions.json"
$Icon = Join-Path $PSScriptRoot "\WIMaster_Ico.ico"
$Autorun = Join-Path $PSScriptRoot "\autorun.inf"
$EIcfg = Join-Path $PSScriptRoot "\ei.cfg"
$ShadowExe = Join-Path $PSScriptRoot "\vshadow.exe"
$SpeedCheckps1 = Join-Path $PSScriptRoot "\WIMaster-USBSpeedCheck.ps1"
$SpeedCheckbat = Join-Path $PSScriptRoot "\WIMaster-USBSpeedCheck.bat"
$ConfigManager = Join-Path $PSScriptRoot "\WIMaster-ConfigManager.ps1"
$ConfigManagerBat = Join-Path $PSScriptRoot "\ConfigManager.bat"
$StartBat = Join-Path $PSScriptRoot "\Start-WIMaster.bat"
$StartUnattendedBat = Join-Path $PSScriptRoot "\Start-WIMaster-Unattended.bat"
$EncryptPasswordPs1 = Join-Path $PSScriptRoot "\EncryptPassword.ps1"
$EncryptPasswordBat = Join-Path $PSScriptRoot "\EncryptPassword.bat"
$SetupBat = Join-Path $PSScriptRoot "\WIMaster-Setup.bat"
$SetupPs1 = Join-Path $PSScriptRoot "\WIMaster-Setup.ps1"
$PasswordReadmeTxt = Join-Path $PSScriptRoot "\README-PasswordSetter.txt"
$PasswordReadmeRtf = Join-Path $PSScriptRoot "\README-PasswordSetter.rtf"
$PasswordReadmeMd = Join-Path $PSScriptRoot "\README-PasswordSetter.md"

# Neue Scripts fuer erweiterte USB-Stick Funktionalitaet
$MenuCmd = Join-Path $PSScriptRoot "\menu.cmd"
$MenuPs1 = Join-Path $PSScriptRoot "\WIMaster-Menu.ps1"
$StartMenuBat = Join-Path $PSScriptRoot "\Start-WIMaster-Menu.bat"
$SmbRestoreCmd = Join-Path $PSScriptRoot "\Scripts\smb-restore.cmd"
$NetworkToolsCmd = Join-Path $PSScriptRoot "\Scripts\network-tools.cmd"
$DiskToolsCmd = Join-Path $PSScriptRoot "\Scripts\disk-tools.cmd"
$SystemInfoCmd = Join-Path $PSScriptRoot "\Scripts\system-info.cmd"
$DefaultSettingsTxt = Join-Path $PSScriptRoot "\Scripts\config\default-settings.txt"
$NetworkProfilesTxt = Join-Path $PSScriptRoot "\Scripts\config\network-profiles.txt"
$LastRestoreTxt = Join-Path $PSScriptRoot "\Scripts\config\last-restore.txt"
$DiskpartMbrTxt = Join-Path $PSScriptRoot "\Scripts\templates\diskpart-mbr.txt"
$DiskpartUefiTxt = Join-Path $PSScriptRoot "\Scripts\templates\diskpart-uefi.txt"
$PostInstallCmd = Join-Path $PSScriptRoot "\Scripts\templates\post-install.cmd"
$SmbFunctionsCmd = Join-Path $PSScriptRoot "\Scripts\utils\smb-functions.cmd"
$NetworkFunctionsCmd = Join-Path $PSScriptRoot "\Scripts\utils\network-functions.cmd"
$DiskFunctionsCmd = Join-Path $PSScriptRoot "\Scripts\utils\disk-functions.cmd"

# Temporaere Dateien

$DiskPart = Join-Path $PSScriptRoot "\DiskPart.txt"

# Variablen

$Build = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
$WinVer = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName
$Version = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion


#######################
# Fenster vorbereiten # 
#######################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# GUI-Encoding fuer korrekte Umlaut-Darstellung
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Basisgroessen

$Gap = 12
$FontSize = 11
$Width = 55
$Height = 58

# SchrIftart

$FontName = "Segoe UI"
$FontNameBold = "Segoe UI Semibold"

# Bei Bedarf an Aufloesung anpassen

$Ratio = [System.Math]::Max((($Width * $Gap) / ([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width)), (($Height * $Gap) / ([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height)))
If ($Ratio -gt 1) {
	$Gap = ($Gap / $Ratio)
	$FontSize = [Math]::Round($FontSize / $Ratio)
}

# Abgeleitete Groessen berechnen

$FontHeadSize = ($FontSize + 4)
$FontButtonSize = ($FontSize - 2)

$WindowWidth = ($Width * $Gap)
$WindowHeight = ($Height * $Gap)

$ButtonWidth = (8 * $Gap)
$ButtonHeight = (3 * $Gap)

# SchrIftart festlegen

$FontName = "Segoe UI"
$FontNameBold = "Segoe UI Semibold"

#######################
# Dialog fuer Hinweise #
#######################

Function Message {
	# Text in Zeilen aufteilen für Höhenberechnung
	$TextLines = $Hinweis.Trim() -split "`r`n"
	$NonEmptyLines = $TextLines | Where-Object { $_.Trim() -ne "" }
	
	# Dynamische Höhenberechnung - großzügiger dimensioniert
	$LineHeight = [int]($FontSize * 1.8)  # Mehr Platz pro Zeile
	$TopMargin = (3 * $Gap)                # Oberer Rand
	$BottomMargin = (4 * $Gap)             # Unterer Rand
	$ButtonArea = $ButtonHeight + (2 * $Gap)  # Button + Abstände
	$LineSpacing = ($Gap * 0.8)           # Abstand zwischen Zeilen
	
	$ContentHeight = $TopMargin + 
	                ($NonEmptyLines.Count * $LineHeight) + 
	                (($NonEmptyLines.Count - 1) * $LineSpacing) + 
	                $Gap + 
	                $ButtonArea + 
	                $BottomMargin
	
	$DialogHeight = [Math]::Max($ContentHeight, (25 * $Gap))  # Höhere Mindesthöhe
	
	# Dynamische Breite basierend auf längster Zeile und Button-Breite
	$TextMeasureFont = New-Object System.Drawing.Font($FontNameBold, $FontSize)
	$MaxTextWidth = 0
	ForEach ($Line in $NonEmptyLines) {
		$Measured = [System.Windows.Forms.TextRenderer]::MeasureText($Line.Trim(), $TextMeasureFont).Width
		if ($Measured -gt $MaxTextWidth) {$MaxTextWidth = $Measured}
	}
	$ButtonsWidth = (2 * $ButtonWidth) + (4 * $Gap)
	$DialogWidth = [Math]::Max(($MaxTextWidth + (4 * $Gap)), ($ButtonsWidth + (4 * $Gap)))
	$DialogWidth = [Math]::Max($DialogWidth, (48 * $Gap))  # Mindestbreite
	
	$Message = New-Object System.Windows.Forms.Form
	$Message.StartPosition = 'CenterScreen'
	$Message.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)
	$Message.Font = New-Object System.Drawing.Font($FontName, ($FontHeadSize))
	$Message.Size = New-Object System.Drawing.Size($DialogWidth, $DialogHeight)
	$Message.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
	$Message.Text = $HinweisArt
	$Message.ControlBox = $False
	$Message.MaximizeBox = $False
	$Message.MinimizeBox = $False

	# Labels für jede Zeile erstellen
	$CurrentY = $TopMargin
	
	ForEach ($Line in $TextLines) {
		If ($Line.Trim() -ne "") {  # Nur nicht-leere Zeilen verarbeiten
			$LineLabel = New-Object System.Windows.Forms.Label
			# Ueberschriften fett, sonst normal
			$IsHeading = ($Line.Trim().EndsWith(":") -or $Line -like "Sie haben*" -or $Line -like "Geplante*")
			if ($IsHeading) {
				$LineLabel.Font = New-Object System.Drawing.Font($FontNameBold, $FontSize)
			} else {
				$LineLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)
			}
			$LineLabel.Text = $Line.Trim()
			$LineLabel.AutoSize = $False
			$LineLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
			
			# Warnung in rot formatieren, sonst dezentes Grau fuer Metainfos
			If ($Line -like "*ACHTUNG*" -or $Line -like "*KOMPLETT GELOESCHT*") {
				$LineLabel.ForeColor = [System.Drawing.Color]::Red
			} ElseIf ($IsHeading) {
				$LineLabel.ForeColor = [System.Drawing.Color]::Black
			} Else {
				$LineLabel.ForeColor = [System.Drawing.Color]::FromArgb(60,60,60)
			}
			
			# Position berechnen - Text mittig positionieren
			$LineLabel.Location = New-Object System.Drawing.Point($Gap, $CurrentY)
			$LineLabel.Width = $Message.Width - (4 * $Gap)
			$LineLabel.Height = $LineHeight
			
			$Message.Controls.Add($LineLabel)
			$CurrentY += ($LineLabel.Height + $LineSpacing)
		}
	}
	
	# Buttons erstellen
	$ButtonY = $CurrentY + $Gap
	
	$MessageOKButton = New-Object System.Windows.Forms.Button
	$MessageOKButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
	$MessageOKButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
	$MessageOKButton.Text = 'OK'
	$MessageOKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	
	$MessageCancelButton = New-Object System.Windows.Forms.Button
	$MessageCancelButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
	$MessageCancelButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
	$MessageCancelButton.Text = 'Abbrechen'
	$MessageCancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	
	# Button-Positionierung - Abbrechen links, OK rechts
	If ($Cancel) {
		# Beide Buttons anzeigen - Abbrechen links, OK rechts
		$TotalButtonWidth = (2 * $ButtonWidth) + (2 * $Gap)
		$StartX = [int](($Message.Width - $TotalButtonWidth) / 2)
		$OKButtonX = [int]($StartX + $ButtonWidth + (2 * $Gap))
		
		$MessageCancelButton.Location = New-Object System.Drawing.Point($StartX, $ButtonY)
		$MessageOKButton.Location = New-Object System.Drawing.Point($OKButtonX, $ButtonY)
		
		$Message.Controls.Add($MessageCancelButton)
		$Message.Controls.Add($MessageOKButton)
	} Else {
		# Nur OK-Button anzeigen (zentriert)
		$OKButtonX = [int](($Message.Width - $ButtonWidth) / 2)
		$MessageOKButton.Location = New-Object System.Drawing.Point($OKButtonX, $ButtonY)
		$Message.Controls.Add($MessageOKButton)
	}
	
	# Event-Handler
	If ($ExitOnOK) {$MessageOKButton.Add_Click({[environment]::exit(0)})}
	If ($Sure)  {$MessageOKButton.Add_Click({$StartWindow.close()})}
	
	$Message.ShowDialog()
}

######################
# Weitere Funktionen #
######################

# USB-Datentraeger erkennen

Function USBDrives {
	$DiskList = @{}
	Get-Disk | Where-Object { $_.BusType -eq 'USB' } | ForEach-Object {
		$VolumeInfo = @()
		Get-Partition -DiskNumber $_.Number  -ErrorAction SilentlyContinue  | Where-Object { $_.DriveLetter } | Where-Object { $_ -ne $null } | ForEach-Object {
			$VolumeInfo += " - " + "$($_.DriveLetter): (" + (Get-Volume -DriveLetter $_.DriveLetter).FileSystemLabel.Trim() + ")"
		}
		$DiskList[$_.Number] = @{
			Number= $_.Number
			Info = "$($_.FriendlyName.Trim()), $([math]::round($_.Size / 1GB, 2)) GB" + $VolumeInfo
		}
	}
	Return $DiskList
}

# Auswahl der USB-Datentraeger erstellen

Function UpdateDriveList {
    $StartListUSB.Items.Clear()
    $DiskList = USBDrives
    $DiskList.Keys | ForEach-Object {[void]$StartListUSB.Items.Add($($DiskList[$_].Info))}
    
    # Automatisch das erste USB-Laufwerk auswählen, falls vorhanden
    if ($StartListUSB.Items.Count -gt 0) {
        $StartListUSB.SelectedIndex = 0
        # USB-Disk-Nummer für das ausgewählte Laufwerk setzen
        $Script:USBDisk = ($DiskList.Values | Where-Object {$_.Info -eq $StartListUSB.SelectedItem}).Number
    }
}


########################
# Anforderungen pruefen #
########################

$Hinweis = $Null

# Vollstaendigkeit der Dateien 

$Missing = ForEach ($Item in @($Batch, $Skript, $ConfigJson, $ExclusionsJson, $Icon, $Autorun, $EIcfg, $ShadowExe, $SpeedCheckps1, $SpeedCheckbat, $ConfigManager, $ConfigManagerBat, $StartBat, $StartUnattendedBat, $EncryptPasswordPs1, $EncryptPasswordBat, $SetupBat, $SetupPs1, $PasswordReadmeTxt, $PasswordReadmeRtf, $PasswordReadmeMd, $MenuPs1, $StartMenuBat)) {
	If (-not (Test-Path $Item)) {Split-Path $Item -Leaf}}
If ($Missing) {$Hinweis = "Es fehlen erforderliche Dateien: " + ($Missing -join ', ')}
	
# System pruefen

$Anforderung = "Skript funktioniert nur unter 64-Bit-Windows."
	If (-not [System.Environment]::Is64BitOperatingSystem) {If ($Hinweis) {$Hinweis = "${Hinweis}`r`n`r`n$Anforderung"} Else {$Hinweis = $Anforderung}}
	
$Anforderung = "Skript funktioniert nur mit x64-Prozessoren."
	If (-not ([System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE") -eq "AMD64")) {If ($Hinweis) {$Hinweis = "${Hinweis}`r`n`r`n$Anforderung"} Else {$Hinweis = $Anforderung}}
		
$Anforderung = "Skript erfordert Windows 10/11 Version 20H2 (Build 19042) oder neuer.`r`nIhre Version: $WinVer $Version (Build $Build)."
	If ($Build -lt 19042) {If ($Hinweis) {$Hinweis = "${Hinweis}`r`n`r`n$Anforderung"} Else {$Hinweis = $Anforderung}}
	
# Melden, falls Problem	

If ($Hinweis){ 
	$HinweisArt = "Anforderung nicht erfuellt"
	$Cancel = $False
	$ExitOnOK = $True
	$Sure = $False
	Message
}

#####################
# Willkommen-Dialog #
#####################

$WindowTitle = "WIMaster: Setup"

$Script:Continue = $False
$StartWindow = New-Object System.Windows.Forms.Form
$StartWindow.Text = $WindowTitle
$StartWindow.Size = New-Object System.Drawing.Size($WindowWidth, $WindowHeight)
$StartWindow.StartPosition = 'CenterScreen'
$StartWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)
$StartWindow.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$StartWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$StartWindow.ControlBox = $False

$StartPicture = New-Object System.Windows.Forms.PictureBox
$StartPicture.Location = New-Object System.Drawing.Point(($WindowWidth - (10 * $Gap)), $Gap) 
$StartPicture.Size = New-Object System.Drawing.Size((8 * $Gap), (8 * $Gap))
$StartPicture.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$StartPicture.Image = [System.Drawing.Image]::Fromfile($Icon)
$StartWindow.Controls.Add($StartPicture)

$StartHead = New-Object System.Windows.Forms.Label
$StartHead.Location = New-Object System.Drawing.Point($Gap, $Gap)
$StartHead.Size = New-Object System.Drawing.Size(($WindowWidth - (12 * $Gap)),(3 * $Gap))
$StartHead.Font = New-Object System.Drawing.Font ($FontNameBold, $FontHeadSize)
$StartHead.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
# $StartHead.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$StartHead.Text = "WIMaster - Windows System Backup Tool"

$StartHelp = New-Object System.Windows.Forms.LinkLabel
$StartHelp.Location = New-Object System.Drawing.Point($Gap, $StartHead.Bottom)
$StartHelp.Size = New-Object System.Drawing.Size(($WindowWidth - (12 * $Gap)),(4 * $Gap))
$StartHelp.Font = New-Object System.Drawing.Font ($FontName, $FontSize)
$StartHelp.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$StartHelp.Text = $HilfeGUI 
$StartHelp.LinkArea = New-Object System.Windows.Forms.LinkArea($HilfeGUI.IndexOf("devops-geek.net"), 15)
$StartHelp.Add_LinkClicked({Start-Process "https://devops-geek.net"})

$StartTextUSB = New-Object System.Windows.Forms.Label
$StartTextUSB.Location = New-Object System.Drawing.Point($Gap, ($StartHelp.Bottom + $Gap))
$StartTextUSB.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)),(2 * $Gap))
$StartTextUSB.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$StartTextUSB.Text = "1. USB-Datentraeger auswaehlen:"

$StartListUSB = New-Object System.Windows.Forms.ComboBox
$StartListUSB.Location = New-Object System.Drawing.Point($Gap, ($StartTextUSB.Bottom + $Gap))
$StartListUSB.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)),(2 * $Gap))
$StartListUSB.Font = New-Object System.Drawing.Font($FontName, $FontSize)

UpdateDriveList

# Verfügbare Laufwerksbuchstaben ermitteln
Function GetAvailableDrives {
    $UsedDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | ForEach-Object {$_.DeviceID.Replace(":","")}
    $AvailableDrives = @()
    for ($i = 67; $i -le 90; $i++) { # C bis Z
        $DriveLetter = [char]$i
        if ($UsedDrives -notcontains $DriveLetter) {
            $AvailableDrives += $DriveLetter
        }
    }
    return $AvailableDrives
}

# Verfügbare Laufwerksbuchstaben in die ComboBoxen laden
Function UpdateDriveLetters {
    $AvailableDrives = GetAvailableDrives
    
    $StartDriveCombo1.Items.Clear()
    $StartDriveCombo2.Items.Clear()
    
    $AvailableDrives | ForEach-Object {
        [void]$StartDriveCombo1.Items.Add($_)
        [void]$StartDriveCombo2.Items.Add($_)
    }
    
    # Standardauswahl setzen, falls verfügbar
    if ($AvailableDrives.Count -ge 2) {
        $StartDriveCombo1.SelectedItem = $AvailableDrives[0]
        $StartDriveCombo2.SelectedItem = $AvailableDrives[1]
        $Script:TargetDrive1 = $AvailableDrives[0]
        $Script:TargetDrive2 = $AvailableDrives[1]
    }
}

$StartRefreshButton = New-Object System.Windows.Forms.Button
$StartRefreshButton.Location = New-Object System.Drawing.Point(($WindowWidth - $ButtonWidth - (2 * $Gap)), ($StartListUSB.Bottom + $Gap))
$StartRefreshButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$StartRefreshButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$StartRefreshButton.Text = "Aktualisieren"
$StartRefreshButton.add_Click({
    UpdateDriveList
    UpdateDriveLetters
})

$StartWarnUSB = New-Object System.Windows.Forms.Label
$StartWarnUSB.Location = New-Object System.Drawing.Point($Gap, ($StartListUSB.Bottom + $Gap))
$StartWarnUSB.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap) - $ButtonWidth),(3 * $Gap))
$StartWarnUSB.Font = New-Object System.Drawing.Font($FontNameBold, $FontSize)
$StartWarnUSB.ForeColor = [System.Drawing.Color]::Red
$StartWarnUSB.Text = "   Achtung, Datentraeger wird komplett geloescht!`r`n   Entfernen Sie alle nicht erforderlichen USB-Datentraeger!"

$StartTextISO = New-Object System.Windows.Forms.Label
$StartTextISO.Location = New-Object System.Drawing.Point($Gap, ($StartWarnUSB.Bottom + $Gap))
$StartTextISO.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)),(2 * $Gap))
$StartTextISO.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$StartTextISO.Text = "2. Windows-Laufwerksimage (ISO) auswaehlen:"

$StartInputISO = New-Object System.Windows.Forms.TextBox
$StartInputISO.Location = New-Object System.Drawing.Point($Gap, ($StartTextISO.Bottom + ($Gap)))
$StartInputISO.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)),(2 * $Gap))
$StartInputISO.Font = New-Object System.Drawing.Font($FontName, $FontSize)

$StartSearchISO = New-Object System.Windows.Forms.Button
$StartSearchISO.Location = New-Object System.Drawing.Point(($WindowWidth - $ButtonWidth - (2 * $Gap)), ($StartInputISO.Bottom + $Gap))
$StartSearchISO.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$StartSearchISO.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$StartSearchISO.Text = 'Durchsuchen'
$StartSearchISO.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.InitialDirectory = [System.Environment]::GetFolderPath('Desktop')
    $openFileDialog.Filter = 'ISO Files (*.iso)|*.iso'
    If ($openFileDialog.ShowDialog() -eq 'OK') {$StartInputISO.Text = $openFileDialog.FileName}
})

$StartLinkISO = New-Object System.Windows.Forms.LinkLabel
$StartLinkISO.Location = New-Object System.Drawing.Point($Gap, ($StartInputISO.Bottom + $Gap))
$StartLinkISO.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)),(2 * $Gap))
$StartLinkISO.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$StartLinkISO.Text = "   Empfohlen: Windows 10 Version 2004 Enterprise Eval (Download)."
$StartLinkISO.LinkArea = New-Object System.Windows.Forms.LinkArea($StartLinkISO.Text.LastIndexOf("Download"), "Download".Length)
$StartLinkISO.Add_LinkClicked({Start-Process "https://software-download.microsoft.com/download/pr/19041.264.200511-0456.vb_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_de-de.iso"})

$StartTextDrive = New-Object System.Windows.Forms.Label
$StartTextDrive.Location = New-Object System.Drawing.Point($Gap, ($StartLinkISO.Bottom + $Gap))
$StartTextDrive.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)),(2 * $Gap))
$StartTextDrive.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$StartTextDrive.Text = "3. Laufwerksbuchstaben fuer WIMaster auswaehlen:"

$StartDriveInfo = New-Object System.Windows.Forms.Label
$StartDriveInfo.Location = New-Object System.Drawing.Point($Gap, ($StartTextDrive.Bottom + $Gap))
$StartDriveInfo.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)),(2 * $Gap))
$StartDriveInfo.Font = New-Object System.Drawing.Font($FontName, ($FontSize - 1))
$StartDriveInfo.Text = "   WIM-BOOT (FAT32) und WIM-DATA (NTFS) benoetigen je einen Laufwerksbuchstaben:"

# WIM-BOOT Laufwerksbuchstabe
$StartDriveLabel1 = New-Object System.Windows.Forms.Label
$StartDriveLabel1.Location = New-Object System.Drawing.Point($Gap, ($StartDriveInfo.Bottom + $Gap))
$StartDriveLabel1.Size = New-Object System.Drawing.Size((8 * $Gap), (2 * $Gap))
$StartDriveLabel1.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$StartDriveLabel1.Text = "   WIM-BOOT:"
$StartDriveLabel1.AutoSize = $True

$StartDriveCombo1 = New-Object System.Windows.Forms.ComboBox
$StartDriveCombo1.Location = New-Object System.Drawing.Point((($StartDriveLabel1.Left) + (9 * $Gap)), ($StartDriveInfo.Bottom + $Gap))
$StartDriveCombo1.Size = New-Object System.Drawing.Size((4 * $Gap), (2 * $Gap))
$StartDriveCombo1.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$StartDriveCombo1.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

# WIM-DATA Laufwerksbuchstabe
$StartDriveLabel2 = New-Object System.Windows.Forms.Label
$StartDriveLabel2.Location = New-Object System.Drawing.Point((($StartDriveCombo1.Right) + (2 * $Gap)), ($StartDriveInfo.Bottom + $Gap))
$StartDriveLabel2.Size = New-Object System.Drawing.Size((8 * $Gap), (2 * $Gap))
$StartDriveLabel2.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$StartDriveLabel2.Text = "WIM-DATA:"
$StartDriveLabel2.AutoSize = $True

$StartDriveCombo2 = New-Object System.Windows.Forms.ComboBox
$StartDriveCombo2.Location = New-Object System.Drawing.Point((($StartDriveLabel2.Left) + (9 * $Gap)), ($StartDriveInfo.Bottom + $Gap))
$StartDriveCombo2.Size = New-Object System.Drawing.Size((4 * $Gap), (2 * $Gap))
$StartDriveCombo2.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$StartDriveCombo2.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

# Event-Handler für die Laufwerksbuchstaben-ComboBoxen
$StartDriveCombo1.Add_SelectedIndexChanged({
    if ($StartDriveCombo1.SelectedItem -eq $StartDriveCombo2.SelectedItem) {
        $AvailableItems = @()
        for ($i = 0; $i -lt $StartDriveCombo2.Items.Count; $i++) {
            if ($StartDriveCombo2.Items[$i] -ne $StartDriveCombo1.SelectedItem) {
                $AvailableItems += $StartDriveCombo2.Items[$i]
            }
        }
        if ($AvailableItems.Count -gt 0) {
            $StartDriveCombo2.SelectedItem = $AvailableItems[0]
        }
    }
    $Script:TargetDrive1 = $StartDriveCombo1.SelectedItem
})

$StartDriveCombo2.Add_SelectedIndexChanged({
    if ($StartDriveCombo1.SelectedItem -eq $StartDriveCombo2.SelectedItem) {
        $AvailableItems = @()
        for ($i = 0; $i -lt $StartDriveCombo1.Items.Count; $i++) {
            if ($StartDriveCombo1.Items[$i] -ne $StartDriveCombo2.SelectedItem) {
                $AvailableItems += $StartDriveCombo1.Items[$i]
            }
        }
        if ($AvailableItems.Count -gt 0) {
            $StartDriveCombo1.SelectedItem = $AvailableItems[0]
        }
    }
    $Script:TargetDrive2 = $StartDriveCombo2.SelectedItem
})

# Laufwerksbuchstaben initial laden
UpdateDriveLetters

$StartCancelButton = New-Object System.Windows.Forms.Button
$StartCancelButton.Location = New-Object System.Drawing.Point(($WindowWidth - $ButtonWidth - $ButtonWidth - (3 * $Gap)), ($StartDriveCombo1.Bottom + (2 * $Gap)))
$StartCancelButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$StartCancelButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$StartCancelButton.Text = "Abbrechen"
$StartCancelButton.Add_Click({
	$StartWindow.Close()
	[environment]::exit(0)
	})

$StartNextButton = New-Object System.Windows.Forms.Button
$StartNextButton.Location = New-Object System.Drawing.Point(($WindowWidth - $ButtonWidth - (2 * $Gap)), ($StartDriveCombo1.Bottom + (2 * $Gap)))
$StartNextButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$StartNextButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$StartNextButton.Text = "Weiter"
# Event-Handler hinzufügen
$StartListUSB.add_SelectedIndexChanged({
    $DiskList = USBDrives
    $Script:USBDisk = ($DiskList.Values | Where-Object {$_.Info -eq $StartListUSB.SelectedItem}).Number
})

$StartInputISO.add_TextChanged({
    # Text geändert - keine weitere Aktion erforderlich
})

$StartNextButton.Add_Click({
	
	$Script:Continue = $True
	$Hinweis = $null
	
	# Auswahl pruefen
	If (-not $Script:USBDisk) {
		$Hinweis = "Kein USB-Datentraeger ausgewaehlt.`r`n"
	} Else {
		If ((Get-Disk -Number $Script:USBDisk).size -lt 28GB) {$Hinweis = "USB-Datentraeger kleiner 28 GByte ausgewaehlt.`r`n"} 
		if ((Get-Partition | Where-Object { $_.DriveLetter -eq $PSScriptRoot[0] } | Get-Disk).Number -eq $Script:USBDisk) {$Hinweis += "Das gerade laufende Skript darf nicht vom ausgewaehlten Stick gestartet sein.`r`n"}
	}
	
	If (-not $StartInputISO.Text) {
		$Hinweis += "Kein ISO-Abbild ausgewaehlt.`r`n"
	} Else {
		If (((Get-Partition -DriveLetter (Get-Item $StartInputISO.Text).PSDrive.Name).DiskNumber) -eq $Script:USBDisk) {$Hinweis += "Ausgewaehltes ISO darf nicht auf dem ausgewaehlten Stick liegen.`r`n"}
		$ISOPath = (Mount-DiskImage -ImagePath $StartInputISO.Text -NoDriveLetter | Get-DiskImage).devicePath
		$ISOSources = Join-Path -Path $ISOPath -ChildPath "Sources"
		$ISOSetup = Join-Path -Path $ISOPath -ChildPath "Setup.exe"
		$ISOBoot = Join-Path -Path $ISOSources -ChildPath "Boot.wim"
		If (-not (Test-Path $ISOSources) -or -not (Test-Path $ISOSetup)) {$Hinweis += "ISO nicht als Setup-Medium erkannt.`r`n"}
		If ((Get-WindowsImage -ImagePath $ISOBoot -Index 1).Architecture -ne 9) {$Hinweis += "ISO nicht als x64-Bit-Setup-Medium erkannt.`r`n"
			} Else {
			If (([int](Get-Item $ISOSetup).VersionInfo.ProductBuildPart) -lt 19041) {$Hinweis += "Setup-Medium nicht aktuell genug (mind. Windows 10 20H2 oder neuer).`r`n"}
			}
		Dismount-Diskimage -ImagePath $StartInputISO.Text
	}
	
	# Laufwerksbuchstaben pruefen (automatisch gesetzt)
	If (-not $Script:TargetDrive1 -or -not $Script:TargetDrive2) {
		$Hinweis += "Laufwerksbuchstaben konnten nicht automatisch zugewiesen werden.`r`n"
	} ElseIf ($Script:TargetDrive1 -eq $Script:TargetDrive2) {
		$Hinweis += "Beide Partitionen koennen nicht den gleichen Laufwerksbuchstaben verwenden.`r`n"
	}
		
	If ($Hinweis) {
		$HinweisArt = "So wird das nix"
		$Cancel = $False
		$ExitOnOK = $False
		$Sure = $False
		Message
	} else {
		
		# $USBCheckName = (Get-Disk -Number ${Script:USBDisk}).FriendlyName
		
		$USBCheckName = "$(Get-Disk -Number ${Script:USBDisk} | ForEach-Object { $_.FriendlyName + ' (' + [math]::Round($_.Size / 1GB, 2).ToString() + ' GB)' })"
		
		$USBCheckVolumes = (Get-Disk $Script:USBDisk | Get-Partition).DriveLetter | Where-Object { $_ -ne $null } | % { $v = Get-Volume -DriveLetter $_; $($v.DriveLetter) + ":\ (" +   $([math]::Round($v.Size / 1GB)) + " GB, " + $($v.FileSystemLabel) + ")".Trim() + "`r`n"}
		
		# Kompakter, doppelte Infos vermeiden (Volumes zeigen Labels bereits)
		$Hinweis = "Sie haben diesen Datentraeger ausgewaehlt:`r`n" +
				  "${USBCheckName}`r`n" +
				  "`r`nPartitionen auf dem Datentraeger:`r`n" +
				  ($USBCheckVolumes.TrimEnd("`r`n")) +
				  "`r`nACHTUNG! Er wird dabei mitsamt ALLER Daten darauf KOMPLETT GELOESCHT!"
		
		If ((Get-Disk -Number $USBDisk).size -gt 2TB) {$Hinweis += "`r`nHinweis: Sie haben einen USB-Datentraeger groesser 2 TByte ausgewaehlt.`r`nSie koennen das problemlos fuer WIMaster verwenden, den Platz jenseits der 2 TByte`r`ndann aber nicht verwenden.`r`n"} 
			
		$HinweisArt = "Formatierung des USB Laufwerks!"
		$Cancel = $True
		$ExitOnOK = $False
		$Sure = $True
		Message
	}
})

# Fenster anzeigen
$StartWindow.Controls.Add($StartHead)
$StartWindow.Controls.Add($StartTextUSB)
$StartWindow.Controls.Add($StartListUSB)
$StartWindow.Controls.Add($StartWarnUSB)
$StartWindow.Controls.Add($StartRefreshButton)
$StartWindow.Controls.Add($StartTextISO)
$StartWindow.Controls.Add($StartInputISO)
$StartWindow.Controls.Add($StartSearchISO)
$StartWindow.Controls.Add($StartLinkISO)
$StartWindow.Controls.Add($StartTextDrive)
$StartWindow.Controls.Add($StartDriveInfo)
$StartWindow.Controls.Add($StartDriveLabel1)
$StartWindow.Controls.Add($StartDriveCombo1)
$StartWindow.Controls.Add($StartDriveLabel2)
$StartWindow.Controls.Add($StartDriveCombo2)
$StartWindow.Controls.Add($StartHelp)
$StartWindow.Controls.Add($StartCancelButton)
$StartWindow.Controls.Add($StartNextButton)

# Dynamische Fensterhoehe passend zum Inhalt setzen
$BottomY = [math]::Max($StartCancelButton.Bottom, $StartNextButton.Bottom) + (2 * $Gap)
$StartWindow.ClientSize = New-Object System.Drawing.Size($StartWindow.ClientSize.Width, [int]$BottomY)

$StartWindow.ShowDialog() | Out-Null

#######################
# Einrichtungs-Dialog #
#######################

# Fenster erstellen

$JobWindow = New-Object System.Windows.Forms.Form
$JobWindow.Text = $WindowTitle
$JobWindow.Size = New-Object System.Drawing.Size($WindowWidth, $WindowHeight)
$JobWindow.StartPosition = 'CenterScreen'
$JobWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)
$JobWindow.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$JobWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$JobWindow.ControlBox = $False

$JobPicture = New-Object System.Windows.Forms.PictureBox
$JobPicture.Location = New-Object System.Drawing.Point(($WindowWidth - $ButtonWidth - (2 * $Gap)), $Gap) 
$JobPicture.Size = New-Object System.Drawing.Size(($ButtonWidth), ($ButtonWidth))
$JobPicture.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$JobPicture.Image = [System.Drawing.Image]::Fromfile($Icon)

$JobHead = New-Object System.Windows.Forms.Label
$JobHead.Location = New-Object System.Drawing.Point($Gap, $Gap)
$JobHead.Size = New-Object System.Drawing.Size(($WindowWidth - $JobPicture.Width - (4 * $Gap)), (3 * $Gap))
$JobHead.Font = New-Object System.Drawing.Font($FontNameBold, $FontHeadSize)
$JobHead.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$JobHead.Text = "Bitte warten, USB-Datentraeger wird eingerichtet."

$JobTicker = New-Object System.Windows.Forms.RichTextBox
$JobTicker.Location = New-Object System.Drawing.Point($Gap, $JobHead.Bottom)
$JobTicker.Size = New-Object System.Drawing.Size(($WindowWidth - $JobPicture.Width - (4 * $Gap)), ($WindowHeight - $JobHead.Bottom - (4 * $Gap)))
$JobTicker.Multiline = $true
$JobTicker.ScrollBars =  [System.Windows.Forms.ScrollBars]::Vertical
$JobTicker.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$JobTicker.Text = $Null

$JobReadyButton = New-Object System.Windows.Forms.Button
$JobReadyButton.Location = New-Object System.Drawing.Point(($WindowWidth - $ButtonWidth - (2 * $Gap)),($JobTicker.Bottom - $ButtonHeight))
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

# Dynamische Fensterhoehe fuer JobWindow: bis unterhalb des Buttons
$jobBottom = [math]::Max($JobReadyButton.Bottom, $JobTicker.Bottom) + (2 * $Gap)
$JobWindow.ClientSize = New-Object System.Drawing.Size($JobWindow.ClientSize.Width, [int]$jobBottom)

# Ausgabe-Funktionen fuer den Ticker

Function Ausgabe {
	param ([String]$JobTickText)
	$JobTicker.AppendText("  ${JobTickText}`r`n");$JobWindow.Refresh()
}

Function Fettdruck {
    param ([String]$JobFettText)
    $StartPos = $JobTicker.Text.Length
    $JobTicker.AppendText("${JobFettText}`r`n")
    $EndPos = $JobTicker.Text.Length
    $JobTicker.Select($StartPos, $EndPos - $StartPos)
    $JobTicker.SelectionFont = New-Object System.Drawing.Font($JobTicker.Font, [System.Drawing.FontStyle]::Bold)
    $JobTicker.Select($EndPos, 0)
	$JobTicker.SelectionFont = New-Object System.Drawing.Font($JobTicker.Font, [System.Drawing.FontStyle]::Regular)
    $JobTicker.ScrollToCaret()
}

# ISO einbinden

Fettdruck " Binde ISO ein"
$LWISO = (Mount-DiskImage -ImagePath $StartInputISO.Text -NoDriveLetter | Get-DiskImage).devicePath

# Partitionierung starten

Fettdruck "`r`n Partitioniere und formatiere USB-Datentraeger"
Ausgabe " Verwende Laufwerksbuchstaben: ${TargetDrive1}: und ${TargetDrive2}:"

# Temporaeres DiskPart-Skript erstellen
Ausgabe " Erstelle Diskpart-Befehlsliste"
@"
select Disk $USBDisk
Clean
Convert MBR
Create Partition Primary Size=8000
Format Quick fs=FAT32 label=WIM-BOOT
Active
Assign Letter=$TargetDrive1
Create Partition Primary
Format Quick fs=NTFS label=WIM-DATA
Assign Letter=$TargetDrive2
Exit
"@ | Out-File $DiskPart -Encoding ASCII

# Temporaeres DiskPart-Skript ausfuehren

# Diskpart /s $DismTemp | Out-Null
Ausgabe " Erstelle neue logische Laufwerke"
Start-Process -FilePath "diskpart.exe" -ArgumentList "/s `"$DiskPart`"" -NoNewWindow -Wait | Out-Null
Ausgabe " WIM-BOOT und WIM-DATA wurden erstellt"
Remove-Item $DiskPart


# Laufwerksbuchstaben zuweisen

Fettdruck "`r`n Weise Laufwerksbuchstaben zu:"

# Warten bis die Partitionen verfügbar sind
Start-Sleep -Seconds 3

# Laufwerksbuchstaben dynamisch ermitteln - verbesserte Logik
$Partitions = Get-Partition -DiskNumber $USBDisk | Where-Object {$_.DriveLetter -ne $null}
$LWFAT32 = ($Partitions | Where-Object {$_.Type -eq "System"}).DriveLetter
$LWNTFS = ($Partitions | Where-Object {$_.Type -eq "Basic" -and $_.DriveLetter -ne $LWFAT32}).DriveLetter

# Fallback: Falls die Erkennung fehlschlaegt, verwende die geplanten Buchstaben
If (-not $LWFAT32 -or -not $LWNTFS) {
    $LWFAT32 = $Script:TargetDrive1
    $LWNTFS = $Script:TargetDrive2
    Ausgabe "  Fallback: Verwende geplante Laufwerksbuchstaben"
}

Ausgabe "  WIM-BOOT ist nun ${LWFAT32}:"
Ausgabe "  WIM-DATA ist nun ${LWNTFS}:"

# Daten kopieren

Fettdruck "`r`n Kopiere ..." 

Ausgabe " ... Boot-Dateien nach WIM-BOOT"
New-Item -Path "${LWFAT32}:\WIMaster" -ItemType Directory | Out-Null
Copy-Item -Path $Icon -Destination "${LWFAT32}:\WIMaster"
Get-Childitem -path "${LWISO}\" | ForEach-Object {If ($_.Name -ne "Sources") {If ($_.Name -ne "Autorun.inf") {Copy-Item -Path $_.Fullname -Destination "${LWFAT32}:" -recurse}}}

Ausgabe " ... PE nach WIM-BOOT"
New-Item -Path "${LWFAT32}:\Sources" -ItemType Directory | Out-Null
Copy-Item -Path "${LWISO}\Sources\Boot.wim" -Destination "${LWFAT32}:\Sources"
attrib -R ${LWFAT32}:\*.* /S /D | Out-Null

Ausgabe " ... Setup-Dateien nach WIM-DATA"
New-Item -Path "${LWNTFS}:\Sources" -ItemType Directory | Out-Null
Copy-Item -Path "${LWISO}\Sources\*" -Destination "${LWNTFS}:\Sources" -exclude "*.wim", "*.esd", "*.swm"  -recurse
Copy-Item -Path $EIcfg -Destination "${LWNTFS}:\Sources" -Force

Ausgabe " ... WIMaster nach WIM-DATA"
Copy-Item -Path $Batch -Destination "${LWNTFS}:"
Copy-Item -Path $Autorun -Destination "${LWNTFS}:"
Copy-Item -Path $MenuCmd -Destination "${LWNTFS}:"
Copy-Item -Path $MenuPs1 -Destination "${LWNTFS}:"
Copy-Item -Path $StartMenuBat -Destination "${LWNTFS}:"
New-Item -Path "${LWNTFS}:\WIMaster" -ItemType Directory | Out-Null
Copy-Item -Path $Skript -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $ConfigJson -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $ExclusionsJson -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $Icon -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $ShadowExe -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $SpeedCheckps1 -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $SpeedCheckbat -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $ConfigManager -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $ConfigManagerBat -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $StartBat -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $StartUnattendedBat -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $EncryptPasswordPs1 -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $EncryptPasswordBat -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $SetupBat -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $SetupPs1 -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $PasswordReadmeTxt -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $PasswordReadmeRtf -Destination "${LWNTFS}:\WIMaster"
Copy-Item -Path $PasswordReadmeMd -Destination "${LWNTFS}:\WIMaster"

Ausgabe " ... Erweiterte Scripts nach WIM-DATA"
New-Item -Path "${LWNTFS}:\Scripts" -ItemType Directory | Out-Null
New-Item -Path "${LWNTFS}:\Scripts\config" -ItemType Directory | Out-Null
New-Item -Path "${LWNTFS}:\Scripts\templates" -ItemType Directory | Out-Null
New-Item -Path "${LWNTFS}:\Scripts\utils" -ItemType Directory | Out-Null

Copy-Item -Path $SmbRestoreCmd -Destination "${LWNTFS}:\Scripts"
Copy-Item -Path $NetworkToolsCmd -Destination "${LWNTFS}:\Scripts"
Copy-Item -Path $DiskToolsCmd -Destination "${LWNTFS}:\Scripts"
Copy-Item -Path $SystemInfoCmd -Destination "${LWNTFS}:\Scripts"
Copy-Item -Path $DefaultSettingsTxt -Destination "${LWNTFS}:\Scripts\config"
Copy-Item -Path $NetworkProfilesTxt -Destination "${LWNTFS}:\Scripts\config"
Copy-Item -Path $LastRestoreTxt -Destination "${LWNTFS}:\Scripts\config"
Copy-Item -Path $DiskpartMbrTxt -Destination "${LWNTFS}:\Scripts\templates"
Copy-Item -Path $DiskpartUefiTxt -Destination "${LWNTFS}:\Scripts\templates"
Copy-Item -Path $PostInstallCmd -Destination "${LWNTFS}:\Scripts\templates"
Copy-Item -Path $SmbFunctionsCmd -Destination "${LWNTFS}:\Scripts\utils"
Copy-Item -Path $NetworkFunctionsCmd -Destination "${LWNTFS}:\Scripts\utils"
Copy-Item -Path $DiskFunctionsCmd -Destination "${LWNTFS}:\Scripts\utils"

attrib -R ${LWNTFS}:\*.* /S /D | Out-Null

# ISO wieder auswerfen

Fettdruck "`r`n Werfe ISO wieder aus"
Dismount-Diskimage -Imagepath $StartInputISO.Text | Out-Null

# Fertig!

Fettdruck "`r`n Fertig!"

$JobReadyButton.Enabled = $True
$JobWindow.Show()

[System.Windows.Forms.Application]::Run($JobWindow)
