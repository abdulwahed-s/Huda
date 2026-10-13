using Microsoft.Win32;
using Windows.UI.Notifications;

namespace Huda.PrayerTaskbar;

/// Removes Huda's toasts and toast registration when the installed (Inno) app
/// is uninstalled. Windows keeps an unpackaged app's scheduled toasts after its
/// files are gone, so without this prayers and reminders would keep arriving
/// for up to a year. Removing an MSIX package already does all of this.
internal static class NotificationUninstall
{
    private const string AppId = "awr.Huda-IslamicCompanionApp";
    private const string ActivatorKey = @"Software\Classes\CLSID\{a8c22b55-049e-422f-b30f-863694de08c8}";
    private const string AppIdKey = @"Software\Classes\AppUserModelId\" + AppId;

    public static void Run()
    {
        if (StartupRegistration.IsPackaged) return;
        var executable = Paths.HudaExecutable;
        // Another Huda copy (portable, or installed elsewhere) registered last
        // and still exists: the identity and its toasts are that copy's.
        if (RegisteredExecutable() is { } registered &&
            !registered.Equals(executable, StringComparison.OrdinalIgnoreCase) && File.Exists(registered)) return;
        try
        {
            var notifier = ToastNotificationManager.CreateToastNotifier(AppId);
            foreach (var toast in notifier.GetScheduledToastNotifications().ToArray())
            {
                try { notifier.RemoveFromSchedule(toast); }
                catch (Exception) { /* Already delivered or removed. */ }
            }
            ToastNotificationManager.History.Clear(AppId);
        }
        catch (Exception) { /* No toasts were ever registered for this identity. */ }
        Registry.CurrentUser.DeleteSubKeyTree(ActivatorKey, throwOnMissingSubKey: false);
        Registry.CurrentUser.DeleteSubKeyTree(AppIdKey, throwOnMissingSubKey: false);
        RemoveShortcut(executable);
    }

    private static string? RegisteredExecutable()
    {
        using var server = Registry.CurrentUser.OpenSubKey(ActivatorKey + @"\LocalServer32");
        return server?.GetValue("ServerExecutable") as string;
    }

    // Huda adds a per-user Start menu shortcut when the installer's shortcut
    // doesn't carry its identity; the uninstaller only removes its own.
    private static void RemoveShortcut(string executable)
    {
        var shortcut = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "Huda.lnk");
        if (!File.Exists(shortcut)) return;
        try
        {
            dynamic shell = Activator.CreateInstance(Type.GetTypeFromProgID("WScript.Shell")!)!;
            string target = shell.CreateShortcut(shortcut).TargetPath;
            if (target.Equals(executable, StringComparison.OrdinalIgnoreCase)) File.Delete(shortcut);
        }
        catch (Exception) { /* Leave a shortcut that can't be read. */ }
    }
}
