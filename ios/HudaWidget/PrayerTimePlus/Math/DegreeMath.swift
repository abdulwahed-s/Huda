import Foundation

// Degree-based trigonometry and angle wrapping.
//
// The solar model is expressed entirely in degrees; these wrappers convert to and
// from radians internally so every result matches the reference engine to the bit.
// They are the only place the standard-library radian trig functions are called.

/// Converts `x` from degrees to radians.
@inline(__always)
func degreesToRadians(_ x: Double) -> Double {
    x * .pi / 180.0
}

/// Converts `x` from radians to degrees.
@inline(__always)
func radiansToDegrees(_ x: Double) -> Double {
    x * 180.0 / .pi
}

/// Sine of an angle given in degrees.
@inline(__always)
func sinDeg(_ x: Double) -> Double {
    sin(degreesToRadians(x))
}

/// Cosine of an angle given in degrees.
@inline(__always)
func cosDeg(_ x: Double) -> Double {
    cos(degreesToRadians(x))
}

/// Tangent of an angle given in degrees.
@inline(__always)
func tanDeg(_ x: Double) -> Double {
    tan(degreesToRadians(x))
}

/// Arcsine, returning degrees.
@inline(__always)
func arcsinDeg(_ x: Double) -> Double {
    radiansToDegrees(asin(x))
}

/// Arccosine, returning degrees.
@inline(__always)
func arccosDeg(_ x: Double) -> Double {
    radiansToDegrees(acos(x))
}

/// Arccotangent, returning degrees.
///
/// Computed as `atan2(1, x)` rather than `atan(1 / x)` so the branch is correct
/// for negative arguments — the two disagree in sign there, which matters for the
/// Asr altitude when latitude and declination straddle.
@inline(__always)
func arccotDeg(_ x: Double) -> Double {
    radiansToDegrees(atan2(1.0, x))
}

/// Two-argument arctangent of `y / x`, returning degrees in `(-180, 180]`.
@inline(__always)
func arctan2Deg(_ y: Double, _ x: Double) -> Double {
    radiansToDegrees(atan2(y, x))
}

/// Wraps an angle to the half-open range `[0, 360)` degrees.
///
/// Uses `floor` (toward −∞) so negative inputs wrap correctly.
func fixAngle(_ x: Double) -> Double {
    let wrapped = x - 360.0 * floor(x / 360.0)
    return wrapped < 0 ? wrapped + 360.0 : wrapped
}

/// Wraps an hour value to the half-open range `[0, 24)` hours.
///
/// Uses `floor` (toward −∞) so negative inputs wrap correctly.
func fixHour(_ x: Double) -> Double {
    let wrapped = x - 24.0 * floor(x / 24.0)
    return wrapped < 0 ? wrapped + 24.0 : wrapped
}
