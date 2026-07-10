/// How Fajr and Isha are resolved where the sun never reaches the required
/// depression angle (high latitudes, especially in summer).
///
/// When a rule other than ``automatic`` or ``unadjusted`` is selected, the night
/// (sunset to the following sunrise) is divided and Fajr/Isha are pinned to a
/// fraction of it whenever the natural angle-based time would fall outside that
/// fraction.
public enum HighLatitudeRule: Sendable, Equatable, CaseIterable {
    /// No fixed rule: use the natural angle-based times, but if that leaves Fajr or
    /// Isha undefined, recompute once using ``seventhOfTheNight``. This is the default.
    case automatic

    /// Never apply a night-fraction fallback. Fajr and Isha may be undefined (`nil`)
    /// near the poles.
    case unadjusted

    /// Fajr and Isha are kept at least halfway through the night.
    case middleOfTheNight

    /// Fajr and Isha are kept within one-seventh of the night from sunrise and sunset.
    case seventhOfTheNight

    /// Fajr and Isha are kept within a fraction of the night proportional to their
    /// twilight angle (`angle / 60`).
    case twilightAngle
}
