using System.Text.RegularExpressions;

namespace Huda.PrayerTray.Core;

/// One prayer's own settings; anything left out follows the defaults.
public sealed record LinuxPrayerOverride
{
    /// silent, adhan, focus, or off for no alert.
    public string? Mode { get; init; }
    public string? ReciterId { get; init; }
    public string? AudioVersion { get; init; }
    public int? AdvanceMinutes { get; init; }
}

public sealed record LinuxPrayerExperience
{
    public static readonly string[] Prayers = ["fajr", "dhuhr", "asr", "maghrib", "isha"];
    public static readonly int[] AdvanceOptions = [0, 5, 10, 15, 30];

    public int Version { get; init; } = 1;
    public bool Configured { get; init; }
    public bool Enabled { get; init; } = true;
    public string Mode { get; init; } = "silent";
    public bool BackgroundEnabled { get; init; } = true;
    public string ReciterId { get; init; } = "huda-default";
    public string AudioVersion { get; init; } = "v1";
    public double Volume { get; init; } = .7;
    public int? StopAfterSeconds { get; init; }
    public string FocusStyle { get; init; } = "compact";
    public int FocusDurationSeconds { get; init; } = 600;
    public bool FocusAudio { get; init; }
    public bool FocusCommitment { get; init; }
    public string FocusDisplay { get; init; } = "current";
    public bool Quiet { get; init; }
    public bool AllowLockedAudio { get; init; }
    /// Minutes before each prayer for a quiet reminder; 0 for none.
    public int AdvanceMinutes { get; init; }
    public Dictionary<string, LinuxPrayerOverride>? Overrides { get; init; }
    public bool NeedsAudio => Mode == "adhan" || Mode == "focus" && FocusAudio;

    /// The settings one prayer uses: its own where it has them, otherwise these.
    public LinuxPrayerExperience For(string prayer)
    {
        if (Overrides?.GetValueOrDefault(prayer) is not { } own) return this with { Overrides = null };
        return this with
        {
            Enabled = Enabled && own.Mode != "off",
            Mode = own.Mode is null or "off" ? Mode : own.Mode,
            ReciterId = own.ReciterId ?? ReciterId,
            AudioVersion = own.ReciterId is null ? AudioVersion : own.AudioVersion ?? AudioVersion,
            AdvanceMinutes = own.AdvanceMinutes ?? AdvanceMinutes,
            Overrides = null,
        };
    }

    /// Every prayer's settings, for checking the recordings they need.
    public IEnumerable<LinuxPrayerExperience> Effective => Prayers.Select(For);
    public void Validate()
    {
        if (Version != 1 || Mode is not ("silent" or "adhan" or "focus") ||
            FocusStyle is not ("compact" or "immersive") || ReciterId is null || AudioVersion is null ||
            !Regex.IsMatch(ReciterId, @"\A[a-z0-9]+(?:-[a-z0-9]+)*\z") ||
            !Regex.IsMatch(AudioVersion, @"\Av[1-9][0-9]*\z") ||
            FocusDisplay is null || !Regex.IsMatch(FocusDisplay, @"\A(?:current|all|monitor-[0-9]+)\z") ||
            !double.IsFinite(Volume) || Volume is < 0 or > 1 ||
            FocusDurationSeconds is < 60 or > 3600 || StopAfterSeconds is < 1 or > 3600 ||
            !AdvanceOptions.Contains(AdvanceMinutes) || Overrides is { Count: > 5 } ||
            Overrides?.Any(pair => !Prayers.Contains(pair.Key) || pair.Value is null ||
                pair.Value.Mode is not (null or "silent" or "adhan" or "focus" or "off") ||
                pair.Value.ReciterId is { } id && !Regex.IsMatch(id, @"\A[a-z0-9]+(?:-[a-z0-9]+)*\z") ||
                pair.Value.AudioVersion is { } version && !Regex.IsMatch(version, @"\Av[1-9][0-9]*\z") ||
                pair.Value.AdvanceMinutes is { } minutes && !AdvanceOptions.Contains(minutes)) == true)
            throw new InvalidDataException("Invalid Linux prayer reminder settings.");
    }
}
