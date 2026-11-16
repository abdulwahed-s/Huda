import XCTest
@testable import HudaWidgetLogic

final class SahurAlarmTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1_791_619_200)
  private var capabilities: IOSPrayerCapabilities {
    var c = IOSPrayerCapabilities(); c.supportsAlarms = true; c.alarms = true
    c.notifications = true; c.notificationSound = true; return c
  }
  private func schedule() throws -> IOSPrayerSchedule {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let data = try Data(contentsOf: root.appendingPathComponent("test/fixtures/mac_prayer_calculation_parity.json"))
    let fixture = (try JSONSerialization.jsonObject(with: data) as! [String: Any])["cases"] as! [[String: Any]]
    return try IOSPrayerJSON.decode(IOSPrayerSchedule.self, fixture[0]["schedule"]!)
  }
  func testExactTimeDoesNotNeedPrayerSetupAndHasStableDailyIdentities() {
    var settings = IOSSahurSettings(); settings.enabled = true
    let all = settings.occurrences(schedule: nil, capabilities: capabilities, now: now, revision: 1, strings: [:])
    XCTAssertEqual(all.count, 30)
    XCTAssertTrue(all.allSatisfy { $0.kind == "sahur" && (114...143).contains($0.integerID) && $0.policy.sound == nil })
    XCTAssertEqual(Set(all.map(\.alarmID)).count, 30)
    var calendar = Calendar(identifier: .gregorian); calendar.timeZone = .current
    XCTAssertTrue(all.allSatisfy { calendar.component(.hour, from: $0.instant) == 4 && calendar.component(.minute, from: $0.instant) == 0 })
    let renewed = settings.occurrences(schedule: nil, capabilities: capabilities, now: now.addingTimeInterval(86400), revision: 2, strings: [:])
    let old = Dictionary(uniqueKeysWithValues: all.map { ($0.key, $0) })
    for event in renewed where old[event.key] != nil {
      XCTAssertEqual(event.alarmID, old[event.key]!.alarmID)
      XCTAssertEqual(event.eventJSON, old[event.key]!.eventJSON)
    }
  }
  func testBeforeFajrUsesAdjustedNativeFajrEvenWhenPrayersAreOff() throws {
    var settings = IOSSahurSettings(); settings.enabled = true; settings.type = 1; settings.minutesBeforeFajr = 150
    let input = try schedule()
    let expected = input.events(from: now, days: 31, revision: 1, signature: "sahur").filter { $0.prayer == "fajr" }
    let all = settings.occurrences(schedule: input, capabilities: capabilities, now: now, revision: 1, strings: [:])
    XCTAssertFalse(all.isEmpty)
    for event in all { XCTAssertTrue(expected.contains { abs($0.instant.timeIntervalSince(event.instant) - 9000) < 0.001 }) }
    XCTAssertTrue(settings.occurrences(schedule: nil, capabilities: capabilities, now: now, revision: 1, strings: [:]).isEmpty)
  }
  func testAlarmPermissionAndPre26SinglePlayFallback() {
    var settings = IOSSahurSettings(); settings.enabled = true
    var c = capabilities; c.alarms = false
    XCTAssertTrue(settings.occurrences(schedule: nil, capabilities: c, now: now, revision: 1, strings: [:]).allSatisfy { $0.policy.effective == .off })
    c.supportsAlarms = false
    let fallback = settings.occurrences(schedule: nil, capabilities: c, now: now, revision: 1, strings: [:])
    XCTAssertTrue(fallback.allSatisfy { $0.policy.effective == .short && $0.policy.sound == "huda-sahur.caf" && $0.timeSensitive })
    c.notificationSound = false
    XCTAssertTrue(settings.occurrences(schedule: nil, capabilities: c, now: now, revision: 1, strings: [:]).allSatisfy { $0.policy.effective == .off })
    settings.enabled = false
    XCTAssertTrue(settings.occurrences(schedule: nil, capabilities: c, now: now, revision: 1, strings: [:]).isEmpty)
  }
  func testSahurSharesCapacityWithPrayersAndOldConfigurationStillDecodes() throws {
    var settings = IOSSahurSettings(); settings.enabled = true
    let input = try schedule()
    let sahur = settings.occurrences(schedule: input, capabilities: capabilities, now: now, revision: 1, strings: [:])
    let prayers = IOSPrayerPlanner.occurrences(schedule: input, experience: IOSPrayerExperience(), capabilities: capabilities,
      now: now, revision: 1, signature: "test", strings: [:])
    let accepted = IOSPrayerPlanner.allocate((sahur + prayers).sorted { $0.instant < $1.instant }, otherNotifications: 17,
      alarmHorizon: now.addingTimeInterval(10 * 86400))
    XCTAssertGreaterThanOrEqual(accepted.filter { $0.kind == "sahur" }.count, 9)
    XCTAssertLessThanOrEqual(accepted.filter { $0.policy.backend == "notification" }.count, 42)
    XCTAssertLessThanOrEqual(accepted.filter { $0.policy.backend == "alarm" }.count, 50)
    var old = try IOSPrayerJSON.object(IOSPrayerConfiguration()); old.removeValue(forKey: "sahur")
    XCTAssertNil(try IOSPrayerJSON.decode(IOSPrayerConfiguration.self, old).sahur)
  }
}
