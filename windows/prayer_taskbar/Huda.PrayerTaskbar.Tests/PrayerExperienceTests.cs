using System.Text.Json;
using Huda.PrayerTaskbar.Core;
using NodaTime;
using Xunit;

namespace Huda.PrayerTaskbar.Tests;

public sealed class PrayerExperienceTests
{
    [Theory]
    [InlineData(false, false, true)]
    [InlineData(true, false, false)]
    [InlineData(true, true, false)]
    public void FocusLockAppliesToRealSessionsAndPreviews(bool locked, bool preview, bool dismissible)
    {
        Assert.Equal(dismissible, new PrayerFocusPolicy(locked, preview).CanDismiss);
    }

    [Fact]
    public void MobileDefaultAndLegacyLengthMigrationUseASingleRecordingWithACutoff()
    {
        Assert.Equal("huda-default", new PrayerExperience().ReciterId);
        Assert.Null(new PrayerExperience().PlaybackCutoffSeconds);
        Assert.Equal(30, new PrayerExperience { Length = "short" }.PlaybackCutoffSeconds);
        Assert.Equal(12, new PrayerExperience { Length = "short", StopAfterSeconds = 12 }.PlaybackCutoffSeconds);
        Assert.Equal("huda-default", new PrayerExperience { ReciterId = "mishary-rashid-alafasy", Length = "short" }.PlaybackReciterId);
        Assert.Equal("mishary-rashid-alafasy", new PrayerExperience { ReciterId = "mishary-rashid-alafasy" }.PlaybackReciterId);
    }

    [Fact]
    public void NotificationPreviewUsesTheScheduledSilentContentWithoutAnOccurrencePayload()
    {
        var config = ContractsTests.Sample();
        var prayer = new PrayerEvent("dhuhr", new LocalDate(2026, 10, 8), Due);
        var document = System.Xml.Linq.XDocument.Parse(PrayerToastContent.Xml(config, prayer));
        Assert.Equal("true", document.Root!.Element("audio")!.Attribute("silent")!.Value);
        Assert.Equal("", document.Root.Attribute("launch")!.Value);
        var body = document.Descendants("text").Last().Value;
        Assert.DoesNotContain("\n", body);
        Assert.DoesNotContain("Next:", body);
    }
    private static readonly Instant Due = Instant.FromUtc(2026, 10, 8, 8, 0);
    private static TaskbarConfiguration Config => ContractsTests.Sample() with {
        PrayerExperience = new PrayerExperience { Configured = true, Mode = "adhan" },
        Location = ContractsTests.Sample().Location! with { Verified = true },
    };
    private static ScheduleSnapshot Schedule(params Instant[] times) => new(new LocalDate(2026, 10, 8),
        new DailySchedule(new LocalDate(2026, 10, 8), new Dictionary<string, Instant?>()),
        times.Select(time => new PrayerEvent("dhuhr", new LocalDate(2026, 10, 8), time)).ToArray(), null);

    [Fact]
    public void ColdLaunchAndRepeatedPollingDoNotReplayPrayers()
    {
        var due = new PrayerDueEvents();
        due.Apply(Due + Duration.FromSeconds(5), null);
        Assert.Empty(due.Poll(Config, Schedule(Due), Due + Duration.FromSeconds(6)));
        due.Apply(Due - Duration.FromSeconds(1), null);
        Assert.Single(due.Poll(Config, Schedule(Due), Due));
        Assert.Empty(due.Poll(Config, Schedule(Due), Due + Duration.FromSeconds(1)));
    }

    [Fact]
    public void SleepClockJumpAndCutoverPreserveFutureEventsWithoutStaleBlockers()
    {
        var due = new PrayerDueEvents();
        due.Apply(Due - Duration.FromSeconds(1), null);
        Assert.Empty(due.Poll(Config, Schedule(Due), Due + Duration.FromSeconds(61)));
        Assert.Single(due.Poll(Config, Schedule(Due + Duration.FromMinutes(3)), Due + Duration.FromMinutes(3)));
        due.Apply(Due - Duration.FromSeconds(1), (Due + Duration.FromSeconds(31)).ToDateTimeOffset());
        Assert.Empty(due.Poll(Config, Schedule(Due), Due + Duration.FromSeconds(1)));
        Assert.Single(due.Poll(Config, Schedule(Due + Duration.FromMinutes(1)), Due + Duration.FromMinutes(1)));
    }

    [Fact]
    public void DisabledSilentAndUnverifiedLocationsNeverStartNativePlayback()
    {
        foreach (var config in new[] {
            Config with { PrayerExperience = Config.PrayerExperience! with { Enabled = false } },
            Config with { PrayerExperience = Config.PrayerExperience! with { Mode = "silent" } },
            Config with { Location = Config.Location! with { Verified = false } },
            Config with { PrayerExperience = null },
        }) {
            var due = new PrayerDueEvents(); due.Apply(Due - Duration.FromSeconds(1), null);
            Assert.Empty(due.Poll(config, Schedule(Due), Due));
        }
    }

    [Fact]
    public void OccurrenceIdsUseTheEffectivePrayerDateAcrossOffsetAndTimezoneBoundaries()
    {
        var prayer = new PrayerEvent("isha", new LocalDate(2026, 10, 8), Instant.FromUtc(2026, 10, 8, 22, 0));
        Assert.Equal(302610095, PrayerOccurrence.Id(prayer, "Asia/Muscat"));
        Assert.Equal(302610085, PrayerOccurrence.Id(prayer, "America/New_York"));
    }

