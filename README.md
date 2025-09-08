# WIMaster

Ein PowerShell-Skript zur Erstellung von Windows Image (WIM) Backups mit Netzwerk-Speicher-Support und unbeaufsichtigten Betriebsmöglichkeiten.

## ⚠️ **Entwicklungsstatus - Wichtiger Hinweis**

> **🚧 Dieses Projekt befindet sich noch in aktiver Entwicklung und ist derzeit nicht für den produktiven Einsatz geeignet.**
>
> ### ✅ **Was bereits funktioniert:**
> - **Backup-Funktionalität**: Vollständig implementiert und getestet
> - **Windows Image (WIM) Erstellung**: Stabil und funktionsfähig
> - **Netzwerk-Speicher-Support**: Läuft zuverlässig
> - **GUI und Benutzeroberfläche**: Vollständig funktional
>
> ### 🔄 **Was noch in Entwicklung ist:**
> - **Restore-Funktionalität**: Aktuell in Implementierung
> - **Erweiterte Wiederherstellungsoptionen**: Noch nicht verfügbar
> - **Vollständige Dokumentation**: Wird kontinuierlich erweitert
>
> ### 📋 **Empfehlung:**
> - **Für Backup-Zwecke**: Kann verwendet werden, da diese Funktionalität stabil läuft
> - **Für Restore-Operationen**: Warten Sie auf zukünftige Releases
> - **Produktive Umgebungen**: Verwenden Sie bewährte Backup-Lösungen bis zur finalen Version
>
> **Bleiben Sie auf dem Laufenden über GitHub Releases für Updates und neue Funktionalität!**

---

## Funktionen

- **Windows System-Backup**: Erstellt WIM-Images von Windows-Installationen
- **Netzwerk-Speicher**: Speichert Backups direkt an Netzwerk-Standorten
- **Standard-Backup-Pfad**: Konfigurierbarer Standard-Speicherort für Backups
- **Interaktive und unbeaufsichtigte Nutzung**: GUI und Konsolenmodus
- **Kompakte GUI**: Integrierte Optionen und Speicherort-Auswahl in einem Dialog; Info-Button öffnet Details
- **Laufwerksauswahl**: Zeigt feste und Wechseldatenträger; Systemlaufwerk C: ist ausgeblendet/nicht wählbar
- **Cloud-Datei-Behandlung**: Lädt automatisch Cloud-Platzhalter-Dateien herunter
- **Maschinenspezifische Benennung**: Enthält Computername und Zeitstempel in Backup-Dateinamen
- **Fortschrittsüberwachung**: Echtzeit-Anzeige des Backup-Fortschritts
- **Fehlerbehandlung**: Umfassende Fehlerprüfung und -berichterstattung

## Anforderungen

- **Windows 10/11** Version 20H2 (Build 19042) oder neuer
- **64-Bit Windows** mit x64-Prozessor
- **Administrator-Berechtigungen**
- **PowerShell 3.0** oder neuer
- **Netzwerkzugriff** zum Backup-Standort (für Netzwerk-Speicher-Funktion)

## Installation

1. Laden Sie die WIMaster-Dateien auf Ihr System herunter
2. Stellen Sie sicher, dass alle erforderlichen Dateien vorhanden sind:
   - `WIMaster.ps1` (Hauptskript)
   - `WIMaster_ConfigManager.ps1` (Konfigurations-Manager)
   - `WIMaster_Exclusions.json` (Ausschlusslisten-Konfiguration)
   - `WIMaster_Ico.ico` (Icon-Datei)
   - `vshadow.exe` (Volume Shadow Copy Utility)
   - `ei.cfg` (Windows Setup-Konfiguration)

## Konfiguration

### Konfigurations-Manager

WIMaster enthält ein separates Konfigurations-Manager-Skript für die sichere Einrichtung:

```powershell
# Konfigurations-Manager ausführen
powershell -ExecutionPolicy Bypass -File WIMaster_ConfigManager.ps1
```

Der Konfigurations-Manager bietet:

- **Sichere Passwort-Speicherung**: Passwörter werden mit Windows DPAPI verschlüsselt
- **Interaktive Einrichtung**: Benutzerfreundliches Menü-System für die Konfiguration
- **Netzwerk-Tests**: Eingebaute Netzwerkverbindungs-Tests mit temporären Mounts
- **Standard-Backup-Pfad**: Konfiguration eines Standard-Speicherorts
- **Konfigurations-Backup**: Anzeigen und Zurücksetzen von Konfigurationseinstellungen

### Konfigurationsdatei

Einstellungen werden in `WIMaster_Config.json` gespeichert:

