/// Per-prayer minute offsets.
///
/// Used both for a method's built-in offsets and for a caller's manual tuning;
/// the two are added together before being applied.
public struct PrayerAdjustments: Sendable, Equatable {
    /// Minutes added to Fajr.
    public var fajr: Int
    /// Minutes added to Sunrise.
    public var sunrise: Int
    /// Minutes added to Dhuhr.
    public var dhuhr: Int
    /// Minutes added to Asr.
    public var asr: Int
    /// Minutes added to Maghrib.
    public var maghrib: Int
    /// Minutes added to Isha.
    public var isha: Int

    /// Creates a set of per-prayer minute offsets, each defaulting to `0`.
    public init(
        fajr: Int = 0,
        sunrise: Int = 0,
        dhuhr: Int = 0,
        asr: Int = 0,
        maghrib: Int = 0,
        isha: Int = 0,
    ) {
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
    }
}
