#Requires -RunAsAdministrator
#Requires -Version 3.0

# SMB Image Restore - GUI Version
# Erstellt von Joachim Mild <joe@root-files.net>
# Basierend auf smb-restore.cmd

# Zeichenkodierung für korrekte Umlaut-Darstellung setzen
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MainDir = Split-Path -Parent $ScriptDir

# Windows Forms und Drawing Assemblies laden
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Basisgrößen für GUI-Elemente
$Gap = 14        # Abstand zwischen Elementen
$FontSize = 10   # Grundschriftgröße
$Width = 60      # Fensterbreite in Gap-Einheiten
$Height = 50     # Fensterhöhe in Gap-Einheiten

# Schriftarten definieren
$FontName = "Segoe UI"           # Standard-Schriftart
$FontNameBold = "Segoe UI Semibold"  # Fettschrift

# GUI-Größen an Bildschirmauflösung anpassen
$Ratio = [System.Math]::Max((($Width * $Gap) / ([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width)), (($Height * $Gap) / ([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height)))
If ($Ratio -gt 1) {
    $Gap = ($Gap / $Ratio)                    # Abstände verkleinern
    $FontSize = [Math]::Round($FontSize / $Ratio)  # Schriftgröße verkleinern
}

# Abgeleitete GUI-Größen berechnen
$FontHeadSize = ($FontSize + 4)      # Überschrift-Schriftgröße
$FontButtonSize = ($FontSize - 2)    # Button-Schriftgröße

$WindowWidth = ($Width * $Gap)       # Fensterbreite in Pixeln
$WindowHeight = ($Height * $Gap)     # Fensterhöhe in Pixeln

$ButtonWidth = (15 * $Gap)           # Button-Breite
$ButtonHeight = (3 * $Gap)           # Button-Höhe
$TextBoxWidth = (20 * $Gap)          # TextBox-Breite
$TextBoxHeight = (2 * $Gap)          # TextBox-Höhe

# Icon-Pfad
$Icon = Join-Path $MainDir "WIMaster_Ico.ico"

# Globale Variablen für Konfiguration
$Global:SMBConfig = @{
    Server = ""
    Share = ""
    User = ""
    Pass = ""
    WIMFile = ""
    WIMIndex = "1"
    DiskNum = ""
}

# Funktion für Nachrichten-Dialoge
Function Show-Message {
    param(
        [string]$Title,
        [string]$Message,
        [string]$MessageType = "Info"
    )
    
    $MessageWindow = New-Object System.Windows.Forms.Form
    $MessageWindow.Text = $Title
    $MessageWindow.Size = New-Object System.Drawing.Size((35 * $Gap), (12 * $Gap))
    $MessageWindow.StartPosition = 'CenterScreen'
    If (Test-Path $Icon) {$MessageWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)}
    $MessageWindow.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    $MessageWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $MessageWindow.ControlBox = $False
    
    $MessageText = New-Object System.Windows.Forms.Label
    $MessageText.Location = New-Object System.Drawing.Point($Gap, $Gap)
    $MessageText.Size = New-Object System.Drawing.Size(($MessageWindow.Width - (3 * $Gap)), (6 * $Gap))
    $MessageText.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    $MessageText.Text = $Message
    $MessageText.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    
    $MessageOKButton = New-Object System.Windows.Forms.Button
    $MessageOKButton.Location = New-Object System.Drawing.Point(($MessageWindow.Width - $ButtonWidth - (2 * $Gap)), ($MessageWindow.Height - $ButtonHeight - (3 * $Gap)))
    $MessageOKButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
    $MessageOKButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
    $MessageOKButton.Text = 'OK'
    $MessageOKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    
    $MessageWindow.Controls.Add($MessageText)
    $MessageWindow.Controls.Add($MessageOKButton)
    $MessageWindow.ShowDialog() | Out-Null
}

# Funktion zum Laden der Standard-Konfiguration
Function Load-DefaultConfig {
    $ConfigFile = Join-Path $MainDir "config\default-settings.txt"
    If (Test-Path $ConfigFile) {
        try {
            $ConfigContent = Get-Content $ConfigFile
            foreach ($Line in $ConfigContent) {
                if ($Line -match "^(\w+)=(.*)$") {
                    $Key = $Matches[1]
                    $Value = $Matches[2]
                    if ($Global:SMBConfig.ContainsKey($Key)) {
                        $Global:SMBConfig[$Key] = $Value
                    }
                }
            }
            Show-Message -Title "Konfiguration geladen" -Message "Standard-Konfiguration wurde erfolgreich geladen." -MessageType "Info"
        } catch {
            Show-Message -Title "Fehler" -Message "Fehler beim Laden der Konfiguration: $($_.Exception.Message)" -MessageType "Error"
        }
    } else {
        Show-Message -Title "Warnung" -Message "Standard-Konfigurationsdatei nicht gefunden. Bitte konfigurieren Sie zuerst die Einstellungen." -MessageType "Warning"
    }
}

# Funktion zum Laden der letzten Konfiguration
Function Load-LastConfig {
    $ConfigFile = Join-Path $MainDir "config\last-restore.txt"
    If (Test-Path $ConfigFile) {
        try {
            $ConfigContent = Get-Content $ConfigFile
            foreach ($Line in $ConfigContent) {
                if ($Line -match "^(\w+)=(.*)$") {
                    $Key = $Matches[1]
                    $Value = $Matches[2]
                    if ($Global:SMBConfig.ContainsKey($Key)) {
                        $Global:SMBConfig[$Key] = $Value
                    }
                }
            }
            Show-Message -Title "Konfiguration geladen" -Message "Letzte Konfiguration wurde erfolgreich geladen." -MessageType "Info"
        } catch {
            Show-Message -Title "Fehler" -Message "Fehler beim Laden der Konfiguration: $($_.Exception.Message)" -MessageType "Error"
        }
    } else {
        Show-Message -Title "Warnung" -Message "Keine gespeicherte Konfiguration gefunden." -MessageType "Warning"
    }
}

# Funktion zum Speichern der aktuellen Konfiguration
Function Save-Config {
    $ConfigFile = Join-Path $MainDir "config\last-restore.txt"
    try {
        $ConfigContent = @()
        foreach ($Key in $Global:SMBConfig.Keys) {
            $ConfigContent += "$Key=$($Global:SMBConfig[$Key])"
        }
        $ConfigContent | Out-File -FilePath $ConfigFile -Encoding UTF8
        Show-Message -Title "Konfiguration gespeichert" -Message "Aktuelle Konfiguration wurde erfolgreich gespeichert." -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Speichern der Konfiguration: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Testen der SMB-Verbindung
Function Test-SMBConnection {
    param(
        [string]$Server,
        [string]$Share,
        [string]$User,
        [string]$Pass
    )
    
    try {
        Show-Message -Title "SMB Test" -Message "Teste SMB-Verbindung..." -MessageType "Info"
        
        # Temporären Laufwerksbuchstaben verwenden
        $DriveLetter = "Z:"
        
        # SMB-Verbindung herstellen
        $Result = net use $DriveLetter "\\$Server\$Share" /user:$User $Pass 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Verbindung erfolgreich - Inhalt anzeigen
            $DirResult = dir $DriveLetter 2>&1
            net use $DriveLetter /delete | Out-Null
            
            Show-Message -Title "SMB Test erfolgreich" -Message "Verbindung zu \\$Server\$Share erfolgreich!`n`nVerzeichnisinhalt:`n$($DirResult -join "`n")" -MessageType "Info"
        } else {
            Show-Message -Title "SMB Test fehlgeschlagen" -Message "Verbindung zu \\$Server\$Share fehlgeschlagen!`n`nFehler: $Result" -MessageType "Error"
        }
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Testen der SMB-Verbindung: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Starten des Restore-Prozesses
Function Start-Restore {
    param(
        [string]$Server,
        [string]$Share,
        [string]$User,
        [string]$Pass,
        [string]$WIMFile,
        [string]$WIMIndex,
        [string]$DiskNum
    )
    
    # Bestätigung einholen
    $ConfirmResult = [System.Windows.Forms.MessageBox]::Show(
        "WARNUNG: Dies wird alle Daten auf Disk $DiskNum löschen!`n`nServer: $Server`nShare: $Share`nUser: $User`nWIM File: $WIMFile`nIndex: $WIMIndex`nTarget Disk: $DiskNum`n`nMöchten Sie wirklich fortfahren?",
        "Restore bestätigen",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($ConfirmResult -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            Show-Message -Title "Restore gestartet" -Message "SMB Image Restore wird gestartet..." -MessageType "Info"
            
            # Schritt 1: Ziel-Disk vorbereiten
            Show-Message -Title "Schritt 1" -Message "Bereite Ziel-Disk vor..." -MessageType "Info"
            $DiskpartScript = @"
select disk $DiskNum
clean
convert gpt
create partition efi size=100
format fs=fat32 quick
assign letter=S
create partition msr size=128
create partition primary
format fs=ntfs quick label="Windows"
assign letter=C
exit
"@
            $DiskpartScript | diskpart
            
            # Schritt 2: SMB-Share mappen
            Show-Message -Title "Schritt 2" -Message "Mappe SMB-Share..." -MessageType "Info"
            net use Z: "\\$Server\$Share" /user:$User $Pass
            
            # Schritt 3: WIM-Image anwenden
            Show-Message -Title "Schritt 3" -Message "Wende WIM-Image an..." -MessageType "Info"
            dism /apply-image /imagefile:"Z:\$WIMFile" /index:$WIMIndex /applydir:C:\
            
            # Schritt 4: Boot-Dateien installieren
            Show-Message -Title "Schritt 4" -Message "Installiere Boot-Dateien..." -MessageType "Info"
            bcdboot C:\Windows /s S: /f UEFI
            
            # Schritt 5: Aufräumen
            Show-Message -Title "Schritt 5" -Message "Räume auf..." -MessageType "Info"
            net use Z: /delete
            
            Show-Message -Title "Restore abgeschlossen" -Message "SMB Image Restore wurde erfolgreich abgeschlossen!" -MessageType "Info"
            
        } catch {
            Show-Message -Title "Fehler" -Message "Fehler beim Restore: $($_.Exception.Message)" -MessageType "Error"
        }
    }
}

# Hauptfenster erstellen
$MainWindow = New-Object System.Windows.Forms.Form
$MainWindow.Text = "SMB Image Restore - GUI Version"
$MainWindow.Size = New-Object System.Drawing.Size($WindowWidth, $WindowHeight)
$MainWindow.StartPosition = 'CenterScreen'
If (Test-Path $Icon) {$MainWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)}
$MainWindow.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$MainWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$MainWindow.ControlBox = $False

# Header
$HeaderLabel = New-Object System.Windows.Forms.Label
$HeaderLabel.Location = New-Object System.Drawing.Point($Gap, $Gap)
$HeaderLabel.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)), (4 * $Gap))
$HeaderLabel.Font = New-Object System.Drawing.Font($FontNameBold, $FontHeadSize)
$HeaderLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$HeaderLabel.Text = "SMB Image Restore"

