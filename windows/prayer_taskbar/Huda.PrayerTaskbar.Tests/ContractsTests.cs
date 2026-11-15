using System.Text.Json;
using System.Text.Json.Nodes;
using Huda.PrayerTaskbar.Core;
using NodaTime;
using NodaTime.Text;
using Xunit;

namespace Huda.PrayerTaskbar.Tests;

public sealed class ContractsTests
{
    private static JsonDocument Fixtures() => JsonDocument.Parse(File.ReadAllText(
        Path.Combine(AppContext.BaseDirectory, "Fixtures", "huda-parity.json")));

    public static IEnumerable<object[]> ParityCases()
    {
        using var document = Fixtures();
        foreach (var fixture in document.RootElement.GetProperty("fixtures").EnumerateArray())
            yield return [fixture.GetProperty("name").GetString()!, fixture.GetRawText()];
    }

    [Theory]
    [MemberData(nameof(ParityCases))]
    public void FinalUtcEventsAgreeWithHuda(string name, string json)
    {
        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;
        var config = TaskbarConfiguration.Parse(root.GetProperty("configuration").GetRawText());
        var date = LocalDatePattern.Iso.Parse(root.GetProperty("date").GetString()!).Value;
        var schedule = new ScheduleCalculator(new RamadanCalendar()).Calculate(config, date);
        foreach (var expected in root.GetProperty("expectedUtc").EnumerateObject())
        {
            long? instant = schedule.Times[expected.Name]?.ToUnixTimeMilliseconds();
            Assert.True(expected.Value.ValueKind == JsonValueKind.Null ? instant is null
                : instant == expected.Value.GetInt64(), $"{name}: {expected.Name}: {instant} != {expected.Value}");
        }
    }

    [Fact]
    public void GapsAndOverlapsMatchDartTimezoneRatherThanAnAssumedResolver()
    {
        using var document = Fixtures();
        foreach (var fixture in document.RootElement.GetProperty("wallTimeCases").EnumerateArray())
        {
            var zone = DateTimeZoneProviders.Tzdb[fixture.GetProperty("zone").GetString()!];
            var wall = LocalDateTimePattern.ExtendedIso.Parse(fixture.GetProperty("wall").GetString()!).Value;
            Assert.Equal(fixture.GetProperty("expectedUtc").GetInt64(),
                LocationClock.Resolve(wall, zone).ToUnixTimeMilliseconds());
        }
    }

    public static TaskbarConfiguration Sample()
    {
        using var document = Fixtures();
        return TaskbarConfiguration.Parse(document.RootElement.GetProperty("fixtures")[0]
            .GetProperty("configuration").GetRawText());
    }

    [Fact]
    public void AppFontsRoundTripAndOlderConfigurationsUseTheSystemFont()
    {
        var config = Sample();
        foreach (var font in new[] { "Amiri", "system" })
        {
            var changed = config with { Presentation = config.Presentation with { FontFamily = font } };
            var parsed = TaskbarConfiguration.Parse(JsonSerializer.Serialize(changed, TaskbarConfiguration.JsonOptions));
            Assert.Equal(font, parsed.Presentation.FontFamily);
        }
        var legacy = JsonNode.Parse(JsonSerializer.Serialize(config, TaskbarConfiguration.JsonOptions))!;
        legacy["presentation"]!.AsObject().Remove("fontFamily");
        Assert.Equal("system", TaskbarConfiguration.Parse(legacy.ToJsonString()).Presentation.FontFamily);
    }

    [Theory]
    [InlineData("unknown")]
    [InlineData("")]
    [InlineData(null)]
    public void UnsupportedFontsRetainTheLastGoodConfiguration(string? font)
    {
        var store = new ConfigurationStore("unused");
        var config = Sample() with { Revision = 3 };
        Assert.True(store.Accept(JsonSerializer.Serialize(config, TaskbarConfiguration.JsonOptions)));
        var unsupported = config with { Revision = 4,
            Presentation = config.Presentation with { FontFamily = font! } };
        Assert.False(store.Accept(JsonSerializer.Serialize(unsupported, TaskbarConfiguration.JsonOptions)));
        Assert.Equal(3, store.Current!.Revision);
        Assert.Equal(config.Presentation.FontFamily, store.Current.Presentation.FontFamily);
    }

