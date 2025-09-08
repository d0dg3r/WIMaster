#Requires -RunAsAdministrator
#Requires -Version 3.0

# Disk Management Tools - GUI Version
# Erstellt von Joachim Mild <joe@devops-geek.net>
# Basierend auf disk-tools.cmd

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
$Gap = 12        # Abstand zwischen Elementen
$FontSize = 10   # Grundschriftgröße
$Width = 70      # Fensterbreite in Gap-Einheiten
$Height = 60     # Fensterhöhe in Gap-Einheiten

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

$ButtonWidth = (12 * $Gap)           # Button-Breite
$ButtonHeight = (3 * $Gap)           # Button-Höhe
$TextBoxWidth = (15 * $Gap)          # TextBox-Breite
$TextBoxHeight = (2 * $Gap)          # TextBox-Höhe

# Icon-Pfad
$Icon = Join-Path $MainDir "WIMaster_Ico.ico"

# Funktion für Nachrichten-Dialoge
Function Show-Message {
    param(
        [string]$Title,
        [string]$Message,
        [string]$MessageType = "Info"
    )
    
    $MessageWindow = New-Object System.Windows.Forms.Form
    $MessageWindow.Text = $Title
    $MessageWindow.Size = New-Object System.Drawing.Size((40 * $Gap), (15 * $Gap))
    $MessageWindow.StartPosition = 'CenterScreen'
    If (Test-Path $Icon) {$MessageWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)}
    $MessageWindow.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    $MessageWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $MessageWindow.ControlBox = $False
    
    $MessageText = New-Object System.Windows.Forms.TextBox
    $MessageText.Location = New-Object System.Drawing.Point($Gap, $Gap)
    $MessageText.Size = New-Object System.Drawing.Size(($MessageWindow.Width - (3 * $Gap)), (10 * $Gap))
    $MessageText.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    $MessageText.Text = $Message
    $MessageText.Multiline = $True
    $MessageText.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $MessageText.ReadOnly = $True
    
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

