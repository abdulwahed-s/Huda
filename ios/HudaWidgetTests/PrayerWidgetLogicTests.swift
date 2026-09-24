import XCTest

@testable import HudaWidgetLogic

final class PrayerWidgetLogicTests: XCTestCase {
  private let utc = TimeZone(secondsFromGMT: 0)!

  func testExactBoundaryBeginsElapsedAtPlusZero() {
    let fajr = date(5, 0)
    let moment = PrayerWidgetStateResolver.resolve(
      now: fajr,
      transitions: [PrayerWidgetTransition(prayer: .fajr, date: fajr)]
    )
    XCTAssertEqual(moment?.mode, .elapsed)
    XCTAssertEqual(moment?.prayer, .fajr)
    XCTAssertEqual(moment?.prayerDate, fajr)
  }

  func testElapsedBoundaryAtTwentyFourFiftyNineAndSwitchAtTwentyFive() {
    let fajr = date(5, 0)
    let dhuhr = date(12, 0)
    let transitions = [
      PrayerWidgetTransition(prayer: .fajr, date: fajr),
      PrayerWidgetTransition(prayer: .dhuhr, date: dhuhr),
    ]
    let before = PrayerWidgetStateResolver.resolve(
      now: fajr.addingTimeInterval(24 * 60 + 59),
      transitions: transitions
    )
    XCTAssertEqual(before?.mode, .elapsed)
    XCTAssertEqual(before?.prayer, .fajr)

    let boundary = PrayerWidgetStateResolver.resolve(
      now: fajr.addingTimeInterval(25 * 60),
      transitions: transitions
    )
    XCTAssertEqual(boundary?.mode, .countdown)
    XCTAssertEqual(boundary?.prayer, .dhuhr)
  }

  func testMostRecentlyStartedPrayerWinsShortGap() {
    let prayerA = date(10, 0)
    let prayerB = date(10, 10)
    let moment = PrayerWidgetStateResolver.resolve(
      now: date(10, 11),
      transitions: [
        PrayerWidgetTransition(prayer: .fajr, date: prayerA),
        PrayerWidgetTransition(prayer: .dhuhr, date: prayerB),
      ]
    )
    XCTAssertEqual(moment?.mode, .elapsed)
    XCTAssertEqual(moment?.prayer, .dhuhr)
    XCTAssertEqual(moment?.prayerDate, prayerB)
  }

  func testLongFajrToDhuhrCountdownKeepsAbsoluteTarget() {
    let fajr = date(4, 0)
    let dhuhr = date(12, 30)
    let moment = PrayerWidgetStateResolver.resolve(
      now: date(5, 0),
      transitions: [
        PrayerWidgetTransition(prayer: .fajr, date: fajr),
        PrayerWidgetTransition(prayer: .dhuhr, date: dhuhr),
      ]
    )
    XCTAssertEqual(moment?.mode, .countdown)
    XCTAssertEqual(moment?.prayer, .dhuhr)
    XCTAssertEqual(moment?.prayerDate.timeIntervalSince(date(5, 0)), 7.5 * 3600)
  }

  func testIshaTransitionsToNextDayFajr() {
    let isha = date(20, 0)
    let fajr = date(5, 0, day: 2)
    let transitions = [
      PrayerWidgetTransition(prayer: .isha, date: isha),
      PrayerWidgetTransition(prayer: .fajr, date: fajr),
    ]
    XCTAssertEqual(
      PrayerWidgetStateResolver.resolve(
        now: isha.addingTimeInterval(25 * 60),
        transitions: transitions
      )?.prayer,
      .fajr
    )
  }

  func testSpotlightRelationshipsBeforeFajrUsePreviousDayIsha() throws {
    let yesterdayIsha = date(20, 0)
    let todayFajr = date(5, 0, day: 2)
    let transitions = [
      PrayerWidgetTransition(prayer: .isha, date: yesterdayIsha),
      PrayerWidgetTransition(prayer: .fajr, date: todayFajr),
    ]
    let moment = PrayerWidgetStateResolver.resolve(
      now: date(4, 0, day: 2),
      transitions: transitions
    )
    XCTAssertEqual(moment?.mode, .countdown)
    XCTAssertEqual(moment?.prayer, .fajr)
    XCTAssertEqual(moment?.latestStartedIndex, 0)
    XCTAssertEqual(try transitions[XCTUnwrap(moment?.latestStartedIndex)].date, yesterdayIsha)
  }

