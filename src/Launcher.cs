using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("1 Click DLSS 5")]
[assembly: AssemblyDescription("Universal Neural Control Center • DLSS 5 (DLSS-NR) Installer")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("1 Click DLSS 5 Project")]
[assembly: AssemblyProduct("1 Click DLSS 5")]
[assembly: AssemblyCopyright("Copyright (c) 2026 MIT License")]
[assembly: AssemblyTrademark("DLSS 5 Neural Control Center")]
[assembly: AssemblyVersion("2.5.3.0")]
[assembly: AssemblyFileVersion("2.5.3.0")]

namespace OneClickDLSS5
{
    static class Program
    {
        [DllImport("user32.dll")]
        private static extern bool SetProcessDpiAwarenessContext(int dpiFlag);

        [STAThread]
        static int Main(string[] args)
        {
            try
            {
                SetProcessDpiAwarenessContext(-4); // DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
            }
            catch { }

            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            string scriptPath = Path.Combine(baseDir, @"core\1-Click-DLSS5.ps1");

            if (!File.Exists(scriptPath))
            {
                // Fallback check
                string altScript = Path.Combine(baseDir, "1-Click-DLSS5.ps1");
                if (File.Exists(altScript))
                {
                    scriptPath = altScript;
                }
                else
                {
                    System.Windows.Forms.MessageBox.Show(
                        "Erro: Não foi possível localizar o script principal em:\n" + scriptPath,
                        "1 Click DLSS 5",
                        System.Windows.Forms.MessageBoxButtons.OK,
                        System.Windows.Forms.MessageBoxIcon.Error);
                    return 1;
                }
            }

            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "powershell.exe";
                psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + scriptPath + "\"";
                psi.WorkingDirectory = Path.GetDirectoryName(scriptPath);
                psi.UseShellExecute = false;
                psi.CreateNoWindow = true;
                psi.WindowStyle = ProcessWindowStyle.Hidden;

                using (Process proc = Process.Start(psi))
                {
                    proc.WaitForExit();
                    return proc.ExitCode;
                }
            }
            catch (Exception ex)
            {
                System.Windows.Forms.MessageBox.Show(
                    "Falha ao iniciar o 1 Click DLSS 5:\n\n" + ex.Message,
                    "1 Click DLSS 5",
                    System.Windows.Forms.MessageBoxButtons.OK,
                    System.Windows.Forms.MessageBoxIcon.Error);
                return 1;
            }
        }
    }
}