```json
{
  "Network": {
    "EnableNetworkBackup": true,
    "NetworkPath": "\\\\backup\\NetBackup",
    "NetworkUser": "joe",
    "NetworkPassword": "[VERSCHLÜSSELT]"
  },
  "Backup": {
    "DefaultShutdown": false,
    "DefaultNoWindowsold": false,
    "DefaultBackupPath": "G:"
  },
  "Advanced": {
    "LogLevel": 3,
    "ScratchDirThresholdGB": 20
  }
}
```

### Backup-Optionen

Das Skript unterstützt zwei Modi:

#### Interaktiver Modus (Standard)

- Kompakter Startdialog mit integrierten Optionen und Speicherort-Auswahl
- Option „Windows.old nicht mitsichern“ und „Herunterfahren nach Sicherung“
- Info-Button (About) mit Logo und Projekthinweisen
- Fortschritt in einem grafischen Fenster
- Laufwerksliste mit Spalten „Laufwerk“, „Name“, „Typ“, „Freier Speicher“ (C: ausgeblendet)

#### Unbeaufsichtigter Modus

- Läuft vollständig in der Konsole
- Verwendet Standardeinstellungen und Standard-Backup-Pfad
- Perfekt für automatisierte Backups und geplante Aufgaben

## Verwendung

### Konfiguration einrichten

Vor der ersten Verwendung konfigurieren Sie Ihre Einstellungen:

```powershell
# Konfigurations-Manager ausführen
powershell -ExecutionPolicy Bypass -File WIMaster_ConfigManager.ps1
```

**Konfigurationsoptionen:**

1. Konfiguration anzeigen
2. Netzwerk-Share konfigurieren
3. Backup-Optionen konfigurieren
4. Standard-Backup-Pfad konfigurieren
5. Standard-Backup-Pfad testen
6. Verbindung testen
7. Zurücksetzen
8. Beenden

### Interaktiver Modus

```powershell
# Mit GUI-Oberfläche ausführen
powershell -ExecutionPolicy Bypass -File WIMaster.ps1
```

### Unbeaufsichtigter Modus

```powershell
# Ohne Benutzerinteraktion ausführen
powershell -ExecutionPolicy Bypass -File WIMaster.ps1 -Unattended
```

### Geplante Aufgabe Beispiel

Erstellen Sie eine Windows-geplante Aufgabe für automatische Backups:

```powershell
# Beispiel für Task Scheduler-Befehl
schtasks /create /tn "WIMaster Backup" /tr "powershell -ExecutionPolicy Bypass -File C:\pfad\zu\WIMaster.ps1 -Unattended" /sc daily /st 02:00 /ru SYSTEM
```

## Backup-Prozess

1. **System-Check**: Überprüft Windows-Version und Anforderungen
2. **Cloud-Datei-Check**: Lädt Cloud-Platzhalter-Dateien herunter
3. **Backup-Pfad-Auswahl**: Verwendet Standard-Pfad oder zeigt Auswahl-Dialog
4. **Netzwerkverbindung**: Testet und verbindet mit Backup-Standort (falls erforderlich)
5. **Schattenkopie**: Erstellt Volume Shadow Copy für konsistentes Backup
6. **WIM-Erstellung**: Verwendet DISM zur Erstellung des Windows-Images
7. **Verifizierung**: Validiert Backup-Integrität
8. **Aufräumen**: Entfernt temporäre Dateien und Schattenkopien

## Ausgabedateien

Backups werden mit beschreibenden Dateinamen gespeichert:

- **Install.wim**: `Install_[ComputerName]_[YYYY-MM-DD_HH-MM].wim`
- **Fresh.wim**: `Fresh_[ComputerName]_[YYYY-MM-DD_HH-MM].wim`

Beispiel: `Install_DESKTOP-ABC123_2024-01-15_14-30.wim`

## Netzwerk-Speicher

Das Skript unterstützt das Speichern von Backups an Netzwerk-Standorten:

- **UNC-Pfade**: `\\server\share\backup`
- **Authentifizierung**: Benutzername/Passwort-Authentifizierung
- **Laufwerk-Auswahl**: Netzwerk-Pfade erscheinen im Laufwerk-Auswahl-Dialog
- **Automatisches Mapping**: Temporäres Laufwerk-Mapping für UNC-Pfade, die Authentifizierung erfordern
- **Fehlerbehandlung**: Automatische Wiederholung und Fehlerberichterstattung
- **Aufräumen**: Automatische Bereinigung temporärer Netzwerk-Mappings

## Standard-Backup-Pfad

Das System unterstützt die Konfiguration eines Standard-Backup-Pfads:

- **Automatische Auswahl**: Der Standard-Pfad wird automatisch in der Laufwerk-Auswahl markiert
- **Unbeaufsichtigter Modus**: Verwendet automatisch den konfigurierten Standard-Pfad
- **Fallback-Verhalten**: Falls der Standard-Pfad nicht verfügbar ist, kann ein anderer Pfad gewählt werden
- **Validierung**: Testet die Erreichbarkeit des Standard-Pfads mit temporären Mounts

