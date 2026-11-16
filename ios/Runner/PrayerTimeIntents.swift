import Foundation
import AppIntents
import AlarmKit

@available(iOS 16.0, *)
enum HudaPrayerName: String, AppEnum {
  case fajr, sunrise, dhuhr, asr, maghrib, isha
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Prayer"
  static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .fajr: "Fajr", .sunrise: "Sunrise", .dhuhr: "Dhuhr", .asr: "Asr", .maghrib: "Maghrib", .isha: "Isha"
  ]
}

@available(iOS 16.0, *)
struct HudaPrayerTimeResult: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Prayer time"
  static var defaultQuery = HudaPrayerTimeQuery()
  let id: String
  @Property(title: "Prayer") var prayer: String
  @Property(title: "Time") var time: Date
  @Property(title: "Location") var location: String
  @Property(title: "Time zone") var timeZone: String
  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(prayer)", subtitle: "\(location)") }
  init(name: String, time: Date, schedule: IOSPrayerSchedule, strings: [String: String]) {
    id = "\(schedule.location.revision)/\(name)/\(time.timeIntervalSince1970)"
    self.prayer = strings[name] ?? name.capitalized
    self.time = time
    location = schedule.location.locality ?? schedule.location.countryName ?? schedule.location.timeZoneId
    timeZone = schedule.location.timeZoneId
  }
}

@available(iOS 16.0, *)
struct HudaPrayerTimeQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [HudaPrayerTimeResult] {
    let configuration = try PrayerIntentCalculation.configuration()
    let schedule = configuration.schedule!
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = schedule.location.zone
    return (-8...21).flatMap { delta -> [HudaPrayerTimeResult] in
      guard let day = calendar.date(byAdding: .day, value: delta, to: Date()) else { return [] }
      let times = schedule.times(on: day)
      return IOSPrayerSchedule.names.compactMap { name in
        times[name].map { HudaPrayerTimeResult(name: name, time: $0, schedule: schedule, strings: configuration.strings) }
      }
    }
      .filter { identifiers.contains($0.id) }
  }
}

@available(iOS 16.0, *)
enum PrayerIntentCalculation {
  static func configuration() throws -> IOSPrayerConfiguration {
    guard let directory = IOSPrayerStore.sharedDirectory,
      let configuration = try? IOSPrayerStore(directory: directory).load().configuration,
      configuration.schedule != nil else { throw IOSPrayerIntentError.setupRequired }
    return configuration
  }
  static func spoken(_ result: HudaPrayerTimeResult, locale: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: locale)
    formatter.timeZone = TimeZone(identifier: result.timeZone)
    formatter.dateStyle = .medium; formatter.timeStyle = .short
    return "\(result.prayer): \(formatter.string(from: result.time)), \(result.location)"
  }
}

enum IOSPrayerIntentError: Error, LocalizedError {
  case setupRequired, unavailable
  var errorDescription: String? {
    switch self {
    case .setupRequired: return NSLocalizedString("Open Huda and set up your prayer location first.", comment: "Prayer intent setup")
    case .unavailable: return NSLocalizedString("This prayer time is unavailable for the selected date.", comment: "Prayer intent calculation")
    }
  }
}

@available(iOS 16.0, *)
struct GetNextHudaPrayerIntent: AppIntent {
  static var title: LocalizedStringResource = "Get Next Prayer"
  static var description = IntentDescription("Get the next prayer using Huda's accepted location and calculation settings.")
  func perform() async throws -> some IntentResult & ReturnsValue<HudaPrayerTimeResult> & ProvidesDialog {
    let configuration = try PrayerIntentCalculation.configuration()
    let schedule = configuration.schedule!
    guard let next = schedule.events(from: Date(), revision: configuration.revision, signature: configuration.configurationSignature).first
    else { throw IOSPrayerIntentError.unavailable }
    let result = HudaPrayerTimeResult(name: next.prayer, time: next.instant, schedule: schedule, strings: configuration.strings)
    return .result(value: result, dialog: IntentDialog(stringLiteral: PrayerIntentCalculation.spoken(result, locale: schedule.localeCode)))
  }
}

