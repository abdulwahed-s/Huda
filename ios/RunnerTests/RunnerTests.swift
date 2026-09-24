import Flutter
import UIKit
import XCTest

@testable import Runner

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