# Separator
$Separator = New-Object System.Windows.Forms.Label
$Separator.Location = New-Object System.Drawing.Point($Gap, ($HeaderLabel.Bottom + $Gap))
$Separator.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)), 2)
$Separator.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D

# Konfigurationsbereich
$ConfigGroup = New-Object System.Windows.Forms.GroupBox
$ConfigGroup.Location = New-Object System.Drawing.Point($Gap, ($Separator.Bottom + $Gap))
$ConfigGroup.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)), (25 * $Gap))
$ConfigGroup.Text = "SMB Konfiguration"
$ConfigGroup.Font = New-Object System.Drawing.Font($FontNameBold, $FontSize)

# SMB Server
$ServerLabel = New-Object System.Windows.Forms.Label
$ServerLabel.Location = New-Object System.Drawing.Point($Gap, (2 * $Gap))
$ServerLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$ServerLabel.Text = "SMB Server IP/Name:"
$ServerLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)

$ServerTextBox = New-Object System.Windows.Forms.TextBox
$ServerTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), (2 * $Gap))
$ServerTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$ServerTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$ServerTextBox.Text = $Global:SMBConfig.Server

# SMB Share
$ShareLabel = New-Object System.Windows.Forms.Label
$ShareLabel.Location = New-Object System.Drawing.Point($Gap, ($ServerLabel.Bottom + $Gap))
$ShareLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$ShareLabel.Text = "SMB Share Name:"
$ShareLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)

