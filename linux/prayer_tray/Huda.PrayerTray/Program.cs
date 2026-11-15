using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.Json;
using Huda.PrayerTray.Core;
using NodaTime;
using Tmds.DBus.Protocol;

namespace Huda.PrayerTray;

internal static class Program
{
    public static async Task<int> Main(string[] args)
    {
        var data = Environment.GetEnvironmentVariable("SNAP_USER_COMMON") ??
            Path.Combine(Environment.GetEnvironmentVariable("XDG_DATA_HOME") ??
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".local", "share"), "huda");
        var directory = Path.Combine(data, "prayer-tray");
        Directory.CreateDirectory(directory);
        var marker = Path.Combine(Environment.GetEnvironmentVariable("XDG_RUNTIME_DIR") ?? directory,
            "huda-prayer-tray-session-stopped");
        // The Snap's login autostart: D-Bus activation starts the service unit, then this exits.
        if (args.SequenceEqual(new[] { "--activate" })) return await Activate();
        if (args.SequenceEqual(new[] { "--start" })) File.Delete(marker);
        else if (args.Length != 0) { Console.Error.WriteLine("Usage: huda-prayer-tray [--start | --activate]"); return 2; }
        if (File.Exists(marker)) return 0;
        var store = new ConfigurationStore(Path.Combine(directory, "configuration.json"));
        using var shutdown = new CancellationTokenSource();
        using var term = PosixSignalRegistration.Create(PosixSignal.SIGTERM, context =>
        { context.Cancel = true; shutdown.Cancel(); });
        Console.CancelKeyPress += (_, ev) => { ev.Cancel = true; shutdown.Cancel(); };
        using var connection = new DBusConnection(DBusAddress.Session!);
        await connection.ConnectAsync();
        if (!await ClaimName(connection)) return 0;
        Console.WriteLine($"Huda prayer display owns {TrayHost.BusName} ({connection.UniqueName}).");
        var host = new TrayHost(connection, store, new DisplayEngine(SystemClock.Instance), marker, shutdown);
        connection.AddMethodHandler(host);
        await using var experience = new PrayerExperienceHost(connection, store, directory,
            Path.Combine(data, "prayer-notifications"), shutdown.Token);
        connection.AddMethodHandler(experience);
        using var reminders = new ReminderHost(connection, store, directory);
        try { await experience.Initialize(); }
        catch (OperationCanceledException) when (shutdown.IsCancellationRequested) { return 0; }
        host.Refresh();
        using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(500));
        // Polling is outside Shell. Schedule calculations are cached by configuration and civil date.
        // It also covers file replacement, clock jumps and resume without relying on wall-clock timers.
        try
        {
            while (!shutdown.IsCancellationRequested)
            {
                var tick = timer.WaitForNextTickAsync(shutdown.Token).AsTask();
                var disconnected = connection.DisconnectedAsync();
                if (await Task.WhenAny(tick, disconnected) != tick)
                { Console.Error.WriteLine(await disconnected); return 1; }
                if (!await tick) break;
                host.Refresh();
                await experience.Tick();
                await reminders.Tick();
            }
        }
        catch (OperationCanceledException) { }
        return 0;
    }

    private static async Task<int> Activate()
    {
        using var connection = new DBusConnection(DBusAddress.Session!);
        await connection.ConnectAsync();
        try
        {
            await connection.CallMethodAsync(BusCalls.Message(connection, TrayHost.BusName, "/com/aw/huda/PrayerTray",
                TrayHost.Interface, "GetSnapshot")).WaitAsync(TimeSpan.FromSeconds(30));
            return 0;
        }
        // A just-started service owns its name a moment before its objects exist: it runs.
        catch (DBusErrorReplyException error) when (error.ErrorName is "org.freedesktop.DBus.Error.UnknownMethod"
            or "org.freedesktop.DBus.Error.UnknownObject") { return 0; }
        catch (Exception error) when (error is DBusExceptionBase or TimeoutException)
        {
            Console.Error.WriteLine($"Huda prayer service activation failed: {error.Message}");
            return 1;
        }
    }

    private static async Task<bool> ClaimName(DBusConnection connection) =>
        await connection.TryRequestNameAsync(TrayHost.BusName, RequestNameOptions.None);
}

