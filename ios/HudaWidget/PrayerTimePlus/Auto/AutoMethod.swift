/// Resolves a calculation method from a location's country, mirroring the
/// reference engine's "Auto" mode.
///
/// Resolution is country-level: the ISO-3166 alpha-2 code maps to a method, and
/// unknown codes fall back to ``CalculationMethod/muslimWorldLeague``.
public enum AutoMethod {
    /// The method configured for a country.
    ///
    /// - Parameter iso2: An ISO-3166 alpha-2 country code (case-insensitive), for
    ///   example `"OM"` or `"fr"`.
    /// - Returns: The resolved method, or ``CalculationMethod/muslimWorldLeague``
    ///   when the code is unknown.
    public static func forCountry(_ iso2: String) -> CalculationMethod {
        let code = iso2.uppercased()
        let key = GeneratedAutoData.country[code] ?? GeneratedAutoData.mwlDefault
        return CalculationMethod.from(key: key) ?? .muslimWorldLeague
    }
}
