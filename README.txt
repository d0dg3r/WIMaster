WIMaster - Windows System Backup Tool
=====================================

Ein PowerShell-Skript zur Erstellung von Windows Image (WIM) Backups mit 
Netzwerk-Speicher-Support und unbeaufsichtigten Betriebsmöglichkeiten.

Entwickelt von Joachim Mild <joe@devops-geek.net>
Basierend auf c't-WIMaster von Axel Vahldiek

FUNKTIONEN
==========

- Windows System-Backup: Erstellt WIM-Images von Windows-Installationen
- Netzwerk-Speicher: Speichert Backups direkt an Netzwerk-Standorten
- Standard-Backup-Pfad: Konfigurierbarer Standard-Speicherort für Backups
- Interaktive und unbeaufsichtigte Nutzung: GUI und Konsolenmodus
- Kompakte GUI: Integrierte Optionen und Speicherort-Auswahl in einem Dialog; Info-Button öffnet Details
- Laufwerksauswahl: Zeigt feste und Wechseldatenträger; Systemlaufwerk C: ist ausgeblendet/nicht wählbar
- Cloud-Datei-Behandlung: Lädt automatisch Cloud-Platzhalter-Dateien herunter
- Maschinenspezifische Benennung: Enthält Computername und Zeitstempel in Backup-Dateinamen
- Fortschrittsüberwachung: Echtzeit-Anzeige des Backup-Fortschritts
- Fehlerbehandlung: Umfassende Fehlerprüfung und -berichterstattung

ANFORDERUNGEN
=============

- Windows 10/11 Version 20H2 (Build 19042) oder neuer
- 64-Bit Windows mit x64-Prozessor
- Administrator-Berechtigungen
- PowerShell 3.0 oder neuer
- Netzwerkzugriff zum Backup-Standort (für Netzwerk-Speicher-Funktion)

INSTALLATION
============

1. Laden Sie die WIMaster-Dateien auf Ihr System herunter
2. Stellen Sie sicher, dass alle erforderlichen Dateien vorhanden sind:
   - WIMaster.ps1 (Hauptskript)
   - WIMaster_ConfigManager.ps1 (Konfigurations-Manager)
   - WIMaster_Exclusions.json (Ausschlusslisten-Konfiguration)
   - WIMaster_Ico.ico (Icon-Datei)
   - vshadow.exe (Volume Shadow Copy Utility)
   - ei.cfg (Windows Setup-Konfiguration)

WIMAGE-SETUP
============

Das WIMaster-Setup-Skript (WIMaster-Setup.ps1) erstellt einen bootfähigen USB-Stick 
mit WIMaster für die Systemwiederherstellung:

FUNKTIONEN DES SETUP-SKRIPTS:
- Erstellt bootfähigen USB-Stick mit Windows PE
- Kopiert alle WIMaster-Dateien auf den USB-Stick
- Konfiguriert automatisch die Boot-Umgebung
- Unterstützt Windows 10/11 ISO-Images

VORBEREITUNG FÜR DAS SETUP:
1. USB-Stick mit mindestens 28 GB Speicherplatz
2. Windows 10/11 ISO-Datei (empfohlen: Windows 10 Version 2004 Enterprise Eval)
3. Administrator-Berechtigungen

SETUP AUSFÜHREN:
1. Rechtsklick auf "WIMaster-Setup.ps1" → "Als Administrator ausführen"
2. USB-Datenträger aus der Liste auswählen
3. Windows ISO-Datei auswählen (über "Durchsuchen" Button)
4. "Weiter" klicken und Bestätigung abgeben
5. Warten bis der Setup-Prozess abgeschlossen ist

WARNUNG: Der ausgewählte USB-Stick wird komplett gelöscht!

SETUP-PROZESS:
1. ISO-Image wird eingebunden
2. USB-Stick wird partitioniert (WIM-BOOT: FAT32, WIM-DATA: NTFS)
3. Boot-Dateien werden kopiert
4. Windows PE wird installiert
5. WIMaster-Dateien werden kopiert
6. Setup.exe wird installiert

KONFIGURATION
=============

KONFIGURATIONS-MANAGER
Das WIMaster enthält ein separates Konfigurations-Manager-Skript für die sichere Einrichtung:

Konfigurations-Manager ausführen:
powershell -ExecutionPolicy Bypass -File WIMaster_ConfigManager.ps1

Der Konfigurations-Manager bietet:
- Sichere Passwort-Speicherung: Passwörter werden mit Windows DPAPI verschlüsselt
- Interaktive Einrichtung: Benutzerfreundliches Menü-System für die Konfiguration
- Netzwerk-Tests: Eingebaute Netzwerkverbindungs-Tests mit temporären Mounts
- Standard-Backup-Pfad: Konfiguration eines Standard-Speicherorts
- Konfigurations-Backup: Anzeigen und Zurücksetzen von Konfigurationseinstellungen

