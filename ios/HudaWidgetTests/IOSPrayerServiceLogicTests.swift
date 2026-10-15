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
}