    [Fact]
    public void PersistedHistorySuppressesReplayAfterRestartAndRefusesCorruptHistory()
    {
        var directory = Path.Combine(Path.GetTempPath(), "HudaPrayerLedger-" + Guid.NewGuid());
        var path = Path.Combine(directory, "history.json");
        try {
            Assert.True(new PrayerOccurrenceLedger(path).Claim(326100082, Due));
            Assert.False(new PrayerOccurrenceLedger(path).Claim(326100082, Due + Duration.FromHours(1)));
            File.WriteAllText(path, "{");
            Assert.Throws<InvalidDataException>(() => new PrayerOccurrenceLedger(path).Claim(326100083, Due));
        } finally { if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true); }
    }

    [Theory]
    [InlineData("../audio")]
    [InlineData("C:\\audio")]
    [InlineData("reciter/other")]
    [InlineData("")]
    public void InvalidAudioIdentitiesCannotEnterTheNativeConfiguration(string id)
    {
        var config = Config with { PrayerExperience = Config.PrayerExperience! with { ReciterId = id } };
        Assert.Throws<InvalidDataException>(() => config.Validate());
    }

    [Fact]
    public void NativePreferencesRejectUnknownModesAndInvalidDurations()
    {
        Assert.Throws<InvalidDataException>(() => new PrayerExperience { Mode = "custom" }.Validate());
        Assert.Throws<InvalidDataException>(() => new PrayerExperience { Volume = double.NaN }.Validate());
        Assert.Throws<InvalidDataException>(() => new PrayerExperience { FocusDurationSeconds = 0 }.Validate());
        var roundTrip = TaskbarConfiguration.Parse(JsonSerializer.Serialize(Config, TaskbarConfiguration.JsonOptions));
        Assert.Equal(Config.PrayerExperience, roundTrip.PrayerExperience);
        Assert.Null(ContractsTests.Sample().PrayerExperience);
    }

    [Fact]
    public void EachPrayerCanDifferAndOffPrayersChangeTheToastSignature()
    {
        var experience = new PrayerExperience {
            Configured = true, Mode = "silent", AdvanceMinutes = 5,
            Overrides = new() {
                ["dhuhr"] = new() { Mode = "adhan", ReciterId = "mishary", AudioVersion = "v2" },
                ["isha"] = new() { Mode = "off" },
                ["fajr"] = new() { Mode = "off" },
            } };
        experience.Validate();
        Assert.Equal(("adhan", "mishary", "v2"), (experience.For("dhuhr").Mode, experience.For("dhuhr").ReciterId,
            experience.For("dhuhr").AudioVersion));
        Assert.False(experience.For("isha").Enabled);
        Assert.Equal(5, experience.For("asr").AdvanceMinutes);
        // Must match WindowsPrayerExperience.deliverySignature in Huda.
        Assert.Equal("windows-reminders-v2:1:silent:off=fajr,isha", experience.DeliverySignature);
        Assert.Equal("windows-reminders-v2:1:silent", (experience with { Overrides = null }).DeliverySignature);
        Assert.Throws<InvalidDataException>(() => (experience with { AdvanceMinutes = 3 }).Validate());
        Assert.Throws<InvalidDataException>(() => (experience with { Overrides = new() {
            ["sunrise"] = new() { Mode = "off" } } }).Validate());
    }

    [Fact]
    public void APrayerWithItsOwnAdhanPlaysEvenWhenTheDefaultIsSilent()
    {
        var config = Config with { PrayerExperience = Config.PrayerExperience! with { Mode = "silent",
            Overrides = new() { ["dhuhr"] = new() { Mode = "adhan" } } } };
        var due = new PrayerDueEvents(); due.Apply(Due - Duration.FromSeconds(1), null);
        Assert.Single(due.Poll(config, Schedule(Due), Due));
        var off = Config with { PrayerExperience = Config.PrayerExperience! with {
            Overrides = new() { ["dhuhr"] = new() { Mode = "off" } } } };
        due = new PrayerDueEvents(); due.Apply(Due - Duration.FromSeconds(1), null);
        Assert.Empty(due.Poll(off, Schedule(Due), Due));
    }

    [Fact]
    public void RemindersBeforeAPrayerArriveOnceAtTheirMinute()
    {
        var config = Config with { PrayerExperience = Config.PrayerExperience! with { AdvanceMinutes = 10 } };
        var at = Due - Duration.FromMinutes(10);
        var due = new PrayerDueEvents(); due.Apply(at - Duration.FromSeconds(1), null);
        var reminders = due.PollAdvance(config, Schedule(Due), at);
        Assert.Single(reminders); Assert.Equal(10, reminders[0].Minutes);
        Assert.Empty(due.PollAdvance(config, Schedule(Due), at + Duration.FromSeconds(1)));
        var xml = PrayerToastContent.AdvanceXml(ContractsTests.Sample(), reminders[0].Prayer, 10);
        Assert.Contains("10", System.Xml.Linq.XDocument.Parse(xml).Descendants("text").Last().Value);
    }
}
