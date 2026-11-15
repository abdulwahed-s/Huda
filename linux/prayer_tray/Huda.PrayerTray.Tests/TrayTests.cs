using System.Text.Json;
using Huda.PrayerTaskbar.Core;
using Huda.PrayerTray.Core;
using NodaTime;
using NodaTime.Text;
using Xunit;
using ConfigurationStore = Huda.PrayerTray.Core.ConfigurationStore;

namespace Huda.PrayerTray.Tests;

public sealed class TrayTests
{
    private sealed class Clock(Instant instant) : IClock
    {
        public Instant Now = instant;
        public Instant GetCurrentInstant() => Now;
    }
    public static IEnumerable<object[]> Fixtures()
    {
        using var source = JsonDocument.Parse(File.ReadAllText("huda-parity.json"));
        foreach (var fixture in source.RootElement.GetProperty("fixtures").EnumerateArray())
            yield return [fixture.GetProperty("name").GetString()!, fixture.GetRawText()];
    }
    private static TrayConfiguration Linux(TaskbarConfiguration windows)
    {
        var strings = new Dictionary<string, string>(windows.Presentation.Strings);
        foreach (var key in TrayConfiguration.RequiredLabels) strings.TryAdd(key, key);
        strings["nameCountdown"] = "{prayer} {time}";
        var tokens = new[] { "surface", "card", "primary", "ink", "muted", "faint", "border", "divider", "highlight", "warning", "error", "success" }
            .ToDictionary(key => key, _ => "#123456ff");
        return new TrayConfiguration
        {
            SchemaVersion = 1, Revision = windows.Revision, PublishedAtUtc = windows.PublishedAtUtc,
            Preferences = new TrayPreferences { Enabled = true, StartAtLogin = false, Style = "iconNameCountdown" },
            Location = windows.Location, Calculation = windows.Calculation,
            Presentation = new TrayPresentation
            {
                Locale = "en", Rtl = false, ThemeMode = "system", FontFamily = "system", Numerals = "western",
                Use24HourClock = true, TextScale = 1, Strings = strings,
                Tokens = new() { ["light"] = tokens, ["dark"] = tokens },
            },
        };
    }
    internal static TrayConfiguration Default()
    {
        using var source = JsonDocument.Parse(File.ReadAllText("huda-parity.json"));
        return Linux(TaskbarConfiguration.Parse(source.RootElement.GetProperty("fixtures")[0]
            .GetProperty("configuration").GetRawText()));
    }
    [Theory]
    [MemberData(nameof(Fixtures))]
    public void MatchesIndependentFlutterFixtures(string name, string json)
    {
        using var fixture = JsonDocument.Parse(json);
        var root = fixture.RootElement;
        var config = Linux(TaskbarConfiguration.Parse(root.GetProperty("configuration").GetRawText()));
        config.Validate();
        var date = LocalDatePattern.Iso.Parse(root.GetProperty("date").GetString()!).Value;
        var clock = new Clock(LocationClock.Resolve(date.At(new LocalTime(12, 0)), DateTimeZoneProviders.Tzdb[config.Location!.TimeZoneId]));
        var actual = new DisplayEngine(clock).Snapshot(config);
        Assert.Equal(date.ToString("yyyy-MM-dd", null), actual.CivilDate);
        foreach (var row in actual.Rows)
        {
            var expected = root.GetProperty("expectedUtc").GetProperty(row.Key);
            Assert.True(expected.ValueKind == JsonValueKind.Null ? row.UtcMs is null : row.UtcMs == expected.GetInt64(),
                $"{name}: {row.Key}: {row.UtcMs} != {expected}");
        }
        Assert.NotEqual("sunrise", actual.Next?.Key);
    }
    [Fact]
    public void BoundaryAndMidnightDoNotRecalculateEachTick()
    {
        var config = Default();
        var clock = new Clock(Instant.FromUtc(2026, 10, 2, 0, 0));
        var engine = new DisplayEngine(clock);
        var first = engine.Snapshot(config);
        var fajr = first.Rows.Single(row => row.Key == "fajr").UtcMs!.Value;
        clock.Now = Instant.FromUnixTimeMilliseconds(fajr);
        Assert.NotEqual("fajr", engine.Snapshot(config).Next?.Key);
        clock.Now += Duration.FromSeconds(1);
        engine.Snapshot(config);
        Assert.Equal(1, engine.CalculationCount);
        clock.Now = Instant.FromUtc(2026, 10, 2, 20, 0);
        var tomorrow = engine.Snapshot(config);
        Assert.Equal("2026-10-03", tomorrow.CivilDate);
        Assert.Equal("fajr", tomorrow.Next?.Key);
        Assert.Equal(2, engine.CalculationCount);
        clock.Now -= Duration.FromDays(1); // isolated clock jump backwards
        Assert.Equal("2026-10-02", engine.Snapshot(config).CivilDate);
    }
    [Fact]
    public void CurrentPrayerExpiresAtWindowEndAndSerializesWithoutContractChanges()
    {
        var config = Default();
        var clock = new Clock(Instant.FromUtc(2026, 10, 2, 0, 0));
        var engine = new DisplayEngine(clock);
        var fajr = engine.Snapshot(config).Rows.Single(row => row.Key == "fajr").UtcMs!.Value;
        clock.Now = Instant.FromUnixTimeMilliseconds(fajr);
        var start = engine.Snapshot(config);
        Assert.Equal("fajr", start.Current?.Key);
        Assert.Equal(fajr + 25 * 60 * 1000, start.CurrentUntilUtcMs);
        Assert.NotEqual("fajr", start.Next?.Key);
        clock.Now += Duration.FromMinutes(24) + Duration.FromSeconds(59);
        var end = engine.Snapshot(config);
        Assert.Equal(start.CurrentUntilUtcMs, end.ValidUntilUtcMs);
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(end, TrayConfiguration.JsonOptions));
        Assert.Equal("fajr", json.RootElement.GetProperty("current").GetProperty("key").GetString());
        clock.Now += Duration.FromSeconds(1);
        Assert.Null(engine.Snapshot(config).Current);
    }
    [Fact]
    public void MaghribUsesFiveMinutesAndOffSkipsTheStartBoundary()
    {
        var config = Default();
        var clock = new Clock(Instant.FromUtc(2026, 10, 2, 0, 0));
        var engine = new DisplayEngine(clock);
        var maghrib = engine.Snapshot(config).Rows.Single(row => row.Key == "maghrib").UtcMs!.Value;
        clock.Now = Instant.FromUnixTimeMilliseconds(maghrib) + Duration.FromSeconds(299);
        Assert.Equal("maghrib", engine.Snapshot(config).Current?.Key);
        Assert.Equal(maghrib + 300000, engine.Snapshot(config).ValidUntilUtcMs);
        clock.Now += Duration.FromSeconds(1);
        Assert.Null(engine.Snapshot(config).Current);
        clock.Now = Instant.FromUnixTimeMilliseconds(maghrib);
        var off = config with { Preferences = config.Preferences with {
            IqamahMinutes = new Dictionary<string, int> { ["maghrib"] = 0 } } };
        Assert.Null(engine.Snapshot(off).Current);
        Assert.Equal("isha", engine.Snapshot(off).Next?.Key);
        var json = JsonSerializer.Serialize(config, TrayConfiguration.JsonOptions);
        var parsed = TrayConfiguration.Parse(json);
        Assert.Equal(5, parsed.Preferences.IqamahMinutes["maghrib"]);
    }

    [Fact]
    public void EmptyProvisionalDisabledAndMissingSolarEventsAreExplicit()
    {
        var engine = new DisplayEngine(new Clock(Instant.FromUtc(2026, 6, 20, 12, 0)));
        Assert.Equal("needsSetup", engine.Snapshot(null).State);
        var config = Default();
        Assert.True(engine.Snapshot(config with { Location = config.Location! with { Verified = false } }).Provisional);
        Assert.Equal("disabled", engine.Snapshot(config with { Preferences = config.Preferences with { Enabled = false } }).State);
        var polar = config with { Location = config.Location! with { Latitude = 89, TimeZoneId = "Arctic/Longyearbyen" },
            Calculation = config.Calculation! with { HighLatitudeRule = "none" } };
        Assert.Equal("calculationUnavailable", engine.Snapshot(polar with { Revision = 2 }).State);
    }
    [Fact]
    public void StoreRejectsPartialStaleReusedRevisionsAndRecoversAcrossRestart()
    {
        var directory = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        var path = Path.Combine(directory, "configuration.json");
        try
        {
            var store = new ConfigurationStore(path);
            Assert.False(store.Reload());
            var good = Default() with { Revision = 10 };
            var json = JsonSerializer.Serialize(good, TrayConfiguration.JsonOptions);
            Assert.True(store.Accept(json));
            Assert.False(store.Accept(json)); Assert.Null(store.Error);
            Assert.False(store.Accept("{\"schemaVersion\":1}"));
            Assert.False(store.Accept(JsonSerializer.Serialize(good with { Revision = 9 }, TrayConfiguration.JsonOptions)));
            Assert.False(store.Accept(JsonSerializer.Serialize(good with { Location = good.Location! with { Latitude = 0 } }, TrayConfiguration.JsonOptions)));
            Assert.Equal(10, store.Current?.Revision);
            File.WriteAllText(path, "{");
            var restarted = new ConfigurationStore(path); restarted.Reload();
            Assert.Equal(10, restarted.Current?.Revision); Assert.NotNull(restarted.Error);
        }
        finally { Directory.Delete(directory, true); }
    }
    [Theory]
    [InlineData("ar", true)] [InlineData("ur", true)] [InlineData("bn", false)]
    [InlineData("de", false)] [InlineData("en", false)] [InlineData("es", false)]
    [InlineData("fr", false)] [InlineData("ms", false)] [InlineData("ru", false)] [InlineData("tr", false)]
    public void LocalesAndTokensHaveValidatedBoundaries(string locale, bool rtl)
    {
        var config = Default();
        (config with { Presentation = config.Presentation with { Locale = locale, Rtl = rtl } }).Validate();
        Assert.Throws<InvalidDataException>(() => (config with { Presentation = config.Presentation with { TextScale = double.NaN } }).Validate());
        Assert.Throws<InvalidDataException>(() => (config with { SchemaVersion = 2 }).Validate());
        Assert.Throws<InvalidDataException>(() => (config with { Location = config.Location! with { TimeZoneId = "unknown" } }).Validate());
    }
}