$ShareTextBox = New-Object System.Windows.Forms.TextBox
$ShareTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), ($ServerLabel.Bottom + $Gap))
$ShareTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$ShareTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$ShareTextBox.Text = $Global:SMBConfig.Share

# Username
$UserLabel = New-Object System.Windows.Forms.Label
$UserLabel.Location = New-Object System.Drawing.Point($Gap, ($ShareLabel.Bottom + $Gap))
$UserLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$UserLabel.Text = "Username:"
$UserLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)

$UserTextBox = New-Object System.Windows.Forms.TextBox
$UserTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), ($ShareLabel.Bottom + $Gap))
$UserTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$UserTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$UserTextBox.Text = $Global:SMBConfig.User

# Password
$PassLabel = New-Object System.Windows.Forms.Label
$PassLabel.Location = New-Object System.Drawing.Point($Gap, ($UserLabel.Bottom + $Gap))
$PassLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$PassLabel.Text = "Password:"
$PassLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)

$PassTextBox = New-Object System.Windows.Forms.TextBox
$PassTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), ($UserLabel.Bottom + $Gap))
$PassTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$PassTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$PassTextBox.Text = $Global:SMBConfig.Pass
$PassTextBox.UseSystemPasswordChar = $True

# WIM File
$WIMFileLabel = New-Object System.Windows.Forms.Label
$WIMFileLabel.Location = New-Object System.Drawing.Point($Gap, ($PassLabel.Bottom + $Gap))
$WIMFileLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$WIMFileLabel.Text = "WIM File Name:"
$WIMFileLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)

