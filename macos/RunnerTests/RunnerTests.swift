import Cocoa
import FlutterMacOS
import XCTest

@testable import huda

class RunnerTests: XCTestCase {

  func testPrayerMenuUsesHudaLogo() {
    XCTAssertNotNil(NSImage(named: NSImage.Name("HudaMenuIcon")))
  }

  func testPrayerMenuLogoFollowsAppLanguage() {
    XCTAssertEqual(
      PrayerMenuBarController.imagePosition(for: "en", showsText: true), .imageRight
    )
    XCTAssertEqual(
      PrayerMenuBarController.imagePosition(for: "ar", showsText: true), .imageLeft
    )
    XCTAssertEqual(
      PrayerMenuBarController.imagePosition(for: "ur", showsText: true), .imageLeft
    )
    XCTAssertEqual(
      PrayerMenuBarController.imagePosition(for: "ar_SA", showsText: true), .imageLeft
    )
    XCTAssertEqual(
      PrayerMenuBarController.imagePosition(for: "en", showsText: false), .imageOnly
    )
  }

  func testPrayerMenuAcceptsOpaqueFlutterPrimaryColor() {
    XCTAssertEqual(
      PrayerMenuBarController.parsedPrimaryColor(NSNumber(value: 0xFF7C3AED)),
      0xFF7C3AED
    )
    XCTAssertNil(PrayerMenuBarController.parsedPrimaryColor(NSNumber(value: -1)))
    XCTAssertNil(PrayerMenuBarController.parsedPrimaryColor(NSNumber(value: 0x007C3AED)))
  }

  func testAppleGeocoderAvailabilityPolicy() {
    XCTAssertFalse(
      PrayerAppleLocationResolver.prefersModernAPI(operatingSystemMajorVersion: 25)
    )
    XCTAssertTrue(
      PrayerAppleLocationResolver.prefersModernAPI(operatingSystemMajorVersion: 26)
    )
  }

  func testPrayerMenuMovesFromIshaToNextDayFajr() throws {
    let today = "2026-09-29"
    let tomorrow = "2026-09-30"
    let isha = date("2026-09-29T15:00:00Z")
    let fajr = date("2026-09-30T01:00:00Z")
    let raw = try payload(
      zone: "Asia/Muscat",
      days: [
        today: ["isha": isha.timeIntervalSince1970 * 1000],
        tomorrow: ["fajr": fajr.timeIntervalSince1970 * 1000],
      ]
    )
    let snapshot = try XCTUnwrap(PrayerMenuSnapshot.parse(raw))
    let now = date("2026-09-29T16:00:00Z")

    XCTAssertEqual(snapshot.dayKey(for: now), today)
    XCTAssertEqual(snapshot.nextPrayer(after: now)?.name, "fajr")
    XCTAssertEqual(snapshot.nextPrayer(after: now)?.time, fajr)
  }

  func testPrayerMenuUsesLocationDayAcrossDaylightSavingChange() throws {
    let fajr = date("2026-03-08T10:00:00Z")
    let raw = try payload(
      zone: "America/New_York",
      days: ["2026-03-08": ["fajr": fajr.timeIntervalSince1970 * 1000]]
    )
    let snapshot = try XCTUnwrap(PrayerMenuSnapshot.parse(raw))
    let now = date("2026-03-08T06:30:00Z")

    XCTAssertEqual(snapshot.dayKey(for: now), "2026-03-08")
    XCTAssertEqual(snapshot.nextPrayer(after: now)?.time, fajr)
    XCTAssertNil(snapshot.nextPrayer(after: fajr))
  }

  func testPrayerMenuRejectsInvalidOrUnavailableDays() throws {
    let raw = try payload(zone: "Invalid/Zone", days: ["2026-09-29": ["fajr": 1]])
    XCTAssertNil(PrayerMenuSnapshot.parse(raw))

    let valid = try payload(
      zone: "Asia/Muscat",
      days: ["2026-09-29": ["fajr": date("2026-09-29T01:00:00Z").timeIntervalSince1970 * 1000]]
    )
    let snapshot = try XCTUnwrap(PrayerMenuSnapshot.parse(valid))
    XCTAssertNil(snapshot.nextPrayer(after: date("2026-10-10T10:00:00Z")))
  }

  private func date(_ value: String) -> Date {
    ISO8601DateFormatter().date(from: value)!
  }

  private func payload(zone: String, days: [String: [String: Double]]) throws -> String {
    let object: [String: Any] = [
      "version": 4,
      "revision": 1,
      "timeZoneId": zone,
      "precomputedDays": days,
    ]
    return String(data: try JSONSerialization.data(withJSONObject: object), encoding: .utf8)!
  }

}