  func testSpotlightRelationshipsAfterIshaKeepTodaysIshaBesideTomorrowFajr() throws {
    let todayIsha = date(20, 0)
    let tomorrowFajr = date(5, 0, day: 2)
    let transitions = [
      PrayerWidgetTransition(prayer: .isha, date: todayIsha),
      PrayerWidgetTransition(prayer: .fajr, date: tomorrowFajr),
    ]
    let moment = PrayerWidgetStateResolver.resolve(
      now: todayIsha.addingTimeInterval(26 * 60),
      transitions: transitions
    )
    XCTAssertEqual(moment?.mode, .countdown)
    XCTAssertEqual(moment?.prayer, .fajr)
    XCTAssertEqual(moment?.latestStartedIndex, 0)
    XCTAssertEqual(try transitions[XCTUnwrap(moment?.latestStartedIndex)].date, todayIsha)
  }

  func testManualOffsetsPreserveCivilDayRollover() {
    let lateIsha = date(23, 55)
    let adjustedIsha = PrayerWidgetCalculator.applyingManualOffset(
      to: lateIsha,
      minutes: 10
    )
    XCTAssertEqual(adjustedIsha, date(0, 5, day: 2))

    let earlyFajr = date(0, 5, day: 2)
    let adjustedFajr = PrayerWidgetCalculator.applyingManualOffset(
      to: earlyFajr,
      minutes: -10
    )
    XCTAssertEqual(adjustedFajr, date(23, 55))
  }

  func testTimelineActivationCoverageExtendsPastThirtySixHours() {
    let now = date(0, 0)
    let transitions = (1...7).map { day in
      PrayerWidgetTransition(prayer: .fajr, date: date(5, 0, day: day))
    }
    let points = PrayerWidgetStateResolver.activationPoints(
      now: now,
      through: now.addingTimeInterval(7 * 24 * 3600),
      transitions: transitions
    )
    XCTAssertTrue(points.contains { $0.timeIntervalSince(now) > 36 * 3600 })
    XCTAssertTrue(points.contains { $0.timeIntervalSince(now) > 6 * 24 * 3600 })
  }

  func testTimelineBuiltDuringGraceIncludesTheGraceEndTransition() {
    let prayer = date(5, 0)
    let now = prayer.addingTimeInterval(10 * 60)
    let graceEnd = prayer.addingTimeInterval(25 * 60)
    let points = PrayerWidgetStateResolver.activationPoints(
      now: now,
      through: now.addingTimeInterval(24 * 3600),
      transitions: [PrayerWidgetTransition(prayer: .fajr, date: prayer)]
    )
    XCTAssertTrue(points.contains(graceEnd))
  }

  func testTimelineAddsOneNativeCompactTimerTransitionAtFiftyNineFiftyNine() {
    let now = date(0, 0)
    let prayer = date(7, 30)
    let compactStart = prayer.addingTimeInterval(-60 * 60 + 1)
    let points = PrayerWidgetStateResolver.activationPoints(
      now: now,
      through: date(12, 0),
      transitions: [
        PrayerWidgetTransition(prayer: .dhuhr, date: prayer)
      ]
    )

    XCTAssertTrue(points.contains(compactStart))
    XCTAssertEqual(
      points,
      [
        now,
        compactStart,
        prayer,
        prayer.addingTimeInterval(25 * 60),
      ])
  }

  func testUmmAlQuraIshaIntervalsInAndOutsideRamadan() throws {
    let settings = makeSettings(method: "ummAlQura", countryCode: "OM")
    let coordinates = Coordinates(latitude: 21.3891, longitude: 39.8579)
    let ramadan = try XCTUnwrap(
      PrayerWidgetCalculator.computeTimes(
        coordinates: coordinates,
        date: gregorian(2026, 3, 1),
        settings: settings
      ))
    let normal = try XCTUnwrap(
      PrayerWidgetCalculator.computeTimes(
        coordinates: coordinates,
        date: gregorian(2026, 5, 1),
        settings: settings
      ))
    XCTAssertEqual(
      try XCTUnwrap(ramadan.time(for: .isha)).timeIntervalSince(
        try XCTUnwrap(ramadan.time(for: .maghrib))
      ),
      120 * 60,
      accuracy: 1
    )
    XCTAssertEqual(
      try XCTUnwrap(normal.time(for: .isha)).timeIntervalSince(
        try XCTUnwrap(normal.time(for: .maghrib))
      ),
      90 * 60,
      accuracy: 1
    )
  }

