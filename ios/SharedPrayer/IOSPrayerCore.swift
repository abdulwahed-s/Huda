import Foundation

enum IOSPrayerError: Error, LocalizedError {
  case invalid(String)
  var errorDescription: String? {
    switch self { case .invalid(let message): return message }
  }
}

enum IOSPrayerJSON {
  static func decode<T: Decodable>(_ type: T.Type, _ value: Any) throws -> T {
    guard JSONSerialization.isValidJSONObject(value) else {
      throw IOSPrayerError.invalid("Invalid JSON configuration.")
    }
    let data = try JSONSerialization.data(withJSONObject: value)
    guard data.count <= 262_144 else { throw IOSPrayerError.invalid("Configuration is too large.") }
    return try JSONDecoder().decode(type, from: data)
  }
  static func object<T: Encodable>(_ value: T) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as! [String: Any]
  }
  static func iso(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }
}

struct IOSPrayerLocation: Codable, Equatable {
  let schemaVersion: Int
  let mode: String
  let revision: Int64
  let latitude: Double
  let longitude: Double
  let timeZoneId: String
  let timeZoneProvenance: String
  let countryCode: String?
  let locality: String?
  let countryName: String?
  let verificationReasons: [String]
  let capturedAtUtc: String
  let committedAtUtc: String
  let source: String
  let accuracyMeters: Double?
  let resolutionSource: String?
  let countryCandidates: [String]?
  var zone: TimeZone { TimeZone(identifier: timeZoneId)! }
  func validate() throws {
    guard schemaVersion == 1, ["manual", "automatic"].contains(mode),
      ["explicit", "foreground", "androidBackground", "iosSignificantChange", "migration"].contains(source),
      timeZoneProvenance == "coordinateResolved", revision > 0, revision <= 9_007_199_254_740_991,
      latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude),
      (-180...180).contains(longitude), TimeZone(identifier: timeZoneId) != nil,
      timeZoneProvenance != "legacyApproximate", verificationReasons.isEmpty
    else { throw IOSPrayerError.invalid("A verified prayer location and IANA time zone are required.") }
  }
}

struct IOSPrayerSchedule: Codable, Equatable {
  struct Angles: Codable, Equatable { let fajr: Double; let maghrib: Double; let isha: Double }
  let version: Int
  let deviceTimeZoneId: String
  let schedulingCapability: String
  let location: IOSPrayerLocation
  let methodToken: String
  let madhabToken: String
  let highLatitudeRuleToken: String
  let customAngles: Angles
  let offsets: [String: Int]
  let localeCode: String
  static let names = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]
  static let obligatory = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
  func validate() throws {
    try location.validate()
    guard version == 1, method != nil, ["shafi", "hanafi"].contains(madhabToken),
      ["automatic", "middleOfTheNight", "seventhOfTheNight", "twilightAngle", "none"].contains(highLatitudeRuleToken),
      customAngles.fajr.isFinite, (0...30).contains(customAngles.fajr),
      customAngles.maghrib.isFinite, (0...30).contains(customAngles.maghrib),
      customAngles.isha.isFinite, (0...30).contains(customAngles.isha),
      offsets.keys.allSatisfy({ Self.names.contains($0) }), offsets.values.allSatisfy({ (-10080...10080).contains($0) }),
      !localeCode.isEmpty, localeCode.count <= 64
    else { throw IOSPrayerError.invalid("Invalid prayer calculation settings.") }
  }
  var method: CalculationMethod? {
    if methodToken == "auto" {
      guard let country = location.countryCode, !country.isEmpty else { return nil }
      return AutoMethod.forCountry(country)
    }
    if methodToken == "other" { return .other }
    let key: String
    switch methodToken {
    case "muslimWorldLeague": key = "mwl"
    case "egyptian": key = "egypt"
    case "ummAlQura": key = "makkah"
    case "northAmerica": key = "isna"
    case "southKorea": key = "southkorea"
    default: key = methodToken
    }
    return CalculationMethod.from(key: key)
  }

  func times(on date: Date) -> [String: Date] {
    guard let method else { return [:] }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = location.zone
    let civil = calendar.dateComponents([.year, .month, .day], from: date)
    var noon = civil
    noon.hour = 12
    let reference = calendar.date(from: noon) ?? date
    let offset = location.zone.secondsFromGMT(for: reference)
    var parameters = method.parameters
    parameters.madhab = madhabToken == "hanafi" ? .hanafi : .shafi
    switch highLatitudeRuleToken {
    case "middleOfTheNight": parameters.highLatitudeRule = .middleOfTheNight
    case "seventhOfTheNight": parameters.highLatitudeRule = .seventhOfTheNight
    case "twilightAngle": parameters.highLatitudeRule = .twilightAngle
    case "none": parameters.highLatitudeRule = .unadjusted
    default: parameters.highLatitudeRule = .automatic
    }
    var hijri = Calendar(identifier: .islamicUmmAlQura)
    hijri.timeZone = location.zone
    parameters.isRamadan = hijri.component(.month, from: reference) == 9
    if method == .ummAlQura, parameters.isRamadan, location.countryCode?.uppercased() != "SA" {
      parameters.ishaValue = 120
    }
    if method == .other {
      parameters.fajrAngle = customAngles.fajr
      parameters.maghribIsInterval = false
      parameters.maghribValue = customAngles.maghrib
      parameters.ishaIsInterval = false
      parameters.ishaValue = customAngles.isha
    }
    let base = PrayerTimes(coordinates: Coordinates(latitude: location.latitude, longitude: location.longitude),
      date: civil, calculationParameters: parameters, utcOffset: TimeInterval(offset), countryCode: location.countryCode ?? "")
    var fixed = Calendar(identifier: .gregorian)
    fixed.timeZone = TimeZone(secondsFromGMT: offset)!
    let prayers: [Prayer] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
    var result: [String: Date] = [:]
    for (name, prayer) in zip(Self.names, prayers) {
      guard let instant = base.time(for: prayer) else { continue }
      let parts = fixed.dateComponents([.year, .month, .day, .hour, .minute, .second], from: instant)
      // Resolve local wall time in the selected zone first, then apply the manual
      // offset as elapsed minutes exactly once, including civil-date crossings.
      guard let zoned = calendar.date(from: parts) else { continue }
      result[name] = zoned.addingTimeInterval(Double(offsets[name] ?? 0) * 60)
    }
    return result
  }
  func dayKey(_ instant: Date) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = location.zone
    let p = calendar.dateComponents([.year, .month, .day], from: instant)
    return String(format: "%04d-%02d-%02d", p.year!, p.month!, p.day!)
  }
  func events(from now: Date, days: Int = 15, revision: Int64, signature: String) -> [IOSPrayerEvent] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = location.zone
    let midnight = calendar.startOfDay(for: now)
    var result: [IOSPrayerEvent] = []
    // The app supports offsets up to seven days in either direction. Include
    // source dates on both sides, then bound the authoritative instant horizon.
    let end = calendar.date(byAdding: .day, value: days, to: midnight)!
    for delta in -7..<(days + 7) {
      guard let day = calendar.date(byAdding: .day, value: delta, to: midnight) else { continue }
      for (name, instant) in times(on: day) where Self.obligatory.contains(name) && instant > now && instant < end {
        result.append(IOSPrayerEvent(prayer: name, instant: instant, civilDay: dayKey(day),
          location: location, revision: revision, signature: signature))
      }
    }
    return result.sorted { $0.instant < $1.instant }
  }
}

