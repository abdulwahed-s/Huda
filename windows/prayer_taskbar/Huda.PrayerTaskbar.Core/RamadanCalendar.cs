using System.Text.Json;
using NodaTime;
using NodaTime.Text;

namespace Huda.PrayerTaskbar.Core;

public sealed class RamadanCalendar
{
    public LocalDate FirstDate { get; }
    public LocalDate LastDate { get; }
    private readonly (LocalDate Start, LocalDate End)[] _ranges;

    public RamadanCalendar()
    {
        using var stream = typeof(RamadanCalendar).Assembly.GetManifestResourceStream(
            "Huda.PrayerTaskbar.Core.Resources.ramadan.json")!;
        using var json = JsonDocument.Parse(stream);
        var root = json.RootElement;
        FirstDate = ParseDate(root.GetProperty("coverageStart").GetString()!);
        LastDate = ParseDate(root.GetProperty("coverageEnd").GetString()!);
        _ranges = root.GetProperty("ranges").EnumerateArray().Select(range =>
            (ParseDate(range.GetProperty("start").GetString()!),
             ParseDate(range.GetProperty("end").GetString()!))).ToArray();
    }

    public bool IsRamadan(LocalDate date)
    {
        if (date < FirstDate || date > LastDate) throw new CalendarCoverageException();
        return _ranges.Any(range => date >= range.Start && date <= range.End);
    }

    private static LocalDate ParseDate(string value) => LocalDatePattern.Iso.Parse(value).Value;
}

public sealed class CalendarCoverageException() : Exception("Ramadan calendar coverage unavailable.");