$WIMFileTextBox = New-Object System.Windows.Forms.TextBox
$WIMFileTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), ($PassLabel.Bottom + $Gap))
$WIMFileTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$WIMFileTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$WIMFileTextBox.Text = $Global:SMBConfig.WIMFile

# WIM Index
$WIMIndexLabel = New-Object System.Windows.Forms.Label
$WIMIndexLabel.Location = New-Object System.Drawing.Point($Gap, ($WIMFileLabel.Bottom + $Gap))
$WIMIndexLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$WIMIndexLabel.Text = "WIM Index (usually 1):"
$WIMIndexLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)

$WIMIndexTextBox = New-Object System.Windows.Forms.TextBox
$WIMIndexTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), ($WIMFileLabel.Bottom + $Gap))
$WIMIndexTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$WIMIndexTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$WIMIndexTextBox.Text = $Global:SMBConfig.WIMIndex

# Target Disk
$DiskLabel = New-Object System.Windows.Forms.Label
$DiskLabel.Location = New-Object System.Drawing.Point($Gap, ($WIMIndexLabel.Bottom + $Gap))
$DiskLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$DiskLabel.Text = "Target Disk Number:"
$DiskLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)

$DiskTextBox = New-Object System.Windows.Forms.TextBox
$DiskTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), ($WIMIndexLabel.Bottom + $Gap))
$DiskTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
$DiskTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
$DiskTextBox.Text = $Global:SMBConfig.DiskNum

# Buttons
$QuickRestoreButton = New-Object System.Windows.Forms.Button
$QuickRestoreButton.Location = New-Object System.Drawing.Point($Gap, ($ConfigGroup.Bottom + $Gap))
$QuickRestoreButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$QuickRestoreButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$QuickRestoreButton.Text = "1. Quick Restore"
$QuickRestoreButton.BackColor = [System.Drawing.Color]::LightGreen
$QuickRestoreButton.Add_Click({
    Load-DefaultConfig
    # TextBox-Werte aktualisieren
    $ServerTextBox.Text = $Global:SMBConfig.Server
    $ShareTextBox.Text = $Global:SMBConfig.Share
    $UserTextBox.Text = $Global:SMBConfig.User
    $PassTextBox.Text = $Global:SMBConfig.Pass
    $WIMFileTextBox.Text = $Global:SMBConfig.WIMFile
    $WIMIndexTextBox.Text = $Global:SMBConfig.WIMIndex
    $DiskTextBox.Text = $Global:SMBConfig.DiskNum
})

$TestSMBButton = New-Object System.Windows.Forms.Button
$TestSMBButton.Location = New-Object System.Drawing.Point(($QuickRestoreButton.Right + $Gap), ($ConfigGroup.Bottom + $Gap))
$TestSMBButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$TestSMBButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$TestSMBButton.Text = "2. Test SMB"
$TestSMBButton.BackColor = [System.Drawing.Color]::LightBlue
$TestSMBButton.Add_Click({
    Test-SMBConnection -Server $ServerTextBox.Text -Share $ShareTextBox.Text -User $UserTextBox.Text -Pass $PassTextBox.Text
})

$StartRestoreButton = New-Object System.Windows.Forms.Button
$StartRestoreButton.Location = New-Object System.Drawing.Point($Gap, ($QuickRestoreButton.Bottom + $Gap))
$StartRestoreButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$StartRestoreButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$StartRestoreButton.Text = "3. Start Restore"
$StartRestoreButton.BackColor = [System.Drawing.Color]::Orange
$StartRestoreButton.Add_Click({
    # Konfiguration aktualisieren
    $Global:SMBConfig.Server = $ServerTextBox.Text
    $Global:SMBConfig.Share = $ShareTextBox.Text
    $Global:SMBConfig.User = $UserTextBox.Text
    $Global:SMBConfig.Pass = $PassTextBox.Text
    $Global:SMBConfig.WIMFile = $WIMFileTextBox.Text
    $Global:SMBConfig.WIMIndex = $WIMIndexTextBox.Text
    $Global:SMBConfig.DiskNum = $DiskTextBox.Text
    
    Start-Restore -Server $Global:SMBConfig.Server -Share $Global:SMBConfig.Share -User $Global:SMBConfig.User -Pass $Global:SMBConfig.Pass -WIMFile $Global:SMBConfig.WIMFile -WIMIndex $Global:SMBConfig.WIMIndex -DiskNum $Global:SMBConfig.DiskNum
})

