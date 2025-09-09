#Requires -RunAsAdministrator
#Requires -Version 3.0

<#
.SYNOPSIS
  WIMaster-Update - Update-Tool fuer bestehende WIMaster USB-Sticks
.DESCRIPTION
  Aktualisiert einen bereits eingerichteten WIMaster USB-Stick mit den neuesten Dateien
  ohne Neuformatierung oder Neueinrichtung des Windows-Setups.
.NOTES
  Autor: Joachim Mild <joe@devops-geek.net>
  Creation Date: 2025-01-27
  Basierend auf WIMaster - Windows System Backup Tool
#>

# Zeichenkodierung fuer korrekte Umlaut-Darstellung setzen
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# GUI-Komponenten laden
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$HilfeGUI = " Entwickelt von Joachim Mild <joe@devops-geek.net>`nBasierend auf c't-WIMage von Axel Vahldiek`n"
$WindowTitle = "WIMaster: Update"

# Pfade definieren (Development-Umgebung)
$Icon = Join-Path $PSScriptRoot "WIMaster_Ico.ico"

##############################
# Git-Informationen sammeln #
##############################

Function Get-GitInfo {
    try {
        $GitInfo = @{}
        
        # Commit Hash
        try {
            $GitInfo.CommitHash = (git rev-parse HEAD 2>$null).Trim()
            $GitInfo.CommitShort = (git rev-parse --short HEAD 2>$null).Trim()
        } catch {
            $GitInfo.CommitHash = "Unknown"
            $GitInfo.CommitShort = "Unknown"
        }
        
        # Branch
        try {
            $GitInfo.Branch = (git branch --show-current 2>$null).Trim()
            if (-not $GitInfo.Branch) {
                $GitInfo.Branch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
            }
        } catch {
            $GitInfo.Branch = "Unknown"
        }
        
        # Letzter Commit
        try {
            $GitInfo.LastCommitDate = (git log -1 --format="%cd" --date=iso 2>$null).Trim()
            $GitInfo.LastCommitMessage = (git log -1 --format="%s" 2>$null).Trim()
            $GitInfo.LastCommitAuthor = (git log -1 --format="%an" 2>$null).Trim()
        } catch {
            $GitInfo.LastCommitDate = "Unknown"
            $GitInfo.LastCommitMessage = "Unknown"
            $GitInfo.LastCommitAuthor = "Unknown"
        }
        
        # Repository Status
        try {
            $GitStatus = (git status --porcelain 2>$null)
            $GitInfo.HasChanges = $GitStatus.Length -gt 0
            $GitInfo.ModifiedFiles = ($GitStatus -split "`n" | Where-Object { $_.Trim() }).Count
        } catch {
            $GitInfo.HasChanges = $false
            $GitInfo.ModifiedFiles = 0
        }
        
        # Remote URL
        try {
            $GitInfo.RemoteUrl = (git remote get-url origin 2>$null).Trim()
        } catch {
            $GitInfo.RemoteUrl = "Unknown"
        }
        
        return $GitInfo
    } catch {
        return @{
            CommitHash = "No Git Repository"
            CommitShort = "No Git"
            Branch = "Unknown"
            LastCommitDate = "Unknown"
            LastCommitMessage = "Unknown"
            LastCommitAuthor = "Unknown"
            HasChanges = $false
            ModifiedFiles = 0
            RemoteUrl = "Unknown"
        }
    }
}

############################
# Version.txt erstellen   #
############################