## Fehlerbehebung

### Häufige Probleme

1. **"Execution Policy" Fehler**

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Netzwerkzugriff verweigert**
   - Verwenden Sie den Konfigurations-Manager zum Testen der Netzwerkverbindung
   - Überprüfen Sie, ob der Netzwerk-Pfad erreichbar ist
   - Überprüfen Sie Benutzername und Passwort in der Konfigurationsdatei
   - Stellen Sie sicher, dass die Netzwerkverbindung verfügbar ist
   - Das System testet Netzwerkpfade mit temporären Mounts

3. **Konfigurationsprobleme**
   - Führen Sie `WIMaster_ConfigManager.ps1` aus, um aktuelle Einstellungen anzuzeigen
   - Verwenden Sie den Konfigurations-Manager zum Zurücksetzen der Einstellungen bei Bedarf
   - Stellen Sie sicher, dass die Konfigurationsdatei nicht beschädigt ist

4. **Unzureichender Speicherplatz**
   - Freigeben Sie Speicherplatz auf dem Systemlaufwerk
   - Überprüfen Sie verfügbaren Speicherplatz am Backup-Standort

5. **Cloud-Dateien werden nicht heruntergeladen**
   - Überprüfen Sie die Internetverbindung
   - Überprüfen Sie den Status des Cloud-Dienstes
   - Stellen Sie sicher, dass Cloud-Dateien nicht synchronisiert werden

6. **Standard-Backup-Pfad nicht erreichbar**
   - Verwenden Sie Option 5 im Konfigurations-Manager zum Testen
   - Überprüfen Sie, ob das Laufwerk verfügbar ist
   - Konfigurieren Sie einen anderen Standard-Pfad falls erforderlich

### Protokolldateien

Das Skript erstellt mehrere Protokolldateien für die Fehlerbehebung:

- `WIMaster_Log_DISM.txt` - DISM-Betriebsprotokolle
- `WIMaster_Log_RE_Enable.txt` - Windows RE Aktivierungsprotokolle
- `WIMaster_Log_RE_Disable.txt` - Windows RE Deaktivierungsprotokolle
- `WIMaster_Backupliste.txt` - Backup-Image-Informationen

## Erweiterte Konfiguration

### Benutzerdefinierte Backup-Optionen

Die Backup-Optionen können über den Konfigurations-Manager angepasst werden:

- **Herunterfahren nach Backup**: Automatisches Herunterfahren nach Abschluss
- **Windows.old ausschließen**: Ausschluss des Windows.old-Ordners

### Standard-Backup-Pfad konfigurieren

1. Führen Sie den Konfigurations-Manager aus
2. Wählen Sie Option 4 "Standard-Backup-Pfad konfigurieren"
3. Wählen Sie aus der Liste der verfügbaren Laufwerke
4. Testen Sie den Pfad mit Option 5

## Sicherheitsüberlegungen

- **Anmeldedaten**: Passwörter werden mit Windows DPAPI verschlüsselt gespeichert
- **Netzwerkzugriff**: Stellen Sie sicher, dass der Backup-Standort angemessene Berechtigungen hat
- **Protokolldateien**: Können sensible Informationen enthalten, sichern Sie sie angemessen
- **Temporäre Mounts**: Werden automatisch nach dem Test entfernt

## Versionshistorie

- **v0.1**: Erweiterte WIMaster-Version mit Netzwerk-Support
- **v0.1+**: Standard-Backup-Pfad-Funktionalität hinzugefügt
- **v0.1+**: Verbesserte Netzwerkpfad-Tests mit temporären Mounts
- **v0.1+**: Kompakter Startdialog, integrierte Options-/Speicherort-Auswahl, C: ausgeblendet
- **v0.1+**: Defender-Option entfernt; UI-Info-Dialog hinzugefügt

## Support

Für Probleme und Fragen:

1. Überprüfen Sie den Fehlerbehebungsabschnitt oben
2. Überprüfen Sie Protokolldateien für Fehlerdetails
3. Verifizieren Sie Systemanforderungen und Netzwerkverbindung
4. Testen Sie mit dem interaktiven Modus vor der Verwendung des unbeaufsichtigten Modus
5. Verwenden Sie den Konfigurations-Manager zum Testen der Einstellungen

## Lizenz

Dieses Projekt steht unter der GNU General Public License v3.0 (GPL-3.0).

Sie können eine Kopie der Lizenz unter folgender Adresse finden:
https://www.gnu.org/licenses/gpl-3.0.html

Das ursprüngliche c't-WIMage-Skript von Axel Vahldiek behält seine ursprüngliche Lizenz. 
Weitere Informationen finden Sie unter ct.de/wimage.

## Danksagungen

- Original c't-WIMage-Skript von Axel Vahldiek
- c't-Magazin (heise.de) für die ursprüngliche Implementierung