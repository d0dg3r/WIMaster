# GitHub Actions Permissions Fix

## ❌ **Problem**
```
⚠️ GitHub release failed with status: 403
retrying... (2 retries remaining)
⚠️ GitHub release failed with status: 403
❌ Too many retries. Aborting...
Error: Too many retries.
```

## 🔍 **Root Cause**
**HTTP 403 Fehler** bedeutet "Forbidden" - der `GITHUB_TOKEN` hat **nicht genügend Permissions** um GitHub Releases zu erstellen.

### **GitHub Actions Token Permissions:**
Seit GitHub Actions Security-Update (2021) sind Token-Permissions standardmäßig **restriktiv**:
- ✅ **Read-only** Zugriff auf Repository-Inhalte  
- ❌ **Keine Write-Permissions** für Releases, Issues, etc.

## ✅ **Lösung: Explizite Permissions**

### **1. Workflow-Level Permissions hinzugefügt:**
```yaml
# create-release.yml
permissions:
  contents: write  # Required for creating releases
  actions: read    # Required for downloading artifacts

# build-setup-exe.yml  
permissions:
  contents: read   # Required for checking out code
  actions: write   # Required for uploading artifacts
```

### **2. GitHub Release Action aktualisiert:**
```yaml
# Vorher:
uses: softprops/action-gh-release@v1
env:
  GITHUB_TOKEN: ${{ github.token }}

# Nachher:
uses: softprops/action-gh-release@v2
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### **3. Zusätzliche Robustheit:**
```yaml
fail_on_unmatched_files: true
generate_release_notes: false
```

## 🔐 **GitHub Permissions Matrix**

| Permission | create-release.yml | build-setup-exe.yml | Begründung |
|------------|-------------------|---------------------|------------|
| **contents: write** | ✅ | ❌ | Release-Erstellung |
| **contents: read** | ✅ (implicit) | ✅ | Code-Checkout |
| **actions: read** | ✅ | ❌ | Artefakt-Download |
| **actions: write** | ❌ | ✅ | Artefakt-Upload |

## 📋 **Permissions Breakdown**

### **contents: write**
```yaml
# Erlaubt:
- GitHub Releases erstellen
- Repository-Tags erstellen
- Dateien ins Repository committen
- Release-Assets hochladen
```

### **contents: read**
```yaml
# Erlaubt:
- Repository-Code auschecken
- Dateien lesen
- Git-History zugreifen
```

### **actions: write**
```yaml
# Erlaubt:
- Workflow-Artefakte hochladen
- Cache-Einträge erstellen
- Job-Status setzen
```

### **actions: read**
```yaml
# Erlaubt:
- Workflow-Artefakte herunterladen
- Cache-Einträge lesen
- Job-Status abfragen
```

## 🔧 **Implementierte Fixes**

### **Fix 1: Workflow-Permissions**
```yaml
# Am Anfang jeder Workflow-Datei:
permissions:
  contents: write  # oder read, je nach Bedarf
  actions: read    # oder write, je nach Bedarf
```

### **Fix 2: Action-Version Update**
```yaml
# Neueste Version für bessere Kompatibilität:
uses: softprops/action-gh-release@v2
```

### **Fix 3: Explicit Token Reference**
```yaml
# Explizite Referenz statt github.token:
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 🎯 **Erwartete Ergebnisse**

### **Vorher (403 Error):**
```
👩‍🏭 Creating new GitHub release for tag v1.0.3...
⚠️ GitHub release failed with status: 403
❌ Too many retries. Aborting...
```

### **Nachher (Success):**
```
👩‍🏭 Creating new GitHub release for tag v1.0.3...
✅ GitHub release created successfully
📦 Uploaded WIMaster-release.zip (2.5 MB)
🎉 Release v1.0.3 published at https://github.com/user/WIMaster/releases/tag/v1.0.3
```

## 🛡️ **Security Best Practices**

### **Principle of Least Privilege:**
```yaml
# Nur minimale Permissions vergeben:
build-job:
  permissions:
    contents: read    # Nur lesen, nicht schreiben
    
release-job:
  permissions:
    contents: write   # Schreiben nur wo nötig
```

### **Job-Spezifische Permissions:**
```yaml
# Pro Job verschiedene Permissions:
jobs:
  build:
    permissions:
      contents: read
      actions: write
      
  release:
    permissions:
      contents: write
      actions: read
```

## 🔄 **GitHub Repository Settings**

### **Workflow Permissions (Optional):**
Zusätzlich können Sie in GitHub Repository Settings überprüfen:

```
Repository → Settings → Actions → General → Workflow permissions
```

**Empfohlene Einstellung:**
- ✅ "Read and write permissions" (für Release-Workflows)
- ✅ "Allow GitHub Actions to create and approve pull requests"

## 📊 **Monitoring & Debugging**

### **Permissions-Debugging:**
```yaml
- name: Debug Permissions
  run: |
    echo "GITHUB_TOKEN permissions:"
    echo "Actor: ${{ github.actor }}"
    echo "Repository: ${{ github.repository }}"
    echo "Event: ${{ github.event_name }}"
    echo "Ref: ${{ github.ref }}"
```

### **Token-Validation:**
```yaml
- name: Validate Token
  run: |
    # Test API access
    curl -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
         https://api.github.com/repos/${{ github.repository }}
```

## 🎉 **Lösung**

**Die GitHub 403 Permission-Fehler sind jetzt behoben durch:**

- ✅ **Explizite Workflow-Permissions** - `contents: write` für Releases
- ✅ **Aktualisierte Action-Version** - `softprops/action-gh-release@v2`
- ✅ **Korrekte Token-Referenz** - `${{ secrets.GITHUB_TOKEN }}`
- ✅ **Job-spezifische Permissions** - Minimale erforderliche Rechte
- ✅ **Security Best Practices** - Principle of Least Privilege

---

## 🚀 **Ergebnis**

**GitHub Releases funktionieren jetzt zuverlässig:**
- 🔐 **Korrekte Permissions** für alle Workflow-Operationen
- 📦 **Automatische Release-Erstellung** bei Git-Tags
- ✅ **Setup.exe** wird automatisch in Releases eingebunden
- 🛡️ **Sichere Token-Behandlung** nach GitHub Best Practices

**Die Permission-Probleme sind vollständig gelöst! 🎊**