    [Fact]
    public void LegacyConfigurationsDefaultToATransparentReadableCaption()
    {
        var legacy = JsonNode.Parse(JsonSerializer.Serialize(Sample(), TaskbarConfiguration.JsonOptions))!;
        foreach (var key in new[] { "transparentBackground", "textColor", "textSize", "showIcon" })
            legacy["preferences"]!.AsObject().Remove(key);
        var preferences = TaskbarConfiguration.Parse(legacy.ToJsonString()).Preferences;
        Assert.True(preferences.TransparentBackground);
        Assert.True(preferences.ShowIcon);
        Assert.Equal("automatic", preferences.TextColor);
        Assert.Equal("medium", preferences.TextSize);
    }

    [Fact]
    public void AppearanceRoundTripsThroughTheFlutterExchange()
    {
        var config = Sample();
        foreach (var color in new[] { "automatic", "light", "dark", "appColor" })
        foreach (var size in new[] { "small", "medium", "large" })
        {
            var changed = config with { Preferences = config.Preferences with {
                TransparentBackground = false, ShowIcon = false, TextColor = color, TextSize = size } };
            var parsed = TaskbarConfiguration.Parse(JsonSerializer.Serialize(changed, TaskbarConfiguration.JsonOptions));
            Assert.Equal(changed.Preferences, parsed.Preferences);
        }
    }

    [Theory]
    [InlineData("textColor", "unsupported")]
    [InlineData("textColor", null)]
    [InlineData("textSize", "huge")]
    [InlineData("textSize", null)]
    public void InvalidAppearanceRetainsTheLastGoodConfiguration(string field, string? value)
    {
        var store = new ConfigurationStore("unused");
        var config = Sample() with { Revision = 3 };
        Assert.True(store.Accept(JsonSerializer.Serialize(config, TaskbarConfiguration.JsonOptions)));
        var invalid = JsonNode.Parse(JsonSerializer.Serialize(config with { Revision = 4 }, TaskbarConfiguration.JsonOptions))!;
        invalid["preferences"]![field] = value;
        Assert.False(store.Accept(invalid.ToJsonString()));
        Assert.Equal(3, store.Current!.Revision);
        Assert.Equal(config.Preferences, store.Current.Preferences);
    }

    [Fact]
    public void IqamahIsAnOptionalDisplayPreferenceWithSafeDefaultsAndClampedValues()
    {
        var legacy = JsonNode.Parse(JsonSerializer.Serialize(Sample(), TaskbarConfiguration.JsonOptions))!;
        legacy["preferences"]!.AsObject().Remove("iqamahMinutes");
        Assert.Equal(PrayerIqamahWindows.Defaults, TaskbarConfiguration.Parse(legacy.ToJsonString()).Preferences.IqamahMinutes);
        foreach (var invalid in new[] { "null", "false", "[]", "\"invalid\"" })
        {
            legacy["preferences"]!["iqamahMinutes"] = JsonNode.Parse(invalid);
            Assert.Equal(PrayerIqamahWindows.Defaults, TaskbarConfiguration.Parse(legacy.ToJsonString()).Preferences.IqamahMinutes);
        }
        legacy["preferences"]!["iqamahMinutes"] = JsonNode.Parse("""
            {"fajr":99,"dhuhr":-1,"asr":"bad","maghrib":0,"isha":true,"sunrise":10}
            """);
        var minutes = TaskbarConfiguration.Parse(legacy.ToJsonString()).Preferences.IqamahMinutes;
        Assert.Equal(60, minutes["fajr"]); Assert.Equal(0, minutes["dhuhr"]);
        Assert.Equal(20, minutes["asr"]); Assert.Equal(0, minutes["maghrib"]); Assert.Equal(20, minutes["isha"]);
        Assert.False(minutes.ContainsKey("sunrise"));
    }