struct IOSPrayerEvent {
  let prayer: String
  let instant: Date
  let civilDay: String
  let location: IOSPrayerLocation
  let revision: Int64
  let signature: String
  var key: String { "\(civilDay)/\(prayer)" }
  // The OS request belongs to the source prayer day. An offset or a captured
  // settings cutover can put two different days' prayers on the same wall day.
  // Keep the scheduled-date ID below for the shared Dart receipt/payload format.
  var legacyNotificationIdentifier: String {
    let day = Int(civilDay.replacingOccurrences(of: "-", with: ""))!
    return String(300_000_000 + (day - 20_000_000) * 10 +
      (["fajr", "dhuhr", "asr", "maghrib", "isha"].firstIndex(of: prayer)! + 1))
  }
  var id: Int {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = location.zone
    let parts = calendar.dateComponents([.year, .month, .day], from: instant)
    let day = parts.year! * 10000 + parts.month! * 100 + parts.day!
    return 300_000_000 + (day - 20_000_000) * 10 + (["fajr", "dhuhr", "asr", "maghrib", "isha"].firstIndex(of: prayer)! + 1)
  }
  func dictionary(strings: [String: String]) -> [String: Any] {
    let wall = DateFormatter()
    wall.locale = Locale(identifier: "en_US_POSIX")
    wall.timeZone = location.zone
    wall.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    return ["id": id, "occurrenceKey": key, "prayer": prayer, "scheduledTime": wall.string(from: instant),
      "scheduledUtc": IOSPrayerJSON.iso(instant), "timeZone": location.timeZoneId,
      "locationRevision": location.revision, "scheduleRevision": revision,
      "configurationSignature": signature,
      "title": strings["\(prayer)Title"] ?? "Time for \(strings[prayer] ?? prayer.capitalized)",
      "body": strings["\(prayer)Body"] ?? "It is time to pray."]
  }
  func payload() -> String {
    var value = dictionary(strings: [:])
    value["type"] = "prayer_time"
    value["schemaVersion"] = 3
    value["occurrenceId"] = id
    return String(data: try! JSONSerialization.data(withJSONObject: value, options: .sortedKeys), encoding: .utf8)!
  }
}

