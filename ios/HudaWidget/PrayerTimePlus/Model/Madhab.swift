/// The juristic school that fixes the Asr shadow length.
public enum Madhab: Int, Sendable, Equatable, CaseIterable {
    /// Shāfiʿī, Mālikī and Ḥanbalī: Asr begins when an object's shadow equals its
    /// own length plus the noon shadow.
    case shafi = 0

    /// Ḥanafī: Asr begins when an object's shadow equals twice its own length plus
    /// the noon shadow.
    case hanafi = 1

    /// The shadow-length multiple used by the Asr calculation (`1` or `2`).
    public var shadowFactor: Int {
        rawValue + 1
    }
}
