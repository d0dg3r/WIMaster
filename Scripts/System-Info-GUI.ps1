#Requires -RunAsAdministrator
#Requires -Version 3.0

# System Information - GUI Version
# Erstellt von Joachim Mild <joe@devops-geek.net>
# Basierend auf system-info.cmd

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
$Width = 80      # Fensterbreite in Gap-Einheiten
$Height = 70     # Fensterhöhe in Gap-Einheiten

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
    $MessageWindow.Size = New-Object System.Drawing.Size((50 * $Gap), (20 * $Gap))
    $MessageWindow.StartPosition = 'CenterScreen'
    If (Test-Path $Icon) {$MessageWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)}
    $MessageWindow.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    $MessageWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $MessageWindow.ControlBox = $False
    
    $MessageText = New-Object System.Windows.Forms.TextBox
    $MessageText.Location = New-Object System.Drawing.Point($Gap, $Gap)
    $MessageText.Size = New-Object System.Drawing.Size(($MessageWindow.Width - (3 * $Gap)), (15 * $Gap))
    $MessageText.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    $MessageText.Text = $Message
    $MessageText.Multiline = $True
    $MessageText.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
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

# Funktion zum Sammeln aller System-Informationen
Function Get-AllSystemInfo {
    try {
        $SystemInfo = @()
        $SystemInfo += "=========================================="
        $SystemInfo += "           System Information"
        $SystemInfo += "=========================================="
        $SystemInfo += ""
        
        # Grundlegende System-Informationen
        $SystemInfo += "Computer Name: $env:COMPUTERNAME"
        $SystemInfo += "Username: $env:USERNAME"
        $SystemInfo += "Current Date/Time: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
        $SystemInfo += ""
        
        # Hardware-Informationen
        $SystemInfo += "=== Hardware Information ==="
        try {
            $ProcessorInfo = systeminfo | Select-String "Processor"
            $SystemInfo += "Processor: $($ProcessorInfo.Line)"
        } catch {
            $SystemInfo += "Processor: Information nicht verfügbar"
        }
        
        try {
            $MemoryInfo = systeminfo | Select-String "Total Physical Memory"
            $SystemInfo += "Memory: $($MemoryInfo.Line)"
        } catch {
            $SystemInfo += "Memory: Information nicht verfügbar"
        }
        $SystemInfo += ""
        
        # Speicher-Informationen
        $SystemInfo += "=== Storage Information ==="
        $SystemInfo += "Available Drives:"
        try {
            $Drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
            foreach ($Drive in $Drives) {
                $FreeSpace = [math]::Round($Drive.FreeSpace / 1GB, 2)
                $TotalSpace = [math]::Round($Drive.Size / 1GB, 2)
                $UsedSpace = [math]::Round(($Drive.Size - $Drive.FreeSpace) / 1GB, 2)
                $SystemInfo += "  $($Drive.DeviceID) - Total: ${TotalSpace}GB, Used: ${UsedSpace}GB, Free: ${FreeSpace}GB"
            }
        } catch {
            $SystemInfo += "  Speicher-Informationen nicht verfügbar"
        }
        $SystemInfo += ""
        
        # Netzwerk-Informationen
        $SystemInfo += "=== Network Information ==="
        $SystemInfo += "Network Interfaces:"
        try {
            $NetworkInterfaces = netsh interface show interface
            $SystemInfo += $NetworkInterfaces
        } catch {
            $SystemInfo += "  Netzwerk-Interface-Informationen nicht verfügbar"
        }
        $SystemInfo += ""
        
        # Aktuelle IP-Konfiguration
        $SystemInfo += "=== Current IP Configuration ==="
        try {
            $IPConfig = ipconfig /all
            $SystemInfo += $IPConfig
        } catch {
            $SystemInfo += "  IP-Konfiguration nicht verfügbar"
        }
        $SystemInfo += ""
        
        # System-Informationen
        $SystemInfo += "=== System Information ==="
        try {
            $OSInfo = systeminfo | Select-String "OS Name", "OS Version", "System Type"
            foreach ($Info in $OSInfo) {
                $SystemInfo += $Info.Line
            }
        } catch {
            $SystemInfo += "  System-Informationen nicht verfügbar"
        }
        $SystemInfo += ""
        
        # Zusätzliche Hardware-Informationen
        $SystemInfo += "=== Additional Hardware Information ==="
        try {
            $SystemInfo += "BIOS Information:"
            $BIOSInfo = Get-WmiObject -Class Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate
            $SystemInfo += "  Manufacturer: $($BIOSInfo.Manufacturer)"
            $SystemInfo += "  Version: $($BIOSInfo.SMBIOSBIOSVersion)"
            $SystemInfo += "  Release Date: $($BIOSInfo.ReleaseDate)"
        } catch {
            $SystemInfo += "  BIOS-Informationen nicht verfügbar"
        }
        $SystemInfo += ""
        
        try {
            $SystemInfo += "Motherboard Information:"
            $MotherboardInfo = Get-WmiObject -Class Win32_BaseBoard | Select-Object Manufacturer, Product, Version
            $SystemInfo += "  Manufacturer: $($MotherboardInfo.Manufacturer)"
            $SystemInfo += "  Product: $($MotherboardInfo.Product)"
            $SystemInfo += "  Version: $($MotherboardInfo.Version)"
        } catch {
            $SystemInfo += "  Motherboard-Informationen nicht verfügbar"
        }
        $SystemInfo += ""
        
        # Netzwerk-Adapter-Details
        $SystemInfo += "=== Network Adapter Details ==="
        try {
            $NetworkAdapters = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 }
            foreach ($Adapter in $NetworkAdapters) {
                $SystemInfo += "  $($Adapter.Name): $($Adapter.NetConnectionID)"
            }
        } catch {
            $SystemInfo += "  Netzwerk-Adapter-Details nicht verfügbar"
        }
        
        return $SystemInfo -join "`n"
    } catch {
        return "Fehler beim Sammeln der System-Informationen: $($_.Exception.Message)"
    }
}

