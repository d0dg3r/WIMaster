using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Security.Principal;
using System.Windows.Forms;

namespace WIMasterSetup
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                // Prüfen ob bereits als Administrator ausgeführt
                if (!IsRunningAsAdministrator())
                {
                    // UAC-Elevation anfordern
                    ElevateToAdministrator();
                    return;
                }

                // Pfad zur PowerShell-Datei bestimmen
                string exeDirectory = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                string powershellScript = Path.Combine(exeDirectory, "WIMaster-Setup.ps1");

                // Prüfen ob PowerShell-Script existiert
                if (!File.Exists(powershellScript))
                {
                    ShowError($"PowerShell-Script nicht gefunden:\n{powershellScript}\n\nStellen Sie sicher, dass die WIMaster-Setup.ps1 im gleichen Verzeichnis wie die Setup.exe liegt.");
                    return;
                }

                // Windows-Version prüfen (mindestens Windows 10 20H2 Build 19042)
                if (!CheckWindowsVersion())
                {
                    ShowError("Dieses Setup erfordert Windows 10 20H2 (Build 19042) oder neuer.");
                    return;
                }

                // PowerShell-Version prüfen
                if (!CheckPowerShellVersion())
                {
                    ShowError("PowerShell Version 3.0 oder neuer ist erforderlich.");
                    return;
                }

                // PowerShell-Script ausführen
                ExecutePowerShellScript(powershellScript);
            }
            catch (Exception ex)
            {
                ShowError($"Unerwarteter Fehler:\n{ex.Message}");
            }
        }

        /// <summary>
        /// Prüft ob die Anwendung als Administrator ausgeführt wird
        /// </summary>
        private static bool IsRunningAsAdministrator()
        {
            using (WindowsIdentity identity = WindowsIdentity.GetCurrent())
            {
                WindowsPrincipal principal = new WindowsPrincipal(identity);
                return principal.IsInRole(WindowsBuiltInRole.Administrator);
            }
        }

        /// <summary>
        /// UAC-Elevation: Anwendung als Administrator neu starten
        /// </summary>
        private static void ElevateToAdministrator()
        {
            try
            {
                ProcessStartInfo startInfo = new ProcessStartInfo
                {
                    UseShellExecute = true,
                    WorkingDirectory = Environment.CurrentDirectory,
                    FileName = Assembly.GetExecutingAssembly().Location,
                    Verb = "runas"  // Als Administrator ausführen
                };

                Process.Start(startInfo);
            }
            catch (Exception ex)
            {
                ShowError($"Fehler beim Anfordern der Administrator-Rechte:\n{ex.Message}\n\nDas Setup benötigt Administrator-Rechte zum Erstellen von USB-Laufwerken.");
            }
        }

        /// <summary>
        /// Prüft die Windows-Version
        /// </summary>
        private static bool CheckWindowsVersion()
        {
            try
            {
                // Build-Nummer aus der Registry lesen
                string buildNumber = Microsoft.Win32.Registry.GetValue(
                    @"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion",
                    "CurrentBuild", "").ToString();

                if (int.TryParse(buildNumber, out int build))
                {
                    return build >= 19042; // Windows 10 20H2 oder neuer
                }
                return false;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Prüft die PowerShell-Version
        /// </summary>
        private static bool CheckPowerShellVersion()
        {
            try
            {
                ProcessStartInfo startInfo = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = "-Command \"$PSVersionTable.PSVersion.Major\"",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    CreateNoWindow = true
                };

                using (Process process = Process.Start(startInfo))
                {
                    string output = process.StandardOutput.ReadToEnd();
                    process.WaitForExit();

                    if (int.TryParse(output.Trim(), out int version))
                    {
                        return version >= 3;
                    }
                }
                return false;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Führt das PowerShell-Script aus
        /// </summary>
        private static void ExecutePowerShellScript(string scriptPath)
        {
            try
            {
                ProcessStartInfo startInfo = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = $"-ExecutionPolicy Bypass -File \"{scriptPath}\"",
                    UseShellExecute = false,
                    CreateNoWindow = false,  // PowerShell-Fenster anzeigen falls Debugging nötig
                    WorkingDirectory = Path.GetDirectoryName(scriptPath)
                };

                using (Process process = Process.Start(startInfo))
                {
                    process.WaitForExit();
                    
                    // Bei Fehler Meldung anzeigen
                    if (process.ExitCode != 0)
                    {
                        ShowError($"PowerShell-Script wurde mit Fehlercode {process.ExitCode} beendet.\n\nÜberprüfen Sie die PowerShell-Ausgabe für weitere Details.");
                    }
                }
            }
            catch (Exception ex)
            {
                ShowError($"Fehler beim Ausführen des PowerShell-Scripts:\n{ex.Message}");
            }
        }

        /// <summary>
        /// Zeigt eine Fehlermeldung an
        /// </summary>
        private static void ShowError(string message)
        {
            MessageBox.Show(message, "WIMaster Setup - Fehler", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
