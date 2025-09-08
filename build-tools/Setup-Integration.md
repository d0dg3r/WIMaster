# Setup.exe Integration in WIMaster

## Übersicht

Diese Anleitung zeigt, wie Sie die neue `Setup.exe` in Ihr bestehendes WIMaster-System integrieren.

## Schnellstart

### 1. Setup.exe erstellen
```batch
# Einfachster Weg:
Quick-Build.bat

# Oder detailliert:
Build-Setup.bat
```

### 2. Setup.exe verwenden
- Doppelklick auf `Setup.exe`
- UAC-Dialog bestätigen  
- WIMaster-Setup startet automatisch

## Integration in bestehende Workflows

### Ersatz für WIMaster-Setup.bat

**Vorher:**
```batch
# Benutzer musste manuell "Als Administrator ausführen"
WIMaster-Setup.bat
```

**Nachher:**
```batch
# Automatische UAC-Elevation
Setup.exe
```

### Verteilung

**Dateien für End-Benutzer:**
```
WIMaster-Distribution/
├── Setup.exe                    # ← Neue Hauptdatei
├── WIMaster-Setup.ps1           # ← Bleibt unverändert
├── WIMaster-Setup.bat           # ← Optional als Fallback
├── WIMaster_Ico.ico             # ← Für Icon
└── [Alle anderen WIMaster-Dateien]
```

## Vorteile gegenüber .bat-Datei

| Aspekt | WIMaster-Setup.bat | Setup.exe |
|--------|-------------------|-----------|
| **UAC-Handling** | Manuell | Automatisch |
| **Fehlerbehandlung** | Basic | Erweitert |
| **Benutzerfreundlichkeit** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Icon** | ❌ | ✅ |
| **Systemprüfung** | Basic | Umfassend |

## Kompatibilität

Die Setup.exe ist **vollständig kompatibel** mit:
- ✅ Bestehenden WIMaster-Setup.ps1
- ✅ Allen WIMaster-Funktionen
- ✅ Bestehenden Konfigurationsdateien
- ✅ Allen PowerShell-Parametern

## Deployment-Optionen

### Option 1: Setup.exe als Hauptstarter
```
# Empfohlen für End-Benutzer
Setup.exe                 # Hauptanwendung
WIMaster-Setup.bat        # Fallback
```

### Option 2: Beide Methoden parallel
```
# Für verschiedene Benutzergruppen
Setup.exe                 # Für normale Benutzer
WIMaster-Setup.bat        # Für Power-User/Scripting
```

### Option 3: In MSI-Package einbetten
```
# Für Enterprise-Deployment
setup.msi
├── Setup.exe
├── WIMaster-Setup.ps1
└── [Weitere Dateien]
```

## Anpassungen für Ihre Umgebung

### 1. Icon ändern
```batch
# Ersetzen Sie WIMaster_Ico.ico mit Ihrem Icon
# Dann neu kompilieren:
Build-Setup.bat
```

### 2. Firmen-Branding
Bearbeiten Sie `WIMaster-Setup.cs`:
```csharp
// Zeile ~141: Titel der Fehlerdialoge
MessageBox.Show(message, "Ihr Firmenname - Setup", ...)
```

### 3. Zusätzliche Prüfungen
Erweitern Sie `WIMaster-Setup.cs`:
```csharp
// Nach CheckPowerShellVersion() hinzufügen:
if (!CheckCustomRequirement()) {
    ShowError("Ihre spezielle Anforderung nicht erfüllt.");
    return;
}
```

## Build-Automatisierung

### CI/CD Integration
```yaml
# Beispiel für Azure DevOps
- task: CmdLine@2
  displayName: 'Build WIMaster Setup.exe'
  inputs:
    script: 'Build-Setup.bat'
    workingDirectory: '$(Build.SourcesDirectory)'
```

### Automatisches Testen
```batch
# Test-Script erstellen
@echo off
echo Testing Setup.exe...
Setup.exe /test
if %errorlevel% equ 0 echo ✓ Test passed
```

## Troubleshooting

### Häufige Probleme

**Problem**: `Setup.exe startet nicht`
```
Lösung: Prüfen Sie .NET Framework Installation
Command: dotnet --info
```

**Problem**: `Kompilierung schlägt fehl`
```
Lösung: Visual Studio Build Tools installieren
Download: https://visualstudio.microsoft.com/downloads/
```

**Problem**: `UAC-Dialog erscheint nicht`
```
Lösung: Prüfen Sie UAC-Einstellungen in Windows
Control Panel → User Account Control Settings
```

### Debug-Modus

Für Debugging bearbeiten Sie `WIMaster-Setup.cs`:
```csharp
// Zeile ~126: CreateNoWindow ändern
CreateNoWindow = false,  // Zeigt PowerShell-Fenster für Debugging
```

## Best Practices

### 1. Versionierung
```batch
# Version in Setup.exe anzeigen
Setup.exe --version
```

### 2. Logging
```csharp
// Optional: Log-Datei erstellen
File.WriteAllText("setup.log", $"Started at {DateTime.Now}");
```

### 3. Digitale Signatur
```batch
# Setup.exe signieren (Optional)
signtool sign /f "certificate.pfx" /p "password" Setup.exe
```

## Migration von .bat zu .exe

### Schritt 1: Parallel testen
1. Beide Dateien beibehalten
2. Setup.exe mit kleiner Benutzergruppe testen
3. Feedback sammeln

### Schritt 2: Schrittweise Einführung
1. Setup.exe als bevorzugte Methode kommunizieren
2. .bat-Datei als Fallback beibehalten
3. Nach 3-6 Monaten .bat-Datei entfernen

### Schritt 3: Dokumentation aktualisieren
1. README.md anpassen
2. Benutzerhandbücher aktualisieren
3. Schulungsmaterialien anpassen

## Support

Bei Fragen zur Integration:
- 📧 E-Mail: joe@devops-geek.net
- 📝 Issues: Erstellen Sie ein GitHub Issue
- 📖 Dokumentation: Siehe README-Setup.md

---

**Hinweis**: Die Setup.exe erweitert WIMaster um moderne Benutzerfreundlichkeit, ohne die bewährte PowerShell-Funktionalität zu ändern.