$LoadConfigButton = New-Object System.Windows.Forms.Button
$LoadConfigButton.Location = New-Object System.Drawing.Point(($StartRestoreButton.Right + $Gap), ($QuickRestoreButton.Bottom + $Gap))
$LoadConfigButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$LoadConfigButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$LoadConfigButton.Text = "4. Load Config"
$LoadConfigButton.BackColor = [System.Drawing.Color]::LightYellow
$LoadConfigButton.Add_Click({
    Load-LastConfig
    # TextBox-Werte aktualisieren
    $ServerTextBox.Text = $Global:SMBConfig.Server
    $ShareTextBox.Text = $Global:SMBConfig.Share
    $UserTextBox.Text = $Global:SMBConfig.User
    $PassTextBox.Text = $Global:SMBConfig.Pass
    $WIMFileTextBox.Text = $Global:SMBConfig.WIMFile
    $WIMIndexTextBox.Text = $Global:SMBConfig.WIMIndex
    $DiskTextBox.Text = $Global:SMBConfig.DiskNum
})

$SaveConfigButton = New-Object System.Windows.Forms.Button
$SaveConfigButton.Location = New-Object System.Drawing.Point($Gap, ($StartRestoreButton.Bottom + $Gap))
$SaveConfigButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$SaveConfigButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$SaveConfigButton.Text = "5. Save Config"
$SaveConfigButton.BackColor = [System.Drawing.Color]::LightCyan
$SaveConfigButton.Add_Click({
    # Konfiguration aktualisieren
    $Global:SMBConfig.Server = $ServerTextBox.Text
    $Global:SMBConfig.Share = $ShareTextBox.Text
    $Global:SMBConfig.User = $UserTextBox.Text
    $Global:SMBConfig.Pass = $PassTextBox.Text
    $Global:SMBConfig.WIMFile = $WIMFileTextBox.Text
    $Global:SMBConfig.WIMIndex = $WIMIndexTextBox.Text
    $Global:SMBConfig.DiskNum = $DiskTextBox.Text
    
    Save-Config
})

# Exit Button
$ExitButton = New-Object System.Windows.Forms.Button
$ExitButton.Location = New-Object System.Drawing.Point(($WindowWidth - $ButtonWidth - (2 * $Gap)), ($WindowHeight - $ButtonHeight - (2 * $Gap)))
$ExitButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$ExitButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$ExitButton.Text = "Beenden"
$ExitButton.Add_Click({
    $MainWindow.Close()
})

# Alle Controls zum Konfigurationsbereich hinzufügen
$ConfigGroup.Controls.Add($ServerLabel)
$ConfigGroup.Controls.Add($ServerTextBox)
$ConfigGroup.Controls.Add($ShareLabel)
$ConfigGroup.Controls.Add($ShareTextBox)
$ConfigGroup.Controls.Add($UserLabel)
$ConfigGroup.Controls.Add($UserTextBox)
$ConfigGroup.Controls.Add($PassLabel)
$ConfigGroup.Controls.Add($PassTextBox)
$ConfigGroup.Controls.Add($WIMFileLabel)
$ConfigGroup.Controls.Add($WIMFileTextBox)
$ConfigGroup.Controls.Add($WIMIndexLabel)
$ConfigGroup.Controls.Add($WIMIndexTextBox)
$ConfigGroup.Controls.Add($DiskLabel)
$ConfigGroup.Controls.Add($DiskTextBox)

# Alle Controls zum Hauptfenster hinzufügen
$MainWindow.Controls.Add($HeaderLabel)
$MainWindow.Controls.Add($Separator)
$MainWindow.Controls.Add($ConfigGroup)
$MainWindow.Controls.Add($QuickRestoreButton)
$MainWindow.Controls.Add($TestSMBButton)
$MainWindow.Controls.Add($StartRestoreButton)
$MainWindow.Controls.Add($LoadConfigButton)
$MainWindow.Controls.Add($SaveConfigButton)
$MainWindow.Controls.Add($ExitButton)

# Fenster anzeigen
$MainWindow.ShowDialog() | Out-Null
