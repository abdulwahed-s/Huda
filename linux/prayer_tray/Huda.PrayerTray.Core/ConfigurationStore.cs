using System.Text.Json;

namespace Huda.PrayerTray.Core;

public sealed class ConfigurationStore(string path)
{
    public TrayConfiguration? Current { get; private set; }
    public string? Error { get; private set; }
    private string? _accepted;
    private readonly object _gate = new();
    public bool Reload()
    {
        lock (_gate) {
        bool changed = false;
        try { changed = Accept(File.ReadAllText(path)); }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException)
        { Error = error.Message; }
        if (Current is null)
        {
            var rejected = Error;
            try { changed = Accept(File.ReadAllText(path + ".accepted")); }
            catch (Exception error) when (error is IOException or UnauthorizedAccessException) { }
            Error = rejected;
        }
        return changed;
        }
    }

    public bool Accept(string json)
    {
        lock (_gate) {
        try
        {
            var next = TrayConfiguration.Parse(json);
            if (Current is { } prior && (next.Revision < prior.Revision ||
                (next.Revision == prior.Revision && json != _accepted)))
                throw new InvalidDataException("Stale or reused configuration revision.");
            var changed = Current?.Revision != next.Revision;
            // Commit the accepted recovery copy before changing observable state.
            if (changed)
            {
                Directory.CreateDirectory(System.IO.Path.GetDirectoryName(path)!);
                DurableFile.Write(path + ".accepted", json);
            }
            Current = next; _accepted = json; Error = null;
            return changed;
        }
        catch (Exception error) when (error is JsonException or InvalidDataException or ArgumentException or
                                             IOException or UnauthorizedAccessException or NullReferenceException)
        { Error = error.Message; return false; }
        }
    }
}
