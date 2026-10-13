using System.Text.RegularExpressions;
using NodaTime;

namespace Huda.PrayerTaskbar.Core;

/// One prayer's own settings; anything left out follows the defaults.
public sealed record PrayerExperienceOverride
{
    /// silent, adhan, focus, or off for no alert (and no toast).
    public string? Mode { get; init; }
    public string? ReciterId { get; init; }
    public string? AudioVersion { get; init; }
    public int? AdvanceMinutes { get; init; }
}

public sealed record PrayerExperience
{
    public const string BundledReciterId = "huda-default";
    public static readonly string[] Prayers = ["fajr", "dhuhr", "asr", "maghrib", "isha"];
    public static readonly int[] AdvanceOptions = [0, 5, 10, 15, 30];
    public int Version { get; init; } = 1;
    public bool Configured { get; init; }
    public bool Enabled { get; init; } = true;
    public string Mode { get; init; } = "silent";
    public string ReciterId { get; init; } = BundledReciterId;
    public string AudioVersion { get; init; } = "v1";
    // Read old exchanges without exposing a second playback-length setting.
    public string? Length { get; init; }
    public double Volume { get; init; } = .7;
    public int? StopAfterSeconds { get; init; }
    public int FocusDurationSeconds { get; init; } = 600;
    public bool FocusAudio { get; init; }
    public bool FocusPreventEarlyExit { get; init; }
    /// Minutes before each prayer for a reminder toast while Huda runs; 0 for none.
    public int AdvanceMinutes { get; init; }
    public Dictionary<string, PrayerExperienceOverride>? Overrides { get; init; }

    /// The settings one prayer uses: its own where it has them, otherwise these.
    public PrayerExperience For(string prayer)
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
    public string PlaybackReciterId => Length is not null && AudioVersion == "v1" &&
        ReciterId == "mishary-rashid-alafasy" ? BundledReciterId : ReciterId;
    public int? PlaybackCutoffSeconds => StopAfterSeconds ?? (Length == "short" ? 30 : null);
    public bool PlaysAudio => Configured && Enabled && (Mode == "adhan" || Mode == "focus" && FocusAudio);
    /// Matches Huda's own (windows_prayer_experience.dart). Only prayers that are
    /// off change which toasts are queued, so only they are part of it.
    public string DeliverySignature => Configured
        ? $"windows-reminders-v2:{(Enabled ? 1 : 0)}:{Mode}" +
            (Prayers.Where(prayer => Overrides?.GetValueOrDefault(prayer)?.Mode == "off").ToArray() is { Length: > 0 } off
                ? ":off=" + string.Join(",", off) : "")
        : "legacy";

    public void Validate()
    {
        if (Version != 1 || Mode is not ("silent" or "adhan" or "focus") ||
            Length is not (null or "short" or "full") ||
            ReciterId is null || !Regex.IsMatch(ReciterId, @"\A[a-z0-9]+(?:-[a-z0-9]+)*\z") ||
            AudioVersion is null || !Regex.IsMatch(AudioVersion, @"\Av[1-9][0-9]*\z") ||
            !double.IsFinite(Volume) || Volume is < 0 or > 1 ||
            FocusDurationSeconds is < 60 or > 3600 || StopAfterSeconds is < 1 or > 3600 ||
            !AdvanceOptions.Contains(AdvanceMinutes) || Overrides is { Count: > 5 } ||
            Overrides?.Any(pair => !Prayers.Contains(pair.Key) || pair.Value is null ||
                pair.Value.Mode is not (null or "silent" or "adhan" or "focus" or "off") ||
                pair.Value.ReciterId is { } id && !Regex.IsMatch(id, @"\A[a-z0-9]+(?:-[a-z0-9]+)*\z") ||
                pair.Value.AudioVersion is { } version && !Regex.IsMatch(version, @"\Av[1-9][0-9]*\z") ||
                pair.Value.AdvanceMinutes is { } minutes && !AdvanceOptions.Contains(minutes)) == true)
            throw new InvalidDataException("Invalid Windows prayer experience.");
    }
}

public readonly record struct PrayerFocusPolicy(bool PreventEarlyExit, bool IsPreview)
{
    public bool CanDismiss => !PreventEarlyExit;
}

public sealed record PrayerNotificationContract
{
    public required long LocationRevision { get; init; }
    public required long ScheduleRevision { get; init; }
    public required string ConfigurationSignature { get; init; }
    public void Validate()
    {
        if (LocationRevision is <= 0 or > 9007199254740991 ||
            ScheduleRevision is <= 0 or > 9007199254740991 ||
            string.IsNullOrWhiteSpace(ConfigurationSignature) || ConfigurationSignature.Length > 8192)
            throw new InvalidDataException("Invalid prayer notification identity.");
    }
}
