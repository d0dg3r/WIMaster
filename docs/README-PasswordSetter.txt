===============================================
WIMaster - Passwort-Verschlüsselungs-Tool
===============================================

Dieses Tool ermöglicht es Ihnen, Passwörter sicher für die Verwendung 
in WIMaster-Konfigurationen zu verschlüsseln.

VERWENDUNG:
-----------
1. Starten Sie "EncryptPassword.bat" oder "EncryptPassword.ps1"
2. Geben Sie das zu verschlüsselnde Passwort ein
3. Kopieren Sie das verschlüsselte Passwort in Ihre WIMaster-Config.json

WICHTIGE HINWEISE:
------------------
• Das verschlüsselte Passwort kann nur auf dem Computer entschlüsselt 
  werden, auf dem es erstellt wurde
• Das verschlüsselte Passwort kann nur von dem Benutzer entschlüsselt 
  werden, der es erstellt hat
• Erstellen Sie das verschlüsselte Passwort auf dem Computer, auf dem 
  WIMaster später laufen soll

KONFIGURATION:
--------------
Fügen Sie das verschlüsselte Passwort in Ihre WIMaster-Config.json ein:

{
  "Network": {
    "NetworkPath": "\\\\server\\backup",
    "NetworkUser": "domain\\username",
    "NetworkPassword": "HIER_DAS_VERSCHLÜSSELTE_PASSWORT_EINFÜGEN"
  }
}

SICHERHEIT:
-----------
• Bewahren Sie das ursprüngliche Passwort sicher auf
• Das verschlüsselte Passwort ist an den Computer und Benutzer gebunden
• Bei Computerwechsel muss das Passwort neu verschlüsselt werden

SUPPORT:
--------
Bei Fragen wenden Sie sich an: joe@devops-geek.net
Weitere Informationen: https://devops-geek.net
