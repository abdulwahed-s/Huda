using Huda.PrayerTaskbar.Core;
using Windows.Data.Xml.Dom;
using Windows.UI.Notifications;

namespace Huda.PrayerTaskbar;

internal sealed class PrayerNotificationPreview : IDisposable
{
    private const string Group = "HudaPrayerPreview";
    private ToastNotifier? _notifier;
    private ToastNotification? _toast;
    public string? SessionId { get; private set; }
    public string? Content { get; private set; }

    public void Show(TaskbarConfiguration config, PrayerEvent prayer, string session, bool prototype)
    {
        if (prototype && !Paths.TestToastQueue)
            throw new InvalidOperationException("Notification probes require the private validation identity.");
        Clear();
        var appId = Paths.TestToastQueue ? "Huda.SchedulingInvestigation.20261003" : "awr.Huda-IslamicCompanionApp";
        _notifier = StartupRegistration.IsPackaged ? ToastNotificationManager.CreateToastNotifier()
            : ToastNotificationManager.CreateToastNotifier(appId);
        var xml = PrayerToastContent.Xml(config, prayer);
        var document = new XmlDocument(); document.LoadXml(xml);
        var toast = new ToastNotification(document) {
            Tag = session.Replace("-", "")[..16], Group = Group,
            ExpirationTime = DateTimeOffset.UtcNow.AddMinutes(1),
        };
        _notifier.Show(toast);
        _toast = toast; SessionId = session; Content = xml;
    }

    public void Clear(string? session = null)
    {
        if (session is not null && session != SessionId) return;
        if (_toast is { } toast) {
            try { _notifier?.Hide(toast); } catch { }
            try {
                if (StartupRegistration.IsPackaged) ToastNotificationManager.History.Remove(toast.Tag, Group);
                else ToastNotificationManager.History.Remove(toast.Tag, Group,
                    Paths.TestToastQueue ? "Huda.SchedulingInvestigation.20261003" : "awr.Huda-IslamicCompanionApp");
            } catch { }
        }
        _toast = null; _notifier = null; SessionId = null; Content = null;
    }
    public void Dispose() => Clear();
}
