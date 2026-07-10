/// The full set of inputs that shape a prayer-time calculation.
///
/// Obtain a preset from ``CalculationMethod/parameters`` and mutate a copy to
/// customise it:
///
/// ```swift
/// var params = CalculationMethod.oman.parameters
/// params.madhab = .hanafi
/// params.highLatitudeRule = .seventhOfTheNight
/// params.adjustments.fajr = 2
/// ```
public struct CalculationParameters: Sendable, Equatable {
    /// The method key this set derives from, if any (for example `"oman"`).
    public var method: String?

    /// Fajr twilight depression angle, in degrees.
    public var fajrAngle: Double

    /// When `true`, Maghrib is Sunset plus ``maghribValue`` minutes; when `false`,
    /// Maghrib is Sunset (plus any offset).
    public var maghribIsInterval: Bool

    /// Minutes after Sunset for Maghrib when ``maghribIsInterval`` is `true`.
    public var maghribValue: Double

    /// When `true`, Isha is Maghrib plus ``ishaValue`` minutes; when `false`, Isha
    /// is the time at the ``ishaValue`` depression angle.
    public var ishaIsInterval: Bool

    /// Either the Isha depression angle in degrees or, when ``ishaIsInterval`` is
    /// `true`, the minutes after Maghrib.
    public var ishaValue: Double

    /// The method's built-in per-prayer minute offsets.
    public var methodAdjustments: PrayerAdjustments

    /// The caller's manual per-prayer minute offsets, added on top of ``methodAdjustments``.
    public var adjustments: PrayerAdjustments

    /// The juristic school used for Asr.
    public var madhab: Madhab

    /// How Fajr and Isha are resolved at high latitudes.
    public var highLatitudeRule: HighLatitudeRule

    /// When `true`, the Umm al-Qura method adds 30 minutes to Isha.
    public var isRamadan: Bool

    /// Creates a parameter set. Every field has a default so a fully custom method
    /// can be built by setting only what it needs.
    public init(
        method: String? = nil,
        fajrAngle: Double = 0,
        maghribIsInterval: Bool = false,
        maghribValue: Double = 0,
        ishaIsInterval: Bool = false,
        ishaValue: Double = 0,
        methodAdjustments: PrayerAdjustments = PrayerAdjustments(),
        adjustments: PrayerAdjustments = PrayerAdjustments(),
        madhab: Madhab = .shafi,
        highLatitudeRule: HighLatitudeRule = .automatic,
        isRamadan: Bool = false,
    ) {
        self.method = method
        self.fajrAngle = fajrAngle
        self.maghribIsInterval = maghribIsInterval
        self.maghribValue = maghribValue
        self.ishaIsInterval = ishaIsInterval
        self.ishaValue = ishaValue
        self.methodAdjustments = methodAdjustments
        self.adjustments = adjustments
        self.madhab = madhab
        self.highLatitudeRule = highLatitudeRule
        self.isRamadan = isRamadan
    }
}

extension CalculationParameters {
    /// Decodes a method's 11-column parameter array into a parameter set.
    ///
    /// Columns: Fajr angle, Maghrib interval flag, Maghrib value, Isha interval
    /// flag, Isha value, then the Fajr/Sunrise/Dhuhr/Asr/Maghrib/Isha minute offsets.
    init(key: String, columns: [Double]) {
        func value(_ index: Int) -> Double {
            index < columns.count ? columns[index] : 0
        }
        func offset(_ index: Int) -> Int {
            Int(value(index))
        }

        self.init(
            method: key,
            fajrAngle: value(0),
            maghribIsInterval: value(1) == 1,
            maghribValue: value(2),
            ishaIsInterval: value(3) == 1,
            ishaValue: value(4),
            methodAdjustments: PrayerAdjustments(
                fajr: offset(5),
                sunrise: offset(6),
                dhuhr: offset(7),
                asr: offset(8),
                maghrib: offset(9),
                isha: offset(10),
            ),
        )
    }
}
