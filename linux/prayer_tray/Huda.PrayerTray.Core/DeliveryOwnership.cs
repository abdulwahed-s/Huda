using System.Runtime.InteropServices;
using System.Text.Json;
using NodaTime;

namespace Huda.PrayerTray.Core;

// Linux flock(2), shared with the shell helper. FileStream.Lock uses another protocol.
public sealed class DispatchLock : IDisposable
{
    private readonly FileStream _file;
    [DllImport("libc", SetLastError = true)] private static extern int flock(int fd, int operation);
    public DispatchLock(string path)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path))!);
        _file = new FileStream(path, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.ReadWrite);
        if (flock(_file.SafeFileHandle.DangerousGetHandle().ToInt32(), 2 | 4) != 0)
        { _file.Dispose(); throw new IOException("Legacy prayer dispatch is still running."); }
    }
    public void Dispose() { flock(_file.SafeFileHandle.DangerousGetHandle().ToInt32(), 8); _file.Dispose(); }
}

public static class DurableFile
{
    public static void Write(string path, string content)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path))!);
        using (var stream = new FileStream(path + ".tmp", FileMode.Create, FileAccess.Write, FileShare.None))
        {
            using var writer = new StreamWriter(stream, leaveOpen: true);
            writer.Write(content); writer.Flush(); stream.Flush(true);
        }
        File.Move(path + ".tmp", path, true);
    }
}

public sealed record DeliveryOwner(string Owner, long Revision, long CutoverUtcMs);
public sealed record OccurrenceEffects(long ClaimedAtUtcMs, string Notification = "claimed",
    string Audio = "notRequested", string Focus = "notRequested");

public sealed class LinuxOccurrenceLedger
{
    private readonly string _path;
    private Dictionary<int, OccurrenceEffects> _entries;
    public LinuxOccurrenceLedger(string path)
    {
        _path = path;
        // Corrupt history fails closed, never clears handled IDs.
        _entries = File.Exists(path) ? JsonSerializer.Deserialize<Dictionary<int, OccurrenceEffects>>(
            File.ReadAllText(path), TrayConfiguration.JsonOptions) ?? throw new InvalidDataException("Invalid prayer ledger.") : [];
        foreach (var id in _entries.Keys.ToArray())
        {
            var entry = _entries[id];
            _entries[id] = entry with { Notification = entry.Notification == "claimed" ? "interruptedUnknown" : entry.Notification,
                Audio = entry.Audio is "loading" or "playing" ? "interrupted" : entry.Audio,
                Focus = entry.Focus is "pending" or "presented" ? "interrupted" : entry.Focus };
        }
    }
    public bool Claim(int id, Instant now)
    {
        if (_entries.ContainsKey(id)) return false;
        var next = _entries.Where(pair => pair.Value.ClaimedAtUtcMs >= (now - Duration.FromDays(400)).ToUnixTimeMilliseconds())
            .ToDictionary(pair => pair.Key, pair => pair.Value);
        next[id] = new(now.ToUnixTimeMilliseconds());
        Save(next); return true;
    }
    public void Import(int id, Instant now) { if (id >= 300000000 && id < 400000000) Claim(id, now); }
    public void ImportMany(IEnumerable<int> ids, Instant now)
    {
        var next = new Dictionary<int, OccurrenceEffects>(_entries);
        foreach (var id in ids.Where(id => id >= 300000000 && id < 400000000))
            next.TryAdd(id, new(now.ToUnixTimeMilliseconds(), Notification: "importedHandled"));
        if (next.Count != _entries.Count) Save(next);
    }
    public void Record(int id, string? notification = null, string? audio = null, string? focus = null)
    {
        if (!_entries.TryGetValue(id, out var entry)) return;
        var next = new Dictionary<int, OccurrenceEffects>(_entries) { [id] = entry with {
            Notification = notification ?? entry.Notification, Audio = audio ?? entry.Audio, Focus = focus ?? entry.Focus } };
        Save(next);
    }
    private void Save(Dictionary<int, OccurrenceEffects> next)
    { DurableFile.Write(_path, JsonSerializer.Serialize(next, TrayConfiguration.JsonOptions)); _entries = next; }
}
