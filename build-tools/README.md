# WIMaster Setup.exe Build Tools

Dieses Verzeichnis enthält alle Dateien zum Erstellen der `Setup.exe` für WIMaster.

## 📁 Dateien in diesem Ordner

### 🔧 Build-Scripts
- **`Build-Setup.bat`** - Einfaches Batch-Script für die Kompilierung
- **`Build-Setup.ps1`** - Erweiterte PowerShell-Version mit intelligenter Compiler-Suche  
- **`Quick-Build.bat`** - Schnelle Kompilierung mit optionalem Test

### 💻 Quellcode
- **`WIMaster-Setup.cs`** - C# Quellcode für die Setup.exe

### 📖 Dokumentation
- **`README-Setup.md`** - Vollständige Anleitung zur Setup.exe
- **`Setup-Integration.md`** - Integrationsleitfaden für bestehende Systeme
- **`GitHub-Actions-Setup.md`** - GitHub Actions Konfiguration und Verwendung

## 🚀 Setup.exe erstellen

### Schnellstart
```batch
cd build-tools
Quick-Build.bat
```

### Detaillierter Build
```batch
cd build-tools
Build-Setup.bat
```

### PowerShell (Erweitert)
```powershell
cd build-tools
.\Build-Setup.ps1
```

## 📋 Voraussetzungen

- **Windows 10/11** mit .NET Framework 4.0+
- **C# Compiler** (Visual Studio, Build Tools, oder .NET Framework SDK)
- **WIMaster-Setup.ps1** im Hauptverzeichnis (eine Ebene höher)

## 📤 Ausgabe

Die kompilierte **`Setup.exe`** wird im **Hauptverzeichnis** erstellt:
```
WIMaster/
├── Setup.exe               ← Hier wird die .exe erstellt
├── WIMaster-Setup.ps1      ← Diese Datei wird von Setup.exe gestartet
└── build-tools/            ← Build-Dateien (dieser Ordner)
    ├── WIMaster-Setup.cs
    ├── Build-Setup.bat
    └── ...
```

## 🔗 Verwendung

Nach dem Erstellen der Setup.exe:
1. **Setup.exe** befindet sich im Hauptverzeichnis
2. **Doppelklick** auf Setup.exe
3. **UAC-Dialog** bestätigen
4. **WIMaster-Setup** startet automatisch

## 🛠️ Entwicklung

### Quellcode bearbeiten
```bash
# C# Code anpassen
nano WIMaster-Setup.cs

# Neu kompilieren
./Build-Setup.bat
```

### Neues Feature testen
```bash
# Build und Test in einem
./Quick-Build.bat
```

### GitHub Actions
Die Build-Tools sind auch in GitHub Actions integriert und erstellen automatisch die Setup.exe bei jedem Release.

---

**Zurück zur Hauptdokumentation**: [../README.md](../README.md)
