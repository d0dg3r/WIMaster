# WIMaster Build-System

## 📁 **Neue Ordnerstruktur**

```
WIMaster/
├── Setup.exe                    # ← Kompilierte Setup-Anwendung (wird erstellt)
├── WIMaster-Setup.ps1           # ← PowerShell-Script (wird von Setup.exe gestartet)
├── WIMaster_Ico.ico             # ← Icon für Setup.exe
├── Build-Setup.bat              # ← Haupt-Build-Launcher (Batch)
├── Build-Setup.ps1              # ← Haupt-Build-Launcher (PowerShell)
├── README-Build-System.md       # ← Diese Datei
│
├── build-tools/                 # ← Alle Build-Dateien (aufgeräumt!)
│   ├── WIMaster-Setup.cs        # ← C# Quellcode
│   ├── Build-Setup.bat          # ← Detailliertes Build-Script (Batch)
│   ├── Build-Setup.ps1          # ← Detailliertes Build-Script (PowerShell)
│   ├── Quick-Build.bat          # ← Schneller Build mit Test
│   ├── README.md                # ← Build-Tools Dokumentation
│   ├── README-Setup.md          # ← Setup.exe Dokumentation
│   ├── Setup-Integration.md     # ← Integration-Leitfaden
│   └── GitHub-Actions-Setup.md  # ← GitHub Actions Dokumentation
│
└── [Alle anderen WIMaster-Dateien]
```

## 🚀 **Setup.exe erstellen - Einfach!**

### **Methode 1: Haupt-Launcher (Empfohlen)**
```batch
# Im Hauptverzeichnis:
Build-Setup.bat
```
oder
```powershell
.\Build-Setup.ps1
```

### **Methode 2: Direkt in build-tools/**
```batch
cd build-tools
Quick-Build.bat
```

### **Methode 3: GitHub Actions (Automatisch)**
```bash
git tag v1.0.0
git push origin v1.0.0
# → Setup.exe wird automatisch erstellt und in Release eingebunden
```

## ✅ **Vorteile der neuen Struktur**

| Vorher | Nachher |
|--------|---------|
| ❌ Dateien im Root verstreut | ✅ Saubere Organisation |
| ❌ Unübersichtlich | ✅ Klare Trennung |
| ❌ Schwer zu finden | ✅ Alles in build-tools/ |
| ❌ Komplizierte Pfade | ✅ Automatische Pfad-Behandlung |

## 🎯 **Verwendung für End-Benutzer**

### **Setup.exe erstellen:**
1. **Doppelklick** auf `Build-Setup.bat` IM HAUPTVERZEICHNIS
2. **Warten** bis Kompilierung abgeschlossen
3. **Setup.exe** wird im Hauptverzeichnis erstellt

### **Setup.exe verwenden:**
1. **Doppelklick** auf `Setup.exe`
2. **UAC-Dialog** bestätigen
3. **WIMaster-Setup** startet automatisch

## 🔧 **Für Entwickler**

### **Build-Scripts bearbeiten:**
```bash
# Zum build-tools Ordner wechseln
cd build-tools

# C# Code bearbeiten
nano WIMaster-Setup.cs

# Build-Konfiguration ändern
nano Build-Setup.ps1

# Schneller Test
./Quick-Build.bat
```

### **GitHub Actions:**
- **Automatischer Build** bei jedem Push auf main/develop
- **Automatische Releases** mit Setup.exe bei Git-Tags
- **Keine eigenen Runner** nötig - kostenlose GitHub Runner

## 📋 **Kompatibilität**

### **Bestehende Verwendung bleibt gleich:**
- ✅ `WIMaster-Setup.ps1` unverändert
- ✅ Alle Parameter funktionieren
- ✅ Alle Konfigurationsdateien unverändert
- ✅ GitHub Actions automatisch angepasst

### **Neue Möglichkeiten:**
- ✅ Saubere Build-Umgebung
- ✅ Einfachere Wartung
- ✅ Bessere Dokumentation
- ✅ Professionellere Struktur

## 🔍 **Troubleshooting**

### **Problem: "build-tools Ordner nicht gefunden"**
```bash
# Lösung: Sicherstellen dass Sie im Hauptverzeichnis sind
ls -la build-tools/
```

### **Problem: "Setup.exe wird nicht erstellt"**
```bash
# Lösung: Detaillierte Logs in build-tools/ prüfen
cd build-tools
./Build-Setup.ps1  # Zeigt detaillierte Fehler
```

### **Problem: "GitHub Actions schlägt fehl"**
```bash
# Lösung: Lokalen Build zuerst testen
./Build-Setup.bat
# Dann: GitHub Actions Logs prüfen
```

## 📈 **Migration von alter Struktur**

Falls Sie noch die alten Build-Dateien im Root haben:

### **Automatisch aufräumen:**
```bash
# Alte Build-Dateien löschen (falls vorhanden)
rm WIMaster-Setup.cs Build-Setup.bat Build-Setup.ps1 Quick-Build.bat 2>/dev/null || true
rm README-Setup.md Setup-Integration.md GitHub-Actions-Setup.md 2>/dev/null || true

# Neue Struktur verwenden
./Build-Setup.bat
```

## 🎊 **Zusammenfassung**

### **Was ist neu:**
- 📁 **build-tools/** Ordner für alle Build-Dateien
- 🚀 **Launcher-Scripts** im Hauptverzeichnis für einfache Verwendung
- 🔧 **Automatische Pfad-Behandlung** in allen Scripts
- 📖 **Verbesserte Dokumentation** und Organisation

### **Was bleibt gleich:**
- 💻 **Setup.exe Funktionalität** unverändert
- ⚙️ **WIMaster-Setup.ps1** unverändert
- 🔄 **GitHub Actions** automatisch angepasst
- 👥 **End-Benutzer Erfahrung** identisch

**Die neue Struktur macht WIMaster professioneller und einfacher zu warten! 🎉**

---

## 📞 **Support**

Bei Fragen zur neuen Build-Struktur:
- 📖 Siehe `build-tools/README.md` für Details
- 📧 E-Mail: joe@devops-geek.net
- 💬 GitHub Issues für Bug-Reports