KONFIGURATIONSDATEI
Einstellungen werden in WIMaster_Config.json gespeichert:

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

BACKUP-OPTIONEN
Das Skript unterstützt zwei Modi:

INTERAKTIVER MODUS (Standard):
- Kompakter Startdialog mit integrierten Optionen und Speicherort-Auswahl
- Optionen: „Herunterfahren nach Sicherung“, „Windows.old nicht mitsichern“
- Info-Button (About) mit Logo und Projekthinweisen
- Laufwerksliste mit Spalten „Laufwerk“, „Name“, „Typ“, „Freier Speicher“ (C: ausgeblendet)
- Fortschritt in einem grafischen Fenster

UNBEAUFSICHTIGTER MODUS:
- Läuft vollständig in der Konsole
- Verwendet Standardeinstellungen und Standard-Backup-Pfad
- Perfekt für automatisierte Backups und geplante Aufgaben

VERWENDUNG
==========

KONFIGURATION EINRICHTEN
Vor der ersten Verwendung konfigurieren Sie Ihre Einstellungen:

Konfigurations-Manager ausführen:
powershell -ExecutionPolicy Bypass -File WIMaster_ConfigManager.ps1

Konfigurationsoptionen:
1. Konfiguration anzeigen
2. Netzwerk-Share konfigurieren
3. Backup-Optionen konfigurieren
4. Standard-Backup-Pfad konfigurieren
5. Standard-Backup-Pfad testen
6. Verbindung testen
7. Zurücksetzen
8. Beenden

INTERAKTIVER MODUS:
Mit GUI-Oberfläche ausführen:
powershell -ExecutionPolicy Bypass -File WIMaster.ps1

UNBEAUFSICHTIGTER MODUS:
Ohne Benutzerinteraktion ausführen:
powershell -ExecutionPolicy Bypass -File WIMaster.ps1 -Unattended

GEPLANTE AUFGABE BEISPIEL:
Erstellen Sie eine Windows-geplante Aufgabe für automatische Backups:

Beispiel für Task Scheduler-Befehl:
schtasks /create /tn "WIMaster Backup" /tr "powershell -ExecutionPolicy Bypass -File C:\pfad\zu\WIMaster.ps1 -Unattended" /sc daily /st 02:00 /ru SYSTEM

BACKUP-PROZESS
==============

1. System-Check: Überprüft Windows-Version und Anforderungen
2. Cloud-Datei-Check: Lädt Cloud-Platzhalter-Dateien herunter
3. Backup-Pfad-Auswahl: Verwendet Standard-Pfad oder zeigt Auswahl-Dialog
4. Netzwerkverbindung: Testet und verbindet mit Backup-Standort (falls erforderlich)
5. Schattenkopie: Erstellt Volume Shadow Copy für konsistentes Backup
6. WIM-Erstellung: Verwendet DISM zur Erstellung des Windows-Images
7. Verifizierung: Validiert Backup-Integrität
8. Aufräumen: Entfernt temporäre Dateien und Schattenkopien

AUSGABEDATEIEN
==============

Backups werden mit beschreibenden Dateinamen gespeichert:
- Install.wim: Install_[ComputerName]_[YYYY-MM-DD_HH-MM].wim
- Fresh.wim: Fresh_[ComputerName]_[YYYY-MM-DD_HH-MM].wim

Beispiel: Install_DESKTOP-ABC123_2024-01-15_14-30.wim

NETZWERK-SPEICHER
=================

Das Skript unterstützt das Speichern von Backups an Netzwerk-Standorten:
- UNC-Pfade: \\server\share\backup
- Authentifizierung: Benutzername/Passwort-Authentifizierung
- Laufwerk-Auswahl: Netzwerk-Pfade erscheinen im Laufwerk-Auswahl-Dialog
- Automatisches Mapping: Temporäres Laufwerk-Mapping für UNC-Pfade, die Authentifizierung erfordern
- Fehlerbehandlung: Automatische Wiederholung und Fehlerberichterstattung
- Aufräumen: Automatische Bereinigung temporärer Netzwerk-Mappings

STANDARD-BACKUP-PFAD
====================

Das System unterstützt die Konfiguration eines Standard-Backup-Pfads:
- Automatische Auswahl: Der Standard-Pfad wird automatisch in der Laufwerk-Auswahl markiert
- Unbeaufsichtigter Modus: Verwendet automatisch den konfigurierten Standard-Pfad
- Fallback-Verhalten: Falls der Standard-Pfad nicht verfügbar ist, kann ein anderer Pfad gewählt werden
- Validierung: Testet die Erreichbarkeit des Standard-Pfads mit temporären Mounts

