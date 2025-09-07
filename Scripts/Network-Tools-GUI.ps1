#Requires -RunAsAdministrator
#Requires -Version 3.0

# Network Tools - GUI Version
# Erstellt von Joachim Mild <joe@root-files.net>
# Basierend auf network-tools.cmd

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

# Globale Variablen für Netzwerk-Konfiguration
$Global:NetworkConfig = @{
    IP = ""
    Mask = "255.255.255.0"
    Gateway = ""
    DNS = ""
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

# Funktion zum Anzeigen der aktuellen IP-Konfiguration
Function Show-IPConfig {
    try {
        $IPConfig = ipconfig /all
        $InterfaceInfo = netsh interface show interface
        $Result = "=== Aktuelle Netzwerk-Konfiguration ===`n`n$IPConfig`n`n=== Netzwerk-Adapter ===`n`n$InterfaceInfo"
        Show-Message -Title "IP-Konfiguration" -Message $Result -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Abrufen der IP-Konfiguration: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Konfigurieren von DHCP
Function Configure-DHCP {
    try {
        Show-Message -Title "DHCP Konfiguration" -Message "Konfiguriere DHCP..." -MessageType "Info"
        
        netsh interface ip set address "Ethernet" dhcp
        netsh interface ip set dns "Ethernet" dhcp
        ipconfig /renew
        
        Show-Message -Title "DHCP konfiguriert" -Message "DHCP wurde erfolgreich konfiguriert und die IP-Adresse wurde erneuert." -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Konfigurieren von DHCP: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Konfigurieren einer statischen IP
Function Configure-StaticIP {
    param(
        [string]$IP,
        [string]$Mask,
        [string]$Gateway,
        [string]$DNS
    )
    
    try {
        Show-Message -Title "Statische IP" -Message "Konfiguriere statische IP-Adresse..." -MessageType "Info"
        
        netsh interface ip set address "Ethernet" static $IP $Mask $Gateway
        netsh interface ip set dns "Ethernet" static $DNS
        
        Show-Message -Title "Statische IP konfiguriert" -Message "Statische IP-Adresse wurde erfolgreich konfiguriert.`nIP: $IP`nMask: $Mask`nGateway: $Gateway`nDNS: $DNS" -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Konfigurieren der statischen IP: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Ping-Test
Function Test-Ping {
    param([string]$Target)
    
    try {
        Show-Message -Title "Ping Test" -Message "Führe Ping-Test durch..." -MessageType "Info"
        
        $PingResult = ping -n 4 $Target
        Show-Message -Title "Ping Ergebnis" -Message "Ping-Test zu $Target`n`n$PingResult" -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Ping-Test: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Testen der SMB-Verbindung
Function Test-SMBConnection {
    param([string]$Server)
    
    try {
        Show-Message -Title "SMB Test" -Message "Teste SMB-Verbindung..." -MessageType "Info"
        
        $PingResult = ping -n 2 $Server
        Show-Message -Title "SMB Test Ergebnis" -Message "SMB-Verbindungstest zu $Server`n`nPing-Ergebnis:`n$PingResult`n`nHinweis: Für detaillierte SMB-Tests verwenden Sie das SMB Image Restore Tool." -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim SMB-Test: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Speichern des Netzwerk-Profils
Function Save-NetworkProfile {
    try {
        $ProfileFile = Join-Path $MainDir "config\current-network.txt"
        $IPConfig = ipconfig /all
        $IPConfig | Out-File -FilePath $ProfileFile -Encoding UTF8
        
        Show-Message -Title "Profil gespeichert" -Message "Aktuelle Netzwerk-Konfiguration wurde gespeichert." -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Speichern des Netzwerk-Profils: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Laden des Netzwerk-Profils
Function Load-NetworkProfile {
    try {
        $ProfileFile = Join-Path $MainDir "config\network-profiles.txt"
        if (Test-Path $ProfileFile) {
            $ProfileContent = Get-Content $ProfileFile
            Show-Message -Title "Netzwerk-Profil" -Message "Gespeicherte Netzwerk-Profile:`n`n$($ProfileContent -join "`n")" -MessageType "Info"
        } else {
            Show-Message -Title "Kein Profil" -Message "Keine gespeicherten Netzwerk-Profile gefunden." -MessageType "Warning"
        }
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Laden des Netzwerk-Profils: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion für Netzwerk-Diagnose
Function Start-NetworkDiagnostics {
    try {
        Show-Message -Title "Netzwerk-Diagnose" -Message "Starte Netzwerk-Diagnose..." -MessageType "Info"
        
        $Results = @()
        $Results += "=== Netzwerk-Diagnose ==="
        $Results += ""
        
        # Ping-Test zu Google DNS
        $Results += "1. Ping-Test zu 8.8.8.8:"
        $PingResult = ping -n 2 8.8.8.8
        $Results += $PingResult
        $Results += ""
        
        # DNS-Auflösung
        $Results += "2. DNS-Auflösungstest (google.com):"
        $DNSResult = nslookup google.com
        $Results += $DNSResult
        $Results += ""
        
        # Netzwerk-Adapter Status
        $Results += "3. Netzwerk-Adapter Status:"
        $InterfaceResult = netsh interface show interface
        $Results += $InterfaceResult
        $Results += ""
        
        # Netzwerk-Adapter Details
        $Results += "4. Netzwerk-Adapter Details:"
        $ConfigResult = netsh interface ip show config
        $Results += $ConfigResult
        
        $DiagnosticResult = $Results -join "`n"
        Show-Message -Title "Netzwerk-Diagnose Ergebnis" -Message $DiagnosticResult -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler bei der Netzwerk-Diagnose: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Hauptfenster erstellen
$MainWindow = New-Object System.Windows.Forms.Form
$MainWindow.Text = "Network Tools - GUI Version"
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
$HeaderLabel.Text = "Network Tools"

# Separator
$Separator = New-Object System.Windows.Forms.Label
$Separator.Location = New-Object System.Drawing.Point($Gap, ($HeaderLabel.Bottom + $Gap))
$Separator.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)), 2)
$Separator.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D

# Buttons - Erste Reihe
$ShowIPButton = New-Object System.Windows.Forms.Button
$ShowIPButton.Location = New-Object System.Drawing.Point($Gap, ($Separator.Bottom + $Gap))
$ShowIPButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$ShowIPButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$ShowIPButton.Text = "1. Show IP Config"
$ShowIPButton.BackColor = [System.Drawing.Color]::LightBlue
$ShowIPButton.Add_Click({ Show-IPConfig })

$DHCPButton = New-Object System.Windows.Forms.Button
$DHCPButton.Location = New-Object System.Drawing.Point(($ShowIPButton.Right + $Gap), ($Separator.Bottom + $Gap))
$DHCPButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$DHCPButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$DHCPButton.Text = "2. Configure DHCP"
$DHCPButton.BackColor = [System.Drawing.Color]::LightGreen
$DHCPButton.Add_Click({ Configure-DHCP })

$StaticIPButton = New-Object System.Windows.Forms.Button
$StaticIPButton.Location = New-Object System.Drawing.Point(($DHCPButton.Right + $Gap), ($Separator.Bottom + $Gap))
$StaticIPButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$StaticIPButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$StaticIPButton.Text = "3. Static IP"
$StaticIPButton.BackColor = [System.Drawing.Color]::LightYellow
$StaticIPButton.Add_Click({
    # Dialog für statische IP-Konfiguration
    $StaticIPDialog = New-Object System.Windows.Forms.Form
    $StaticIPDialog.Text = "Statische IP-Konfiguration"
    $StaticIPDialog.Size = New-Object System.Drawing.Size((30 * $Gap), (20 * $Gap))
    $StaticIPDialog.StartPosition = 'CenterScreen'
    $StaticIPDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $StaticIPDialog.ControlBox = $False
    
    # IP-Adresse
    $IPLabel = New-Object System.Windows.Forms.Label
    $IPLabel.Location = New-Object System.Drawing.Point($Gap, $Gap)
    $IPLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $IPLabel.Text = "IP-Adresse:"
    $IPLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    
    $IPTextBox = New-Object System.Windows.Forms.TextBox
    $IPTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), $Gap)
    $IPTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $IPTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    $IPTextBox.Text = $Global:NetworkConfig.IP
    
    # Subnetz-Maske
    $MaskLabel = New-Object System.Windows.Forms.Label
    $MaskLabel.Location = New-Object System.Drawing.Point($Gap, ($IPLabel.Bottom + $Gap))
    $MaskLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $MaskLabel.Text = "Subnetz-Maske:"
    $MaskLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    
    $MaskTextBox = New-Object System.Windows.Forms.TextBox
    $MaskTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), ($IPLabel.Bottom + $Gap))
    $MaskTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $MaskTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    $MaskTextBox.Text = $Global:NetworkConfig.Mask
    
    # Gateway
    $GatewayLabel = New-Object System.Windows.Forms.Label
    $GatewayLabel.Location = New-Object System.Drawing.Point($Gap, ($MaskLabel.Bottom + $Gap))
    $GatewayLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $GatewayLabel.Text = "Gateway:"
    $GatewayLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    
    $GatewayTextBox = New-Object System.Windows.Forms.TextBox
    $GatewayTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), ($MaskLabel.Bottom + $Gap))
    $GatewayTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $GatewayTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    $GatewayTextBox.Text = $Global:NetworkConfig.Gateway
    
    # DNS
    $DNSLabel = New-Object System.Windows.Forms.Label
    $DNSLabel.Location = New-Object System.Drawing.Point($Gap, ($GatewayLabel.Bottom + $Gap))
    $DNSLabel.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $DNSLabel.Text = "DNS-Server:"
    $DNSLabel.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    
    $DNSTextBox = New-Object System.Windows.Forms.TextBox
    $DNSTextBox.Location = New-Object System.Drawing.Point(($TextBoxWidth + (2 * $Gap)), ($GatewayLabel.Bottom + $Gap))
    $DNSTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)
    $DNSTextBox.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    $DNSTextBox.Text = $Global:NetworkConfig.DNS
    
    # OK Button
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(($StaticIPDialog.Width - (2 * $ButtonWidth) - (3 * $Gap)), ($StaticIPDialog.Height - $ButtonHeight - (2 * $Gap)))
    $OKButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
    $OKButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
    $OKButton.Text = "OK"
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $OKButton.Add_Click({
        Configure-StaticIP -IP $IPTextBox.Text -Mask $MaskTextBox.Text -Gateway $GatewayTextBox.Text -DNS $DNSTextBox.Text
        $StaticIPDialog.Close()
    })
    
    # Cancel Button
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(($StaticIPDialog.Width - $ButtonWidth - (2 * $Gap)), ($StaticIPDialog.Height - $ButtonHeight - (2 * $Gap)))
    $CancelButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
    $CancelButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
    $CancelButton.Text = "Abbrechen"
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $CancelButton.Add_Click({ $StaticIPDialog.Close() })
    
    $StaticIPDialog.Controls.Add($IPLabel)
    $StaticIPDialog.Controls.Add($IPTextBox)
    $StaticIPDialog.Controls.Add($MaskLabel)
    $StaticIPDialog.Controls.Add($MaskTextBox)
    $StaticIPDialog.Controls.Add($GatewayLabel)
    $StaticIPDialog.Controls.Add($GatewayTextBox)
    $StaticIPDialog.Controls.Add($DNSLabel)
    $StaticIPDialog.Controls.Add($DNSTextBox)
    $StaticIPDialog.Controls.Add($OKButton)
    $StaticIPDialog.Controls.Add($CancelButton)
    
    $StaticIPDialog.ShowDialog() | Out-Null
})

# Buttons - Zweite Reihe
$PingButton = New-Object System.Windows.Forms.Button
$PingButton.Location = New-Object System.Drawing.Point($Gap, ($ShowIPButton.Bottom + $Gap))
$PingButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$PingButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$PingButton.Text = "4. Ping Test"
$PingButton.BackColor = [System.Drawing.Color]::LightCoral
$PingButton.Add_Click({
    $Target = [Microsoft.VisualBasic.Interaction]::InputBox("Geben Sie die IP-Adresse oder den Hostnamen ein:", "Ping Test", "8.8.8.8")
    if ($Target) {
        Test-Ping -Target $Target
    }
})

$SMBTestButton = New-Object System.Windows.Forms.Button
$SMBTestButton.Location = New-Object System.Drawing.Point(($PingButton.Right + $Gap), ($ShowIPButton.Bottom + $Gap))
$SMBTestButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$SMBTestButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$SMBTestButton.Text = "5. SMB Test"
$SMBTestButton.BackColor = [System.Drawing.Color]::LightPink
$SMBTestButton.Add_Click({
    $Server = [Microsoft.VisualBasic.Interaction]::InputBox("Geben Sie die SMB-Server-Adresse ein:", "SMB Test", "")
    if ($Server) {
        Test-SMBConnection -Server $Server
    }
})

$SaveProfileButton = New-Object System.Windows.Forms.Button
$SaveProfileButton.Location = New-Object System.Drawing.Point(($SMBTestButton.Right + $Gap), ($ShowIPButton.Bottom + $Gap))
$SaveProfileButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$SaveProfileButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$SaveProfileButton.Text = "6. Save Profile"
$SaveProfileButton.BackColor = [System.Drawing.Color]::LightCyan
$SaveProfileButton.Add_Click({ Save-NetworkProfile })

# Buttons - Dritte Reihe
$LoadProfileButton = New-Object System.Windows.Forms.Button
$LoadProfileButton.Location = New-Object System.Drawing.Point($Gap, ($PingButton.Bottom + $Gap))
$LoadProfileButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$LoadProfileButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$LoadProfileButton.Text = "7. Load Profile"
$LoadProfileButton.BackColor = [System.Drawing.Color]::LightSteelBlue
$LoadProfileButton.Add_Click({ Load-NetworkProfile })

$DiagnosticsButton = New-Object System.Windows.Forms.Button
$DiagnosticsButton.Location = New-Object System.Drawing.Point(($LoadProfileButton.Right + $Gap), ($PingButton.Bottom + $Gap))
$DiagnosticsButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$DiagnosticsButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$DiagnosticsButton.Text = "8. Diagnostics"
$DiagnosticsButton.BackColor = [System.Drawing.Color]::Orange
$DiagnosticsButton.Add_Click({ Start-NetworkDiagnostics })

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
$MainWindow.Controls.Add($ShowIPButton)
$MainWindow.Controls.Add($DHCPButton)
$MainWindow.Controls.Add($StaticIPButton)
$MainWindow.Controls.Add($PingButton)
$MainWindow.Controls.Add($SMBTestButton)
$MainWindow.Controls.Add($SaveProfileButton)
$MainWindow.Controls.Add($LoadProfileButton)
$MainWindow.Controls.Add($DiagnosticsButton)
$MainWindow.Controls.Add($ExitButton)

# Fenster anzeigen
$MainWindow.ShowDialog() | Out-Null