Function Create-VersionFile {
    param([string]$TargetPath)
    
    $GitInfo = Get-GitInfo
    $UpdateDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $VersionContent = @"
===============================================
WIMaster - Windows System Backup Tool
Version Information
===============================================

Update-Datum:     $UpdateDate
Computer:         $env:COMPUTERNAME
Benutzer:         $env:USERNAME

Git-Informationen:
------------------
Repository:       $($GitInfo.RemoteUrl)
Branch:           $($GitInfo.Branch)
Commit (kurz):    $($GitInfo.CommitShort)
Commit (voll):    $($GitInfo.CommitHash)

Letzter Commit:
---------------
Datum:            $($GitInfo.LastCommitDate)
Autor:            $($GitInfo.LastCommitAuthor)
Nachricht:        $($GitInfo.LastCommitMessage)

Repository-Status:
------------------
Uncommitted Changes: $(if ($GitInfo.HasChanges) { "JA ($($GitInfo.ModifiedFiles) Dateien)" } else { "NEIN" })

System-Informationen:
---------------------
PowerShell:       $($PSVersionTable.PSVersion)
Windows:          $(Get-CimInstance Win32_OperatingSystem | ForEach-Object { "$($_.Caption) Build $($_.BuildNumber)" })
.NET Framework:   $([System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription)

===============================================
"@

    $VersionContent | Out-File -FilePath $TargetPath -Encoding UTF8
    return $UpdateDate
}

############################
# Update-Log erstellen    #
############################

Function Write-UpdateLog {
    param(
        [string]$LogPath,
        [string]$UpdateDate,
        [array]$UpdatedFiles
    )
    
    $GitInfo = Get-GitInfo
    
    $LogEntry = @"

===============================================
Update durchgefuehrt am: $UpdateDate
===============================================

Git-Status:
-----------
Branch: $($GitInfo.Branch)
Commit: $($GitInfo.CommitShort) ($($GitInfo.CommitHash))
Letzter Commit: $($GitInfo.LastCommitMessage)

Aktualisierte Dateien ($($UpdatedFiles.Count)):
$(($UpdatedFiles | ForEach-Object { "  - $_" }) -join "`n")

System: $env:COMPUTERNAME ($env:USERNAME)
PowerShell: $($PSVersionTable.PSVersion)

===============================================

"@

    $LogEntry | Out-File -FilePath $LogPath -Append -Encoding UTF8
}

##########################
# USB-Datentraeger finden #
##########################

Function Get-USBDrives {
    $USBDrives = @()
    Get-Disk | Where-Object { $_.BusType -eq 'USB' } | ForEach-Object {
        $Partitions = Get-Partition -DiskNumber $_.Number -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter }
        $Partitions | ForEach-Object {
            $Volume = Get-Volume -DriveLetter $_.DriveLetter
            # Pruefe ob es ein WIMaster USB-Stick ist
            $WIMasterPath = Join-Path ($_.DriveLetter + ":") "WIMaster"
            if (Test-Path $WIMasterPath) {
                $USBDrives += @{
                    DriveLetter = $_.DriveLetter
                    Label = $Volume.FileSystemLabel
                    Size = [math]::Round($Volume.Size / 1GB, 2)
                    WIMasterPath = $WIMasterPath
                    Description = "$($_.DriveLetter): ($($Volume.FileSystemLabel)) - $([math]::Round($Volume.Size / 1GB, 2)) GB"
                }
            }
        }
    }
    return $USBDrives
}

##############################
# Update-Dateien kopieren   #
##############################

