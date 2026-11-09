using System.Diagnostics;
using System.Runtime.InteropServices;
using Huda.PrayerTray.Core;

namespace Huda.PrayerTray;

internal sealed record PlaybackStatus(string? SessionId = null, string State = "idle", double Position = 0,
    double Duration = 0, bool Fallback = false, string? Error = null);

// One libmpv client, one cancellable generation; no child shell, loop or device-volume changes.
internal sealed class PrayerPlayback : IAsyncDisposable
{
    private const string Library = "libmpv.so.2";
    [DllImport(Library)] private static extern IntPtr mpv_create();
    [DllImport(Library)] private static extern int mpv_initialize(IntPtr handle);
    [DllImport(Library)] private static extern int mpv_set_option_string(IntPtr handle, string name, string value);
    [DllImport(Library)] private static extern int mpv_set_property_string(IntPtr handle, string name, string value);
    [DllImport(Library)] private static extern int mpv_get_property(IntPtr handle, string name, int format, out double value);
    [DllImport(Library)] private static extern IntPtr mpv_wait_event(IntPtr handle, double timeout);
    [DllImport(Library)] private static extern int mpv_command(IntPtr handle, IntPtr arguments);
    [DllImport(Library)] private static extern void mpv_terminate_destroy(IntPtr handle);
    [StructLayout(LayoutKind.Sequential)] private struct Event { public int Id, Error; public ulong UserData; public IntPtr Data; }
    private readonly object _gate = new();
    private CancellationTokenSource? _cancel;
    private Task? _worker;
    private PlaybackStatus _status = new();
    private IntPtr _handle;
    public PlaybackStatus Status { get { lock (_gate) return _status; } }
    static PrayerPlayback()
    {
        NativeLibrary.SetDllImportResolver(typeof(PrayerPlayback).Assembly, (name, assembly, path) =>
        {
            if (name != Library) return IntPtr.Zero;
            var bundled = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppContext.BaseDirectory, "..", "lib", Library));
            return NativeLibrary.TryLoad(bundled, out var handle) ? handle : IntPtr.Zero;
        });
    }
    public async Task Start(string session, ResolvedAudio file, LinuxPrayerExperience settings)
    {
        await Stop();
        var cancel = _cancel = new CancellationTokenSource();
        lock (_gate) _status = new(session, "loading", Fallback: file.Fallback);
        _worker = Task.Run(() => Run(session, file.Path, settings, cancel.Token));
    }
    public async Task Stop(string? session = null)
    {
        if (session is not null && Status.SessionId != session) return;
        _cancel?.Cancel();
        if (_worker is not null) await _worker;
        _cancel?.Dispose(); _cancel = null; _worker = null;
    }
    public bool SetVolume(string session, double volume)
    {
        if (!double.IsFinite(volume) || volume is < 0 or > 1) return false;
        lock (_gate) return _status.SessionId == session && _handle != IntPtr.Zero &&
            mpv_set_property_string(_handle, "volume", (volume * 100).ToString(System.Globalization.CultureInfo.InvariantCulture)) >= 0;
    }
    private static void Check(int result) { if (result < 0) throw new IOException($"libmpv error {result}."); }
    private void Run(string session, string file, LinuxPrayerExperience settings, CancellationToken cancel)
    {
        IntPtr handle = IntPtr.Zero;
        var ended = "ended";
        try
        {
            handle = mpv_create();
            if (handle == IntPtr.Zero) throw new IOException("libmpv could not create an audio client.");
            foreach (var (key, value) in new[] { ("config", "no"), ("load-scripts", "no"), ("vid", "no"), ("vo", "null"), ("ao", "pulse"), ("loop-file", "no"),
                ("audio-client-name", "Huda Prayer"), ("terminal", "no"),
                ("volume", (settings.Volume * 100).ToString(System.Globalization.CultureInfo.InvariantCulture)) })
                Check(mpv_set_option_string(handle, key, value));
            Check(mpv_initialize(handle));
            lock (_gate) _handle = handle;
            var values = new[] { "loadfile", file, "replace" }.Select(Marshal.StringToCoTaskMemUTF8).ToArray();
            var arguments = Marshal.AllocHGlobal((values.Length + 1) * IntPtr.Size);
            try
            {
                for (var index = 0; index < values.Length; index++) Marshal.WriteIntPtr(arguments, index * IntPtr.Size, values[index]);
                Marshal.WriteIntPtr(arguments, values.Length * IntPtr.Size, IntPtr.Zero);
                Check(mpv_command(handle, arguments));
            }
            finally { Marshal.FreeHGlobal(arguments); foreach (var value in values) Marshal.FreeCoTaskMem(value); }
            Stopwatch? playback = null;
            var loading = Stopwatch.StartNew();
            while (!cancel.IsCancellationRequested)
            {
                var ev = Marshal.PtrToStructure<Event>(mpv_wait_event(handle, .1));
                if (ev.Error < 0) Check(ev.Error);
                if (ev.Id == 21 && playback is null) playback = Stopwatch.StartNew();
                if (ev.Id == 7)
                {
                    // mpv_event_end_file: reason, error. Errors retain the notification.
                    if (ev.Data != IntPtr.Zero && Marshal.ReadInt32(ev.Data) == 4) Check(Marshal.ReadInt32(ev.Data, 4));
                    break;
                }
                if (playback is null && loading.Elapsed > TimeSpan.FromSeconds(15)) throw new IOException("Audio did not start.");
                if (playback is not null && settings.StopAfterSeconds is { } cutoff && playback.Elapsed.TotalSeconds >= cutoff)
                { ended = "cutoff"; break; }
                mpv_get_property(handle, "time-pos", 5, out var position);
                mpv_get_property(handle, "duration", 5, out var duration);
                lock (_gate) _status = _status with { State = playback is null ? "loading" : "playing", Position = position, Duration = duration };
            }
            if (cancel.IsCancellationRequested) ended = "stopped";
            lock (_gate) _status = _status with { State = ended };
        }
        catch (Exception error) when (error is IOException or DllNotFoundException or EntryPointNotFoundException)
        { lock (_gate) _status = _status with { State = "failed", Error = error.Message }; }
        finally
        {
            lock (_gate) _handle = IntPtr.Zero;
            if (handle != IntPtr.Zero) mpv_terminate_destroy(handle);
        }
    }
    public async ValueTask DisposeAsync() => await Stop();
}
