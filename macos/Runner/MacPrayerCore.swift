import Foundation

enum MacPrayerError: Error, LocalizedError {
  case invalid(String)
  var errorDescription: String? {
    switch self { case .invalid(let message): return message }
  }
}

/// One prayer's own settings; anything nil follows the defaults.
struct MacPrayerOverride: Codable, Equatable {
  /// silent, adhan, focus, or off for no alert.
  var mode: String?
  var delivery: MacPrayerExperience.Delivery?
  var reciterId: String?
  var audioVersion: String?
  var advanceMinutes: Int?
}

struct MacPrayerExperience: Codable, Equatable {
  static let prayers = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
  static let advanceOptions = [0, 5, 10, 15, 30]
  enum Mode: String, Codable { case silent, adhan, focus }
  enum Delivery: String, Codable { case short, full }
  enum FocusStyle: String, Codable { case compact, immersive }
  var version = 1
  var configured = false
  var enabled = true
  var mode = Mode.silent
  var backgroundEnabled = false
  var startAtLogin = false
  var reciterId = "huda-default"
  var audioVersion = "v1"
  var delivery = Delivery.full
  var volume = 0.7
  var stopAfterSeconds: Int?
  var focusStyle = FocusStyle.compact
  var focusDurationSeconds = 600
  var focusAudio = false
  var focusCommitment = false
  var focusDisplay = "current"
  var timeSensitive = false
  var allowLockedAudio = false
  var quiet = false
  // Optional, so settings saved before these existed still decode.
  /// Minutes before each prayer for a reminder; nil or 0 for none.
  var advanceMinutes: Int?
  var overrides: [String: MacPrayerOverride]?

  /// The settings one prayer uses: its own where it has them, otherwise these.
  func effective(for prayer: String) -> MacPrayerExperience {
    var result = self
    result.overrides = nil
    guard let own = overrides?[prayer] else { return result }
    if own.mode == "off" { result.enabled = false }
    else if let mode = own.mode.flatMap(Mode.init(rawValue:)) { result.mode = mode }
    if let delivery = own.delivery { result.delivery = delivery }
    if let reciter = own.reciterId { result.reciterId = reciter; result.audioVersion = own.audioVersion ?? audioVersion }
    if let minutes = own.advanceMinutes { result.advanceMinutes = minutes }
    return result
  }
  /// Every prayer's settings, for checking the recordings they need.
  var effectivePrayers: [MacPrayerExperience] { Self.prayers.map(effective(for:)) }
  var usesShortSound: Bool { mode == .adhan && delivery == .short }

  var playerAudio: Bool { mode == .adhan && delivery == .full || mode == .focus && focusAudio }
  func validate() throws {
    guard version == 1, Self.matches(reciterId, "^[a-z0-9]+(?:-[a-z0-9]+)*$"),
      Self.matches(audioVersion, "^v[1-9][0-9]*$"), volume.isFinite, (0...1).contains(volume),
      (60...3600).contains(focusDurationSeconds),
      stopAfterSeconds == nil || (1...3600).contains(stopAfterSeconds!),
      focusDisplay == "current" || focusDisplay == "all" || Self.matches(focusDisplay, "^display:[0-9]+$"),
      !startAtLogin || backgroundEnabled,
      advanceMinutes.map(Self.advanceOptions.contains) ?? true,
      (overrides ?? [:]).allSatisfy({ prayer, own in
        Self.prayers.contains(prayer) &&
          (own.mode == nil || ["silent", "adhan", "focus", "off"].contains(own.mode!)) &&
          (own.reciterId == nil || Self.matches(own.reciterId!, "^[a-z0-9]+(?:-[a-z0-9]+)*$") &&
            Self.matches(own.audioVersion ?? "", "^v[1-9][0-9]*$")) &&
          (own.advanceMinutes.map(Self.advanceOptions.contains) ?? true)
      })
    else { throw MacPrayerError.invalid("Invalid prayer reminder preferences.") }
  }
  static func matches(_ value: String, _ pattern: String) -> Bool {
    value.range(of: pattern, options: .regularExpression) != nil
  }
  func dictionary() -> [String: Any] { (try? MacPrayerJSON.object(self)) ?? [:] }
}

