using System.Text.Json;
using System.Text.Json.Serialization;
using NodaTime;

namespace Huda.PrayerTaskbar.Core;

public static class PrayerIqamahWindows
{
    public static IReadOnlyDictionary<string, int> Defaults { get; } =
        new System.Collections.ObjectModel.ReadOnlyDictionary<string, int>(new Dictionary<string, int>
        { ["fajr"] = 25, ["dhuhr"] = 20, ["asr"] = 20, ["maghrib"] = 5, ["isha"] = 20 });

    public static Duration Window(string key, IReadOnlyDictionary<string, int>? minutes = null) =>
        Duration.FromMinutes(Defaults.TryGetValue(key, out var fallback)
            ? Math.Clamp(minutes?.GetValueOrDefault(key, fallback) ?? fallback, 0, 60) : 0);
}

public sealed class PrayerIqamahMinutesConverter : JsonConverter<IReadOnlyDictionary<string, int>>
{
    public override bool HandleNull => true;

    public override IReadOnlyDictionary<string, int> Read(ref Utf8JsonReader reader, Type type,
        JsonSerializerOptions options)
    {
        using var document = JsonDocument.ParseValue(ref reader);
        var root = document.RootElement;
        var minutes = PrayerIqamahWindows.Defaults.ToDictionary(entry => entry.Key, entry =>
            root.ValueKind == JsonValueKind.Object && root.TryGetProperty(entry.Key, out var value) &&
            value.ValueKind == JsonValueKind.Number && value.TryGetDouble(out var number) && double.IsFinite(number)
                ? (int)Math.Clamp(number, 0, 60) : entry.Value);
        return minutes.All(entry => PrayerIqamahWindows.Defaults[entry.Key] == entry.Value)
            ? PrayerIqamahWindows.Defaults : minutes;
    }

    public override void Write(Utf8JsonWriter writer, IReadOnlyDictionary<string, int> value,
        JsonSerializerOptions options)
    {
        writer.WriteStartObject();
        foreach (var key in PrayerIqamahWindows.Defaults.Keys)
            writer.WriteNumber(key, (int)PrayerIqamahWindows.Window(key, value).TotalMinutes);
        writer.WriteEndObject();
    }
}