# Funktion zum Anzeigen der Hardware-Informationen
Function Show-HardwareInfo {
    try {
        $HardwareInfo = @()
        $HardwareInfo += "=== Hardware Information ==="
        $HardwareInfo += ""
        
        # Prozessor
        try {
            $ProcessorInfo = systeminfo | Select-String "Processor"
            $HardwareInfo += "Processor: $($ProcessorInfo.Line)"
        } catch {
            $HardwareInfo += "Processor: Information nicht verfügbar"
        }
        $HardwareInfo += ""
        
        # Arbeitsspeicher
        try {
            $MemoryInfo = systeminfo | Select-String "Total Physical Memory"
            $HardwareInfo += "Memory: $($MemoryInfo.Line)"
        } catch {
            $HardwareInfo += "Memory: Information nicht verfügbar"
        }
        $HardwareInfo += ""
        
        # BIOS
        try {
            $HardwareInfo += "BIOS Information:"
            $BIOSInfo = Get-WmiObject -Class Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate
            $HardwareInfo += "  Manufacturer: $($BIOSInfo.Manufacturer)"
            $HardwareInfo += "  Version: $($BIOSInfo.SMBIOSBIOSVersion)"
            $HardwareInfo += "  Release Date: $($BIOSInfo.ReleaseDate)"
        } catch {
            $HardwareInfo += "  BIOS-Informationen nicht verfügbar"
        }
        $HardwareInfo += ""
        
        # Motherboard
        try {
            $HardwareInfo += "Motherboard Information:"
            $MotherboardInfo = Get-WmiObject -Class Win32_BaseBoard | Select-Object Manufacturer, Product, Version
            $HardwareInfo += "  Manufacturer: $($MotherboardInfo.Manufacturer)"
            $HardwareInfo += "  Product: $($MotherboardInfo.Product)"
            $HardwareInfo += "  Version: $($MotherboardInfo.Version)"
        } catch {
            $HardwareInfo += "  Motherboard-Informationen nicht verfügbar"
        }
        
        Show-Message -Title "Hardware Information" -Message ($HardwareInfo -join "`n") -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Abrufen der Hardware-Informationen: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Anzeigen der Speicher-Informationen
Function Show-StorageInfo {
    try {
        $StorageInfo = @()
        $StorageInfo += "=== Storage Information ==="
        $StorageInfo += ""
        
        try {
            $Drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
            foreach ($Drive in $Drives) {
                $FreeSpace = [math]::Round($Drive.FreeSpace / 1GB, 2)
                $TotalSpace = [math]::Round($Drive.Size / 1GB, 2)
                $UsedSpace = [math]::Round(($Drive.Size - $Drive.FreeSpace) / 1GB, 2)
                $UsagePercent = [math]::Round(($UsedSpace / $TotalSpace) * 100, 1)
                $StorageInfo += "$($Drive.DeviceID) - $($Drive.VolumeName)"
                $StorageInfo += "  Total: ${TotalSpace}GB"
                $StorageInfo += "  Used: ${UsedSpace}GB (${UsagePercent}%)"
                $StorageInfo += "  Free: ${FreeSpace}GB"
                $StorageInfo += "  File System: $($Drive.FileSystem)"
                $StorageInfo += ""
            }
        } catch {
            $StorageInfo += "Speicher-Informationen nicht verfügbar"
        }
        
        Show-Message -Title "Storage Information" -Message ($StorageInfo -join "`n") -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Abrufen der Speicher-Informationen: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Anzeigen der Netzwerk-Informationen
Function Show-NetworkInfo {
    try {
        $NetworkInfo = @()
        $NetworkInfo += "=== Network Information ==="
        $NetworkInfo += ""
        
        # Netzwerk-Interfaces
        $NetworkInfo += "Network Interfaces:"
        try {
            $NetworkInterfaces = netsh interface show interface
            $NetworkInfo += $NetworkInterfaces
        } catch {
            $NetworkInfo += "  Netzwerk-Interface-Informationen nicht verfügbar"
        }
        $NetworkInfo += ""
        
        # IP-Konfiguration
        $NetworkInfo += "IP Configuration:"
        try {
            $IPConfig = ipconfig /all
            $NetworkInfo += $IPConfig
        } catch {
            $NetworkInfo += "  IP-Konfiguration nicht verfügbar"
        }
        $NetworkInfo += ""
        
        # Netzwerk-Adapter-Details
        $NetworkInfo += "Network Adapter Details:"
        try {
            $NetworkAdapters = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 }
            foreach ($Adapter in $NetworkAdapters) {
                $NetworkInfo += "  $($Adapter.Name): $($Adapter.NetConnectionID)"
                $NetworkInfo += "    MAC Address: $($Adapter.MACAddress)"
                $NetworkInfo += "    Speed: $($Adapter.Speed) bps"
            }
        } catch {
            $NetworkInfo += "  Netzwerk-Adapter-Details nicht verfügbar"
        }
        
        Show-Message -Title "Network Information" -Message ($NetworkInfo -join "`n") -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Abrufen der Netzwerk-Informationen: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Funktion zum Anzeigen der System-Informationen
Function Show-SystemInfo {
    try {
        $SystemInfo = @()
        $SystemInfo += "=== System Information ==="
        $SystemInfo += ""
        
        $SystemInfo += "Computer Name: $env:COMPUTERNAME"
        $SystemInfo += "Username: $env:USERNAME"
        $SystemInfo += "Current Date/Time: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
        $SystemInfo += ""
        
        try {
            $OSInfo = systeminfo | Select-String "OS Name", "OS Version", "System Type", "System Model", "System Manufacturer"
            foreach ($Info in $OSInfo) {
                $SystemInfo += $Info.Line
            }
        } catch {
            $SystemInfo += "System-Informationen nicht verfügbar"
        }
        
        Show-Message -Title "System Information" -Message ($SystemInfo -join "`n") -MessageType "Info"
    } catch {
        Show-Message -Title "Fehler" -Message "Fehler beim Abrufen der System-Informationen: $($_.Exception.Message)" -MessageType "Error"
    }
}

# Hauptfenster erstellen
$MainWindow = New-Object System.Windows.Forms.Form
$MainWindow.Text = "System Information - GUI Version"
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
$HeaderLabel.Text = "System Information"

# Separator
$Separator = New-Object System.Windows.Forms.Label
$Separator.Location = New-Object System.Drawing.Point($Gap, ($HeaderLabel.Bottom + $Gap))
$Separator.Size = New-Object System.Drawing.Size(($WindowWidth - (3 * $Gap)), 2)
$Separator.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D

# Buttons - Erste Reihe
$AllInfoButton = New-Object System.Windows.Forms.Button
$AllInfoButton.Location = New-Object System.Drawing.Point($Gap, ($Separator.Bottom + $Gap))
$AllInfoButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$AllInfoButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$AllInfoButton.Text = "1. All Information"
$AllInfoButton.BackColor = [System.Drawing.Color]::LightBlue
$AllInfoButton.Add_Click({
    $AllInfo = Get-AllSystemInfo
    Show-Message -Title "Complete System Information" -Message $AllInfo -MessageType "Info"
})

$HardwareButton = New-Object System.Windows.Forms.Button
$HardwareButton.Location = New-Object System.Drawing.Point(($AllInfoButton.Right + $Gap), ($Separator.Bottom + $Gap))
$HardwareButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$HardwareButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$HardwareButton.Text = "2. Hardware Info"
$HardwareButton.BackColor = [System.Drawing.Color]::LightGreen
$HardwareButton.Add_Click({ Show-HardwareInfo })

$StorageButton = New-Object System.Windows.Forms.Button
$StorageButton.Location = New-Object System.Drawing.Point(($HardwareButton.Right + $Gap), ($Separator.Bottom + $Gap))
$StorageButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$StorageButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$StorageButton.Text = "3. Storage Info"
$StorageButton.BackColor = [System.Drawing.Color]::LightYellow
$StorageButton.Add_Click({ Show-StorageInfo })

# Buttons - Zweite Reihe
$NetworkButton = New-Object System.Windows.Forms.Button
$NetworkButton.Location = New-Object System.Drawing.Point($Gap, ($AllInfoButton.Bottom + $Gap))
$NetworkButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$NetworkButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$NetworkButton.Text = "4. Network Info"
$NetworkButton.BackColor = [System.Drawing.Color]::LightCoral
$NetworkButton.Add_Click({ Show-NetworkInfo })

$SystemButton = New-Object System.Windows.Forms.Button
$SystemButton.Location = New-Object System.Drawing.Point(($NetworkButton.Right + $Gap), ($AllInfoButton.Bottom + $Gap))
$SystemButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$SystemButton.Font = New-Object System.Drawing.Font($FontName, $FontButtonSize)
$SystemButton.Text = "5. System Info"
$SystemButton.BackColor = [System.Drawing.Color]::LightPink
$SystemButton.Add_Click({ Show-SystemInfo })

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
$MainWindow.Controls.Add($AllInfoButton)
$MainWindow.Controls.Add($HardwareButton)
$MainWindow.Controls.Add($StorageButton)
$MainWindow.Controls.Add($NetworkButton)
$MainWindow.Controls.Add($SystemButton)
$MainWindow.Controls.Add($ExitButton)

# Fenster anzeigen
$MainWindow.ShowDialog() | Out-Null
