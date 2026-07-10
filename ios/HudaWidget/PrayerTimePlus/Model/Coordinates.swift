import Foundation

/// A geographic location for which prayer times are computed.
///
/// Longitude is **east-positive**. Altitude is metres above sea level and only
/// affects methods that model the horizon dip; it is otherwise ignored.
///
/// ```swift
/// let sohar = Coordinates(latitude: 24.3486, longitude: 56.6953, altitude: 5)
/// ```
public struct Coordinates: Sendable, Equatable {
    /// Latitude in degrees, north positive, in `-90...90`.
    public let latitude: Double

    /// Longitude in degrees, east positive, in `-180...180`.
    public let longitude: Double

    /// Altitude in metres above sea level.
    public let altitude: Double

    /// Creates a location.
    ///
    /// - Parameters:
    ///   - latitude: Degrees north of the equator.
    ///   - longitude: Degrees east of the prime meridian.
    ///   - altitude: Metres above sea level. Defaults to `0`.
    ///   - validate: When `true`, a precondition failure is raised if `latitude`
    ///     or `longitude` is out of range. Defaults to `false` (permissive).
    public init(
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        validate: Bool = false,
    ) {
        if validate {
            precondition((-90.0 ... 90.0).contains(latitude), "latitude must be within -90...90")
            precondition(
                (-180.0 ... 180.0).contains(longitude),
                "longitude must be within -180...180",
            )
        }
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }
}
