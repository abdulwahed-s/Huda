using System.Security.Cryptography;
using System.Text.Json;
using Huda.PrayerTaskbar.Core;
using Microsoft.UI.Dispatching;
using Windows.Media.Core;
using Windows.Media.Playback;
using Windows.Storage;

namespace Huda.PrayerTaskbar;

internal static class PrayerAudioFiles
{
    public static string BundledDirectory => Path.Combine(AppContext.BaseDirectory, "Assets", "Adhan");
    public static string CacheDirectory => Paths.PrototypeDirectory is { } prototype
        ? Path.Combine(prototype, "PrayerAudio") : Path.Combine(Path.GetDirectoryName(Paths.DirectoryPath)!, "PrayerAudio");
    public static async Task<string> Resolve(PrayerExperience settings, bool fallback = false)
    {
        settings.Validate();
        var id = fallback ? PrayerExperience.BundledReciterId : settings.PlaybackReciterId;
        var version = fallback ? "v1" : settings.AudioVersion;
        var bundled = id == PrayerExperience.BundledReciterId && version == "v1";
        var directory = Path.Combine(bundled ? BundledDirectory : CacheDirectory, version, id);
        const string filename = "full.mp3";
        var path = Path.Combine(directory, filename);
        // Hash checks and file reads stay off the WinUI dispatcher.
        await Task.Run(() => {
            using var manifest = JsonDocument.Parse(File.ReadAllText(bundled
                ? Path.Combine(BundledDirectory, "catalog.json") : Path.Combine(directory, "manifest.json")));
            var reciter = bundled ? manifest.RootElement.GetProperty("reciters").EnumerateArray()
                .First(item => item.GetProperty("id").GetString() == id) : manifest.RootElement.GetProperty("reciter");
            if (!bundled && (manifest.RootElement.GetProperty("audio_version").GetString() != version ||
                reciter.GetProperty("id").GetString() != id)) throw new InvalidDataException("Audio identity mismatch.");
            var variant = reciter.GetProperty("full");
            using var file = File.OpenRead(path);
            if (file.Length is <= 0 or > 8388608 || file.Length != variant.GetProperty("bytes").GetInt64() ||
                !Convert.ToHexString(SHA256.HashData(file)).Equals(variant.GetProperty("sha256").GetString(), StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException("Adhan integrity verification failed.");
        });
        return path;
    }
}

internal sealed class PrayerPlayback(DispatcherQueue dispatcher) : IDisposable
{
    private MediaPlayer? _player;
    private DispatcherQueueTimer? _cutoff;
    private long _generation;
    public string? SessionId { get; private set; }
    public bool Playing => _player is not null;
    public string PlaybackState => _player?.PlaybackSession.PlaybackState.ToString() ?? "Stopped";
    public double DurationMs => _player?.PlaybackSession.NaturalDuration.TotalMilliseconds ?? 0;
    public bool IsPreview { get; private set; }
    public string? Error { get; private set; }
    public event Action? Changed;

    public async Task Start(PrayerExperience settings, string sessionId, bool preview)
    {
        Stop();
        var generation = ++_generation;
        SessionId = sessionId; IsPreview = preview; Error = null;
        string path;
        var fallback = false;
        try { path = await PrayerAudioFiles.Resolve(settings); }
        catch (Exception error) {
            if (generation != _generation) return;
            Error = error.Message; fallback = true;
            try { path = await PrayerAudioFiles.Resolve(settings, fallback: true); }
            catch (Exception failure) { if (generation == _generation) { Error = failure.Message; SessionId = null; Changed?.Invoke(); } return; }
        }
        if (generation != _generation) return;
        await Open(path, settings, sessionId, generation, fallback);
    }

    private async Task Open(string path, PrayerExperience settings, string sessionId, long generation, bool fallback)
    {
        MediaPlayer? player = null;
        try {
            var file = await StorageFile.GetFileFromPathAsync(path);
            if (generation != _generation) return;
            player = new MediaPlayer { Volume = settings.Volume, IsLoopingEnabled = false,
                AutoPlay = false, Source = MediaSource.CreateFromStorageFile(file) };
            var current = player;
            player.MediaEnded += (_, _) => dispatcher.TryEnqueue(() => { if (_player == current) Stop(sessionId); });
            player.MediaFailed += (_, args) => dispatcher.TryEnqueue(async () => {
                if (_player != current || generation != _generation) return;
                Error = string.IsNullOrWhiteSpace(args.ErrorMessage) ? args.Error.ToString() : args.ErrorMessage;
                _player = null; current.Dispose();
                if (!fallback) {
                    try { await Open(await PrayerAudioFiles.Resolve(settings, fallback: true), settings, sessionId, generation, true); }
                    catch (Exception error) { if (generation == _generation) { Error = error.Message; Stop(sessionId); } }
                } else { Stop(sessionId); }
                Changed?.Invoke();
            });
            _player = player;
            player.Play();
            _cutoff?.Stop();
            if (settings.PlaybackCutoffSeconds is { } seconds) {
                _cutoff = dispatcher.CreateTimer(); _cutoff.IsRepeating = false;
                _cutoff.Interval = TimeSpan.FromSeconds(seconds);
                _cutoff.Tick += (_, _) => Stop(sessionId); _cutoff.Start();
            }
            Changed?.Invoke();
        } catch (Exception error) {
            player?.Dispose();
            if (generation != _generation) return;
            _player = null; Error = error.Message;
            if (!fallback) {
                try {
                    var bundled = await PrayerAudioFiles.Resolve(settings, fallback: true);
                    if (generation != _generation) return;
                    await Open(bundled, settings, sessionId, generation, true);
                    return;
                } catch (Exception failure) {
                    if (generation != _generation) return;
                    Error = failure.Message;
                }
            }
            Stop(sessionId);
        }
    }

    public void SetVolume(double volume) { if (_player is { } player) player.Volume = volume; }
    public void Stop(string? sessionId = null)
    {
        if (sessionId is not null && sessionId != SessionId) return;
        ++_generation; _cutoff?.Stop(); _cutoff = null;
        var player = _player; _player = null; SessionId = null; IsPreview = false;
        player?.Pause(); player?.Dispose(); Changed?.Invoke();
    }
    public void Dispose() => Stop();
}