  func testExplicitClockFormatsIgnoreSystemPreference() {
    let instant = date(17, 4)
    XCTAssertEqual(
      PrayerTimeFormatter.formatDevice(
        instant,
        useArabicNumerals: false,
        languageCode: "en_US_POSIX",
        format: .twelveHour,
        timeZone: utc
      ),
      "5:04 PM"
    )
    XCTAssertEqual(
      PrayerTimeFormatter.formatDevice(
        instant,
        useArabicNumerals: false,
        languageCode: "en_US_POSIX",
        format: .twentyFourHour,
        timeZone: utc
      ),
      "17:04"
    )
  }

  func testVersionedPayloadWinsAndLegacySettingsStillMigrate() throws {
    let suite = "PrayerWidgetLogicTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set("1", forKey: "latitude")
    defaults.set("2", forKey: "longitude")
    defaults.set("12h", forKey: "prayer_widget_time_format")
    let payload: [String: Any] = [
      "version": 2,
      "revision": 42,
      "committedAt": "2026-09-05T00:00:00.123456Z",
      "coordinates": ["latitude": "23.5", "longitude": "58.4"],
      "timeZoneId": "Asia/Muscat",
      "locationMode": "manual",
      "timeFormat": "24h",
    ]
    try defaults.set(
      String(data: JSONSerialization.data(withJSONObject: payload), encoding: .utf8),
      forKey: "prayer_widget_settings_v2"
    )
    let current = PrayerWidgetDataLoader.loadSettings(from: defaults)
    XCTAssertEqual(current.coordinates?.latitude, 23.5)
    XCTAssertEqual(current.timeZoneIdentifier, "Asia/Muscat")
    XCTAssertEqual(current.locationMode, "manual")
    XCTAssertEqual(current.timeFormat, .twentyFourHour)

    var payloadWithoutFormat = payload
    payloadWithoutFormat.removeValue(forKey: "timeFormat")
    try defaults.set(
      String(
        data: JSONSerialization.data(withJSONObject: payloadWithoutFormat),
        encoding: .utf8
      ),
      forKey: "prayer_widget_settings_v2"
    )
    let atomic = PrayerWidgetDataLoader.loadSettings(from: defaults)
    XCTAssertEqual(atomic.coordinates?.latitude, 23.5)
    XCTAssertEqual(atomic.timeFormat, .system)

    defaults.removeObject(forKey: "prayer_widget_settings_v2")
    let migrated = PrayerWidgetDataLoader.loadSettings(from: defaults)
    XCTAssertEqual(migrated.coordinates?.latitude, 1)
    XCTAssertEqual(migrated.locationMode, "manual")
    XCTAssertEqual(migrated.timeFormat, .twelveHour)
  }

