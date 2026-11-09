using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text.Json;
using Huda.PrayerTray.Core;

namespace Huda.PrayerTray;

internal sealed record ResolvedAudio(string Path, bool Fallback);
internal sealed class PrayerAudioStore(string cacheRoot)
{
    private readonly string _bundledRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "data", "prayer-audio"));
    [DllImport("libc", SetLastError = true)] private static extern IntPtr realpath(string path, IntPtr buffer);
    [DllImport("libc")] private static extern void free(IntPtr value);
    private static string Canonical(string path)
    {
        var value = realpath(path, IntPtr.Zero);
        if (value == IntPtr.Zero) throw new IOException("Audio file unavailable.");
        try { return Marshal.PtrToStringUTF8(value)!; } finally { free(value); }
    }
    private async Task<string> Verify(string id, string version)
    {
        new LinuxPrayerExperience { ReciterId = id, AudioVersion = version }.Validate();
        var bundled = id == "huda-default" && version == "v1";
        var root = Canonical(bundled ? _bundledRoot : cacheRoot);
        var directory = Path.Combine(root, version, id);
        var file = Canonical(Path.Combine(directory, "full.mp3"));
        if (!file.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.Ordinal))
            throw new IOException("Audio escaped its trusted root.");
        long bytes = 3272108;
        var hash = "ab1ae80b2ccb0cc3397d809822ed5457aaa65441684d693ea5293c22a44df675";
        if (!bundled)
        {
            var manifest = Canonical(Path.Combine(directory, "manifest.json"));
            if (!manifest.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.Ordinal) ||
                new FileInfo(manifest).Length > 262144) throw new IOException("Invalid audio manifest.");
            using var json = JsonDocument.Parse(await File.ReadAllTextAsync(manifest));
            var data = json.RootElement;
            if (data.GetProperty("audio_version").GetString() != version ||
                data.GetProperty("reciter").GetProperty("id").GetString() != id)
                throw new IOException("Audio identity mismatch.");
            var full = data.GetProperty("reciter").GetProperty("full");
            bytes = full.GetProperty("bytes").GetInt64(); hash = full.GetProperty("sha256").GetString()!;
        }
        if (bytes is <= 0 or > 8388608 || new FileInfo(file).Length != bytes || hash.Length != 64)
            throw new IOException("Invalid audio size.");
        await using var stream = File.OpenRead(file);
        if (!Convert.ToHexStringLower(await SHA256.HashDataAsync(stream)).Equals(hash, StringComparison.Ordinal))
            throw new IOException("Audio integrity verification failed.");
        return file;
    }
    public async Task<ResolvedAudio> Resolve(LinuxPrayerExperience settings, bool allowFallback)
    {
        try { return new(await Verify(settings.ReciterId, settings.AudioVersion), false); }
        catch (Exception error) when (allowFallback && settings.ReciterId != "huda-default" &&
            error is IOException or UnauthorizedAccessException or JsonException or KeyNotFoundException or InvalidOperationException)
        { return new(await Verify("huda-default", "v1"), true); }
    }
}
