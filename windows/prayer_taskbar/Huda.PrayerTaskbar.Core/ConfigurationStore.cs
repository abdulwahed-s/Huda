using System.Text.Json;

namespace Huda.PrayerTaskbar.Core;

public sealed class ConfigurationStore(string path)
{
    public TaskbarConfiguration? Current { get; private set; }
    public string? Error { get; private set; }
    private string? _acceptedJson;

    // Only Huda's bridge writes this file. Invalid/partial updates keep the last good revision.
    public bool Reload()
    {
        try
        {
            var accepted = Accept(Read(path));
            if (Current is null) LoadBackup();
            return accepted;
        }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException)
        {
            Error = error.Message;
            if (Current is null) LoadBackup();
            return false;
        }
    }

    private void LoadBackup()
    {
        var error = Error;
        try { Accept(Read(Path.ChangeExtension(path, "backup.json"))); }
        catch (Exception failure) when (failure is IOException or UnauthorizedAccessException) { }
        Error = error; // Recover the last valid state and still report the rejected update.
    }

    private static string Read(string file)
    {
        // The bridge replaces this path atomically. Readers must not prevent
        // Windows from renaming or deleting the previous committed file.
        using var stream = new FileStream(file, FileMode.Open, FileAccess.Read,
            FileShare.ReadWrite | FileShare.Delete);
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }

    public bool Accept(string json)
    {
        try
        {
            var next = TaskbarConfiguration.Parse(json);
            if (Current is { } previous && (next.Revision < previous.Revision ||
                (next.Revision == previous.Revision && json != _acceptedJson)))
                throw new InvalidDataException("Stale configuration revision.");
            var changed = Current?.Revision != next.Revision;
            Current = next;
            _acceptedJson = json;
            Error = null;
            return changed;
        }
        catch (Exception error) when (error is JsonException or InvalidDataException or ArgumentException)
        {
            Error = error.Message;
            return false;
        }
    }
}
