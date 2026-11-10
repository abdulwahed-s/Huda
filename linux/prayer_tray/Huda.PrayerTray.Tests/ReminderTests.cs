using Huda.PrayerTaskbar.Core;
using Huda.PrayerTray.Core;
using NodaTime;
using Xunit;

namespace Huda.PrayerTray.Tests;

public sealed class ReminderTests : IDisposable
{
    private static readonly DateTimeZone Zone = DateTimeZoneProviders.Tzdb["Asia/Muscat"];
    private readonly string _directory = Directory.CreateTempSubdirectory("huda-reminders").FullName;

    private static Instant At(int month, int day, int hour, int minute = 0) =>
        Zone.AtStrictly(new LocalDateTime(2026, month, day, hour, minute)).ToInstant();

    // 2026-10-13 is a Tuesday.
    private static readonly Instant Now = At(10, 13, 20);

    private static ReminderRule Daily(long id = 1004, int hour = 7, int minute = 0, Instant? first = null) => new()
    {
        Id = id, Kind = "daily", Style = "dailyReminder", Title = "Quran", Body = "Read", Payload = $"p{id}",
        UtcMillis = (first ?? At(10, 14, hour, minute)).ToUnixTimeMilliseconds(), Hour = hour, Minute = minute,
    };

    private static ReminderRule Athkar(int minutes = 60, Instant? first = null) => new()
    {
        Id = 1101, Kind = "interval", Style = "athkar", Title = "Athkar", Payload = "live",
        UtcMillis = (first ?? Now + Duration.FromMinutes(minutes)).ToUnixTimeMilliseconds(),
        IntervalMinutes = minutes, Texts = ["a", "b", "c"],
    };

    public void Dispose() => Directory.Delete(_directory, true);

    [Fact]
    public void NextDeliveryFollowsLocalTimeAndNeverPrecedesTheFirst()
    {
        Assert.Equal(At(10, 14, 7), ReminderSchedule.Next(Daily(), Now, Zone));
        Assert.Equal(At(10, 15, 7), ReminderSchedule.Next(Daily(), At(10, 14, 7), Zone));
        var weekly = Daily() with { Kind = "weekly", Weekday = 5, UtcMillis = At(10, 16, 9).ToUnixTimeMilliseconds(), Hour = 9 };
        Assert.Equal(At(10, 16, 9), ReminderSchedule.Next(weekly, Now, Zone));
        Assert.Equal(At(10, 23, 9), ReminderSchedule.Next(weekly, At(10, 16, 9), Zone));
        var athkar = Athkar(45);
        Assert.Equal(athkar.First, ReminderSchedule.Next(athkar, Now, Zone));
        Assert.Equal(athkar.First + Duration.FromMinutes(90),
            ReminderSchedule.Next(athkar, athkar.First + Duration.FromMinutes(50), Zone));
        var once = Daily() with { Kind = "once", UtcMillis = At(10, 14, 9).ToUnixTimeMilliseconds() };
        Assert.Equal(At(10, 14, 9), ReminderSchedule.Next(once, Now, Zone));
        Assert.Null(ReminderSchedule.Next(once, At(10, 14, 9), Zone));
    }

    [Fact]
    public void AReminderIsShownOnceAndNeverRepeatedWhenTheClockMovesBack()
    {
        var path = Path.Combine(_directory, "state.json");
        var rules = new[] { Daily() };

        Assert.Empty(new ReminderDispatcher(path).Due(rules, At(10, 14, 6, 59), Zone, new Random(1)));
        var first = new ReminderDispatcher(path).Due(rules, At(10, 14, 7, 0), Zone, new Random(1));
        Assert.Equal(At(10, 14, 7), Assert.Single(first).Occurrence);
        Assert.Empty(new ReminderDispatcher(path).Due(rules, At(10, 14, 7, 1), Zone, new Random(1)));
        // A restarted companion with the clock moved back half an hour.
        Assert.Empty(new ReminderDispatcher(path).Due(rules, At(10, 14, 6, 30), Zone, new Random(1)));
        Assert.Single(new ReminderDispatcher(path).Due(rules, At(10, 15, 7, 0), Zone, new Random(1)));
    }

