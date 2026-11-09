using System.Diagnostics;
using Huda.PrayerTray.Core;
using Tmds.DBus.Protocol;

namespace Huda.PrayerTray;

internal sealed record NotificationBinding(string Owner, string Session, string Title, string Body,
    TrayConfiguration Configuration, string[] Actions, string? Payload = null);

internal sealed class PrayerNotificationDelivery(DBusConnection connection) : IDisposable
{
    private const string Bus = "org.freedesktop.Notifications", Path = "/org/freedesktop/Notifications";
    private readonly Dictionary<uint, NotificationBinding> _bindings = [];
    private readonly Dictionary<uint, string> _tokens = [];
    private readonly List<IDisposable> _signals = [];
    public string? Owner { get; private set; }
    public string[] Capabilities { get; private set; } = [];
    public string[] ServerInformation { get; private set; } = [];
    public string State { get; private set; } = "unavailable";
    public string? Error { get; private set; }
    public bool SilentSupported => Capabilities.Contains("sound");
    public Func<string, string, Task>? Action { get; set; }
    public async Task Initialize()
    {
        foreach (var member in new[] { "ActionInvoked", "NotificationClosed", "ActivationToken" })
        {
            var watched = member;
            _signals.Add(await connection.AddMatchAsync(new MatchRule { Type = MessageType.Signal,
                Sender = Bus, Path = Path, Interface = Bus, Member = member },
                (message, _) =>
                {
                    var reader = message.GetBodyReader();
                    var id = reader.ReadUInt32();
                    return (Sender: message.SenderAsString, Id: id,
                        Value: watched == "NotificationClosed" ? reader.ReadUInt32().ToString() : reader.ReadString());
                }, notification =>
                {
                    if (notification.HasValue) {
                        var signal = notification.Value;
                        _ = Signal(watched, signal.Sender, signal.Id, signal.Value);
                    }
                }, emitOnCapturedContext: false));
        }
        await Refresh();
    }
    public async Task Refresh()
    {
        var owner = await BusCalls.Owner(connection, Bus);
        if (owner == Owner && State == "ready") return;
        lock (_bindings) { _bindings.Clear(); _tokens.Clear(); }
        Owner = owner; Capabilities = []; ServerInformation = [];
        try
        {
            if (owner is null)
            {
                // GNOME 46 starts its notification proxy on the first client call.
                // A missing owner is not yet evidence that desktop delivery is unavailable.
                await connection.CallMethodAsync(BusCalls.Message(connection, Bus, Path, Bus, "GetCapabilities"),
                    static (message, _) => message.GetBodyReader().ReadArrayOfString()).WaitAsync(TimeSpan.FromSeconds(3));
                owner = await BusCalls.Owner(connection, Bus);
                Owner = owner;
            }
            if (owner is null) throw new IOException("Desktop notification server unavailable.");
            Capabilities = await connection.CallMethodAsync(BusCalls.Message(connection, owner, Path, Bus, "GetCapabilities"),
                static (message, _) => message.GetBodyReader().ReadArrayOfString()).WaitAsync(TimeSpan.FromSeconds(3));
            ServerInformation = await connection.CallMethodAsync(BusCalls.Message(connection, owner, Path, Bus, "GetServerInformation"),
                static (message, _) => { var reader = message.GetBodyReader(); return new[] {
                    reader.ReadString(), reader.ReadString(), reader.ReadString(), reader.ReadString() }; }).WaitAsync(TimeSpan.FromSeconds(3));
            State = "ready"; Error = null;
        }
        catch (Exception error) when (error is DBusExceptionBase or IOException or TimeoutException)
        { State = "unavailable"; Error = error.Message; }
    }
    public async Task<uint> Notify(string session, string title, string body, TrayConfiguration config,
        bool audio, bool focus, uint replaces = 0)
    {
        if (Owner is null || !SilentSupported) throw new IOException("Notification server cannot verify silent delivery.");
        var labels = config.Presentation.Strings;
        var actions = new List<string>();
        if (Capabilities.Contains("actions"))
        {
            // A click opens Huda; at most one button. Dismissing Focus also stops
            // its sound, so Stop only appears when there is nothing to dismiss.
            actions.AddRange(["default", labels["prayerSettings"]]);
            if (focus && config.Experience?.FocusCommitment != true)
                actions.AddRange(["dismissFocus", labels.GetValueOrDefault("dismiss", "Dismiss")]);
            else if (audio) actions.AddRange(["stopAudio", labels.GetValueOrDefault("stop", "Stop")]);
        }
        MessageBuffer message;
        {
        using var writer = connection.GetMessageWriter();
        writer.WriteMethodCallHeader(destination: Owner, path: Path, @interface: Bus, member: "Notify", signature: "susssasa{sv}i");
        writer.WriteString("Huda"); writer.WriteUInt32(replaces);
        var bundle = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppContext.BaseDirectory, ".."));
        writer.WriteString(System.IO.Path.Combine(bundle, "data/flutter_assets/assets/images/huda.png"));
        writer.WriteString(title); writer.WriteString(body); writer.WriteArray(actions.ToArray());
        writer.WriteDictionary(new Dictionary<string, VariantValue> {
            ["suppress-sound"] = true, ["urgency"] = (byte)1,
            ["desktop-entry"] = Environment.GetEnvironmentVariable("SNAP") is null ? "com.aw.huda" : "huda_huda",
            ["category"] = "x-huda.prayer" });
        writer.WriteInt32(-1);
        message = writer.CreateMessage();
        }
        var id = await connection.CallMethodAsync(message,
            static (message, _) => message.GetBodyReader().ReadUInt32()).WaitAsync(TimeSpan.FromSeconds(3));
        lock (_bindings) _bindings[id] = new(Owner, session, title, body, config, actions.ToArray());
        return id;
    }
    /// <summary>
    /// A reminder banner. Unlike prayer banners it keeps the desktop's sound,
    /// since no companion audio replaces it. Activating it opens Huda.
    /// </summary>
    public async Task<uint> NotifyReminder(string title, string body, string openLabel, TrayConfiguration config,
        string payload)
    {
        if (Owner is null) throw new IOException("Desktop notification server unavailable.");
        var actions = Capabilities.Contains("actions") ? new[] { "default", openLabel } : [];
        MessageBuffer message;
        {
        using var writer = connection.GetMessageWriter();
        writer.WriteMethodCallHeader(destination: Owner, path: Path, @interface: Bus, member: "Notify", signature: "susssasa{sv}i");
        writer.WriteString("Huda"); writer.WriteUInt32(0);
        var bundle = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppContext.BaseDirectory, ".."));
        writer.WriteString(System.IO.Path.Combine(bundle, "data/flutter_assets/assets/images/huda.png"));
        writer.WriteString(title); writer.WriteString(body); writer.WriteArray(actions);
        writer.WriteDictionary(new Dictionary<string, VariantValue> {
            ["urgency"] = (byte)1, ["sound-name"] = "message-new-instant",
            ["desktop-entry"] = Environment.GetEnvironmentVariable("SNAP") is null ? "com.aw.huda" : "huda_huda",
            ["category"] = "x-huda.reminder" });
        writer.WriteInt32(-1);
        message = writer.CreateMessage();
        }
        var id = await connection.CallMethodAsync(message,
            static (message, _) => message.GetBodyReader().ReadUInt32()).WaitAsync(TimeSpan.FromSeconds(3));
        lock (_bindings) _bindings[id] = new(Owner, ReminderSession, title, body, config, actions, payload);
        return id;
    }

    public async Task Close(string session)
    {
        uint[] ids;
        lock (_bindings) ids = _bindings.Where(pair => pair.Value.Session == session).Select(pair => pair.Key).ToArray();
        foreach (var id in ids)
        {
            NotificationBinding? binding;
            lock (_bindings) { _bindings.Remove(id, out binding); _tokens.Remove(id); }
            if (binding?.Owner != Owner) continue;
            try
            {
                MessageBuffer message;
                {
                using var writer = connection.GetMessageWriter();
                writer.WriteMethodCallHeader(destination: Owner, path: Path, @interface: Bus, member: "CloseNotification", signature: "u");
                writer.WriteUInt32(id); message = writer.CreateMessage();
                }
                await connection.CallMethodAsync(message).WaitAsync(TimeSpan.FromSeconds(3));
            }
            catch (Exception error) when (error is DBusExceptionBase or TimeoutException) { }
        }
    }
    public async Task RetireActions(string session, bool keepFocus)
    {
        KeyValuePair<uint, NotificationBinding>[] matches;
        lock (_bindings) matches = _bindings.Where(pair => pair.Value.Session == session &&
            (pair.Value.Actions.Contains("stopAudio") || !keepFocus && pair.Value.Actions.Contains("dismissFocus"))).ToArray();
        foreach (var (id, binding) in matches)
        {
            // Keep the history item, replacing only its obsolete live controls.
            try { await Notify(session, binding.Title, binding.Body, binding.Configuration, false,
                keepFocus && binding.Actions.Contains("dismissFocus"), id); }
            catch (Exception error) when (error is DBusExceptionBase or IOException or TimeoutException) { Error = error.Message; }
        }
    }
    private async Task Signal(string member, string? sender, uint id, string value)
    {
        NotificationBinding? binding;
        string? token;
        lock (_bindings)
        {
            _bindings.TryGetValue(id, out binding); _tokens.TryGetValue(id, out token);
            if (binding?.Owner != sender || sender != Owner) return;
            if (member == "NotificationClosed") { _bindings.Remove(id); _tokens.Remove(id); return; }
            if (member == "ActivationToken") { _tokens[id] = value; return; }
        }
        if (member != "ActionInvoked" || binding is null || !binding.Actions.Contains(value)) return;
        try
        {
            if (value == "default" && binding.Session == ReminderSession) OpenHuda(token, binding.Payload);
            else if (value is "settings" or "default") await OpenSettings(token);
            else if (Action is not null) await Action(value, binding.Session);
        }
        catch (Exception error) { Error = error.Message; }
    }
    public static Task OpenSettings(string? token = null)
    {
        var app = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppContext.BaseDirectory, "..", "huda"));
        var info = new ProcessStartInfo(app) { UseShellExecute = false };
        info.ArgumentList.Add("--prayer-settings");
        Activation(info, token);
        using var process = Process.Start(info) ?? throw new IOException("Huda could not open Prayer Settings.");
        return Task.CompletedTask;
    }
    private const string ReminderSession = "reminder";

    /// <summary>
    /// Passes the click's activation token on, so the desktop raises Huda and ends the
    /// launch cursor. GTK 3 reads it from DESKTOP_STARTUP_ID, including when a second
    /// launch hands over to a running Huda; newer toolkits read XDG_ACTIVATION_TOKEN.
    /// </summary>
    private static void Activation(ProcessStartInfo info, string? token)
    {
        if (string.IsNullOrEmpty(token)) return;
        info.Environment["XDG_ACTIVATION_TOKEN"] = token;
        info.Environment["DESKTOP_STARTUP_ID"] = token;
    }

    /// <summary>Opens Huda on the page of the clicked reminder (its payload).</summary>
    private static void OpenHuda(string? token, string? payload)
    {
        var app = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppContext.BaseDirectory, "..", "huda"));
        var info = new ProcessStartInfo(app) { UseShellExecute = false };
        info.ArgumentList.Add("--open-huda");
        if (!string.IsNullOrEmpty(payload)) info.ArgumentList.Add("--notification-payload=" + payload);
        Activation(info, token);
        using var process = Process.Start(info) ?? throw new IOException("Huda could not open.");
    }

    public void Dispose() { foreach (var signal in _signals) signal.Dispose(); }
}
