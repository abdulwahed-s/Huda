using Huda.PrayerTaskbar.Core;
using NodaTime;
using Xunit;

namespace Huda.PrayerTaskbar.Tests;

public sealed class MissedToastTests
{
    private static readonly Instant Now = Instant.FromUtc(2026, 10, 17, 9, 0); // 13:00 in Muscat
    private static Instant Ago(int minutes) => Now - Duration.FromMinutes(minutes);
    private static Instant? NoEnd(MissedToast _) => null;

    private static string[] Shown(Func<MissedToast, Instant?> prayerEnd, params MissedToast[] missed) =>
        MissedToastPolicy.ToShow(missed, Now, prayerEnd).Select(item => item.Tag).ToArray();

    [Fact]
    public void TheLatestMissedPrayerIsShownWhileItsTimeIsCurrent()
    {
        var fajr = new MissedToast("302710171", Ago(480), "fajr");
        var dhuhr = new MissedToast("302710172", Ago(56), "dhuhr");
        Assert.Equal(["302710172"], Shown(_ => Now + Duration.FromHours(3), fajr, dhuhr));
    }

    [Fact]
    public void AMissedPrayerWhoseTimeEndedIsOnlyRemoved()
    {
        // Fajr missed in the night, woken after sunrise.
        var fajr = new MissedToast("302710171", Ago(300), "fajr");
        Assert.Empty(Shown(_ => Ago(200), fajr));
    }

    [Fact]
    public void AMissedPrayerWithoutAKnownEndIsCurrentForAnHour()
    {
        Assert.Equal(["302710172"], Shown(NoEnd, new MissedToast("302710172", Ago(59), "dhuhr")));
        Assert.Empty(Shown(NoEnd, new MissedToast("302710172", Ago(61), "dhuhr")));
    }

    [Fact]
    public void RemindersAreShownUpToTwoHoursLateOncePerReminder()
    {
        var checklistOld = new MissedToast("1005", Ago(119));                 // 4.x one-time toast
        var checklistDated = new MissedToast("432610175", Ago(30));           // the same reminder, dated
        var quranTooLate = new MissedToast("432610174", Ago(121));
        var calendar = new MissedToast("421294340", Ago(10));
        var test = new MissedToast("1099", Ago(5));
        Assert.Equal(["432610175", "421294340", "1099"],
            Shown(NoEnd, checklistOld, checklistDated, quranTooLate, calendar, test));
    }

    [Fact]
    public void RandomAthkarAreNotCaughtUp()
    {
        Assert.Empty(Shown(NoEnd, new MissedToast("1101", Ago(20)), new MissedToast("1550", Ago(5))));
    }

    [Fact]
    public void ToastsWindowsMayStillShowAreLeftAlone()
    {
        Assert.False(MissedToastPolicy.IsMissed(Now - Duration.FromSeconds(50), Now));
        Assert.True(MissedToastPolicy.IsMissed(Now - Duration.FromSeconds(70), Now));
        Assert.Empty(Shown(NoEnd, new MissedToast("432610175", Now - Duration.FromSeconds(30))));
    }

    [Fact]
    public void ShownToastsAreOrderedByTheirTimeAndForeignTagsIgnored()
    {
        var prayer = new MissedToast("302710172", Ago(40), "dhuhr");
        var reminder = new MissedToast("432610175", Ago(90));
        Assert.Equal(["432610175", "302710172"],
            Shown(NoEnd, prayer, reminder, new MissedToast("not-a-number", Ago(10))));
    }
}
