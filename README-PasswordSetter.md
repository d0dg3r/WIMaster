# c't-WIMaster Netzwerk-Passwort Setter

Dieses einfache Skript ermöglicht es Ihnen, das sichere Netzwerk-Passwort für c't-WIMaster zu setzen, ohne den vollständigen ConfigManager verwenden zu müssen.

## Dateien

- `EncryptPassword.ps1` - Das Haupt-PowerShell-Skript
- `EncryptPassword.bat` - Einfacher Batch-Wrapper für Windows
- `README-PasswordSetter.md` - Diese Anleitung

## Verwendung

### Option 1: Batch-Datei (Empfohlen für Windows)

1. **Als Administrator ausführen**: Rechtsklick auf `EncryptPassword.bat` → "Als Administrator ausführen"
2. Folgen Sie den Anweisungen auf dem Bildschirm

### Option 2: PowerShell direkt

1. **PowerShell als Administrator öffnen**
2. Zum ct-WIMaster Ordner navigieren:
   ```powershell
   cd "C:\Pfad\zu\ct-WIMaster"
   ```
3. Skript ausführen:
   ```powershell
   .\EncryptPassword.ps1
   ```

### Option 3: Mit Parametern

```powershell
# Passwort direkt setzen (falls das Skript erweitert wird)
.\EncryptPassword.ps1 -Password "MeinPasswort"

# Aktuellen Status anzeigen (falls das Skript erweitert wird)
.\EncryptPassword.ps1 -ShowCurrent

# Passwort löschen (falls das Skript erweitert wird)
.\EncryptPassword.ps1 -Clear
```

## Funktionen

Das Skript bietet folgende Optionen:

1. **Neues Passwort setzen** - Verschlüsselt und speichert das Passwort sicher
2. **Aktuellen Status anzeigen** - Zeigt an, ob ein Passwort gesetzt ist
3. **Passwort löschen** - Entfernt das gespeicherte Passwort
4. **Beenden** - Schließt das Skript

## Sicherheit

- Das Passwort wird mit **Windows DPAPI** verschlüsselt
- Es kann **nur auf diesem Computer** entschlüsselt werden
- Das Passwort wird **nicht im Klartext** gespeichert
- Die Verschlüsselung ist **maschinenspezifisch** und sicher

## Voraussetzungen

- Windows PowerShell 3.0 oder höher
- Administrator-Rechte
- c't-WIMaster Konfigurationsdatei (`ct-WIMaster_Config.ini`)

## Fehlerbehebung

### "Execution Policy" Fehler
Falls Sie einen Execution Policy Fehler erhalten:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Administrator-Rechte" Fehler
Das Skript muss als Administrator ausgeführt werden. Starten Sie PowerShell oder die Eingabeaufforderung als Administrator.

### "Konfigurationsdatei nicht gefunden"
Stellen Sie sicher, dass die `ct-WIMaster_Config.ini` Datei im gleichen Ordner wie das Skript liegt.

## Integration mit c't-WIMaster

Das gesetzte Passwort wird automatisch von c't-WIMaster verwendet, wenn:
- Netzwerk-Backup aktiviert ist (`EnableNetworkBackup=true`)
- Ein Netzwerk-Pfad konfiguriert ist
- Ein Netzwerk-Benutzer konfiguriert ist

Das verschlüsselte Passwort wird in der Sektion `[Network]` unter `NetworkPassword=` gespeichert.

## Verwendung des verschlüsselten Passworts

Nach der Ausführung des Skripts erhalten Sie eine Ausgabe wie:

```
Verschlüsseltes Passwort:
01000000d08c9ddf0115d1118c7a00c04fc297eb01000000...

Kopieren Sie diese Zeile in Ihre INI-Datei:
NetworkPassword=01000000d08c9ddf0115d1118c7a00c04fc297eb01000000...
```

Kopieren Sie die gesamte Zeile `NetworkPassword=...` in Ihre `ct-WIMaster_Config.ini` Datei unter der `[Network]` Sektion.

## Beispiel-Konfiguration

Nach der Verwendung des Passwort-Setters sollte Ihre `ct-WIMaster_Config.ini` so aussehen:

```ini
[Network]
EnableNetworkBackup=true
NetworkPath=\\server\backup
NetworkUser=meinbenutzername
NetworkPassword=01000000d08c9ddf0115d1118c7a00c04fc297eb01000000...

[Backup]
DefaultShutdown=false
DefaultNoWindowsold=false

[Advanced]
LogLevel=3
ScratchDirThresholdGB=20
```

## Hinweise

- Das verschlüsselte Passwort ist maschinenspezifisch und funktioniert nur auf dem Computer, auf dem es erstellt wurde
- Wenn Sie das System neu installieren, müssen Sie das Passwort erneut verschlüsseln
- Das Skript löscht das eingegebene Passwort sofort aus dem Speicher nach der Verschlüsselung
- Verwenden Sie den vollständigen ConfigManager (`ct-WIMaster_ConfigManager.ps1`) für erweiterte Konfigurationsoptionen