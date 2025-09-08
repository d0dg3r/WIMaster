# WIMaster Setup.exe

## Übersicht

Die `Setup.exe` ist ein C# Wrapper, der das PowerShell-Script `WIMaster-Setup.ps1` automatisch mit Administrator-Rechten ausführt.

## Vorteile der Setup.exe

- ✅ **Automatische UAC-Elevation**: Fordert Administrator-Rechte automatisch an
- ✅ **Systemprüfung**: Überprüft Windows-Version und PowerShell-Verfügbarkeit  
- ✅ **Benutzerfreundlich**: Kein manuelles "Als Administrator ausführen" erforderlich
- ✅ **Fehlerbehandlung**: Zeigt aussagekräftige Fehlermeldungen an
- ✅ **Icon-Support**: Verwendet das WIMaster-Icon wenn verfügbar

## Erstellen der Setup.exe

### Methode 1: Batch-Script (Einfach)
```batch
Build-Setup.bat
```

### Methode 2: PowerShell-Script (Erweitert)
```powershell
.\Build-Setup.ps1
```

## Voraussetzungen für die Kompilierung

- **Windows 10/11** mit .NET Framework 4.0 oder neuer
- **C# Compiler** (eine der folgenden Optionen):
  - Visual Studio 2019/2022 (Community, Professional, Enterprise)
  - Visual Studio Build Tools
  - .NET Framework Developer Pack

### Installation der Build-Tools

**Option 1: Visual Studio Community (Empfohlen)**
1. Download: https://visualstudio.microsoft.com/de/vs/community/
2. Installation mit "C# Desktop-Entwicklung" Workload

**Option 2: Build Tools**
1. Download: https://visualstudio.microsoft.com/de/downloads/#build-tools-for-visual-studio-2022
2. Installation mit ".NET build tools" Komponente

**Option 3: .NET Framework Developer Pack**
1. Download: https://dotnet.microsoft.com/download/dotnet-framework
2. Installation des aktuellen Developer Packs

## Verwendung

### 1. Setup.exe erstellen
```batch
# Kompilierung starten
Build-Setup.bat

# Oder mit PowerShell
.\Build-Setup.ps1
```

### 2. Setup.exe verwenden
- Doppelklick auf `Setup.exe`
- UAC-Dialog mit "Ja" bestätigen
- WIMaster-Setup startet automatisch

## Dateistruktur

```
WIMaster/
├── Setup.exe                    # ← Hauptanwendung
├── WIMaster-Setup.ps1           # ← PowerShell-Script (erforderlich)
├── WIMaster-Setup.cs            # ← C# Quellcode
├── Build-Setup.bat              # ← Build-Script (Batch)
├── Build-Setup.ps1              # ← Build-Script (PowerShell)
├── WIMaster_Ico.ico             # ← Icon (optional)
└── README-Setup.md              # ← Diese Datei
```

## Funktionsweise

1. **Start**: `Setup.exe` wird gestartet
2. **Admin-Prüfung**: Überprüft ob bereits als Administrator ausgeführt
3. **UAC-Elevation**: Falls nicht Admin, fordert UAC-Rechte an und startet neu
4. **System-Prüfung**: 
   - Windows-Version (min. Build 19042)
   - PowerShell-Version (min. 3.0)
   - Script-Verfügbarkeit
5. **Ausführung**: Startet `WIMaster-Setup.ps1` mit Bypass-Policy

## Fehlerbehandlung

Die Setup.exe behandelt folgende Szenarien:

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| UAC-Dialog abgebrochen | Benutzer hat Admin-Rechte verweigert | Setup erneut starten und UAC akzeptieren |
| Script nicht gefunden | `WIMaster-Setup.ps1` fehlt | Script in gleiches Verzeichnis kopieren |
| Windows zu alt | Build < 19042 | Windows 10 20H2 oder neuer installieren |
| PowerShell zu alt | Version < 3.0 | PowerShell aktualisieren |

## Build-Optionen

### Standard-Kompilierung
```batch
csc /target:winexe /platform:anycpu /optimize+ /reference:System.Windows.Forms.dll /reference:Microsoft.Win32.Registry.dll /out:Setup.exe WIMaster-Setup.cs
```

### Mit Icon
```batch
csc /target:winexe /platform:anycpu /optimize+ /win32icon:WIMaster_Ico.ico /reference:System.Windows.Forms.dll /reference:Microsoft.Win32.Registry.dll /out:Setup.exe WIMaster-Setup.cs
```

## Technische Details

- **Framework**: .NET Framework 4.0+
- **Sprache**: C# 
- **GUI**: Windows Forms (für Fehlerdialoge)
- **Zielplattform**: AnyCPU
- **Optimierung**: Aktiviert
- **Ausgabetyp**: Windows-Anwendung (winexe)

## Deployment

Für die Verteilung benötigen Sie:
- `Setup.exe` (kompilierte Anwendung)
- `WIMaster-Setup.ps1` (PowerShell-Script)
- Alle WIMaster-Dateien (Icons, Configs, etc.)

Die Setup.exe kann auch in einem Setup-Package (MSI, NSIS, etc.) verwendet werden.

## Lizenz

Gleiche Lizenz wie WIMaster - siehe Haupt-README.

## Support

Bei Problemen:
1. Prüfen Sie die Voraussetzungen
2. Verwenden Sie die Build-Scripts
3. Kontaktieren Sie: joe@devops-geek.net
