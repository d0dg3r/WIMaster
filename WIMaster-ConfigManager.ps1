#Requires -RunAsAdministrator

<#
.SYNOPSIS
  WIMaster Konfigurations-Manager
.DESCRIPTION
  Verwaltet die Konfiguration für WIMaster inklusive Netzwerk-Einstellungen,
  Backup-Optionen und Standard-Backup-Pfad.
.NOTES
  Version:        0.1
  Autor:          Joachim Mild <joe@devops-geek.net>
  Erstellungsdatum: 2025-01-27
 #>

# Zeichenkodierung fuer korrekte Umlaut-Darstellung setzen
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Parameter-Handling (alternative zu param block)
$ShowCurrent = $false
$Reset = $false
$TestConnection = $false

# Pruefe Kommandozeilenargumente
foreach ($arg in $args) {
    switch ($arg) {
        "-ShowCurrent" { $ShowCurrent = $true }
        "-Reset" { $Reset = $true }
        "-TestConnection" { $TestConnection = $true }
    }
}

$ConfigFile = Join-Path $PSScriptRoot "WIMaster-Config.json"

# Funktion zum Lesen der Konfiguration aus der JSON-Datei
function Read-Config {
    if (-not (Test-Path $ConfigFile)) {
        return $null
    }
    $JsonContent = Get-Content $ConfigFile -Raw -Encoding UTF8
    return $JsonContent | ConvertFrom-Json
}

# Funktion zum Schreiben der Konfiguration in die JSON-Datei
function Write-Config {
    param([PSObject]$Config)
    $JsonContent = $Config | ConvertTo-Json -Depth 10
    Set-Content -Path $ConfigFile -Value $JsonContent -Encoding UTF8
}

# Funktion zum Verschluesseln von Passwoertern mit Windows DPAPI
function Encrypt-Password {
    param([string]$PlainTextPassword)
    if ([string]::IsNullOrEmpty($PlainTextPassword)) { 
        return "" 
    }
    $SecureString = ConvertTo-SecureString -String $PlainTextPassword -AsPlainText -Force
    return ConvertFrom-SecureString -SecureString $SecureString
}

# Funktion zum Entschluesseln von Passwoertern mit Windows DPAPI
function Decrypt-Password {
    param([string]$EncryptedPassword)
    if ([string]::IsNullOrEmpty($EncryptedPassword)) { 
        return "" 
    }
    $SecureString = ConvertTo-SecureString -String $EncryptedPassword
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    $PlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    return $PlainTextPassword
}

# Funktion zum Anzeigen der aktuellen Konfiguration
function Show-CurrentConfig {
    $Config = Read-Config
    if ($Config -eq $null) {
        Write-Host "Keine Konfiguration gefunden." -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host "=== WIMaster Konfiguration ===" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Config.Network) {
        Write-Host "Netzwerk-Einstellungen:" -ForegroundColor Yellow
        Write-Host "  Netzwerk-Backup: $($Config.Network.EnableNetworkBackup)"
        Write-Host "  Netzwerk-Pfad: $($Config.Network.NetworkPath)"
        Write-Host "  Netzwerk-Benutzer: $($Config.Network.NetworkUser)"
        if (-not [string]::IsNullOrEmpty($Config.Network.NetworkPassword)) {
            Write-Host "  Netzwerk-Passwort: [VERSCHLUESSELT]"
        } else {
            Write-Host "  Netzwerk-Passwort: [NICHT GESETZT]"
        }
        Write-Host ""
    }
    
    if ($Config.Backup) {
        Write-Host "Backup-Einstellungen:" -ForegroundColor Yellow
        Write-Host "  Herunterfahren: $($Config.Backup.DefaultShutdown)"
        Write-Host "  Windows.old ausschliessen: $($Config.Backup.DefaultNoWindowsold)"
        $DefaultPath = if ($Config.Backup.PSObject.Properties['DefaultBackupPath']) { $Config.Backup.DefaultBackupPath } else { "[Nicht verfuegbar]" }
        Write-Host "  Standard-Backup-Pfad: $DefaultPath"
        Write-Host ""
    }
}

