using System.Text.Json;
using Huda.PrayerTaskbar.Core;
using NodaTime;
using Xunit;

namespace Huda.PrayerTaskbar.Tests;

public sealed class PrayerMomentTests
{
    public static IEnumerable<object[]> Cases()
    {
        using var document = JsonDocument.Parse(File.ReadAllText(
            Path.Combine(AppContext.BaseDirectory, "Fixtures", "huda-parity.json")));
        foreach (var sample in document.RootElement.GetProperty("momentCases").EnumerateArray())
            yield return [sample.GetProperty("name").GetString()!, sample.GetRawText()];
    }

    [Theory]
    [MemberData(nameof(Cases))]
    public void CountdownPrayerAndElapsedStateMatchTheFlutterPage(string name, string json)
    {
        using var document = JsonDocument.Parse(json);
        var sample = document.RootElement;
        var now = Instant.FromUnixTimeMilliseconds(sample.GetProperty("nowUtc").GetInt64());
        var events = sample.GetProperty("events").EnumerateArray().Select(item => {
            var time = Instant.FromUnixTimeMilliseconds(item.GetProperty("timeUtc").GetInt64());
            return new PrayerEvent(item.GetProperty("key").GetString()!, time.InUtc().Date, time);
        }).ToArray();
        var snapshot = new ScheduleSnapshot(now.InUtc().Date,
            new DailySchedule(now.InUtc().Date, new Dictionary<string, Instant?>()), events, null);
        var minutes = sample.TryGetProperty("iqamahMinutes", out var rawMinutes)
            ? JsonSerializer.Deserialize<Dictionary<string, int>>(rawMinutes.GetRawText()) : null;
        var moment = snapshot.Moment(now, minutes);
        Assert.NotNull(moment);
        Assert.True(sample.GetProperty("expectedPrayer").GetString() == moment.Prayer.Key,
            $"{name}: native selected {moment.Prayer.Key}.");
        Assert.Equal(sample.GetProperty("expectedElapsed").GetBoolean(), moment.IsElapsed);
        var counter = CountdownFormatter.Counter(moment, now, true);
        Assert.Equal(moment.IsElapsed, counter.StartsWith('+'));
        var components = counter.TrimStart('+').Split(':').Select(int.Parse).ToArray();
        Assert.Equal(sample.GetProperty("expectedSeconds").GetInt32(),
            components[0] * 3600 + components[1] * 60 + components[2]);
        var config = ContractsTests.Sample();
        if (minutes is not null) config = config with { Preferences = config.Preferences with { IqamahMinutes = minutes } };
        Assert.Contains(config.Presentation.Label(moment.Prayer.Key), CountdownFormatter.Text(config, snapshot, now));
        Assert.Contains(counter, CountdownFormatter.Text(config, snapshot, now));
    }
}