enum MacPrayerJSON {
  static func decode<T: Decodable>(_ type: T.Type, _ value: Any) throws -> T {
    guard JSONSerialization.isValidJSONObject(value) else {
      throw MacPrayerError.invalid("Invalid JSON configuration.")
    }
    let data = try JSONSerialization.data(withJSONObject: value)
    guard data.count <= 262_144 else { throw MacPrayerError.invalid("Configuration is too large.") }
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

struct MacPrayerLocation: Codable, Equatable {
  let revision: Int64
  let latitude: Double
  let longitude: Double
  let timeZoneId: String
  let timeZoneProvenance: String
  let countryCode: String?
  let locality: String?
  let countryName: String?
  let verificationReasons: [String]
  var zone: TimeZone { TimeZone(identifier: timeZoneId)! }
  func validate() throws {
    guard revision > 0, revision <= 9_007_199_254_740_991,
      latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude),
      (-180...180).contains(longitude), TimeZone(identifier: timeZoneId) != nil,
      timeZoneProvenance != "legacyApproximate", verificationReasons.isEmpty
    else { throw MacPrayerError.invalid("A verified prayer location and IANA time zone are required.") }
  }
}

struct MacPrayerSchedule: Codable, Equatable {
  struct Angles: Codable, Equatable { let fajr: Double; let maghrib: Double; let isha: Double }
  let version: Int
  let location: MacPrayerLocation
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
    else { throw MacPrayerError.invalid("Invalid prayer calculation settings.") }
  }
  var method: CalculationMethod? {
    // Flutter resolves automatic/regional choices before publication. Reuse the
    // same Swift calculation core linked into both Apple widget targets.
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
  func events(from now: Date, days: Int = 15, revision: Int64, signature: String) -> [MacPrayerEvent] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = location.zone
    let midnight = calendar.startOfDay(for: now)
    var result: [MacPrayerEvent] = []
    // The app supports offsets up to seven days in either direction. Include
    // source dates on both sides, then bound the authoritative instant horizon.
    let end = calendar.date(byAdding: .day, value: days, to: midnight)!
    for delta in -7..<(days + 7) {
      guard let day = calendar.date(byAdding: .day, value: delta, to: midnight) else { continue }
      for (name, instant) in times(on: day) where Self.obligatory.contains(name) && instant > now && instant < end {
        result.append(MacPrayerEvent(prayer: name, instant: instant, civilDay: dayKey(day),
          location: location, revision: revision, signature: signature))
      }
    }
    return result.sorted { $0.instant < $1.instant }
  }
}