internal sealed class TrayHost(DBusConnection connection, ConfigurationStore store, DisplayEngine engine,
    string marker, CancellationTokenSource shutdown) : IPathMethodHandler
{
    public const string BusName = "com.aw.huda.PrayerTray";
    public const string Interface = "com.aw.huda.PrayerTray1";
    public string Path => "/com/aw/huda/PrayerTray";
    public bool HandlesChildPaths => false;
    private readonly object _gate = new();
    private string _json = "{}";
    private long _lastSignalMs;
    private string? _identity;
    private ulong _serial;
    private bool _stopping;
    private TaskCompletionSource<string> _nextChange = new(TaskCreationOptions.RunContinuationsAsynchronously);
    private static readonly byte[] InterfaceXml = ReadSchema();
    private static byte[] ReadSchema()
    {
        using var input = typeof(TrayHost).Assembly.GetManifestResourceStream(
            "com.aw.huda.PrayerTray1.xml")!;
        using var buffer = new MemoryStream(); input.CopyTo(buffer); return buffer.ToArray();
    }

    public void Refresh()
    {
        lock (_gate)
        {
            if (_stopping) return;
            store.Reload();
            var snapshot = engine.Snapshot(store.Current, store.Current is null ? null : store.Error);
            var identity = $"{snapshot.AppliedRevision}:{snapshot.State}:{snapshot.CivilDate}:{snapshot.Next?.UtcMs}:{snapshot.Current?.UtcMs}:{snapshot.CurrentUntilUtcMs}:{snapshot.Error}";
            var changed = _identity != identity || snapshot.GeneratedAtUtcMs - _lastSignalMs >= 30000 ||
                snapshot.GeneratedAtUtcMs < _lastSignalMs;
            if (changed) _serial++;
            _json = JsonSerializer.Serialize(snapshot with { ChangeSerial = _serial }, TrayConfiguration.JsonOptions);
            if (changed)
            {
                _identity = identity; _lastSignalMs = snapshot.GeneratedAtUtcMs; Changed(_json);
            }
        }
    }

    public ValueTask HandleMethodAsync(MethodContext context)
    {
        if (context.IsDBusIntrospectRequest) { context.ReplyIntrospectXml([InterfaceXml]); return default; }
        var request = context.Request;
        if (request.InterfaceAsString != Interface) return default;
        switch ((request.MemberAsString, request.SignatureAsString))
        {
            case ("GetSnapshot", ""):
            case ("Refresh", ""):
                Refresh();
                using (var writer = context.CreateReplyWriter("s"))
                {
                    lock (_gate) writer.WriteString(_json);
                    context.Reply(writer.CreateMessage());
                }
                break;
            case ("Command", "s"):
                var action = request.GetBodyReader().ReadString();
                context.DisposesAsynchronously = true;
                _ = HandleCommand(context, action);
                break;
            case ("WaitForSnapshot", "t"):
                var serial = request.GetBodyReader().ReadUInt64();
                context.DisposesAsynchronously = true;
                _ = HandleWatch(context, serial);
                break;
        }
        return default;
    }

    private async Task HandleWatch(MethodContext context, ulong afterSerial)
    {
        using (context)
        {
            Task<string> next;
            lock (_gate) next = afterSerial != _serial ? Task.FromResult(_json) : _nextChange.Task;
            string json;
            try { json = await next.WaitAsync(TimeSpan.FromSeconds(35), shutdown.Token); }
            catch (TimeoutException) { lock (_gate) json = _json; }
            catch (OperationCanceledException)
            { context.ReplyError(Interface + ".Stopping", "Prayer display stopped."); return; }
            using var writer = context.CreateReplyWriter("s");
            writer.WriteString(json); context.Reply(writer.CreateMessage());
        }
    }

    private async Task HandleCommand(MethodContext context, string action)
    {
        using (context)
        {
            try
            {
                if (action is not ("openHuda" or "prayerSettings" or "quit"))
                { context.ReplyError(Interface + ".InvalidAction", "Unknown action."); return; }
                var argument = action switch { "prayerSettings" => "--prayer-settings", "quit" => "--quit-huda", _ => "--open-huda" };
                if (action == "quit")
                {
                    File.WriteAllText(marker, "stopped");
                    lock (_gate)
                    {
                        _stopping = true;
                        var stopped = engine.Snapshot(store.Current) with { State = "stopped", ChangeSerial = ++_serial };
                        _json = JsonSerializer.Serialize(stopped, TrayConfiguration.JsonOptions);
                        Changed(_json);
                    }
                }
                // A fixed sibling binary, never an executable or shell command from configuration.
                var app = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppContext.BaseDirectory, "..", "huda"));
                if (!File.Exists(app)) throw new FileNotFoundException("Huda executable missing.", app);
                var launch = new ProcessStartInfo(app) { UseShellExecute = false };
                launch.ArgumentList.Add(argument);
                using var process = Process.Start(launch) ?? throw new IOException("Huda could not start.");
                // A primary app stays running. A secondary activation process exits immediately.
                var exited = process.WaitForExitAsync();
                if (await Task.WhenAny(exited, Task.Delay(750)) == exited && process.ExitCode != 0)
                    throw new IOException("Huda activation failed.");
                using var writer = context.CreateReplyWriter("b");
                writer.WriteBool(true); context.Reply(writer.CreateMessage());
            }
            catch (Exception error) when (error is IOException or InvalidOperationException or System.ComponentModel.Win32Exception)
            { context.ReplyError(Interface + ".ActivationFailed", error.Message); }
            finally { if (action == "quit") shutdown.Cancel(); }
        }
    }

    private void Changed(string json)
    {
        var waiting = _nextChange;
        _nextChange = new(TaskCreationOptions.RunContinuationsAsynchronously);
        waiting.TrySetResult(json);
        using var writer = connection.GetMessageWriter();
        writer.WriteSignalHeader(path: Path, @interface: Interface, member: "SnapshotChanged", signature: "s");
        writer.WriteString(json); connection.TrySendMessage(writer.CreateMessage());
    }
}