Function Update-WIMasterFiles {
    param(
        [string]$TargetDrive,
        [ref]$UpdatedFiles
    )
    
    $TargetRoot = $TargetDrive + ":"
    $TargetWIMaster = Join-Path $TargetRoot "WIMaster"
    $UpdatedFilesList = @()
    
    Write-Host "Aktualisiere WIMaster-Dateien auf $TargetDrive..." -ForegroundColor Green
    
    # Erstelle Verzeichnisse falls nicht vorhanden
    $Directories = @("$TargetWIMaster\ps1", "$TargetWIMaster\docs", "$TargetRoot\logs")
    foreach ($Dir in $Directories) {
        if (-not (Test-Path $Dir)) {
            New-Item -Path $Dir -ItemType Directory -Force | Out-Null
            Write-Host "  Verzeichnis erstellt: $Dir" -ForegroundColor Yellow
        }
    }
    
    # PowerShell-Skripte aktualisieren
    Write-Host "  Kopiere PowerShell-Skripte..." -ForegroundColor Cyan
    $PS1Files = Get-ChildItem -Path (Join-Path $PSScriptRoot "ps1") -Filter "*.ps1"
    foreach ($File in $PS1Files) {
        $TargetPath = Join-Path "$TargetWIMaster\ps1" $File.Name
        Copy-Item -Path $File.FullName -Destination $TargetPath -Force
        $UpdatedFilesList += "WIMaster\ps1\$($File.Name)"
        Write-Host "    + $($File.Name)" -ForegroundColor Gray
    }
    
    # Batch-Dateien aktualisieren
    Write-Host "  Kopiere Batch-Dateien..." -ForegroundColor Cyan
    $BatFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "bat") -Filter "*.bat"
    foreach ($File in $BatFiles) {
        $TargetPath = Join-Path $TargetRoot $File.Name
        Copy-Item -Path $File.FullName -Destination $TargetPath -Force
        $UpdatedFilesList += $File.Name
        Write-Host "    + $($File.Name)" -ForegroundColor Gray
    }
    
    # Tools aktualisieren
    Write-Host "  Kopiere Tools..." -ForegroundColor Cyan
    $ToolsPath = Join-Path $PSScriptRoot "tools"
    if (Test-Path $ToolsPath) {
        $ToolFiles = Get-ChildItem -Path $ToolsPath
        foreach ($File in $ToolFiles) {
            $TargetPath = Join-Path $TargetWIMaster $File.Name
            Copy-Item -Path $File.FullName -Destination $TargetPath -Force
            $UpdatedFilesList += "WIMaster\$($File.Name)"
            Write-Host "    + $($File.Name)" -ForegroundColor Gray
        }
    }
    
    # Dokumentation aktualisieren
    Write-Host "  Kopiere Dokumentation..." -ForegroundColor Cyan
    $DocsPath = Join-Path $PSScriptRoot "docs"
    if (Test-Path $DocsPath) {
        $DocFiles = Get-ChildItem -Path $DocsPath
        foreach ($File in $DocFiles) {
            $TargetPath = Join-Path "$TargetWIMaster\docs" $File.Name
            Copy-Item -Path $File.FullName -Destination $TargetPath -Force
            $UpdatedFilesList += "WIMaster\docs\$($File.Name)"
            Write-Host "    + $($File.Name)" -ForegroundColor Gray
        }
    }
    
    # Template-Dateien aktualisieren
    Write-Host "  Kopiere Templates..." -ForegroundColor Cyan
    $TemplatesPath = Join-Path $PSScriptRoot "templates"
    if (Test-Path $TemplatesPath) {
        $TemplateFiles = Get-ChildItem -Path $TemplatesPath
        foreach ($File in $TemplateFiles) {
            if ($File.Name -eq "ei.cfg") {
                # ei.cfg nach Sources kopieren
                $TargetPath = Join-Path "$TargetRoot\Sources" $File.Name
                if (Test-Path (Split-Path $TargetPath)) {
                    Copy-Item -Path $File.FullName -Destination $TargetPath -Force
                    $UpdatedFilesList += "Sources\$($File.Name)"
                    Write-Host "    + $($File.Name) -> Sources\" -ForegroundColor Gray
                }
            }
        }
    }
    
    # Icon und andere Ressourcen
    Write-Host "  Kopiere Ressourcen..." -ForegroundColor Cyan
    $ResourceFiles = @("WIMaster_Ico.ico", "autorun.inf")
    foreach ($FileName in $ResourceFiles) {
        $SourcePath = Join-Path $PSScriptRoot $FileName
        if (Test-Path $SourcePath) {
            $TargetPath = Join-Path $TargetWIMaster $FileName
            Copy-Item -Path $SourcePath -Destination $TargetPath -Force
            $UpdatedFilesList += "WIMaster\$FileName"
            Write-Host "    + $FileName" -ForegroundColor Gray
        }
    }
    
    # Menu-Dateien
    Write-Host "  Kopiere Menu-Dateien..." -ForegroundColor Cyan
    $MenuPath = Join-Path $PSScriptRoot "menu"
    if (Test-Path $MenuPath) {
        $MenuFiles = Get-ChildItem -Path $MenuPath
        foreach ($File in $MenuFiles) {
            $TargetPath = Join-Path $TargetRoot $File.Name
            Copy-Item -Path $File.FullName -Destination $TargetPath -Force
            $UpdatedFilesList += $File.Name
            Write-Host "    + $($File.Name)" -ForegroundColor Gray
        }
    }
    
    # Scripts-Verzeichnis aktualisieren
    Write-Host "  Kopiere erweiterte Scripts..." -ForegroundColor Cyan
    $ScriptsPath = Join-Path $PSScriptRoot "Scripts"
    if (Test-Path $ScriptsPath) {
        $TargetScriptsPath = Join-Path $TargetWIMaster "Scripts"
        if (-not (Test-Path $TargetScriptsPath)) {
            New-Item -Path $TargetScriptsPath -ItemType Directory -Force | Out-Null
        }
        Copy-Item -Path "$ScriptsPath\*" -Destination $TargetScriptsPath -Recurse -Force
        $ScriptFiles = Get-ChildItem -Path $ScriptsPath -Recurse -File
        foreach ($File in $ScriptFiles) {
            $RelativePath = $File.FullName.Replace($ScriptsPath, "").TrimStart("\")
            $UpdatedFilesList += "WIMaster\Scripts\$RelativePath"
        }
        Write-Host "    + Scripts-Verzeichnis komplett aktualisiert" -ForegroundColor Gray
    }
    
    $UpdatedFiles.Value = $UpdatedFilesList
    Write-Host "Update abgeschlossen! $($UpdatedFilesList.Count) Dateien aktualisiert." -ForegroundColor Green
}

