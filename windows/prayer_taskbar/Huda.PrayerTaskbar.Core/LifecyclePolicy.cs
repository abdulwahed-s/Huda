namespace Huda.PrayerTaskbar.Core;

public static class LifecyclePolicy
{
    public static bool ShouldStart(TaskbarPreferences? preferences, bool signIn) =>
        preferences?.Enabled == true && (!signIn || preferences.StartWithWindows);
    public static bool ShowTaskbar(TaskbarPreferences preferences) =>
        preferences.Enabled && preferences.ShowTaskbarCountdown;
    public static bool ShowTray(TaskbarPreferences preferences) =>
        preferences.Enabled;
}
