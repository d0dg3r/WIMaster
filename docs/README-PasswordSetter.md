# WIMaster - Passwort-Verschlüsselungs-Tool

Dieses Tool ermöglicht es Ihnen, Passwörter sicher für die Verwendung in WIMaster-Konfigurationen zu verschlüsseln.

## 🚀 Verwendung

1. **Starten** Sie `EncryptPassword.bat` oder `EncryptPassword.ps1`
2. **Geben** Sie das zu verschlüsselnde Passwort ein
3. **Kopieren** Sie das verschlüsselte Passwort in Ihre `WIMaster-Config.json`

## ⚠️ Wichtige Hinweise

- **Computer-gebunden**: Das verschlüsselte Passwort kann nur auf dem Computer entschlüsselt werden, auf dem es erstellt wurde
- **Benutzer-gebunden**: Das verschlüsselte Passwort kann nur von dem Benutzer entschlüsselt werden, der es erstellt hat  
- **Erstellung**: Erstellen Sie das verschlüsselte Passwort auf dem Computer, auf dem WIMaster später laufen soll

## 📝 Konfiguration

Fügen Sie das verschlüsselte Passwort in Ihre `WIMaster-Config.json` ein:

```json
{
  "Network": {
    "NetworkPath": "\\\\server\\backup",
    "NetworkUser": "domain\\username", 
    "NetworkPassword": "HIER_DAS_VERSCHLÜSSELTE_PASSWORT_EINFÜGEN"
  }
}
```

## 🔒 Sicherheit

- **Original bewahren**: Bewahren Sie das ursprüngliche Passwort sicher auf
- **Bindung**: Das verschlüsselte Passwort ist an den Computer und Benutzer gebunden
- **Computerwechsel**: Bei Computerwechsel muss das Passwort neu verschlüsselt werden

## 📞 Support

- **E-Mail**: joe@devops-geek.net
- **Website**: https://devops-geek.net
- **GitHub**: https://github.com/DevOps-Geek/WIMaster

---

*Teil des WIMaster - Windows System Backup Tool*