########################
# GUI fuer USB-Auswahl #
########################

Function Show-USBSelectionDialog {
    $USBDrives = Get-USBDrives
    
    if ($USBDrives.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Es wurden keine WIMaster USB-Sticks gefunden.`n`nStellen Sie sicher, dass:`n- Der USB-Stick angeschlossen ist`n- WIMaster bereits eingerichtet wurde`n- Das WIMaster-Verzeichnis vorhanden ist",
            "Kein WIMaster USB-Stick gefunden",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return $null
    }
    
    # GUI erstellen
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "WIMaster Update - USB-Stick auswaehlen"
    $Form.Size = New-Object System.Drawing.Size(600, 400)
    $Form.StartPosition = 'CenterScreen'
    $Form.FormBorderStyle = 'FixedDialog'
    $Form.MaximizeBox = $false
    
    if (Test-Path $Icon) {
        $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)
    }
    
    # Ueberschrift
    $Label = New-Object System.Windows.Forms.Label
    $Label.Text = "Waehlen Sie den WIMaster USB-Stick aus, der aktualisiert werden soll:"
    $Label.Location = New-Object System.Drawing.Point(20, 20)
    $Label.Size = New-Object System.Drawing.Size(550, 30)
    $Label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($Label)
    
    # ListBox fuer USB-Sticks
    $ListBox = New-Object System.Windows.Forms.ListBox
    $ListBox.Location = New-Object System.Drawing.Point(20, 60)
    $ListBox.Size = New-Object System.Drawing.Size(550, 200)
    $ListBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    
    foreach ($Drive in $USBDrives) {
        [void]$ListBox.Items.Add($Drive.Description)
    }
    
    if ($ListBox.Items.Count -gt 0) {
        $ListBox.SelectedIndex = 0
    }
    
    $Form.Controls.Add($ListBox)
    
    # Warnung
    $WarningLabel = New-Object System.Windows.Forms.Label
    $WarningLabel.Text = "ACHTUNG: Alle WIMaster-Dateien werden ueberschrieben!`nBenutzer-Konfigurationen bleiben erhalten."
    $WarningLabel.Location = New-Object System.Drawing.Point(20, 280)
    $WarningLabel.Size = New-Object System.Drawing.Size(550, 40)
    $WarningLabel.ForeColor = [System.Drawing.Color]::DarkOrange
    $WarningLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($WarningLabel)
    
    # Buttons
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Text = "Update starten"
    $OKButton.Location = New-Object System.Drawing.Point(380, 330)
    $OKButton.Size = New-Object System.Drawing.Size(100, 30)
    $OKButton.DialogResult = 'OK'
    $Form.Controls.Add($OKButton)
    
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Text = "Abbrechen"
    $CancelButton.Location = New-Object System.Drawing.Point(490, 330)
    $CancelButton.Size = New-Object System.Drawing.Size(80, 30)
    $CancelButton.DialogResult = 'Cancel'
    $Form.Controls.Add($CancelButton)
    
    $Form.AcceptButton = $OKButton
    $Form.CancelButton = $CancelButton
    
    $Result = $Form.ShowDialog()
    
    if ($Result -eq 'OK' -and $ListBox.SelectedIndex -ge 0) {
        return $USBDrives[$ListBox.SelectedIndex]
    }
    
    return $null
}

################
# Haupt-Logik  #
################

try {
    Write-Host "WIMaster Update Tool" -ForegroundColor Yellow
    Write-Host "====================" -ForegroundColor Yellow
    Write-Host ""
    
    # USB-Stick auswaehlen
    $SelectedUSB = Show-USBSelectionDialog
    if (-not $SelectedUSB) {
        Write-Host "Update abgebrochen." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Ausgewaehlter USB-Stick: $($SelectedUSB.Description)" -ForegroundColor Green
    Write-Host ""
    
    # Version.txt erstellen
    Write-Host "Erstelle Version.txt..." -ForegroundColor Cyan
    $VersionPath = Join-Path ($SelectedUSB.DriveLetter + ":") "Version.txt"
    $UpdateDate = Create-VersionFile -TargetPath $VersionPath
    Write-Host "+ Version.txt erstellt: $VersionPath" -ForegroundColor Green
    
    # Update durchfuehren
    $UpdatedFiles = @()
    Update-WIMasterFiles -TargetDrive $SelectedUSB.DriveLetter -UpdatedFiles ([ref]$UpdatedFiles)
    
    # Update-Log schreiben
    Write-Host "Schreibe Update-Log..." -ForegroundColor Cyan
    $LogPath = Join-Path ($SelectedUSB.DriveLetter + ":") "logs\WIMaster-Update.log"
    Write-UpdateLog -LogPath $LogPath -UpdateDate $UpdateDate -UpdatedFiles $UpdatedFiles
    Write-Host "+ Update-Log geschrieben: $LogPath" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Update erfolgreich abgeschlossen!" -ForegroundColor Green
    Write-Host "   $($UpdatedFiles.Count) Dateien wurden aktualisiert." -ForegroundColor White
    Write-Host "   Version.txt: $VersionPath" -ForegroundColor White
    Write-Host "   Update-Log: $LogPath" -ForegroundColor White
    
    # Erfolgs-Dialog
    [System.Windows.Forms.MessageBox]::Show(
        "Update erfolgreich abgeschlossen!`n`n$($UpdatedFiles.Count) Dateien wurden aktualisiert.`n`nVersion.txt und Update-Log wurden erstellt.",
        "Update erfolgreich",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    
} catch {
    $ErrorMessage = "Fehler beim Update: $($_.Exception.Message)"
    Write-Host $ErrorMessage -ForegroundColor Red
    [System.Windows.Forms.MessageBox]::Show(
        $ErrorMessage,
        "Update-Fehler",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}