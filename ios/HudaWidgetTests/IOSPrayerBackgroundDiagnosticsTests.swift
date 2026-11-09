import XCTest
@testable import HudaWidgetLogic

final class IOSPrayerBackgroundDiagnosticsTests: XCTestCase {
  func testTaskEvidencePersistsAcrossReloadAndHistoryIsBounded() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let log = IOSPrayerBackgroundDiagnostics(directory: directory, limit: 3)
    log.record("started", runID: "controlled", label: "completion")
    log.record("queueBefore", runID: "controlled", label: "completion",
      applicationState: "background", backgroundRefresh: "available", lowPowerMode: false,
      status: ["notificationCount": 49, "alarmCount": 0, "coverageMillis": 1_791_619_200_000.0])
    log.record("completed", runID: "controlled", label: "completion", success: true)
    log.record("started", runID: "natural")
    let records = try IOSPrayerBackgroundDiagnostics(directory: directory).read()
    XCTAssertEqual(records.map(\.event), ["queueBefore", "completed", "started"])
    XCTAssertEqual(records[0].notificationCount, 49)
    XCTAssertEqual(records[0].coverage, Date(timeIntervalSince1970: 1_791_619_200))
    XCTAssertEqual(records[0].applicationState, "background")
    XCTAssertEqual(records[1].success, true)
    XCTAssertNil(records[2].validationLabel)
    XCTAssertNil(records[2].success, "An interrupted task must not be reported as completed")
  }

  func testConcurrentTaskRecordsRemainReadableWithoutLostEvents() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let log = IOSPrayerBackgroundDiagnostics(directory: directory)
    DispatchQueue.concurrentPerform(iterations: 80) { index in
      log.record(index.isMultiple(of: 2) ? "expired" : "workFailed", runID: "run-\(index)")
    }
    let records = try log.read()
    XCTAssertEqual(records.count, 80)
    XCTAssertEqual(Set(records.compactMap(\.runID)).count, 80)
  }

  func testExpirationAndSuccessCompleteExactlyOnceUnderRace() {
    let lock = NSLock()
    var callbacks = [Bool]()
    var winners = 0
    let completion = IOSPrayerBackgroundCompletion { success in
      lock.lock(); callbacks.append(success); lock.unlock()
    }
    DispatchQueue.concurrentPerform(iterations: 100) { index in
      let won = completion.finish(index.isMultiple(of: 2))
      if won { lock.lock(); winners += 1; lock.unlock() }
    }
    XCTAssertEqual(callbacks.count, 1)
    XCTAssertEqual(winners, 1)
    XCTAssertFalse(completion.finish(true))
    XCTAssertFalse(completion.finish(false))
    XCTAssertEqual(callbacks.count, 1)
  }
}