struct MacPrayerEvent {
  let prayer: String
  let instant: Date
  let civilDay: String
  let location: MacPrayerLocation
  let revision: Int64
  let signature: String
  var key: String { "\(civilDay)/\(prayer)" }
  // The OS request belongs to the source prayer day. An offset or a captured
  // settings cutover can put two different days' prayers on the same wall day.
  // Keep the scheduled-date ID below for the shared Dart receipt/payload format.
  var notificationIdentifier: String {
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
      "scheduledUtc": MacPrayerJSON.iso(instant), "timeZone": location.timeZoneId,
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

struct MacPrayerConfiguration: Codable, Equatable {
  var schemaVersion = 1
  var revision: Int64 = 0
  var cutoverMillis = 0.0
  var experience = MacPrayerExperience()
  var schedule: MacPrayerSchedule?
  var configurationSignature = ""
  var legacyNotifications = false
  var locale = "en"
  var strings: [String: String] = [:]
  var primaryColor: UInt32 = 0xFF134E4A
  var themeMode = "system"
  var use24HourClock = false
  var fontFamily: String?
  var numerals: String?
  var textScale: Double?
  func validate() throws {
    guard schemaVersion == 1, revision >= 0, revision < 9_007_199_254_740_991,
      cutoverMillis.isFinite, ["system", "light", "dark"].contains(themeMode),
      strings.count <= 100, strings.allSatisfy({ $0.key.count <= 64 && $0.value.count <= 4096 }),
      configurationSignature.count <= 8192, !locale.isEmpty, locale.count <= 64
    else { throw MacPrayerError.invalid("Invalid prayer configuration.") }
    try experience.validate()
    try schedule?.validate()
    guard fontFamily == nil || fontFamily!.count <= 128,
      numerals == nil || ["western", "eastern"].contains(numerals!),
      textScale == nil || textScale!.isFinite && (0.5...2).contains(textScale!)
    else { throw MacPrayerError.invalid("Invalid prayer presentation settings.") }
  }
  var deliverySignature: String {
    "\(configurationSignature)|mac:\(experience.enabled):\(experience.mode.rawValue):\(experience.delivery.rawValue):\(experience.reciterId):\(experience.audioVersion):\(experience.timeSensitive):\(legacyNotifications)" +
      (experience.overrides == nil && (experience.advanceMinutes ?? 0) == 0 ? "" : ":" + perPrayerSignature)
  }
  private var perPrayerSignature: String {
    (["a\(experience.advanceMinutes ?? 0)"] + MacPrayerExperience.prayers.compactMap { prayer in
      experience.overrides?[prayer].map { own in
        "\(prayer)=\(own.mode ?? "")/\(own.delivery?.rawValue ?? "")/\(own.reciterId ?? "")/\(own.audioVersion ?? "")/\(own.advanceMinutes.map(String.init) ?? "")"
      }
    }).joined(separator: ",")
  }
  /// This configuration as one prayer sees it.
  func forPrayer(_ prayer: String) -> MacPrayerConfiguration {
    var result = self
    result.experience = experience.effective(for: prayer)
    return result
  }
}

/// Atomic configuration and independent durable occurrence claims. A corrupt
/// current configuration never overwrites the last validated backup.
final class MacPrayerStore {
  let directory: URL
  private(set) var recoveryError: String?
  init(directory: URL) { self.directory = directory }
  func load() -> MacPrayerConfiguration? {
    for name in ["configuration.json", "configuration.last-good.json"] {
      do {
        let data = try Data(contentsOf: directory.appendingPathComponent(name))
        guard data.count <= 262_144 else { throw MacPrayerError.invalid("Configuration too large.") }
        let value = try JSONDecoder().decode(MacPrayerConfiguration.self, from: data)
        try value.validate()
        return value
      } catch {
        if FileManager.default.fileExists(atPath: directory.appendingPathComponent(name).path) {
          recoveryError = "Prayer configuration recovery: \(error.localizedDescription)"
        }
      }
    }
    return nil
  }
  func save(_ value: MacPrayerConfiguration) throws {
    try value.validate()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let file = directory.appendingPathComponent("configuration.json")
    if let previous = load() {
      try JSONEncoder().encode(previous).write(to: directory.appendingPathComponent("configuration.last-good.json"), options: .atomic)
    }
    try JSONEncoder().encode(value).write(to: file, options: .atomic)
    recoveryError = nil
  }
}

struct MacPrayerClaim: Codable {
  let claimedMillis: Double
  var notification: String?
  var playback: String
  var overlay: String
}

final class MacPrayerLedger {
  private let file: URL
  private(set) var claims: [String: MacPrayerClaim] = [:]
  private(set) var error: String?
  init(directory: URL) {
    file = directory.appendingPathComponent("occurrences.json")
    do {
      if FileManager.default.fileExists(atPath: file.path) {
        let data = try Data(contentsOf: file)
        guard data.count <= 4_194_304 else { throw MacPrayerError.invalid("Occurrence ledger too large.") }
        claims = try JSONDecoder().decode([String: MacPrayerClaim].self, from: data)
      }
    } catch { self.error = "Prayer occurrence ledger needs recovery: \(error.localizedDescription)" }
  }
  func contains(_ key: String) -> Bool { claims[key] != nil }
  func claim(_ key: String, at now: Date, notification: String = "notObserved") throws -> Bool {
    // Fail closed if the ledger is damaged; guessing would replay prayers.
    guard error == nil else { throw MacPrayerError.invalid(error!) }
    guard claims[key] == nil else { return false }
    claims = claims.filter { now.timeIntervalSince1970 * 1000 - $0.value.claimedMillis < 400 * 86400 * 1000 }
    claims[key] = MacPrayerClaim(claimedMillis: now.timeIntervalSince1970 * 1000, notification: notification,
      playback: "claimed", overlay: "claimed")
    do { try persist(); return true }
    catch { claims.removeValue(forKey: key); throw error }
  }
  func outcome(_ key: String, playback: String, overlay: String) {
    guard var claim = claims[key] else { return }
    claim.playback = playback; claim.overlay = overlay; claims[key] = claim
    do { try persist() } catch { self.error = error.localizedDescription }
  }
  func notificationOutcome(_ key: String, _ outcome: String) {
    guard var claim = claims[key] else { return }
    claim.notification = outcome; claims[key] = claim
    do { try persist() } catch { self.error = error.localizedDescription }
  }
  private func persist() throws {
    try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    try JSONEncoder().encode(claims).write(to: file, options: .atomic)
  }
}

enum MacPrayerDuePolicy {
  static func shouldDeliver(instant: Date, now: Date, continuouslyRunning: Bool) -> Bool {
    let late = now.timeIntervalSince(instant)
    return continuouslyRunning && late >= 0 && late <= 60
  }
  static func capacity(otherCount: Int) -> Int { max(0, min(50, 60 - max(0, otherCount))) }
}