# Funktion zum Anzeigen der Disk-Informationen
Function Show-DiskInfo {
    try {
        Show-Message -Title "Disk Information" -Message "Lade Disk-Informationen..." -MessageType "Info"
        
        $DiskpartScript = @"
list disk
exit
"@
        $DiskInfo = $DiskpartScript | diskpart
        
        Show-Message -Title "Disk Information" -Message "Disk-Informationen:`n`n$DiskInfo" -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Abrufen der Disk-Informationen: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion für interaktives Diskpart
Function Start-InteractiveDiskpart {
    try {
        Show-Message -Title "Interaktives Diskpart" -Message "Starte interaktives Diskpart...`n`nGeben Sie 'exit' ein, um zum Menü zurückzukehren." -MessageType "Info"
        
        # Starte Diskpart in einem neuen Fenster
        Start-Process -FilePath "diskpart" -Wait
        
        Show-Message -Title "Diskpart beendet" -Message "Interaktives Diskpart wurde beendet." -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Starten von Diskpart: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion für schnelle Formatierung
Function Start-QuickFormat {
    param(
        [string]$DiskNum,
        [string]$Label
    )
    
    try {
        Show-Message -Title "Schnelle Formatierung" -Message "Starte schnelle Formatierung..." -MessageType "Info"
        
        $DiskpartScript = @"
select disk $DiskNum
clean
create partition primary
active
format fs=ntfs quick label="$Label"
assign
exit
"@
        $FormatResult = $DiskpartScript | diskpart
        
        Show-Message -Title "Formatierung abgeschlossen" -Message "Disk $DiskNum wurde erfolgreich formatiert.`n`nErgebnis:`n$FormatResult" -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler bei der Formatierung: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Erstellen von Windows-Partitionen (MBR)
Function Create-MBRPartitions {
    param([string]$DiskNum)
    
    try {
        Show-Message -Title "MBR Partitionen" -Message "Erstelle MBR-Partitionen..." -MessageType "Info"
        
        $TemplateFile = Join-Path $ScriptDir "templates\diskpart-mbr.txt"
        if (Test-Path $TemplateFile) {
            $TemplateContent = Get-Content $TemplateFile
            $DiskpartScript = $TemplateContent -replace "DISK_NUM", $DiskNum
            $PartitionResult = $DiskpartScript | diskpart
            
            Show-Message -Title "MBR Partitionen erstellt" -Message "MBR-Partitionen für Disk $DiskNum wurden erfolgreich erstellt.`n`nErgebnis:`n$PartitionResult" -MessageType "Info"
        } else {
            Show-Message -Title "Fehler" -Message "MBR-Template-Datei nicht gefunden: $TemplateFile" -MessageType "Error"
        }
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Erstellen der MBR-Partitionen: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Erstellen von Windows-Partitionen (UEFI)
Function Create-UEFIPartitions {
    param([string]$DiskNum)
    
    try {
        Show-Message -Title "UEFI Partitionen" -Message "Erstelle UEFI-Partitionen..." -MessageType "Info"
        
        $TemplateFile = Join-Path $ScriptDir "templates\diskpart-uefi.txt"
        if (Test-Path $TemplateFile) {
            $TemplateContent = Get-Content $TemplateFile
            $DiskpartScript = $TemplateContent -replace "DISK_NUM", $DiskNum
            $PartitionResult = $DiskpartScript | diskpart
            
            Show-Message -Title "UEFI Partitionen erstellt" -Message "UEFI-Partitionen für Disk $DiskNum wurden erfolgreich erstellt.`n`nErgebnis:`n$PartitionResult" -MessageType "Info"
        } else {
            Show-Message -Title "Fehler" -Message "UEFI-Template-Datei nicht gefunden: $TemplateFile" -MessageType "Error"
        }
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Erstellen der UEFI-Partitionen: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zur Disk-Gesundheitsprüfung
Function Check-DiskHealth {
    try {
        Show-Message -Title "Disk-Gesundheit" -Message "Prüfe Disk-Gesundheit..." -MessageType "Info"
        
        $DiskpartScript = @"
list disk
exit
"@
        $DiskInfo = $DiskpartScript | diskpart
        
        $HealthInfo = "Disk-Gesundheitsprüfung:`n`n$DiskInfo`n`nHinweis: Für detaillierte Gesundheitsinformationen verwenden Sie 'chkdsk' in der Eingabeaufforderung."
        
        Show-Message -Title "Disk-Gesundheit" -Message $HealthInfo -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler bei der Disk-Gesundheitsprüfung: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Hauptfenster erstellen
$MainWindow = New-Object System.Windows.Forms.Form
$MainWindow.Text = "Disk Management Tools - GUI Version"
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
$HeaderLabel.Text = "Disk Management Tools"

# Separator
$Separator = New-Object System.Windows.Forms.Label
$Separator.Location = New-Object System.Drawing.Point($Gap, ($HeaderLabel.Bottom + $Gap))
$Separator.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)), 2)
$Separator.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D

# Buttons - Erste Reihe
$DiskInfoButton = New-Object System.Windows.Forms.Button
$DiskInfoButton.Location = New-Object System.Drawing.Point($Gap, ($Separator.Bottom + $Gap))
$DiskInfoButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$DiskInfoButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$DiskInfoButton.Text = "1. Disk Information"
$DiskInfoButton.BackColor = [System.Drawing.Color]::LightBlue
$DiskInfoButton.Add_Click({ Show-DiskInfo })

$InteractiveDiskpartButton = New-Object System.Windows.Forms.Button
$InteractiveDiskpartButton.Location = New-Object System.Drawing.Point(($DiskInfoButton.Right + $Gap), ($Separator.Bottom + $Gap))
$InteractiveDiskpartButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$InteractiveDiskpartButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$InteractiveDiskpartButton.Text = "2. Interactive Diskpart"
$InteractiveDiskpartButton.BackColor = [System.Drawing.Color]::LightGreen
$InteractiveDiskpartButton.Add_Click({ Start-InteractiveDiskpart })

$QuickFormatButton = New-Object System.Windows.Forms.Button
$QuickFormatButton.Location = New-Object System.Drawing.Point(($InteractiveDiskpartButton.Right + $Gap), ($Separator.Bottom + $Gap))
$QuickFormatButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$QuickFormatButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$QuickFormatButton.Text = "3. Quick Format"
$QuickFormatButton.BackColor = [System.Drawing.Color]::LightYellow
$QuickFormatButton.Add_Click({
    # Dialog für schnelle Formatierung
    $FormatDialog = New-Object System.Windows.Forms.Form
    $FormatDialog.Text = "Schnelle Formatierung"
    $FormatDialog.Size = New-Object System.Drawing.Size((25 * $Gap), (12 * $Gap))
    $FormatDialog.StartPosition = 'CenterScreen'
    $FormatDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $FormatDialog.ControlBox = $False
    
    # Disk-Nummer
    $DiskLabel = New-Object System.Windows.Forms.Label
    $DiskLabel.Location = New-Object System.Drawing.Point($Gap, $Gap)
    $DiskLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $DiskLabel.Text = "Disk-Nummer:"
    $DiskLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    
    $DiskTextBox = New-Object System.Windows.Forms.TextBox
    $DiskTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), $Gap)
    $DiskTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $DiskTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    
    # Volume-Label
    $LabelLabel = New-Object System.Windows.Forms.Label
    $LabelLabel.Location = New-Object System.Drawing.Point($Gap, ($DiskLabel.Bottom + $Gap))
    $LabelLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $LabelLabel.Text = "Volume-Label:"
    $LabelLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    
    $LabelTextBox = New-Object System.Windows.Forms.TextBox
    $LabelTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), ($DiskLabel.Bottom + $Gap))
    $LabelTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $LabelTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    $LabelTextBox.Text = "NewVolume"
    
    # OK Button
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(($FormatDialog.Width - (2 * $ButtonWidth) - (3 * $Gap)), ($FormatDialog.Height - $ButtonHeight - (2 * $Gap)))
    $OKButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
    $OKButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
    $OKButton.Text = "OK"
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $OKButton.Add_Click({
        $ConfirmResult = [System.Windows.Forms.MessageBox]::Show(
            "WARNUNG: Dies wird alle Daten auf Disk $($DiskTextBox.Text) löschen!`n`nMöchten Sie wirklich fortfahren?",
            "Formatierung bestätigen",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($ConfirmResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            Start-QuickFormat -DiskNum $DiskTextBox.Text -Label $LabelTextBox.Text
        }
        $FormatDialog.Close()
    })
    
    # Cancel Button
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(($FormatDialog.Width - $ButtonWidth - (2 * $Gap)), ($FormatDialog.Height - $ButtonHeight - (2 * $Gap)))
    $CancelButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
    $CancelButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
    $CancelButton.Text = "Abbrechen"
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $CancelButton.Add_Click({ $FormatDialog.Close() })
    
    $FormatDialog.Controls.Add($DiskLabel)
    $FormatDialog.Controls.Add($DiskTextBox)
    $FormatDialog.Controls.Add($LabelLabel)
    $FormatDialog.Controls.Add($LabelTextBox)
    $FormatDialog.Controls.Add($OKButton)
    $FormatDialog.Controls.Add($CancelButton)
    
    $FormatDialog.ShowDialog() | Out-Null
})

# Buttons - Zweite Reihe
$MBRButton = New-Object System.Windows.Forms.Button
$MBRButton.Location = New-Object System.Drawing.Point($Gap, ($DiskInfoButton.Bottom + $Gap))
$MBRButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$MBRButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$MBRButton.Text = "4. Create MBR"
$MBRButton.BackColor = [System.Drawing.Color]::LightCoral
$MBRButton.Add_Click({
    $DiskNum = [Microsoft.VisualBasic.Interaction]::InputBox("Geben Sie die Disk-Nummer ein:", "MBR Partitionen erstellen", "")
    if ($DiskNum) {
        $ConfirmResult = [System.Windows.Forms.MessageBox]::Show(
            "WARNUNG: Dies wird alle Daten auf Disk $DiskNum löschen!`n`nMöchten Sie wirklich MBR-Partitionen erstellen?",
            "MBR Partitionen bestätigen",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($ConfirmResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            Create-MBRPartitions -DiskNum $DiskNum
        }
    }
})

$UEFIButton = New-Object System.Windows.Forms.Button
$UEFIButton.Location = New-Object System.Drawing.Point(($MBRButton.Right + $Gap), ($DiskInfoButton.Bottom + $Gap))
$UEFIButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$UEFIButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$UEFIButton.Text = "5. Create UEFI"
$UEFIButton.BackColor = [System.Drawing.Color]::LightPink
$UEFIButton.Add_Click({
    $DiskNum = [Microsoft.VisualBasic.Interaction]::InputBox("Geben Sie die Disk-Nummer ein:", "UEFI Partitionen erstellen", "")
    if ($DiskNum) {
        $ConfirmResult = [System.Windows.Forms.MessageBox]::Show(
            "WARNUNG: Dies wird alle Daten auf Disk $DiskNum löschen!`n`nMöchten Sie wirklich UEFI-Partitionen erstellen?",
            "UEFI Partitionen bestätigen",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($ConfirmResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            Create-UEFIPartitions -DiskNum $DiskNum
        }
    }
})

$HealthButton = New-Object System.Windows.Forms.Button
$HealthButton.Location = New-Object System.Drawing.Point(($UEFIButton.Right + $Gap), ($DiskInfoButton.Bottom + $Gap))
$HealthButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$HealthButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$HealthButton.Text = "6. Disk Health"
$HealthButton.BackColor = [System.Drawing.Color]::LightSteelBlue
$HealthButton.Add_Click({ Check-DiskHealth })

# Exit Button
$ExitButton = New-Object System.Windows.Forms.Button
$ExitButton.Location = New-Object System.Drawing.Point(($WindowWidth - $ButtonWidth - (2 * $Gap)), ($WindowHeight - $ButtonHeight - (2 * $Gap)))
$ExitButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$ExitButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$ExitButton.Text = "Beenden"
$ExitButton.Add_Click({
    $MainWindow.Close()
})

# Alle Controls zum Hauptfenster hinzufügen
$MainWindow.Controls.Add($HeaderLabel)
$MainWindow.Controls.Add($Separator)
$MainWindow.Controls.Add($DiskInfoButton)
$MainWindow.Controls.Add($InteractiveDiskpartButton)
$MainWindow.Controls.Add($QuickFormatButton)
$MainWindow.Controls.Add($MBRButton)
$MainWindow.Controls.Add($UEFIButton)
$MainWindow.Controls.Add($HealthButton)
$MainWindow.Controls.Add($ExitButton)

# Fenster anzeigen
$MainWindow.ShowDialog() | Out-Null
