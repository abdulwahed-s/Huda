using System.Diagnostics;
using System.Security.Principal;
using System.Text.Json;
using Huda.PrayerTaskbar.Core;
using Microsoft.UI.Xaml;

namespace Huda.PrayerTaskbar;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        try { Run(args); }
        catch (Exception error)
        {
            Console.Error.Write(error);
            Environment.ExitCode = 1;
        }
    }

    private static void Run(string[] args)
    {
        var prototypeIdIndex = Array.IndexOf(args, "--prototype-id");
        if (prototypeIdIndex >= 0) {
            if (!args.Contains("--prototype") || prototypeIdIndex + 1 >= args.Length ||
                !Guid.TryParseExact(args[prototypeIdIndex + 1], "D", out var prototypeId))
                throw new ArgumentException("A prototype instance requires a GUID identifier.");
            Paths.InstanceSuffix = "." + prototypeId.ToString();
        }
        if (args.Contains("--prototype-test-toasts")) {
            if (Paths.InstanceSuffix.Length == 0 || StartupRegistration.IsPackaged)
                throw new ArgumentException("Toast probes require an isolated, unpackaged prototype instance.");
            Paths.TestToastQueue = true;
        }
        if (args.Contains("--startup-state") || args.Contains("--set-startup"))
        {
            try
            {
                var state = args.Contains("--set-startup")
                    ? StartupRegistration.Set(args.Contains("true")).GetAwaiter().GetResult()
                    : StartupRegistration.State().GetAwaiter().GetResult();
                Console.Write(JsonSerializer.Serialize(new { startupState = state }));
            }
            catch (Exception error) { Console.Write(JsonSerializer.Serialize(new { startupState = "unavailable", error = error.Message })); }
            return;
        }
        // Maintenance commands work without starting WinUI or creating surfaces.
        if (args.Contains("--shutdown") || args.Contains("--uninstall"))
        {
            var stopped = PipeServer.RequestShutdown();
            if (args.Contains("--uninstall"))
            {
                StartupRegistration.RemoveUnpackaged();
                NotificationUninstall.Run();
            }
            else if (!stopped) Environment.ExitCode = 3; // Installer: no running helper to resume.
            return;
        }
        using var guard = new Mutex(false, Paths.MutexName);
        bool owner;
        try { owner = guard.WaitOne(0); }
        catch (AbandonedMutexException) { owner = true; }
        if (!owner) return;
        try { RunApplication(args); }
        finally { guard.ReleaseMutex(); }
    }

    private static void RunApplication(string[] args)
    {
        var prototype = args.Contains("--prototype");
        string? Argument(string key) {
            var index = Array.IndexOf(args, key);
            return index >= 0 && index + 1 < args.Length ? args[index + 1] : null;
        }
        var configurationPath = prototype ? Argument("--prototype-config") ??
            Path.Combine(AppContext.BaseDirectory, "prototype-configuration.json") : Paths.Configuration;
        if (prototype && Paths.InstanceSuffix.Length != 0)
            Paths.PrototypeDirectory = Path.GetDirectoryName(Path.GetFullPath(configurationPath));
        if (Paths.TestToastQueue) Paths.PrototypeConfiguration = Path.GetFullPath(configurationPath);
        var store = new ConfigurationStore(configurationPath);
        store.Reload();
        if (args.Contains("--startup") &&
            store.Current?.Preferences is not { Enabled: true, StartWithWindows: true }) return;
        if (!args.Contains("--prototype") && store.Current?.Preferences.Enabled == false) return;
        WinRT.ComWrappersSupport.InitializeComWrappers();
        Application.Start(parameters =>
        {
            SynchronizationContext.SetSynchronizationContext(
                new Microsoft.UI.Dispatching.DispatcherQueueSynchronizationContext(
                    Microsoft.UI.Dispatching.DispatcherQueue.GetForCurrentThread()));
            _ = new App(store, prototype, prototype && args.Contains("--smoke-test"),
                prototype ? Argument("--preview-output") : null);
        });
    }
}

internal static class Paths
{
    public static string InstanceSuffix { get; set; } = "";
    public static string? PrototypeDirectory { get; set; }
    public static string? PrototypeConfiguration { get; set; }
    public static bool TestToastQueue { get; set; }
    public static string UserSid => WindowsIdentity.GetCurrent().User!.Value;
    public static string PipeName => "Huda.PrayerTaskbar." + UserSid + InstanceSuffix;
    public static string MutexName => @"Local\Huda.PrayerTaskbar." + UserSid + InstanceSuffix;
    public static string DirectoryPath
    {
        get
        {
            var localAppData = new Guid("F1B32785-6FBA-4FCF-9D55-7B8E7F157091");
            System.Runtime.InteropServices.Marshal.ThrowExceptionForHR(
                NativeMethods.SHGetKnownFolderPath(ref localAppData, 0x10000, 0, out var pointer));
            try { return Path.Combine(System.Runtime.InteropServices.Marshal.PtrToStringUni(pointer)!, "Huda", "PrayerTaskbar"); }
            finally { System.Runtime.InteropServices.Marshal.FreeCoTaskMem(pointer); }
        }
    }
    public static string Configuration => Path.Combine(DirectoryPath, "configuration.json");
    public static string HudaExecutable => Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "huda.exe"));
}
