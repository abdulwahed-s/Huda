using Microsoft.Win32;
using Windows.ApplicationModel;

namespace Huda.PrayerTaskbar;

internal static class StartupRegistration
{
    internal const string TaskId = "HudaPrayerTaskbar";
    private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string ApprovedKey = @"Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run";
    public static bool IsPackaged
    {
        get { uint length = 0; return NativeMethods.GetCurrentPackageFullName(ref length, null) != 15700; }
    }

    public static async Task<string> State()
    {
        if (IsPackaged)
        {
            var task = await StartupTask.GetAsync(TaskId);
            return Name(task.State);
        }
        using var run = Registry.CurrentUser.OpenSubKey(RunKey);
        if (run?.GetValue(TaskId) is not string) return "disabled";
        using var approved = Registry.CurrentUser.OpenSubKey(ApprovedKey);
        var bytes = approved?.GetValue(TaskId) as byte[];
        return bytes is { Length: >= 4 } && (bytes[0] == 3 || bytes[0] == 7)
            ? "disabledByUser" : "enabled";
    }

    public static async Task<string> Set(bool enabled)
    {
        if (IsPackaged)
        {
            var task = await StartupTask.GetAsync(TaskId);
            if (!enabled) task.Disable();
            else if (task.State == StartupTaskState.Disabled) await task.RequestEnableAsync();
            // DisabledByUser and DisabledByPolicy belong to Windows, not Huda.
            return Name(task.State);
        }
        if (!enabled) { RemoveUnpackaged(); return "disabled"; }
        using var run = Registry.CurrentUser.CreateSubKey(RunKey);
        var executable = Path.Combine(AppContext.BaseDirectory, "Huda.PrayerTaskbar.exe");
        run.SetValue(TaskId, $"\"{executable}\" --startup");
        return await State();
    }

    public static void RemoveUnpackaged()
    {
        if (IsPackaged) return;
        using var run = Registry.CurrentUser.OpenSubKey(RunKey, writable: true);
        var owned = $"\"{Path.Combine(AppContext.BaseDirectory, "Huda.PrayerTaskbar.exe")}\" --startup";
        if (run?.GetValue(TaskId) is string command &&
            command.Equals(owned, StringComparison.OrdinalIgnoreCase))
            run.DeleteValue(TaskId, throwOnMissingValue: false);
    }

    private static string Name(StartupTaskState state) => state switch {
        StartupTaskState.Enabled => "enabled", StartupTaskState.EnabledByPolicy => "enabled",
        StartupTaskState.DisabledByUser => "disabledByUser", StartupTaskState.DisabledByPolicy => "disabledByPolicy",
        _ => "disabled",
    };
}