FEHLERBEHEBUNG
==============

HÄUFIGE PROBLEME:

1. "Execution Policy" Fehler
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

2. Netzwerkzugriff verweigert
   - Verwenden Sie den Konfigurations-Manager zum Testen der Netzwerkverbindung
   - Überprüfen Sie, ob der Netzwerk-Pfad erreichbar ist
   - Überprüfen Sie Benutzername und Passwort in der Konfigurationsdatei
   - Stellen Sie sicher, dass die Netzwerkverbindung verfügbar ist
   - Das System testet Netzwerkpfade mit temporären Mounts

3. Konfigurationsprobleme
   - Führen Sie WIMaster_ConfigManager.ps1 aus, um aktuelle Einstellungen anzuzeigen
   - Verwenden Sie den Konfigurations-Manager zum Zurücksetzen der Einstellungen bei Bedarf
   - Stellen Sie sicher, dass die Konfigurationsdatei nicht beschädigt ist

4. Unzureichender Speicherplatz
   - Freigeben Sie Speicherplatz auf dem Systemlaufwerk
   - Überprüfen Sie verfügbaren Speicherplatz am Backup-Standort

5. Cloud-Dateien werden nicht heruntergeladen
   - Überprüfen Sie die Internetverbindung
   - Überprüfen Sie den Status des Cloud-Dienstes
   - Stellen Sie sicher, dass Cloud-Dateien nicht synchronisiert werden

6. Standard-Backup-Pfad nicht erreichbar
   - Verwenden Sie Option 5 im Konfigurations-Manager zum Testen
   - Überprüfen Sie, ob das Laufwerk verfügbar ist
   - Konfigurieren Sie einen anderen Standard-Pfad falls erforderlich

PROTOKOLLDATEIEN
================

Das Skript erstellt mehrere Protokolldateien für die Fehlerbehebung:
- WIMaster_Log_DISM.txt - DISM-Betriebsprotokolle
- WIMaster_Log_RE_Enable.txt - Windows RE Aktivierungsprotokolle
- WIMaster_Log_RE_Disable.txt - Windows RE Deaktivierungsprotokolle
- WIMaster_Backupliste.txt - Backup-Image-Informationen

ERWEITERTE KONFIGURATION
========================

BENUTZERDEFINIERTE BACKUP-OPTIONEN
Die Backup-Optionen können über den Konfigurations-Manager angepasst werden:
- Herunterfahren nach Backup: Automatisches Herunterfahren nach Abschluss
- Windows.old ausschließen: Ausschluss des Windows.old-Ordners

STANDARD-BACKUP-PFAD KONFIGURIEREN
1. Führen Sie den Konfigurations-Manager aus
2. Wählen Sie Option 4 "Standard-Backup-Pfad konfigurieren"
3. Wählen Sie aus der Liste der verfügbaren Laufwerke
4. Testen Sie den Pfad mit Option 5

SICHERHEITSÜBERLEGUNGEN
========================

- Anmeldedaten: Passwörter werden mit Windows DPAPI verschlüsselt gespeichert
- Netzwerkzugriff: Stellen Sie sicher, dass der Backup-Standort angemessene Berechtigungen hat
- Protokolldateien: Können sensible Informationen enthalten, sichern Sie sie angemessen
- Temporäre Mounts: Werden automatisch nach dem Test entfernt

VERSIONSHISTORIE
================

- v0.1: Erweiterte WIMaster-Version mit Netzwerk-Support
- v0.1+: Standard-Backup-Pfad-Funktionalität hinzugefügt
- v0.1+: Verbesserte Netzwerkpfad-Tests mit temporären Mounts
- v0.1+: Kompakter Startdialog, integrierte Options-/Speicherort-Auswahl, C: ausgeblendet
- v0.1+: Defender-Option entfernt; UI-Info-Dialog hinzugefügt

SUPPORT
=======

Für Probleme und Fragen:
1. Überprüfen Sie den Fehlerbehebungsabschnitt oben
2. Überprüfen Sie Protokolldateien für Fehlerdetails
3. Verifizieren Sie Systemanforderungen und Netzwerkverbindung
4. Testen Sie mit dem interaktiven Modus vor der Verwendung des unbeaufsichtigten Modus
5. Verwenden Sie den Konfigurations-Manager zum Testen der Einstellungen

LIZENZ
======

Dieses Skript basiert auf c't-WIMaster von Axel Vahldiek. Bitte beachten Sie die 
ursprüngliche Dokumentation unter ct.de/wimage für Lizenzinformationen.

DANKSAGUNGEN
============

- Original c't-WIMaster-Skript von Axel Vahldiek
- c't-Magazin (heise.de) für die ursprüngliche Implementierung
