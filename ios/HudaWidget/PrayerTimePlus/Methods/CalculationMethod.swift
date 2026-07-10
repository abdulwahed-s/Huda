/// A named preset of calculation parameters.
///
/// Each case maps to a stable string ``key`` and yields a fresh
/// ``CalculationParameters`` value via ``parameters``. Use ``other`` to build a
/// fully custom method.
///
/// ```swift
/// let params = CalculationMethod.muslimWorldLeague.parameters
/// ```
public enum CalculationMethod: String, Sendable, Equatable, CaseIterable {
    /// Muslim World League — Fajr 18°, Isha 17°.
    case muslimWorldLeague = "mwl"
    /// Egyptian General Authority of Survey — Fajr 19.5°, Isha 17.5°.
    case egyptian = "egypt"
    /// Umm al-Qura, Makkah — Fajr 18.5°, Isha 90 minutes after Maghrib (120 in Ramadan).
    case ummAlQura = "makkah"
    /// Islamic Society of North America — Fajr 15°, Isha 15°.
    case northAmerica = "isna"
    /// University of Islamic Sciences, Karachi — Fajr 18°, Isha 18°.
    case karachi

    /// United Arab Emirates (GAIAE).
    case emirates
    /// Dubai. Shares the Muslim World League base angles.
    case dubai
    /// Qatar Calendar House.
    case qatar
    /// Kuwait.
    case kuwait
    /// Oman.
    case oman
    /// Diyanet, Turkey.
    case turkey
    /// Habous, Morocco.
    case morocco
    /// Algeria.
    case algeria
    /// Tunisia.
    case tunisia
    /// Sudan.
    case sudan
    /// Libya.
    case libya
    /// Hashemi, Syria.
    case syria
    /// Jordan.
    case jordan
    /// Iraq.
    case iraq
    /// Palestine.
    case palestine
    /// Kazakhstan.
    case kazakhstan
    /// Tajikistan.
    case tajikistan
    /// Maldives.
    case maldives
    /// Moscow.
    case moscow
    /// Southeast Asian countries.
    case malaysia
    /// Malaysian Islamic Development Department (JAKIM).
    case malaysia2
    /// Indonesia (Kemenag).
    case indonesia
    /// South Korea.
    case southKorea = "southkorea"
    /// Muscat, Oman.
    case omanMuscat
    /// Azrou, Morocco.
    case azrou

    /// London.
    case london
    /// Birmingham.
    case birmingham
    /// Blackburn.
    case blackburn
    /// Aachen, Germany.
    case aachen
    /// Munich, Germany.
    case munchen
    /// Potsdam, Germany.
    case potsdam
    /// Nuremberg, Germany.
    case nurnberg
    /// Austria.
    case austria
    /// Belgium.
    case belgium
    /// Luxembourg.
    case luxembourg
    /// Czech Republic.
    case czech
    /// Switzerland.
    case switzerland
    /// Fribourg, Switzerland.
    case fribourg
    /// Union des Organisations Islamiques de France.
    case uoif
    /// Paris.
    case paris
    /// Toulouse.
    case toulouse
    /// Lyon.
    case lyon
    /// Orléans.
    case orleans
    /// Montreal.
    case montreal
    /// Windsor, Canada.
    case windsor
    /// Calgary, Canada.
    case calgary
    /// Mississauga, Canada.
    case mississauga
    /// Rotterdam.
    case rotterdam
    /// Dordrecht.
    case dordrecht
    /// Eindhoven.
    case eindhoven

    /// A fully custom method: ``parameters`` returns a neutral set for the caller
    /// to configure.
    case other

    /// The stable string key for this method.
    public var key: String {
        rawValue
    }

    /// A fresh parameter set for this method.
    ///
    /// ``other`` returns a neutral set; ``dubai`` (which has no dedicated row) uses
    /// the Muslim World League base angles.
    public var parameters: CalculationParameters {
        if self == .other {
            return CalculationParameters(method: rawValue)
        }
        let columns = GeneratedMethodData.parameters[rawValue]
            ?? GeneratedMethodData.parameters["mwl"]
            ?? [18, 1, 0, 0, 17, 0, 0, 0, 0, 0, 0]
        return CalculationParameters(key: rawValue, columns: columns)
    }

    /// The method for a string key, or `nil` if none matches.
    public static func from(key: String) -> CalculationMethod? {
        CalculationMethod(rawValue: key)
    }
}
