using System.Runtime.InteropServices;
using Tmds.DBus.Protocol;

namespace Huda.PrayerTray;

// The kernel clocks remain available when strict confinement denies logind.
// CLOCK_BOOTTIME includes sleep; CLOCK_MONOTONIC excludes it. Comparing them
// detects even a short suspend without depending on wall-clock changes or Shell.
internal sealed class PrayerSessionObservation : IDisposable
{
    private DBusConnection? _systemBus;
    private IDisposable? _sleepSignal;
    private long? _sleepOffset;
    private int _boundary, _sleeping;
    public string Source { get; private set; } = "unavailable";
    public string? Error { get; private set; }
    public bool Sleeping => Volatile.Read(ref _sleeping) != 0;
    public Func<Task>? Interrupt { get; set; }

    [StructLayout(LayoutKind.Sequential)]
    private struct Timespec { public nint Seconds; public nint Nanoseconds; }
    [DllImport("libc", EntryPoint = "clock_gettime", SetLastError = true)]
    private static extern int ClockGetTime(int clock, out Timespec time);
    private static long? SleepOffset()
    {
        if (ClockGetTime(7, out var boot) != 0 || ClockGetTime(1, out var monotonic) != 0) return null;
        return (long)(boot.Seconds - monotonic.Seconds) * 1000 +
            (long)(boot.Nanoseconds - monotonic.Nanoseconds) / 1000000;
    }
    public async Task Initialize()
    {
        _sleepOffset = SleepOffset();
        if (_sleepOffset is not null) Source = "kernelClocks";
        try
        {
            _systemBus = new DBusConnection(DBusAddress.System!);
            await _systemBus.ConnectAsync().AsTask().WaitAsync(TimeSpan.FromSeconds(2));
            _sleepSignal = await _systemBus.AddMatchAsync(new MatchRule {
                Type = MessageType.Signal, Sender = "org.freedesktop.login1",
                Path = "/org/freedesktop/login1", Interface = "org.freedesktop.login1.Manager", Member = "PrepareForSleep"
            }, static (message, _) => message.GetBodyReader().ReadBool(), notification => {
                if (!notification.HasValue) return;
                Interlocked.Exchange(ref _sleeping, notification.Value ? 1 : 0);
                Interlocked.Exchange(ref _boundary, 1);
                if (Interrupt is not null) _ = Interrupt();
            }, emitOnCapturedContext: false);
            // Reading this property proves access to the service, rather than
            // treating a successful match registration as permission to receive.
            MessageBuffer request;
            using (var writer = _systemBus.GetMessageWriter())
            {
                writer.WriteMethodCallHeader(destination: "org.freedesktop.login1", path: "/org/freedesktop/login1",
                    @interface: "org.freedesktop.DBus.Properties", member: "Get", signature: "ss");
                writer.WriteString("org.freedesktop.login1.Manager"); writer.WriteString("PreparingForSleep");
                request = writer.CreateMessage();
            }
            var sleeping = await _systemBus.CallMethodAsync(request,
                static (message, _) => message.GetBodyReader().ReadVariantValue().GetBool()).WaitAsync(TimeSpan.FromSeconds(2));
            Interlocked.Exchange(ref _sleeping, sleeping ? 1 : 0);
            Source = "logindAndKernelClocks";
        }
        catch (Exception error) when (error is DBusExceptionBase or IOException or TimeoutException)
        {
            Error = error.Message;
            _sleepSignal?.Dispose(); _sleepSignal = null;
            _systemBus?.Dispose(); _systemBus = null;
        }
    }
    public bool ConsumeBoundary()
    {
        var offset = SleepOffset();
        var resumed = offset is not null && _sleepOffset is not null && Math.Abs(offset.Value - _sleepOffset.Value) > 100;
        _sleepOffset = offset;
        return Interlocked.Exchange(ref _boundary, 0) != 0 || resumed;
    }
    public void Dispose() { Interrupt = null; _sleepSignal?.Dispose(); _systemBus?.Dispose(); }
}