    [Fact]
    public void MissedRemindersFollowTheWindowsCatchUpPolicy()
    {
        var dispatcher = new ReminderDispatcher(Path.Combine(_directory, "state.json"));
        var athkar = Athkar(10, At(10, 14, 7));

        // Random Athkar are not shown late; the next one follows on time.
        Assert.Empty(dispatcher.Due([athkar], At(10, 14, 7, 35), Zone, new Random(1)));
        var onTime = Assert.Single(dispatcher.Due([athkar], At(10, 14, 7, 40), Zone, new Random(1)));
        Assert.Equal(At(10, 14, 7, 40), onTime.Occurrence);
        Assert.Contains(onTime.Body, athkar.Texts);
        // A daily reminder is shown once up to two hours late; later it is skipped.
        var late = Assert.Single(dispatcher.Due([Daily()], At(10, 14, 8, 59), Zone, new Random(1)));
        Assert.Equal(At(10, 14, 7), late.Occurrence);
        Assert.Empty(new ReminderDispatcher(Path.Combine(_directory, "other.json"))
            .Due([Daily()], At(10, 14, 9, 1), Zone, new Random(1)));
    }

    [Fact]
    public void ARemovedReminderStartsFreshWhenItsIdReturns()
    {
        var path = Path.Combine(_directory, "state.json");
        var dispatcher = new ReminderDispatcher(path);
        Assert.Single(dispatcher.Due([Daily()], At(10, 14, 7), Zone, new Random(1)));

        Assert.Empty(dispatcher.Due([], At(10, 14, 7, 5), Zone, new Random(1)));
        var replaced = Daily(minute: 10, first: At(10, 14, 7, 10));

        Assert.Single(dispatcher.Due([replaced], At(10, 14, 7, 10), Zone, new Random(1)));
    }

    [Fact]
    public void WindowsTopsUpOnlyMissingDatedToasts()
    {
        var rule = Daily();
        var queued = new Dictionary<long, Instant>
        {
            [ReminderSchedule.WindowsOccurrenceId(1004, new LocalDate(2026, 10, 14))] = At(10, 14, 7),
        };

        var additions = ReminderToastPlan.Additions([rule], queued, Now, Zone, new Random(1), 4000);

        Assert.Equal(59, additions.Count);
        Assert.Equal(432610154L, additions[0].Id);
        Assert.Equal(At(10, 15, 7), additions[0].At);
        Assert.All(additions, toast => Assert.Equal(1004L, ReminderSchedule.WindowsReminderOf(toast.Id)));
        Assert.All(additions, toast => Assert.Equal("p1004", toast.Payload));
    }

    [Fact]
    public void WindowsContinuesTheAthkarSeriesWithRandomText()
    {
        var rule = Athkar(60);
        var queued = new Dictionary<long, Instant>
        {
            [1101] = rule.First, [1102] = rule.First + Duration.FromHours(1),
        };

        var additions = ReminderToastPlan.Additions([rule], queued, Now, Zone, new Random(1), 4000);

        Assert.Equal(ReminderToastPlan.AthkarLimit - 2, additions.Count);
        Assert.Equal(1103L, additions[0].Id);
        Assert.Equal(rule.First + Duration.FromHours(2), additions[0].At);
        Assert.All(additions, toast => Assert.Contains(toast.Body, rule.Texts));
        // The same tag Huda's Dart NotificationIds.windowsReminderOccurrence gives.
        Assert.Equal(432610134L, ReminderSchedule.WindowsOccurrenceId(1004, new LocalDate(2026, 10, 13)));
    }

    [Fact]
    public void WindowsAdditionsRespectTheQueueCapacity()
    {
        var additions = ReminderToastPlan.Additions([Daily(), Athkar()], new Dictionary<long, Instant>(),
            Now, Zone, new Random(1), 10);
        Assert.Equal(10, additions.Count);
    }

    [Fact]
    public void InvalidOrDuplicateRulesAreRejected()
    {
        TaskbarConfiguration.ValidateReminders([Daily(), Athkar()]);
        Assert.Throws<InvalidDataException>(() => TaskbarConfiguration.ValidateReminders([Daily(), Daily()]));
        Assert.Throws<InvalidDataException>(() => TaskbarConfiguration.ValidateReminders([Daily() with { Hour = 24 }]));
        Assert.Throws<InvalidDataException>(() => TaskbarConfiguration.ValidateReminders([Athkar() with { Texts = [] }]));
        Assert.Throws<InvalidDataException>(() => TaskbarConfiguration.ValidateReminders([Daily() with { Kind = "hourly" }]));
    }
}
