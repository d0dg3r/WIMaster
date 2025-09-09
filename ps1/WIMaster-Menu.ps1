#Requires -RunAsAdministrator
#Requires -Version 3.0

# Windows Setup & Restore Menu - GUI Version
# Erstellt von Joachim Mild <joe@devops-geek.net>
# Basierend auf menu.cmd

# Zeichenkodierung für korrekte Umlaut-Darstellung setzen
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Auf USB-Stick zeigt $ScriptDir auf U:\WIMaster\ps1
$WIMasterDir = Split-Path -Parent $ScriptDir

# Windows Forms und Drawing Assemblies laden
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Basisgrößen für GUI-Elemente
$Gap = 14        # Abstand zwischen Elementen
$FontSize = 12   # Grundschriftgröße
$Width = 50      # Fensterbreite in Gap-Einheiten
$Height = 35     # Fensterhöhe in Gap-Einheiten

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

# Icon-Pfad
$Icon = Join-Path $ScriptDir "WIMaster_Ico.ico"

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

# Funktion zum Ausführen von Skripten
Function Start-Script {
    param(
        [string]$ScriptPath,
        [string]$ScriptName
    )
    
    If (Test-Path $ScriptPath) {
        Show-Message -Title "Starte $ScriptName" -Message "Starte $ScriptName..." -MessageType "Info"
        try {
            & $ScriptPath
        } catch {
            Show-Message -Title "Fehler" -Message "Fehler beim Ausführen von $ScriptName`: $($_.Exception.Message)" -MessageType "Error"
        }
    } else {
        Show-Message -Title "Fehler" -Message "Fehler: $ScriptPath nicht gefunden!" -MessageType "Error"
    }
}

# Hauptfenster erstellen
$MainWindow = New-Object System.Windows.Forms.Form
$MainWindow.Text = "Windows Setup & Restore Menu"
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
$HeaderLabel.Text = "Windows Setup & Restore"

# Separator
$Separator = New-Object System.Windows.Forms.Label
$Separator.Location = New-Object System.Drawing.Point($Gap, ($HeaderLabel.Bottom + $Gap))
$Separator.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)), 2)
$Separator.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D

# Button 1: SMB Image Restore
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Location = New-Object System.Drawing.Point($Gap, ($Separator.Bottom + (2 * $Gap)))
$Button1.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$Button1.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$Button1.Text = "1. SMB Image Restore"
$Button1.Add_Click({
    $ScriptPath = Join-Path $WIMasterDir "Scripts\SMB-Restore-GUI.ps1"
    Start-Script -ScriptPath $ScriptPath -ScriptName "SMB Image Restore"
})

# Button 2: Network Tools
$Button2 = New-Object System.Windows.Forms.Button
$Button2.Location = New-Object System.Drawing.Point($Gap, ($Button1.Bottom + $Gap))
$Button2.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$Button2.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$Button2.Text = "2. Network Tools"
$Button2.Add_Click({
    $ScriptPath = Join-Path $WIMasterDir "Scripts\Network-Tools-GUI.ps1"
    Start-Script -ScriptPath $ScriptPath -ScriptName "Network Tools"
})

# Button 3: Disk Tools
$Button3 = New-Object System.Windows.Forms.Button
$Button3.Location = New-Object System.Drawing.Point($Gap, ($Button2.Bottom + $Gap))
$Button3.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$Button3.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$Button3.Text = "3. Disk Tools"
$Button3.Add_Click({
    $ScriptPath = Join-Path $WIMasterDir "Scripts\Disk-Tools-GUI.ps1"
    Start-Script -ScriptPath $ScriptPath -ScriptName "Disk Tools"
})

# Button 4: System Information
$Button4 = New-Object System.Windows.Forms.Button
$Button4.Location = New-Object System.Drawing.Point($Gap, ($Button3.Bottom + $Gap))
$Button4.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$Button4.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$Button4.Text = "4. System Information"
$Button4.Add_Click({
    $ScriptPath = Join-Path $WIMasterDir "Scripts\System-Info-GUI.ps1"
    Start-Script -ScriptPath $ScriptPath -ScriptName "System Information"
})

# Button 5: Command Prompt
$Button5 = New-Object System.Windows.Forms.Button
$Button5.Location = New-Object System.Drawing.Point($Gap, ($Button4.Bottom + $Gap))
$Button5.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$Button5.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$Button5.Text = "5. Command Prompt"
$Button5.Add_Click({
    Show-Message -Title "Command Prompt" -Message "Starte Command Prompt..." -MessageType "Info"
    Start-Process cmd
})

# Button 6: Reboot
$Button6 = New-Object System.Windows.Forms.Button
$Button6.Location = New-Object System.Drawing.Point($Gap, ($Button5.Bottom + $Gap))
$Button6.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$Button6.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$Button6.Text = "6. Reboot"
$Button6.BackColor = [System.Drawing.Color]::LightCoral
$Button6.Add_Click({
    $Result = [System.Windows.Forms.MessageBox]::Show("Möchten Sie das System wirklich neu starten?", "Neustart bestätigen", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    If ($Result -eq [System.Windows.Forms.DialogResult]::Yes) {
        Show-Message -Title "Neustart" -Message "System wird neu gestartet..." -MessageType "Info"
        wpeutil reboot
    }
})

# Button 7: Shutdown
$Button7 = New-Object System.Windows.Forms.Button
$Button7.Location = New-Object System.Drawing.Point($Gap, ($Button6.Bottom + $Gap))
$Button7.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$Button7.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$Button7.Text = "7. Shutdown"
$Button7.BackColor = [System.Drawing.Color]::LightCoral
$Button7.Add_Click({
    $Result = [System.Windows.Forms.MessageBox]::Show("Möchten Sie das System wirklich herunterfahren?", "Herunterfahren bestätigen", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    If ($Result -eq [System.Windows.Forms.DialogResult]::Yes) {
        Show-Message -Title "Herunterfahren" -Message "System wird heruntergefahren..." -MessageType "Info"
        wpeutil shutdown
    }
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

# Alle Controls zum Hauptfenster hinzufügen
$MainWindow.Controls.Add($HeaderLabel)
$MainWindow.Controls.Add($Separator)
$MainWindow.Controls.Add($Button1)
$MainWindow.Controls.Add($Button2)
$MainWindow.Controls.Add($Button3)
$MainWindow.Controls.Add($Button4)
$MainWindow.Controls.Add($Button5)
$MainWindow.Controls.Add($Button6)
$MainWindow.Controls.Add($Button7)
$MainWindow.Controls.Add($ExitButton)

# Fenster anzeigen
$MainWindow.ShowDialog() | Out-Null
