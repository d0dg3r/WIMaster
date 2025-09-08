# GitHub Actions für WIMaster Setup.exe

## Übersicht

Ihre WIMaster-Repository ist jetzt für **automatische Setup.exe-Erstellung** mit GitHub Actions konfiguriert - **komplett kostenlos** mit GitHub-gehosteten Runnern!

## 🆓 **Kostenlose GitHub-gehostete Runner**

Sie benötigen **KEINEN eigenen Runner**! GitHub bietet:

- ✅ **Windows Server 2022** Runner (kostenlos)
- ✅ **Vorinstalliertes .NET Framework**
- ✅ **Visual Studio Build Tools**
- ✅ **2000 Minuten/Monat kostenlos** für private Repos
- ✅ **Unbegrenzt** für öffentliche Repos

## 📋 **Erstellte Workflows**

### 1. **build-setup-exe.yml** - Kontinuierlicher Build
```yaml
Trigger: Push/PR auf main/develop
Runner: windows-latest (kostenlos)
Funktion: Kompiliert Setup.exe bei jeder Änderung
Artefakt: Setup.exe (30 Tage verfügbar)
```

### 2. **create-release.yml** - Release mit Setup.exe
```yaml
Trigger: Git-Tags (v*.*.*)
Workflow: 
  1. Windows-Runner kompiliert Setup.exe
  2. Ubuntu-Runner erstellt Release-Zip mit Setup.exe
  3. GitHub Release wird automatisch erstellt
```

## 🚀 **Verwendung**

### Automatischer Build bei Code-Änderungen
```bash
# Jeder Push triggert automatischen Build
git add .
git commit -m "Update WIMaster"
git push origin main

# Setup.exe wird automatisch kompiliert und als Artefakt gespeichert
```

### Release erstellen mit Setup.exe
```bash
# Tag erstellen und pushen
git tag v1.2.0
git push origin v1.2.0

# Automatischer Ablauf:
# 1. Setup.exe wird kompiliert
# 2. Release-Zip wird mit Setup.exe erstellt  
# 3. GitHub Release wird veröffentlicht
```

### Manueller Trigger
```
GitHub → Actions → "Build Setup.exe" → "Run workflow"
```

## 📊 **Workflow-Status überwachen**

### In GitHub Interface:
1. **Repository** → **Actions**-Tab
2. **Workflow-Liste** anzeigen
3. **Build-Logs** einsehen
4. **Artefakte herunterladen**

### Status-Badge (Optional):
```markdown
![Build Status](https://github.com/IHRUSERNAME/WIMaster/workflows/Build%20Setup.exe/badge.svg)
```

## 📁 **Artefakte**

### Build-Artefakte (nach jedem Build):
- **WIMaster-Setup-exe** - Enthält die kompilierte Setup.exe
- **build-logs** - Build-Protokolle bei Fehlern
- **Verfügbarkeit**: 30 Tage

### Release-Artefakte (bei Tags):
- **WIMaster-release.zip** - Komplettes Release mit Setup.exe
- **Verfügbarkeit**: Permanent

## 🔧 **Anpassungen**

### Build-Trigger ändern
```yaml
# .github/workflows/build-setup-exe.yml
on:
  push:
    branches: [ main, develop, feature/* ]  # Weitere Branches
  schedule:
    - cron: '0 2 * * 1'  # Wöchentlicher Build (Montags 2 Uhr)
```

### Mehrere .NET-Versionen testen
```yaml
strategy:
  matrix:
    dotnet-version: ['4.8', '6.0', '8.0']
```

### Custom Icon für Builds
```yaml
- name: Setup custom icon
  run: |
    # Verschiedene Icons für verschiedene Branches
    if ("${{ github.ref }}" -like "*/main") {
      Copy-Item "icons/release-icon.ico" "WIMaster_Ico.ico"
    } else {
      Copy-Item "icons/dev-icon.ico" "WIMaster_Ico.ico"  
    }
```

## 🎯 **Kosten**

### GitHub Free Account:
- **Öffentliche Repos**: Unbegrenzte Minuten ✅
- **Private Repos**: 2000 Minuten/Monat ✅
- **Windows-Runner**: 2x Multiplikator (1 Min = 2 Min)
- **Ihr Setup.exe Build**: ~2-3 Minuten pro Build

### Kostenschätzung:
```
10 Builds/Monat × 3 Minuten × 2 (Windows) = 60 Minuten
= 3% Ihres kostenlosen Kontingents! 🎉
```

## 🔍 **Debugging**

### Build-Fehler analysieren:
1. **Actions**-Tab → **Failed Workflow**
2. **Job erweitern** → **Step-Details**
3. **Logs herunterladen**

### Häufige Probleme:

**Problem**: `csc.exe not found`
```yaml
# Lösung: Setup MSBuild hinzufügen
- name: Setup .NET Framework
  uses: microsoft/setup-msbuild@v1.1
```

**Problem**: `Icon not found`
```yaml
# Lösung: Icon-Existenz prüfen
- name: Check icon
  run: |
    if (!(Test-Path "WIMaster_Ico.ico")) {
      Write-Host "No icon found - building without icon"
    }
```

**Problem**: `Compilation fails`
```yaml
# Lösung: Erweiterte Fehlerbehandlung
- name: Debug compilation
  run: |
    csc /target:winexe /out:Setup.exe WIMaster-Setup.cs 2>&1 | Tee-Object -FilePath "build.log"
    Get-Content "build.log"
```

## 📈 **Erweiterte Features**

### Automatische Versionierung
```yaml
- name: Auto-version Setup.exe
  run: |
    $version = (Get-Date).ToString("yyyy.MM.dd.HHmm")
    (Get-Content WIMaster-Setup.cs) -replace 'VERSION_PLACEHOLDER', $version | Set-Content WIMaster-Setup.cs
```

### Multi-Platform Support
```yaml
jobs:
  build-windows:
    runs-on: windows-latest
    # Setup.exe für Windows
    
  build-cross-platform:
    runs-on: ubuntu-latest  
    # PowerShell-Scripts für Linux/Mac
```

### Automatische Tests
```yaml
- name: Test Setup.exe
  run: |
    # Grundlegende Tests ohne UAC
    $file = Get-Item "Setup.exe"
    if ($file.Length -lt 1000) { 
      throw "Setup.exe too small"
    }
    Write-Host "✅ Setup.exe size: $($file.Length) bytes"
```

## 🎊 **Fazit**

Mit den konfigurierten GitHub Actions haben Sie:

- ✅ **Kostenlose automatische Builds**
- ✅ **Professionelle CI/CD-Pipeline** 
- ✅ **Automatische Releases**
- ✅ **Keine eigene Infrastruktur nötig**
- ✅ **Enterprise-grade Build-System**

**Alles ohne eigenen GitHub Runner - komplett kostenlos! 🚀**

## 📞 **Support**

Bei Fragen zu GitHub Actions:
- 📖 [GitHub Actions Dokumentation](https://docs.github.com/en/actions)
- 📧 joe@devops-geek.net
- 💬 GitHub Issues in Ihrem Repository