    [Fact]
    public void InvalidPartialUnsupportedAndStaleRevisionsRetainTheLastGoodConfiguration()
    {
        var store = new ConfigurationStore("unused");
        var config = Sample() with { Revision = 3 };
        var json = JsonSerializer.Serialize(config, TaskbarConfiguration.JsonOptions);
        Assert.True(store.Accept(json));
        Assert.False(store.Accept("{\"schemaVersion\":1,"));
        Assert.False(store.Accept(JsonSerializer.Serialize(config with { SchemaVersion = 2 }, TaskbarConfiguration.JsonOptions)));
        Assert.False(store.Accept(JsonSerializer.Serialize(config with { Revision = 2 }, TaskbarConfiguration.JsonOptions)));
        Assert.False(store.Accept(JsonSerializer.Serialize(config with { Preferences = config.Preferences with { Enabled = false } }, TaskbarConfiguration.JsonOptions)));
        Assert.Equal(config.Revision, store.Current!.Revision);
        Assert.True(store.Current.Preferences.Enabled);
        Assert.False(store.Accept(json)); // Idempotent retries are accepted without recalculation.
        Assert.Null(store.Error);
    }

    [Fact]
    public void SetupConfigurationHasNoFabricatedPrayerSchedule()
    {
        var config = Sample() with { Location = null, Calculation = null };
        config.Validate();
        Assert.Equal(config.Presentation.Label("needsSetup"),
            CountdownFormatter.Text(config, null, Instant.FromUtc(2026, 10, 2, 12, 0)));
        Assert.Throws<InvalidDataException>(() => (config with { Calculation = Sample().Calculation }).Validate());
    }

    [Fact]
    public void NextPrayerSkipsSunriseMovesBeyondIshaAndUsesStrictUtcOrdering()
    {
        var calculator = new ScheduleCalculator(new RamadanCalendar());
        var config = Sample();
        var day = calculator.Calculate(config, new LocalDate(2026, 10, 2));
        var afterFajr = day.Times["fajr"]!.Value + Duration.FromSeconds(1);
        Assert.Equal("dhuhr", calculator.Snapshot(config, afterFajr).Next(afterFajr)!.Key);
        var atIsha = day.Times["isha"]!.Value;
        var next = calculator.Snapshot(config, atIsha).Next(atIsha)!;
        Assert.Equal("fajr", next.Key);
        Assert.Equal(new LocalDate(2026, 10, 3), next.CivilDate);
        var shifted = config with { Calculation = config.Calculation! with {
            ManualOffsets = new Dictionary<string, int>(config.Calculation.ManualOffsets) { ["maghrib"] = -10080 }
        }};
        Assert.True(calculator.Snapshot(shifted, afterFajr).Events.Zip(
            calculator.Snapshot(shifted, afterFajr).Events.Skip(1)).All(pair => pair.First.Time <= pair.Second.Time));
    }

    [Fact]
    public void CountdownReadsTheClockEveryTimeAndFormatsLocalizedDigits()
    {
        var target = Instant.FromUtc(2026, 10, 2, 12, 0);
        Assert.Equal("00:42:18", CountdownFormatter.Countdown(target, target - Duration.FromSeconds(2538), true));
        Assert.Equal("00:00:00", CountdownFormatter.Countdown(target, target + Duration.FromSeconds(8), true));
        Assert.Equal("01:02", CountdownFormatter.Countdown(target, target - Duration.FromSeconds(3725), false));
        Assert.Equal("٠١:٤٢", CountdownFormatter.Digits("01:42", "arabic"));
        Assert.Equal("۰۱:۴۲", CountdownFormatter.Digits("01:42", "easternArabic"));
        Assert.Equal("16:00", CountdownFormatter.Clock(target, "Asia/Muscat", Sample().Presentation));
    }

    [Fact]
    public void CalendarCoverageFailureIsVisibleOnlyForMethodsThatNeedRamadan()
    {
        var calculator = new ScheduleCalculator(new RamadanCalendar());
        var config = Sample();
        var outside = new LocalDate(2090, 1, 1);
        var makkah = config with { Calculation = config.Calculation! with { MethodKey = "makkah" } };
        Assert.Throws<CalendarCoverageException>(() => calculator.Calculate(makkah, outside));
        Assert.Equal("calendarUnavailable", calculator.Snapshot(makkah,
            Instant.FromUtc(2090, 1, 1, 12, 0)).Error);
        Assert.Null(calculator.Snapshot(config, Instant.FromUtc(2090, 1, 1, 12, 0)).Error);
    }

