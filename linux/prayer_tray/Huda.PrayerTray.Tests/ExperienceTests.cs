using System.Diagnostics;
using System.Text.Json;
using Huda.PrayerTaskbar.Core;
using Huda.PrayerTray.Core;
using NodaTime;
using Xunit;

namespace Huda.PrayerTray.Tests;

public sealed class ExperienceTests
{
    private static TrayConfiguration Config(string mode = "silent")
    {
        var baseline = TrayTests.Default();
        return baseline with { Preferences = baseline.Preferences with { Enabled = false },
            Experience = new() { Configured = true, Mode = mode },
            NotificationContract = new() { LocationRevision = baseline.Location!.Revision,
                ScheduleRevision = 100, ConfigurationSignature = "linux-test" } };
    }
    [Fact]
    public void DefaultsPreserveLegacyAndExplicitBackgroundChoice()
    {
        var old = TrayTests.Default(); old.Validate(); Assert.Null(old.Experience);
        var fresh = new LinuxPrayerExperience();
        Assert.False(fresh.Configured); Assert.True(fresh.BackgroundEnabled);
        Assert.Equal("silent", fresh.Mode); Assert.Equal(.7, fresh.Volume);
        var saved = JsonSerializer.Deserialize<LinuxPrayerExperience>(
            "{\"version\":1,\"backgroundEnabled\":false}", TrayConfiguration.JsonOptions)!;
        Assert.False(saved.BackgroundEnabled);
        Assert.True(JsonSerializer.Deserialize<LinuxPrayerExperience>("{\"version\":1}", TrayConfiguration.JsonOptions)!.BackgroundEnabled);
    }
    [Theory]
    [InlineData("silent")] [InlineData("adhan")] [InlineData("focus")]
    public void AllModesFireAtBoundaryWithHiddenPanel(string mode)
    {
        var config = Config(mode); config.Validate();
        var engine = new LinuxPrayerDueEvents();
        var initial = Instant.FromUtc(2026, 10, 2, 0, 0);
        engine.Poll(config, initial, true);
        var prayer = engine.Schedule!.Next(initial)!;
        engine.Reset(prayer.Time - Duration.FromSeconds(1));
        var events = engine.Poll(config, prayer.Time, true);
        Assert.Single(events); Assert.Equal(prayer, events[0]); Assert.NotEqual("sunrise", events[0].Key);
        Assert.Empty(engine.Poll(config, prayer.Time, true));
        Assert.Empty(engine.Poll(config, prayer.Time + Duration.FromSeconds(1), true));
    }
    [Fact]
    public void AMissedPrayerIsCaughtUpOnlyWhileItsTimeIsCurrent()
    {
        var config = Config();
        var start = Instant.FromUtc(2026, 10, 2, 0, 0);
        var engine = new LinuxPrayerDueEvents(); engine.Poll(config, start, true);
        var fajr = engine.Schedule!.Events.First(item => item.Key == "fajr" && item.Time > start);
        var sunrise = engine.Schedule.Daily.Times["sunrise"]!.Value;
        if (engine.Schedule.Daily.Date != fajr.CivilDate)
            sunrise = new ScheduleCalculator(new RamadanCalendar()).Calculate(config.ToCalculationConfiguration(), fajr.CivilDate).Times["sunrise"]!.Value;
        engine.Reset(fajr.Time - Duration.FromMinutes(10));
        Assert.Equal(fajr, engine.Missed(config, fajr.Time + Duration.FromMinutes(5)));
        // Fajr's time ends at sunrise, and sunrise itself is never shown.
        Assert.Null(engine.Missed(config, sunrise + Duration.FromMinutes(1)));
        // Nothing before the gap, and no catch-up on a cold start.
        Assert.Null(new LinuxPrayerDueEvents().Missed(config, fajr.Time + Duration.FromMinutes(5)));
        engine.Reset(fajr.Time + Duration.FromMinutes(1));
        Assert.Null(engine.Missed(config, fajr.Time + Duration.FromMinutes(5)));
    }
    [Fact]
    public void ColdStartResumeDisableAndForwardJumpSkipBacklog()
    {
        var config = Config();
        var clock = Instant.FromUtc(2026, 10, 2, 0, 0);
        var engine = new LinuxPrayerDueEvents(); engine.Poll(config, clock, true);
        var time = engine.Schedule!.Next(clock)!.Time;
        var cold = new LinuxPrayerDueEvents();
        Assert.Empty(cold.Poll(config, time + Duration.FromSeconds(1), true));
        engine.Reset(time - Duration.FromSeconds(1));
        Assert.Empty(engine.Poll(config, time, false));
        Assert.Empty(engine.Poll(config, time + Duration.FromSeconds(1), true));
        engine.Reset(time - Duration.FromSeconds(61));
        Assert.Empty(engine.Poll(config, time, true));
        engine.Reset(time + Duration.FromSeconds(10));
        Assert.Empty(engine.Poll(config, time + Duration.FromSeconds(11), true));
    }
    [Fact]
    public void WarmJitterCutoverAndEqualTimePrayersAreBounded()
    {
        var config = Config();
        var now = Instant.FromUtc(2026, 10, 2, 0, 0);
        var engine = new LinuxPrayerDueEvents(); engine.Poll(config, now, true);
        var prayer = engine.Schedule!.Next(now)!;
        engine.Reset(prayer.Time - Duration.FromSeconds(1));
        Assert.Single(engine.Poll(config, prayer.Time + Duration.FromSeconds(58), true));
        var cutover = prayer.Time + Duration.FromSeconds(1);
        var next = config with { Revision = config.Revision + 1, CutoverInstantUtc = cutover.ToDateTimeOffset() };
        engine.Reset(prayer.Time - Duration.FromSeconds(1));
        Assert.Empty(engine.Poll(next, prayer.Time + Duration.FromSeconds(2), true));
        var times = engine.Schedule!.Daily.Times;
        var delta = (int)((times["dhuhr"]!.Value - times["asr"]!.Value).TotalMinutes);
        var offsets = new Dictionary<string, int>(config.Calculation!.ManualOffsets) { ["asr"] = delta };
        var equal = config with { Revision = next.Revision + 1, Calculation = config.Calculation with { ManualOffsets = offsets } };
        engine.Poll(equal, now, true);
        var dhuhr = engine.Schedule!.Daily.Times["dhuhr"]!.Value;
        engine.Reset(dhuhr - Duration.FromSeconds(1));
        Assert.Equal(new[] { "dhuhr", "asr" }, engine.Poll(equal, dhuhr, true).Select(p => p.Key));
    }
    [Fact]
    public void DurableClaimsImportHistoryAndMarkInterruptedEffects()
    {
        var directory = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        var path = Path.Combine(directory, "ledger.json");
        try
        {
            var now = Instant.FromUtc(2026, 10, 12, 0, 0);
            var ledger = new LinuxOccurrenceLedger(path);
            ledger.Import(302610121, now);
            Assert.False(ledger.Claim(302610121, now));
            Assert.True(ledger.Claim(302610122, now));
            ledger.Record(302610122, audio: "playing", focus: "presented");
            var restarted = new LinuxOccurrenceLedger(path);
            Assert.False(restarted.Claim(302610122, now - Duration.FromDays(1)));
            restarted.Record(302610122, notification: "transportAccepted");
            using var json = JsonDocument.Parse(File.ReadAllText(path));
            Assert.Equal("interrupted", json.RootElement.GetProperty("302610122").GetProperty("audio").GetString());
            File.WriteAllText(path, "{");
            Assert.Throws<JsonException>(() => new LinuxOccurrenceLedger(path));
        }
        finally { Directory.Delete(directory, true); }
    }
    [Fact]
    public void LinuxFlockCoordinatesWithTheActualShellProtocol()
    {
        var directory = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        var path = Path.Combine(directory, "dispatch.lock");
        try
        {
            using (var held = new DispatchLock(path))
            {
                var info = new ProcessStartInfo("flock") { UseShellExecute = false };
                foreach (var arg in new[] { "-n", path, "true" }) info.ArgumentList.Add(arg);
                using var process = Process.Start(info)!; process.WaitForExit(); Assert.NotEqual(0, process.ExitCode);
                Assert.Throws<IOException>(() => new DispatchLock(path));
            }
            using var released = new DispatchLock(path);
        }
        finally { Directory.Delete(directory, true); }
    }
    [Fact]
    public void InvalidPoliciesAndMismatchedContractsAreRejected()
    {
        foreach (var invalid in new[] { new LinuxPrayerExperience { Volume = double.NaN },
            new LinuxPrayerExperience { StopAfterSeconds = 0 }, new LinuxPrayerExperience { StopAfterSeconds = 3601 },
            new LinuxPrayerExperience { FocusDurationSeconds = 59 }, new LinuxPrayerExperience { FocusDisplay = "../../tmp" },
            new LinuxPrayerExperience { Mode = "unknown" }, new LinuxPrayerExperience { ReciterId = "../audio" } })
            Assert.Throws<InvalidDataException>(invalid.Validate);
        var config = Config();
        Assert.Throws<InvalidDataException>(() => (config with { NotificationContract = null }).Validate());
        Assert.Throws<InvalidDataException>(() => (config with { NotificationContract = config.NotificationContract! with {
            LocationRevision = config.Location!.Revision + 1 } }).Validate());
    }
    [Fact]
    public void APrayerUsesItsOwnSettingsAndTheRestFollowTheDefaults()
    {
        var experience = new LinuxPrayerExperience {
            Configured = true, Mode = "adhan", AdvanceMinutes = 10,
            Overrides = new() {
                ["fajr"] = new() { Mode = "focus", ReciterId = "mishary", AudioVersion = "v2" },
                ["isha"] = new() { Mode = "off" },
                ["asr"] = new() { AdvanceMinutes = 0 },
            } };
        experience.Validate();
        Assert.Equal("focus", experience.For("fajr").Mode);
        Assert.Equal(("mishary", "v2"), (experience.For("fajr").ReciterId, experience.For("fajr").AudioVersion));
        Assert.False(experience.For("isha").Enabled);
        Assert.Equal(0, experience.For("asr").AdvanceMinutes);
        Assert.Equal(("adhan", "huda-default", 10), (experience.For("dhuhr").Mode, experience.For("dhuhr").ReciterId,
            experience.For("dhuhr").AdvanceMinutes));
        Assert.Null(experience.For("fajr").Overrides);
        // Older settings without the new fields read as before.
        var saved = JsonSerializer.Deserialize<LinuxPrayerExperience>(
            "{\"version\":1,\"configured\":true,\"mode\":\"adhan\"}", TrayConfiguration.JsonOptions)!;
        saved.Validate();
        Assert.Equal(0, saved.AdvanceMinutes); Assert.Null(saved.Overrides);
        Assert.Throws<InvalidDataException>(() => (experience with { AdvanceMinutes = 7 }).Validate());
        Assert.Throws<InvalidDataException>(() => (experience with { Overrides = new() {
            ["sunrise"] = new() { Mode = "off" } } }).Validate());
        Assert.Throws<InvalidDataException>(() => (experience with { Overrides = new() {
            ["fajr"] = new() { Mode = "loud" } } }).Validate());
    }
    [Fact]
    public void APrayerThatIsOffNeverFires()
    {
        var baseline = Config("adhan");
        var engine = new LinuxPrayerDueEvents();
        var initial = Instant.FromUtc(2026, 10, 2, 0, 0);
        engine.Poll(baseline, initial, true);
        var prayer = engine.Schedule!.Next(initial)!;
        var config = baseline with { Experience = baseline.Experience! with {
            Overrides = new() { [prayer.Key] = new() { Mode = "off" } } } };
        engine.Reset(prayer.Time - Duration.FromSeconds(1));
        Assert.Empty(engine.Poll(config, prayer.Time, true));
    }
    [Fact]
    public void RemindersBeforeAPrayerFireOnceAtTheirMinute()
    {
        var config = Config("adhan");
        config = config with { Experience = config.Experience! with { AdvanceMinutes = 10 } };
        var engine = new LinuxPrayerDueEvents();
        var initial = Instant.FromUtc(2026, 10, 2, 0, 0);
        engine.Poll(config, initial, true);
        var prayer = engine.Schedule!.Next(initial)!;
        var at = prayer.Time - Duration.FromMinutes(10);
        engine.Reset(at - Duration.FromSeconds(1));
        engine.Poll(config, at, true);
        var due = engine.PollAdvance(config, at, true);
        Assert.Single(due); Assert.Equal((prayer, 10), due[0]);
        engine.Poll(config, at + Duration.FromSeconds(1), true);
        Assert.Empty(engine.PollAdvance(config, at + Duration.FromSeconds(1), true));
        // Not while delivery is off, and not after a long gap.
        var quiet = new LinuxPrayerDueEvents(); quiet.Poll(config, initial, true);
        quiet.Reset(at - Duration.FromSeconds(1));
        Assert.Empty(quiet.PollAdvance(config, at, false));
        var late = new LinuxPrayerDueEvents(); late.Poll(config, initial, true);
        late.Reset(at - Duration.FromMinutes(5));
        late.Poll(config, at, true);
        Assert.Empty(late.PollAdvance(config, at, true));
    }
}