# Funktion zum Zuruecksetzen der Konfiguration
function Reset-Config {
    if (Test-Path $ConfigFile) {
        Remove-Item $ConfigFile -Force
        Write-Host "Konfiguration zurueckgesetzt." -ForegroundColor Green
    } else {
        Write-Host "Keine Konfiguration vorhanden." -ForegroundColor Yellow
    }
}

# Funktion zum Testen der Netzwerkverbindung mit temporaeren Mounts
function Test-NetworkConnection {
    $Config = Read-Config
    if ($Config -eq $null -or -not $Config.Network) {
        Write-Host "Keine Netzwerk-Konfiguration gefunden." -ForegroundColor Red
        return
    }
    
    $NetworkPath = $Config.Network.NetworkPath
    if ([string]::IsNullOrEmpty($NetworkPath)) {
        Write-Host "Netzwerk-Pfad nicht konfiguriert." -ForegroundColor Red
        return
    }
    
    Write-Host "Teste Verbindung zu: $NetworkPath" -ForegroundColor Cyan
    
    # Test for local drives first
    if ($NetworkPath -notlike "\\*") {
        $PathTest = Test-Path $NetworkPath -ErrorAction SilentlyContinue
        if ($PathTest) {
            Write-Host "Verbindung erfolgreich" -ForegroundColor Green
        } else {
            Write-Host "Verbindung fehlgeschlagen" -ForegroundColor Red
        }
        return
    }
    
    # Test for network paths (UNC) with temporary mount
    Write-Host "Teste Netzwerkpfad mit temporaerem Mount..." -ForegroundColor Cyan
    
    $TempDrive = "Y:"
    $MountSuccess = $false
    
    try {
        # Remove any existing mapping first
        net use $TempDrive /delete /y 2>$null
        
        # Try to mount with credentials if available
        if (-not [string]::IsNullOrEmpty($Config.Network.NetworkUser) -and -not [string]::IsNullOrEmpty($Config.Network.NetworkPassword)) {
            Write-Host "Versuche Mount mit Anmeldedaten..." -ForegroundColor Yellow
            $PlainPassword = Decrypt-Password $Config.Network.NetworkPassword
            $MapResult = net use $TempDrive $NetworkPath /user:$($Config.Network.NetworkUser) $PlainPassword /persistent:no
            if ($LASTEXITCODE -eq 0) {
                $MountSuccess = $true
                Write-Host "Mount mit Anmeldedaten erfolgreich" -ForegroundColor Green
            }
        }
        
        # If credential mount failed, try without credentials
        if (-not $MountSuccess) {
            Write-Host "Versuche Mount ohne Anmeldedaten..." -ForegroundColor Yellow
            $MapResult = net use $TempDrive $NetworkPath /persistent:no
            if ($LASTEXITCODE -eq 0) {
                $MountSuccess = $true
                Write-Host "Mount ohne Anmeldedaten erfolgreich" -ForegroundColor Green
            }
        }
        
        # Test the mounted path
        if ($MountSuccess) {
            $PathTest = Test-Path $TempDrive -ErrorAction SilentlyContinue
            if ($PathTest) {
                Write-Host "Verbindung erfolgreich" -ForegroundColor Green
                Write-Host "Netzwerkpfad kann erfolgreich gemountet werden" -ForegroundColor Green
            } else {
                Write-Host "Mount erfolgreich, aber Pfad nicht zugaenglich" -ForegroundColor Red
            }
        } else {
            Write-Host "Verbindung fehlgeschlagen" -ForegroundColor Red
            Write-Host "Netzwerkpfad kann nicht gemountet werden" -ForegroundColor Red
            Write-Host "Moegliche Ursachen:" -ForegroundColor Yellow
            Write-Host "- Netzwerk nicht verfuegbar" -ForegroundColor Yellow
            Write-Host "- Falsche Anmeldedaten" -ForegroundColor Yellow
            Write-Host "- Berechtigungen unzureichend" -ForegroundColor Yellow
            Write-Host "- Server nicht erreichbar" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "Fehler beim Testen der Netzwerkverbindung: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        # Clean up temporary mapping
        if ($MountSuccess) {
            net use $TempDrive /delete /y 2>$null
            Write-Host "Temporaerer Mount entfernt" -ForegroundColor Cyan
        }
    }
}

# Funktion zum Abrufen verfuegbarer Laufwerke fuer Backup
function Get-AvailableDrives {
    $Drives = @()
    
    # Lokale Laufwerke abrufen
    Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and $_.Size -gt 0 } | ForEach-Object {
        $FreeSpaceGB = [math]::Round($_.FreeSpace / 1GB, 1)
        $TotalSpaceGB = [math]::Round($_.Size / 1GB, 1)
        $Drives += [PSCustomObject]@{
            Drive = $_.DeviceID
            Label = $_.VolumeName
            FreeSpace = $FreeSpaceGB
            TotalSpace = $TotalSpaceGB
            Type = "Local Drive"
            Path = $_.DeviceID
        }
    }
    
    # Netzwerkpfad hinzufuegen falls Netzwerk-Backup aktiviert ist
    $Config = Read-Config
    if ($Config -and $Config.Network -and $Config.Network.EnableNetworkBackup -and -not [string]::IsNullOrEmpty($Config.Network.NetworkPath)) {
        $Drives += [PSCustomObject]@{
            Drive = "Network"
            Label = "Network Backup (UNC)"
            FreeSpace = "Unknown"
            TotalSpace = "Unknown"
            Type = "Network Drive"
            Path = $Config.Network.NetworkPath
        }
    }
    
    return $Drives
}

