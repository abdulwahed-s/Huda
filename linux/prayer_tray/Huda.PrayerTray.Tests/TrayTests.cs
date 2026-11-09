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