  func testVersionThreeRejectsIncompleteMixedAndUnsafeRevisions() throws {
    let suite = "PrayerWidgetV3Tests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set("1", forKey: "latitude")
    defaults.set("2", forKey: "longitude")
    defaults.set("Europe/London", forKey: "prayer_time_zone_id")

    var payload: [String: Any] = [
      "version": 3,
      "revision": 13,
      "publicationRevision": 13,
      "locationRevision": 7,
      "scheduleRevision": 11,
      "configurationSignature": "configuration",
      "committedAt": "2026-09-05T00:00:00.123456Z",
      "coordinates": ["latitude": "23.588", "longitude": "58.3829"],
      "timeZoneId": "Asia/Muscat",
      "locationMode": "automatic",
    ]
    try setPayload(payload, in: defaults)
    let valid = PrayerWidgetDataLoader.loadSettings(from: defaults)
    XCTAssertEqual(valid.coordinates?.latitude, 23.588)
    XCTAssertEqual(valid.locationRevision, 7)
    XCTAssertEqual(valid.scheduleRevision, 11)
    XCTAssertEqual(valid.publicationRevision, 13)
    XCTAssertEqual(valid.configurationSignature, "configuration")

    let validPayload = payload

    payload.removeValue(forKey: "scheduleRevision")
    try setPayload(payload, in: defaults)
    let incomplete = PrayerWidgetDataLoader.loadSettings(from: defaults)
    XCTAssertEqual(incomplete.coordinates?.latitude, 1)
    XCTAssertEqual(incomplete.timeZoneIdentifier, "Europe/London")

    payload["scheduleRevision"] = 11
    payload["publicationRevision"] = 12
    try setPayload(payload, in: defaults)
    XCTAssertEqual(
      PrayerWidgetDataLoader.loadSettings(from: defaults).coordinates?.latitude,
      1
    )

    payload["publicationRevision"] = 13
    payload["locationRevision"] = 9_007_199_254_740_992
    try setPayload(payload, in: defaults)
    XCTAssertEqual(
      PrayerWidgetDataLoader.loadSettings(from: defaults).coordinates?.latitude,
      1
    )

    payload = validPayload
    payload["committedAt"] = "not-an-instant"
    try setPayload(payload, in: defaults)
    XCTAssertEqual(
      PrayerWidgetDataLoader.loadSettings(from: defaults).coordinates?.latitude,
      1
    )

    payload = validPayload
    payload.removeValue(forKey: "coordinates")
    try setPayload(payload, in: defaults)
    XCTAssertEqual(
      PrayerWidgetDataLoader.loadSettings(from: defaults).coordinates?.latitude,
      1
    )

    payload = validPayload
    payload["timeZoneId"] = "Unknown/Nowhere"
    try setPayload(payload, in: defaults)
    XCTAssertEqual(
      PrayerWidgetDataLoader.loadSettings(from: defaults).coordinates?.latitude,
      1
    )

    payload = validPayload
    payload["locationMode"] = "unexpected"
    try setPayload(payload, in: defaults)
    XCTAssertEqual(
      PrayerWidgetDataLoader.loadSettings(from: defaults).coordinates?.latitude,
      1
    )

    payload = validPayload
    payload["locationRevision"] = 7.5
    try setPayload(payload, in: defaults)
    XCTAssertEqual(
      PrayerWidgetDataLoader.loadSettings(from: defaults).coordinates?.latitude,
      1
    )
  }

  private func setPayload(
    _ payload: [String: Any],
    in defaults: UserDefaults
  ) throws {
    defaults.set(
      String(
        data: try JSONSerialization.data(withJSONObject: payload),
        encoding: .utf8
      ),
      forKey: "prayer_widget_settings_v2"
    )
  }

  private func makeSettings(
    method: String,
    countryCode: String
  ) -> PrayerWidgetSettings {
    PrayerWidgetSettings(
      coordinates: nil,
      offsets: [:],
      countryCode: countryCode,
      timeZoneIdentifier: "Asia/Muscat",
      locationMode: "manual",
      calculationMethod: method,
      madhab: "shafi",
      highLatitudeRule: "automatic",
      customFajrAngle: 18,
      customMaghribAngle: 0,
      customIshaAngle: 17,
      themeName: "teal",
      themeMode: "light",
      locale: "en",
      design: .hero,
      language: "en",
      numerals: .latin,
      backgroundEnabled: true,
      backgroundColor: nil,
      glassify: false,
      rounded: false,
      contentColor: nil,
      highlightColor: nil,
      contentSize: 100,
      timeFormat: .system,
      locationRevision: 0,
      scheduleRevision: 0,
      publicationRevision: 0,
      configurationSignature: "test"
    )
  }

  private func gregorian(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Muscat")!
    return calendar.date(
      from: DateComponents(
        year: year,
        month: month,
        day: day,
        hour: 12
      ))!
  }

  private func date(_ hour: Int, _ minute: Int, day: Int = 1) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = utc
    return calendar.date(
      from: DateComponents(
        year: 2026,
        month: 1,
        day: day,
        hour: hour,
        minute: minute
      ))!
  }
}
