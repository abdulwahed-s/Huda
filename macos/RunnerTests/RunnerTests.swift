import Cocoa
import FlutterMacOS
import XCTest

@testable import huda

class RunnerTests: XCTestCase {

  func testAppleGeocoderAvailabilityPolicy() {
    XCTAssertFalse(
      PrayerAppleLocationResolver.prefersModernAPI(operatingSystemMajorVersion: 25)
    )
    XCTAssertTrue(
      PrayerAppleLocationResolver.prefersModernAPI(operatingSystemMajorVersion: 26)
    )
  }

}