# Funktion zum Testen des Standard-Backup-Pfads mit temporaeren Mounts
function Test-DefaultBackupPath {
    $Config = Read-Config
    if ($Config -eq $null -or -not $Config.Backup -or -not $Config.Backup.PSObject.Properties['DefaultBackupPath'] -or [string]::IsNullOrEmpty($Config.Backup.DefaultBackupPath)) {
        Write-Host "Kein Standard-Backup-Pfad konfiguriert." -ForegroundColor Yellow
        return
    }
    
    $DefaultPath = $Config.Backup.DefaultBackupPath
    Write-Host "Teste Standard-Backup-Pfad: $DefaultPath" -ForegroundColor Cyan
    
    # Test für lokale Laufwerke
    if ($DefaultPath -notlike "\\*") {
        $PathTest = Test-Path $DefaultPath -ErrorAction SilentlyContinue
        if ($PathTest) {
            Write-Host "Standard-Backup-Pfad ist erreichbar" -ForegroundColor Green
        } else {
            Write-Host "Standard-Backup-Pfad ist nicht erreichbar" -ForegroundColor Red
            Write-Host "Das lokale Laufwerk ist moeglicherweise nicht verfuegbar." -ForegroundColor Yellow
        }
        return
    }
    
    # Test fuer Netzwerkpfade (UNC) mit temporaerem Mount
    Write-Host "Teste Netzwerkpfad mit temporaerem Mount..." -ForegroundColor Cyan
    
    $TempDrive = "Z:"
    $MountSuccess = $false
    
    try {
        # Vorhandene Mappings entfernen
        net use $TempDrive /delete /y 2>$null
        
        # Mount mit Anmeldedaten versuchen falls verfuegbar
        if ($Config.Network -and -not [string]::IsNullOrEmpty($Config.Network.NetworkUser) -and -not [string]::IsNullOrEmpty($Config.Network.NetworkPassword)) {
            Write-Host "Versuche Mount mit Anmeldedaten..." -ForegroundColor Yellow
            $PlainPassword = Decrypt-Password $Config.Network.NetworkPassword
            $MapResult = net use $TempDrive $DefaultPath /user:$($Config.Network.NetworkUser) $PlainPassword /persistent:no
            if ($LASTEXITCODE -eq 0) {
                $MountSuccess = $true
                Write-Host "Mount mit Anmeldedaten erfolgreich" -ForegroundColor Green
            }
        }
        
        # Falls Mount mit Anmeldedaten fehlschlaegt, ohne Anmeldedaten versuchen
        if (-not $MountSuccess) {
            Write-Host "Versuche Mount ohne Anmeldedaten..." -ForegroundColor Yellow
            $MapResult = net use $TempDrive $DefaultPath /persistent:no
            if ($LASTEXITCODE -eq 0) {
                $MountSuccess = $true
                Write-Host "Mount ohne Anmeldedaten erfolgreich" -ForegroundColor Green
            }
        }
        
        # Den gemounteten Pfad testen
        if ($MountSuccess) {
            $PathTest = Test-Path $TempDrive -ErrorAction SilentlyContinue
            if ($PathTest) {
                Write-Host "Standard-Backup-Pfad ist erreichbar" -ForegroundColor Green
                Write-Host "Netzwerkpfad kann erfolgreich gemountet werden" -ForegroundColor Green
            } else {
                Write-Host "Mount erfolgreich, aber Pfad nicht zugaenglich" -ForegroundColor Red
            }
        } else {
            Write-Host "Standard-Backup-Pfad ist nicht erreichbar" -ForegroundColor Red
            Write-Host "Netzwerkpfad kann nicht gemountet werden" -ForegroundColor Red
            Write-Host "Moegliche Ursachen:" -ForegroundColor Yellow
            Write-Host "- Netzwerk nicht verfuegbar" -ForegroundColor Yellow
            Write-Host "- Falsche Anmeldedaten" -ForegroundColor Yellow
            Write-Host "- Berechtigungen unzureichend" -ForegroundColor Yellow
            Write-Host "- Server nicht erreichbar" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "Fehler beim Testen des Netzwerkpfads: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        # Temporaeres Mapping aufraeumen
        if ($MountSuccess) {
            net use $TempDrive /delete /y 2>$null
            Write-Host "Temporaerer Mount entfernt" -ForegroundColor Cyan
        }
    }
}

# Funktion zum Konfigurieren des Standard-Backup-Pfads
function Set-DefaultBackupPath {
    $Config = Read-Config
    if ($Config -eq $null) {
        $Config = [PSCustomObject]@{
            Network = [PSCustomObject]@{
                EnableNetworkBackup = $false
                NetworkPath = ""
                NetworkUser = ""
                NetworkPassword = ""
            }
            Backup = [PSCustomObject]@{
                DefaultShutdown = $false
                DefaultNoWindowsold = $false
                DefaultBackupPath = ""
            }
            Advanced = [PSCustomObject]@{
                LogLevel = 3
                ScratchDirThresholdGB = 20
            }
        }
    } else {
        # Sicherstellen dass Backup-Objekt existiert und DefaultBackupPath-Eigenschaft hat
        if (-not $Config.Backup) {
            $Config.Backup = [PSCustomObject]@{
                DefaultShutdown = $false
                DefaultNoWindowsold = $false
                DefaultBackupPath = ""
            }
        } else {
            # DefaultBackupPath-Eigenschaft hinzufuegen falls sie nicht existiert
            if (-not $Config.Backup.PSObject.Properties['DefaultBackupPath']) {
                $Config.Backup | Add-Member -MemberType NoteProperty -Name "DefaultBackupPath" -Value ""
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== Standard-Backup-Pfad konfigurieren ===" -ForegroundColor Cyan
    Write-Host ""
    
    $AvailableDrives = Get-AvailableDrives
    if ($AvailableDrives.Count -eq 0) {
        Write-Host "Keine verfuegbaren Laufwerke gefunden." -ForegroundColor Red
        return
    }
    
    Write-Host "Verfuegbare Laufwerke:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $AvailableDrives.Count; $i++) {
        $Drive = $AvailableDrives[$i]
        Write-Host "  $($i + 1). $($Drive.Drive) - $($Drive.Type) ($($Drive.FreeSpace) GB frei)"
        if ($Drive.Type -eq "Local Drive") {
            Write-Host "     Label: $($Drive.Label), Gesamt: $($Drive.TotalSpace) GB"
        }
        Write-Host "     Pfad: $($Drive.Path)"
        Write-Host ""
    }
    
    $CurrentDefault = if ($Config.Backup.PSObject.Properties['DefaultBackupPath'] -and $Config.Backup.DefaultBackupPath) { $Config.Backup.DefaultBackupPath } else { "[Nicht gesetzt]" }
    Write-Host "Aktueller Standard-Pfad: $CurrentDefault" -ForegroundColor Cyan
    Write-Host ""
    
    do {
        $Choice = Read-Host "Laufwerk auswaehlen (1-$($AvailableDrives.Count)) oder Enter fuer aktuellen Wert beibehalten"
        
        if ([string]::IsNullOrEmpty($Choice)) {
            Write-Host "Standard-Pfad unveraendert." -ForegroundColor Yellow
            return
        }
        
        $Index = [int]$Choice - 1
        if ($Index -ge 0 -and $Index -lt $AvailableDrives.Count) {
            $SelectedDrive = $AvailableDrives[$Index]
            $Config.Backup.DefaultBackupPath = $SelectedDrive.Path
            Write-Config $Config
            Write-Host ""
            Write-Host "Standard-Backup-Pfad gesetzt auf: $($SelectedDrive.Path)" -ForegroundColor Green
            
            # Den neuen Pfad testen
            Write-Host ""
            Test-DefaultBackupPath
            return
        } else {
            Write-Host "Ungueltige Auswahl. Bitte waehlen Sie eine Zahl zwischen 1 und $($AvailableDrives.Count)." -ForegroundColor Red
        }
    } while ($true)
}

# Funktion zum Konfigurieren der Netzwerk-Einstellungen
function Set-NetworkConfig {
    $Config = Read-Config
    if ($Config -eq $null) {
        $Config = [PSCustomObject]@{
            Network = [PSCustomObject]@{
                EnableNetworkBackup = $false
                NetworkPath = ""
                NetworkUser = ""
                NetworkPassword = ""
            }
            Backup = [PSCustomObject]@{
                DefaultShutdown = $false
                DefaultNoWindowsold = $false
                DefaultBackupPath = ""
            }
            Advanced = [PSCustomObject]@{
                LogLevel = 3
                ScratchDirThresholdGB = 20
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== Netzwerk-Konfiguration ===" -ForegroundColor Cyan
    Write-Host ""
    
    $EnableInput = Read-Host "Netzwerk-Backup aktivieren? (true/false) [$($Config.Network.EnableNetworkBackup)]"
    if (-not [string]::IsNullOrEmpty($EnableInput)) {
        $Config.Network.EnableNetworkBackup = $EnableInput.ToLower() -eq "true"
    }
    
    $PathInput = Read-Host "Netzwerk-Pfad [$($Config.Network.NetworkPath)]"
    if (-not [string]::IsNullOrEmpty($PathInput)) {
        $Config.Network.NetworkPath = $PathInput
    }
    
    $UserInput = Read-Host "Netzwerk-Benutzer [$($Config.Network.NetworkUser)]"
    if (-not [string]::IsNullOrEmpty($UserInput)) {
        $Config.Network.NetworkUser = $UserInput
    }
    
    $PasswordInput = Read-Host "Netzwerk-Passwort (wird verschluesselt)" -AsSecureString
    if ($PasswordInput -ne $null) {
        $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordInput))
        $Config.Network.NetworkPassword = Encrypt-Password $PlainPassword
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordInput))
    }
    
    Write-Config $Config
    Write-Host ""
    Write-Host "Konfiguration gespeichert." -ForegroundColor Green
}

# Funktion zum Konfigurieren der Backup-Optionen
function Set-BackupConfig {
    $Config = Read-Config
    if ($Config -eq $null) {
        $Config = [PSCustomObject]@{
            Network = [PSCustomObject]@{
                EnableNetworkBackup = $false
                NetworkPath = ""
                NetworkUser = ""
                NetworkPassword = ""
            }
            Backup = [PSCustomObject]@{
                DefaultShutdown = $false
                DefaultNoWindowsold = $false
                DefaultBackupPath = ""
            }
            Advanced = [PSCustomObject]@{
                LogLevel = 3
                ScratchDirThresholdGB = 20
            }
        }
    } else {
        # Sicherstellen dass Backup-Objekt existiert und DefaultBackupPath-Eigenschaft hat
        if (-not $Config.Backup) {
            $Config.Backup = [PSCustomObject]@{
                DefaultShutdown = $false
                DefaultNoWindowsold = $false
                DefaultBackupPath = ""
            }
        } else {
            # DefaultBackupPath-Eigenschaft hinzufuegen falls sie nicht existiert
            if (-not $Config.Backup.PSObject.Properties['DefaultBackupPath']) {
                $Config.Backup | Add-Member -MemberType NoteProperty -Name "DefaultBackupPath" -Value ""
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== Backup-Konfiguration ===" -ForegroundColor Cyan
    Write-Host ""
    
    $ShutdownInput = Read-Host "Herunterfahren nach Backup? (true/false) [$($Config.Backup.DefaultShutdown)]"
    if (-not [string]::IsNullOrEmpty($ShutdownInput)) {
        $Config.Backup.DefaultShutdown = $ShutdownInput.ToLower() -eq "true"
    }
    
    $NoWindowsoldInput = Read-Host "Windows.old ausschliessen? (true/false) [$($Config.Backup.DefaultNoWindowsold)]"
    if (-not [string]::IsNullOrEmpty($NoWindowsoldInput)) {
        $Config.Backup.DefaultNoWindowsold = $NoWindowsoldInput.ToLower() -eq "true"
    }
    
    
    Write-Host ""
    $SetDefaultPath = Read-Host "Standard-Backup-Pfad konfigurieren? (y/n)"
    if ($SetDefaultPath.ToLower() -eq "y" -or $SetDefaultPath.ToLower() -eq "yes") {
        Set-DefaultBackupPath
    }
    
    Write-Config $Config
    Write-Host ""
    Write-Host "Konfiguration gespeichert." -ForegroundColor Green
}

# Hauptlogik des Konfigurations-Managers
if ($ShowCurrent) {
    Show-CurrentConfig
    exit
}

if ($Reset) {
    Reset-Config
    exit
}

if ($TestConnection) {
    Test-NetworkConnection
    exit
}

# Interaktiver Modus des Konfigurations-Managers
do {
    Write-Host ""
    Write-Host "=== WIMaster Konfigurations-Manager ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Konfiguration anzeigen"
    Write-Host "2. Netzwerk-Share konfigurieren"
    Write-Host "3. Backup-Optionen konfigurieren"
    Write-Host "4. Standard-Backup-Pfad konfigurieren"
    Write-Host "5. Standard-Backup-Pfad testen"
    Write-Host "6. Verbindung testen"
    Write-Host "7. Zuruecksetzen"
    Write-Host "8. Beenden"
    Write-Host ""
    
    $Choice = Read-Host "Option (1-8)"
    
    switch ($Choice) {
        "1" { Show-CurrentConfig }
        "2" { Set-NetworkConfig }
        "3" { Set-BackupConfig }
        "4" { Set-DefaultBackupPath }
        "5" { Test-DefaultBackupPath }
        "6" { Test-NetworkConnection }
        "7" { 
            $Confirm = Read-Host "Konfiguration zuruecksetzen? (yes/no)"
            if ($Confirm.ToLower() -eq "yes") {
                Reset-Config
            }
        }
        "8" { 
            Write-Host "Auf Wiedersehen!" -ForegroundColor Green
            break 
        }
        default { 
            Write-Host "Ungueltige Option." -ForegroundColor Red 
        }
    }
    
    if ($Choice -ne "8") {
        Read-Host "Enter zum Fortfahren..."
    }
    
} while ($Choice -ne "8")