@available(iOS 16.0, *)
struct GetHudaPrayerTimeIntent: AppIntent {
  static var title: LocalizedStringResource = "Get Prayer Time"
  @Parameter(title: "Prayer") var prayer: HudaPrayerName
  @Parameter(title: "Date") var date: Date?
  @Parameter(title: "Next occurrence", default: false) var nextOccurrence: Bool
  func perform() async throws -> some IntentResult & ReturnsValue<HudaPrayerTimeResult> & ProvidesDialog {
    let configuration = try PrayerIntentCalculation.configuration()
    let schedule = configuration.schedule!
    let instant: Date?
    if nextOccurrence {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = schedule.location.zone
      let now = Date()
      instant = (-7...21).compactMap { delta -> Date? in
        guard let day = calendar.date(byAdding: .day, value: delta, to: now) else { return nil }
        return schedule.times(on: day)[prayer.rawValue]
      }.filter { $0 > now }.min()
    } else { instant = schedule.times(on: date ?? Date())[prayer.rawValue] }
    guard let instant else { throw IOSPrayerIntentError.unavailable }
    let result = HudaPrayerTimeResult(name: prayer.rawValue, time: instant, schedule: schedule, strings: configuration.strings)
    return .result(value: result, dialog: IntentDialog(stringLiteral: PrayerIntentCalculation.spoken(result, locale: schedule.localeCode)))
  }
}

@available(iOS 16.0, *)
struct GetTodayHudaPrayerTimesIntent: AppIntent {
  static var title: LocalizedStringResource = "Get Today's Prayer Times"
  func perform() async throws -> some IntentResult & ReturnsValue<[HudaPrayerTimeResult]> & ProvidesDialog {
    let configuration = try PrayerIntentCalculation.configuration()
    let schedule = configuration.schedule!
    let times = schedule.times(on: Date())
    let results = IOSPrayerSchedule.names.compactMap { name in
      times[name].map { HudaPrayerTimeResult(name: name, time: $0, schedule: schedule, strings: configuration.strings) }
    }
    return .result(value: results, dialog: IntentDialog(stringLiteral: results.map { PrayerIntentCalculation.spoken($0, locale: schedule.localeCode) }.joined(separator: ". ")))
  }
}

@available(iOS 16.0, *)
struct OpenHudaPrayerTimesIntent: AppIntent {
  static var title: LocalizedStringResource = "Open Prayer Times"
  static var openAppWhenRun = true
  func perform() async throws -> some IntentResult {
    UserDefaults(suiteName: "group.hudaHomeApp")?.set(true, forKey: "iosPrayerOpenTimes")
    return .result()
  }
}

@available(iOS 16.0, *)
struct HudaPrayerShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(intent: GetNextHudaPrayerIntent(), phrases: ["When is the next prayer in \(.applicationName)"], shortTitle: "Next Prayer", systemImageName: "sun.horizon")
    AppShortcut(intent: GetHudaPrayerTimeIntent(), phrases: ["What time is \(\.$prayer) in \(.applicationName)"], shortTitle: "Prayer Time", systemImageName: "clock")
    AppShortcut(intent: GetTodayHudaPrayerTimesIntent(), phrases: ["Today's prayer times in \(.applicationName)"], shortTitle: "Today's Prayers", systemImageName: "calendar")
    AppShortcut(intent: OpenHudaPrayerTimesIntent(), phrases: ["Open prayer times in \(.applicationName)"], shortTitle: "Open Prayers", systemImageName: "sun.max")
  }
}

@available(iOS 26.0, *)
struct StopHudaPrayerAlarmIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Stop Prayer Alarm"
  @Parameter(title: "Alarm") var alarmID: String
  @Parameter(title: "Occurrence") var occurrenceKey: String
  init() {}
  init(alarmID: String, occurrenceKey: String) { self.alarmID = alarmID; self.occurrenceKey = occurrenceKey }
  func perform() async throws -> some IntentResult {
    if let id = UUID(uuidString: alarmID) {
      try await IOSPrayerService.shared.observe(key: occurrenceKey, outcome: "stopped", alarmID: id)
    }
    return .result()
  }
}

/// The alarm's "Open Huda" button: stops the adhan and opens prayer times.
@available(iOS 26.0, *)
struct OpenHudaPrayerAlarmIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Open Huda"
  static var openAppWhenRun = true
  @Parameter(title: "Alarm") var alarmID: String
  @Parameter(title: "Occurrence") var occurrenceKey: String
  init() {}
  init(alarmID: String, occurrenceKey: String) { self.alarmID = alarmID; self.occurrenceKey = occurrenceKey }
  func perform() async throws -> some IntentResult {
    UserDefaults(suiteName: "group.hudaHomeApp")?.set(true, forKey: "iosPrayerOpenTimes")
    if let id = UUID(uuidString: alarmID) {
      try? await IOSPrayerService.shared.observe(key: occurrenceKey, outcome: "stopped", alarmID: id)
    }
    return .result()
  }
}