    [Fact]
    public void SignInIsOptInAndTheTrayStaysAvailableWhenTheCountdownIsHidden()
    {
        var p = Sample().Preferences with { Enabled = true, StartWithWindows = false,
            ShowTrayIcon = false, ShowTaskbarCountdown = true };
        Assert.False(LifecyclePolicy.ShouldStart(p, true));
        Assert.True(LifecyclePolicy.ShouldStart(p, false));
        Assert.True(LifecyclePolicy.ShowTaskbar(p));
        Assert.True(LifecyclePolicy.ShowTray(p)); // Legacy tray-off preferences are ignored.
        Assert.False(LifecyclePolicy.ShouldStart(p with { Enabled = false, StartWithWindows = true }, true));
        Assert.True(LifecyclePolicy.ShouldStart(p with { StartWithWindows = true }, true));
        Assert.True(LifecyclePolicy.ShouldStart(p with { ShowTaskbarCountdown = false }, false));
        Assert.True(LifecyclePolicy.ShowTray(p with { ShowTaskbarCountdown = false }));
        Assert.False(LifecyclePolicy.ShowTaskbar(p with { ShowTaskbarCountdown = false }));
        Assert.False(LifecyclePolicy.ShowTray(p with { Enabled = false }));
        Assert.False(LifecyclePolicy.ShouldStart(null, true));
    }

    [Fact]
    public void TaskbarPlacementFindsMeasuredGapsWithoutOverlappingShellControls()
    {
        var centered = new[] { new HorizontalSpan(0, 30), new HorizontalSpan(480, 720),
            new HorizontalSpan(840, 1000) };
        Assert.Equal(352, TaskbarSpace.FindGap(0, 1000, centered, 120, 8));
        var leftAligned = new[] { new HorizontalSpan(0, 400), new HorizontalSpan(840, 1000) };
        Assert.Equal(712, TaskbarSpace.FindGap(0, 1000, leftAligned, 120, 8));
        Assert.Null(TaskbarSpace.FindGap(0, 1000, [new HorizontalSpan(0, 1000)], 120, 8));
        // Overlapping and off-monitor UIA spans are merged and clipped.
        Assert.Equal(632, TaskbarSpace.FindGap(0, 1000,
            [new HorizontalSpan(-100, 500), new HorizontalSpan(400, 600), new HorizontalSpan(760, 1100)], 120, 8));
    }

    [Fact]
    public void CorruptPrimaryRecoversBackupAndStillReportsTheRejectedUpdate()
    {
        var directory = Path.Combine(Path.GetTempPath(), "HudaTaskbarTest-" + Guid.NewGuid());
        Directory.CreateDirectory(directory);
        try
        {
            var path = Path.Combine(directory, "configuration.json");
            File.WriteAllText(path, "{broken");
            File.WriteAllText(Path.ChangeExtension(path, "backup.json"),
                JsonSerializer.Serialize(Sample() with { Revision = 7 }, TaskbarConfiguration.JsonOptions));
            var store = new ConfigurationStore(path);
            Assert.False(store.Reload()); Assert.Equal(7, store.Current!.Revision); Assert.NotNull(store.Error);
            File.WriteAllText(path,
                JsonSerializer.Serialize(Sample() with { Revision = 8 }, TaskbarConfiguration.JsonOptions));
            Assert.True(store.Reload()); Assert.Equal(8, store.Current.Revision); Assert.Null(store.Error);
        }
        finally { Directory.Delete(directory, recursive: true); }
    }

    [Fact]
    public void UnverifiedLocationMarksTheCaptionAndDoesNotAlterCalculatedInstants()
    {
        var now = Instant.FromUtc(2026, 10, 2, 8, 0);
        var verified = Sample();
        var provisional = verified with { Location = verified.Location! with { Verified = false } };
        var calculator = new ScheduleCalculator(new RamadanCalendar());
        var snapshot = calculator.Snapshot(provisional, now);
        Assert.Equal(calculator.Snapshot(verified, now).Next(now), snapshot.Next(now));
        Assert.StartsWith("⚠ ", CountdownFormatter.Text(provisional, snapshot, now));
    }
}
