import XCTest
@testable import HudaWidgetLogic

final class IOSPrayerServiceLogicTests: XCTestCase {
  private var fixtures: [[String: Any]] {
    get throws {
      let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      let object = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("test/fixtures/mac_prayer_calculation_parity.json"))) as! [String: Any]
      return object["cases"] as! [[String: Any]]
    }
  }
  private func schedule() throws -> IOSPrayerSchedule { try IOSPrayerJSON.decode(IOSPrayerSchedule.self, fixtures[0]["schedule"]!) }
  private let now = Date(timeIntervalSince1970: 1_791_619_200)
  private var authorized: IOSPrayerCapabilities {
    var c = IOSPrayerCapabilities(); c.notifications = true; c.notificationSound = true
    c.supportsAlarms = true; c.alarms = true; c.customAlarmSound = true; return c
  }
  private func events(_ experience: IOSPrayerExperience = IOSPrayerExperience()) throws -> [IOSPrayerOccurrence] {
    IOSPrayerPlanner.occurrences(schedule: try schedule(), experience: experience, capabilities: authorized,
      now: now, revision: 1, signature: "fixture", strings: [:])
  }
  func testAllDartCalculatorFixturesAndWireSchema() throws {
    for fixture in try fixtures {
      let configuration = try IOSPrayerJSON.decode(IOSPrayerSchedule.self, fixture["schedule"]!)
      try configuration.validate()
      let actual = configuration.times(on: Date(timeIntervalSince1970: (fixture["dateMillis"] as! Double) / 1000))
      for name in IOSPrayerSchedule.names {
        let expected = (fixture["expected"] as! [String: Any])[name]
        if let expected = expected as? Double {
          XCTAssertEqual(try XCTUnwrap(actual[name]).timeIntervalSince1970 * 1000, expected, accuracy: 1,
            "\(fixture["name"]!)/\(name)")
        } else { XCTAssertNil(actual[name], "\(fixture["name"]!)/\(name)") }
      }
      let wire = try IOSPrayerJSON.object(configuration)
      XCTAssertEqual((wire["location"] as? [String: Any])?["schemaVersion"] as? Int, 1)
    }
  }
  func testSparseOverridesAndMasterOffSuppressAllKinds() throws {
    var p = IOSPrayerExperience(); p.mode = .silent; p.advanceMinutes = 10
    p.overrides["fajr"] = IOSPrayerOverride(mode: .alarm, reciterId: nil, advanceMinutes: nil, advanceMode: nil)
    p.overrides["isha"] = IOSPrayerOverride(mode: .off, reciterId: nil, advanceMinutes: nil, advanceMode: nil)
    try p.validate()
    let planned = try events(p)
    XCTAssertFalse(planned.contains { $0.prayer == "isha" })
    XCTAssertEqual(planned.first { $0.prayer == "fajr" && $0.kind == "main" }?.policy.backend, "alarm")
    XCTAssertTrue(planned.contains { $0.prayer == "dhuhr" && $0.kind == "advance" })
    p.enabled = false; XCTAssertTrue(try events(p).isEmpty)
  }
  func testAlarmAndFullGatesAndSilentSoundFallback() {
    var c = authorized
    // Without the full recording (before iOS 26.1) it is still an alarm, short.
    var result = IOSPrayerEffectivePolicy.resolve(.fullAlarm, reciter: "huda-default", fallback: .short, capabilities: c)
    XCTAssertEqual(result.effective, .alarm); XCTAssertEqual(result.reason, "fullAudioUnavailable")
    // A reciter without its own alarm file uses the default's whole adhan.
    c.installedFull["huda-default"] = "adhan_full.caf"
    result = IOSPrayerEffectivePolicy.resolve(.fullAlarm, reciter: "another-reciter", fallback: .short, capabilities: c)
    XCTAssertEqual(result.effective, .fullAlarm); XCTAssertEqual(result.sound, "adhan_full.caf")
    XCTAssertEqual(result.reason, "fullAudioFallback")
    c.installedFull["another-reciter"] = "huda-v1-another-reciter-alarm-0123456789abcdef.caf"
    result = IOSPrayerEffectivePolicy.resolve(.fullAlarm, reciter: "another-reciter", fallback: .short, capabilities: c)
    XCTAssertEqual(result.sound, "huda-v1-another-reciter-alarm-0123456789abcdef.caf"); XCTAssertNil(result.reason)
    // The opening-only alarm uses the padded clip so it plays once.
    c.customAlarmSound = true
    c.installedShort["another-reciter"] = "huda-v1-another-reciter-clip.wav"
    result = IOSPrayerEffectivePolicy.resolve(.alarm, reciter: "another-reciter", fallback: .short, capabilities: c)
    XCTAssertEqual(result.sound, "huda-v1-another-reciter-clip.wav")
    c.installedOpening["another-reciter"] = "huda-v1-another-reciter-opening-0123456789abcdef.caf"
    result = IOSPrayerEffectivePolicy.resolve(.alarm, reciter: "another-reciter", fallback: .short, capabilities: c)
    XCTAssertEqual(result.sound, "huda-v1-another-reciter-opening-0123456789abcdef.caf")
    c.alarms = false
    result = IOSPrayerEffectivePolicy.resolve(.alarm, reciter: "huda-default", fallback: .silent, capabilities: c)
    XCTAssertEqual(result.effective, .silent); XCTAssertEqual(result.reason, "alarmPermission")
    c.supportsAlarms = false
    XCTAssertEqual(IOSPrayerEffectivePolicy.resolve(.alarm, reciter: "huda-default", fallback: .short, capabilities: c).reason, "alarmUnsupported")
    c.notificationSound = false
    result = IOSPrayerEffectivePolicy.resolve(.short, reciter: "huda-default", fallback: .short, capabilities: c)
    XCTAssertEqual(result.effective, .silent); XCTAssertNil(result.sound)
    c.notifications = false
    XCTAssertEqual(IOSPrayerEffectivePolicy.resolve(.silent, reciter: "huda-default", fallback: .short, capabilities: c).effective, .off)
  }
  func testSeparateCapacitiesAndAdvanceRemindersGetRealSlots() throws {
    var p = IOSPrayerExperience(); p.advanceMinutes = 10
    let planned = try events(p)
    let allocation = IOSPrayerPlanner.allocate(planned, otherNotifications: 7,
      reservedNotifications: 3, alarmHorizon: now.addingTimeInterval(10 * 86400))
    XCTAssertEqual(allocation.count, 50)
    XCTAssertTrue(allocation.contains { $0.kind == "advance" })
    let accepted = Dictionary(uniqueKeysWithValues: allocation.map { ($0.key, $0) })
    XCTAssertGreaterThan(try XCTUnwrap(IOSPrayerPlanner.coverage(planned, accepted: accepted, kind: "main")).timeIntervalSince(now), 7 * 86400)
    p.mode = .alarm
    let alarms = IOSPrayerPlanner.allocate(try events(p), otherNotifications: 59,
      alarmLimit: 3, alarmHorizon: now.addingTimeInterval(10 * 86400))
    XCTAssertEqual(alarms.filter { $0.policy.backend == "alarm" }.count, 3)
    XCTAssertFalse(alarms.contains { $0.policy.backend == "notification" })
  }
  func testCoverageStopsAtFirstMissingOccurrence() throws {
    let planned = try events()
    var accepted = Dictionary(uniqueKeysWithValues: planned.prefix(50).map { ($0.key, $0) })
    accepted.removeValue(forKey: planned[2].key)
    XCTAssertEqual(IOSPrayerPlanner.coverage(planned, accepted: accepted, kind: "main"), planned[1].instant)
  }
  func testStableOSIdentitiesSurviveModeAndRevisionChanges() throws {
    let a = try events()
    var p = IOSPrayerExperience(); p.mode = .alarm
    let b = IOSPrayerPlanner.occurrences(schedule: try schedule(), experience: p, capabilities: authorized,
      now: now, revision: 99, signature: "changed", strings: ["fajrTitle": "Changed title"])
    XCTAssertEqual(a.map(\.key), b.map(\.key)); XCTAssertEqual(a.map(\.alarmID), b.map(\.alarmID))
    XCTAssertEqual(a.map(\.identifier), b.map(\.identifier))
    XCTAssertNotEqual(a.first?.eventJSON, b.first?.eventJSON)
  }
  func testStoreRecoversBackupAndFencesConcurrentWriter() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = IOSPrayerStore(directory: directory)
    let second = IOSPrayerStore(directory: directory)
    try store.beginExclusive(); defer { store.endExclusive() }
    XCTAssertThrowsError(try second.beginExclusive())
    var state = IOSPrayerState(); state.configuration.schedule = try schedule()
    state.configuration.revision = 1; state.configuration.migration = "native"
    try store.save(state)
    state.configuration.revision = 2; try store.save(state)
    try Data("corrupt".utf8).write(to: directory.appendingPathComponent("state.json"))
    XCTAssertEqual(try store.load().configuration.revision, 1)
    try FileManager.default.removeItem(at: directory.appendingPathComponent("state.json"))
    XCTAssertEqual(try store.load().configuration.revision, 1)
    store.endExclusive(); try second.beginExclusive(); second.endExclusive()
  }
  func testInvalidLocationAndUnsupportedPoliciesFailBeforePublication() throws {
    var wire = try IOSPrayerJSON.object(schedule())
    var location = wire["location"] as! [String: Any]; location["schemaVersion"] = 2; wire["location"] = location
    XCTAssertThrowsError(try IOSPrayerJSON.decode(IOSPrayerSchedule.self, wire).validate())
    var p = IOSPrayerExperience(); p.advanceMinutes = 1
    XCTAssertThrowsError(try p.validate())
    p.advanceMinutes = 0; p.overrides["sunrise"] = IOSPrayerOverride(mode: .short, reciterId: nil, advanceMinutes: nil, advanceMode: nil)
    XCTAssertThrowsError(try p.validate())
  }
  func testWidgetReadsAcceptedNativeInputsWhileKeepingAppearance() throws {
    let defaults = UserDefaults(suiteName: "iosPrayer.fixture.\(UUID().uuidString)")!
    defaults.set("dark", forKey: "themeMode"); defaults.set("arabic", forKey: "prayerWidgetNumerals")
    var native = IOSPrayerState(); native.configuration.schedule = try schedule()
    native.configuration.revision = 5; native.configuration.migration = "native"
    let widget = PrayerWidgetDataLoader.loadSettings(from: defaults, native: native)
    XCTAssertEqual(widget.timeZoneIdentifier, "Asia/Muscat"); XCTAssertEqual(widget.scheduleRevision, 5)
    XCTAssertEqual(widget.themeMode, "dark"); XCTAssertEqual(widget.numerals, .arabic)
    XCTAssertTrue(widget.precomputedDays.isEmpty)
    native.configuration.migration = "pending"
    XCTAssertEqual(PrayerWidgetDataLoader.loadSettings(from: defaults, native: native).scheduleRevision, 0)
  }
  func testAlarmsCarryTheThemeColorAndOpenButton() throws {
    var p = IOSPrayerExperience()
    p.overrides["fajr"] = IOSPrayerOverride(mode: .alarm, reciterId: nil, advanceMinutes: nil, advanceMode: nil)
    let strings = ["alarmTint": "0f766e", "openApp": "افتح هدى"]
    let all = IOSPrayerPlanner.occurrences(schedule: try schedule(), experience: p, capabilities: authorized,
      now: now, revision: 1, signature: "fixture", strings: strings)
    let alarm = try XCTUnwrap(all.first { $0.policy.backend == "alarm" })
    XCTAssertEqual(alarm.eventDictionary["tint"] as? String, "0f766e")
    XCTAssertEqual(alarm.eventDictionary["openApp"] as? String, "افتح هدى")
    XCTAssertNil(try XCTUnwrap(all.first { $0.policy.backend != "alarm" }).eventDictionary["tint"])
    // A theme change alters the event, so the alarm is submitted again.
    let other = IOSPrayerPlanner.occurrences(schedule: try schedule(), experience: p, capabilities: authorized,
      now: now, revision: 1, signature: "fixture", strings: strings.merging(["alarmTint": "991b1b"]) { _, new in new })
    XCTAssertNotEqual(other.first { $0.key == alarm.key }?.eventJSON, alarm.eventJSON)
    XCTAssertNil(IOSPrayerPlanner.alarmPresentation(["alarmTint": "#FFF; x"])["tint"])
  }
}
