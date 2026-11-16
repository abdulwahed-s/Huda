import Cocoa
import AVFoundation
import Carbon
import CryptoKit
import FlutterMacOS
import UserNotifications
import XCTest
@testable import huda

private final class FakePrayerNotifications: MacPrayerNotificationBackend {
  var pending: [String: UNNotificationRequest] = [:]
  var rejected = Set<String>()
  var discardAccepted = false
  var discardRemovals = false
  var additions = 0
  var removals: [String] = []
  var permissionRequests = 0
  var authorizationStatus: UNAuthorizationStatus = .authorized
  var alertStyle: UNAlertStyle = .banner
  func getSettings(_ completion: @escaping (MacPrayerNotificationSettings) -> Void) {
    completion(MacPrayerNotificationSettings(authorizationStatus: authorizationStatus, alertStyle: alertStyle))
  }
  func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
    completionHandler(Array(pending.values))
  }
  func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
    additions += 1
    if rejected.contains(request.identifier) { completionHandler?(MacPrayerError.invalid("Injected add failure")); return }
    if !discardAccepted { pending[request.identifier] = request }
    completionHandler?(nil)
  }
  func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
    removals += identifiers
    if discardRemovals { return }
    for id in identifiers { pending.removeValue(forKey: id) }
  }
  func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
  func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
    permissionRequests += 1; completionHandler(true, nil)
  }
}

final class MacPrayerServiceTests: XCTestCase {
  private static var forwardedEvents = 0
  private static var forwardedRefcon: UnsafeMutableRawPointer?
  private var directory: URL!
  override func setUpWithError() throws {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent("huda-mac-prayer-tests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try MacPrayerStore(directory: directory).save(MacPrayerConfiguration())
  }
  override func tearDownWithError() throws { try FileManager.default.removeItem(at: directory) }
  private func schedule() throws -> [String: Any] {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let data = try Data(contentsOf: root.appendingPathComponent("test/fixtures/mac_prayer_calculation_parity.json"))
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    return (json["cases"] as! [[String: Any]])[0]["schedule"] as! [String: Any]
  }
  private func apply(_ service: MacPrayerService, method: String, values: [String: Any] = [:]) -> [String: Any] {
    let done = expectation(description: method)
    var response: [String: Any] = [:]
    service.handle(FlutterMethodCall(methodName: method, arguments: ["schemaVersion": 1].merging(values) { _, new in new })) { value in
      if let value = value as? [String: Any] { response = value }
      else { XCTFail("\(method) returned \(String(describing: value))") }
      done.fulfill()
    }
    wait(for: [done], timeout: 10)
    return response
  }
  private func configure(_ service: MacPrayerService) throws -> [String: Any] {
    let current = apply(service, method: "status")
    return apply(service, method: "configure", values: ["expectedRevision": current["revision"]!,
      "schedule": try schedule(), "configurationSignature": "native-test"])
  }
  func testNewInstallAndLaunchClassificationDoNotInferStartupConsent() throws {
    let settings = MacPrayerExperience()
    XCTAssertEqual(settings.mode, .silent)
    XCTAssertFalse(settings.backgroundEnabled)
    XCTAssertFalse(settings.startAtLogin)
    XCTAssertEqual(settings.focusStyle, .compact)
    XCTAssertEqual(MacPrayerLaunchClassifier.context(property: OSType(keyAELaunchedAsLogInItem)), .login)
    XCTAssertEqual(MacPrayerLaunchClassifier.context(property: OSType(keyAELaunchedAsServiceItem)), .login)
    XCTAssertEqual(MacPrayerLaunchClassifier.context(property: nil), .manual)
    let fake = FakePrayerNotifications()
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    _ = apply(service, method: "status")
    XCTAssertEqual(fake.permissionRequests, 0)
    XCTAssertFalse(service.backgroundEnabled)
  }
  func testStatusRefreshReadsAlertStyleWithoutChangingUserSettings() throws {
    let fake = FakePrayerNotifications()
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    let revision = service.configuration.revision
    XCTAssertEqual(apply(service, method: "status")["notificationAlertStyle"] as? String, "banner")
    fake.alertStyle = .alert
    XCTAssertEqual(apply(service, method: "status")["notificationAlertStyle"] as? String, "alert")
    fake.alertStyle = .none
    fake.authorizationStatus = .denied
    let denied = apply(service, method: "status")
    XCTAssertEqual(denied["notificationAlertStyle"] as? String, "none")
    XCTAssertEqual(denied["authorization"] as? String, "denied")
    XCTAssertEqual(service.configuration.revision, revision)
    XCTAssertEqual(fake.permissionRequests, 0)
  }
  func testLoginAppleEventIsCapturedBeforeTheOriginalHandlerAndForwarded() throws {
    var original: AEEventHandlerUPP?
    var refcon: UnsafeMutableRawPointer?
    AEGetEventHandler(AEEventClass(kCoreEventClass), AEEventID(kAEOpenApplication), &original, &refcon, false)
    defer {
      if let original { AEInstallEventHandler(AEEventClass(kCoreEventClass), AEEventID(kAEOpenApplication), original, refcon, false) }
    }
    Self.forwardedEvents = 0; Self.forwardedRefcon = nil
    let sentinel = UnsafeMutableRawPointer(bitPattern: 5)!
    let previous: AEEventHandlerUPP = { _, _, refcon in
      MacPrayerServiceTests.forwardedEvents += 1
      MacPrayerServiceTests.forwardedRefcon = refcon
      return 0
    }
    AEInstallEventHandler(AEEventClass(kCoreEventClass), AEEventID(kAEOpenApplication), previous, sentinel, false)
    let classifier = MacPrayerLaunchClassifier()
    classifier.install(); defer { classifier.restoreHandler() }
    classifier.onClassified = { context in
      XCTAssertEqual(context, .login)
      XCTAssertEqual(Self.forwardedEvents, 0)
    }
    let event = NSAppleEventDescriptor.appleEvent(withEventClass: AEEventClass(kCoreEventClass),
      eventID: AEEventID(kAEOpenApplication), targetDescriptor: .null(), returnID: AEReturnID(kAutoGenerateReturnID),
      transactionID: AETransactionID(kAnyTransactionID))
    event.setParam(NSAppleEventDescriptor(enumCode: OSType(keyAELaunchedAsLogInItem)), forKeyword: AEKeyword(keyAEPropData))
    var reply = AppleEvent()
    XCTAssertEqual(classifier.handle(event.aeDesc, reply: &reply), 0)
    XCTAssertEqual(classifier.context, .login)
    XCTAssertEqual(Self.forwardedEvents, 1)
    XCTAssertEqual(Self.forwardedRefcon, sentinel)
  }
  func testURLAppleEventRevealsBeforeForwardingTheUnchangedPluginEvent() throws {
    var original: AEEventHandlerUPP?
    var originalRefcon: UnsafeMutableRawPointer?
    AEGetEventHandler(AEEventClass(kInternetEventClass), AEEventID(kAEGetURL), &original, &originalRefcon, false)
    defer {
      if let original {
        AEInstallEventHandler(AEEventClass(kInternetEventClass), AEEventID(kAEGetURL), original, originalRefcon, false)
      }
    }
    MacPrayerServiceTests.forwardedEvents = 0; MacPrayerServiceTests.forwardedRefcon = nil
    let sentinel = UnsafeMutableRawPointer(bitPattern: 6)!
    let previous: AEEventHandlerUPP = { event, _, refcon in
      var direct = AEDesc()
      XCTAssertEqual(AEGetParamDesc(event, AEKeyword(keyDirectObject), DescType(typeWildCard), &direct), OSErr(noErr))
      XCTAssertEqual(NSAppleEventDescriptor(aeDescNoCopy: &direct).stringValue, "huda://prayer_times")
      MacPrayerServiceTests.forwardedEvents += 1; MacPrayerServiceTests.forwardedRefcon = refcon
      return OSErr(-50)
    }
    AEInstallEventHandler(AEEventClass(kInternetEventClass), AEEventID(kAEGetURL), previous, sentinel, false)
    let handler = MacPrayerURLHandler()
    handler.onOpenURL = { url in
      XCTAssertEqual(url.absoluteString, "huda://prayer_times")
      XCTAssertEqual(MacPrayerServiceTests.forwardedEvents, 0)
    }
    handler.install(); defer { handler.restoreHandler() }
    let event = NSAppleEventDescriptor.appleEvent(withEventClass: AEEventClass(kInternetEventClass),
      eventID: AEEventID(kAEGetURL), targetDescriptor: .null(), returnID: AEReturnID(kAutoGenerateReturnID),
      transactionID: AETransactionID(kAnyTransactionID))
    event.setParam(NSAppleEventDescriptor(string: "huda://prayer_times"), forKeyword: AEKeyword(keyDirectObject))
    var reply = AppleEvent()
    XCTAssertEqual(handler.handle(event.aeDesc, reply: &reply), -50)
    XCTAssertEqual(MacPrayerServiceTests.forwardedEvents, 1)
    XCTAssertEqual(MacPrayerServiceTests.forwardedRefcon, sentinel)
  }
  func testNativeQueueSharesCapacityAndSchedulesAbsoluteNonrepeatingInstants() throws {
    let fake = FakePrayerNotifications()
    for id in 1000..<1015 {
      fake.pending[String(id)] = UNNotificationRequest(identifier: String(id), content: UNMutableNotificationContent(),
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false))
    }
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    let status = try configure(service)
    XCTAssertEqual(status["pendingCount"] as? Int, 45)
    XCTAssertEqual(fake.pending.count, 61) // + the renewal notice, outside the budget
    XCTAssertNotNil(status["coverageMillis"] as? Double)
    XCTAssertTrue(fake.removals.allSatisfy { $0 == "299999999" || (Int($0).map { $0 >= 300_000_000 } ?? false) })
    for request in fake.pending.values.filter(MacPrayerService.isPrayerRequest) {
      let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
      XCTAssertFalse(trigger.repeats)
      XCTAssertEqual(trigger.dateComponents.timeZone, TimeZone(secondsFromGMT: 0))
      XCTAssertNil(request.content.sound)
      XCTAssertEqual(request.content.userInfo["presentSound"] as? Bool, false)
      XCTAssertNotEqual((request.content.userInfo["hudaEvent"] as? [String: Any])?["prayer"] as? String, "sunrise")
    }
  }
  func testRenewalNoticeFollowsCoverageOutsideThePrayerBudget() throws {
    let fake = FakePrayerNotifications()
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    let status = try configure(service)
    let renewal = try XCTUnwrap(fake.pending[MacPrayerService.renewalIdentifier])
    XCTAssertFalse(MacPrayerService.isPrayerRequest(renewal))
    XCTAssertNil(renewal.content.sound)
    let coverage = Date(timeIntervalSince1970: try XCTUnwrap(status["coverageMillis"] as? Double) / 1000)
    let fire = try XCTUnwrap((renewal.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate())
    XCTAssertEqual(fire.timeIntervalSince(coverage), -86400 + 900, accuracy: 1)
    // A full prayer queue beside it: the notice doesn't take a prayer's slot.
    XCTAssertEqual(status["pendingCount"] as? Int, 50)
    XCTAssertEqual(try configure(service)["pendingCount"] as? Int, 50)
  }
  func testReadbackDoesNotClaimCoverageForDiscardedRequests() throws {
    let fake = FakePrayerNotifications(); fake.discardAccepted = true
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    let status = try configure(service)
    XCTAssertEqual(status["pendingCount"] as? Int, 0)
    XCTAssertTrue(status["coverageMillis"] is NSNull)
    XCTAssertNotNil(status["error"] as? String)
    XCTAssertEqual((status["events"] as? [[String: Any]])?.count, 0)
  }
  func testUnchangedPublicationAndQueueRenewalDoNotReplaceRequests() throws {
    let fake = FakePrayerNotifications()
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    let original = try configure(service)
    let additions = fake.additions
    let renewed = try configure(service)
    XCTAssertEqual(renewed["revision"] as? Int64, original["revision"] as? Int64)
    XCTAssertEqual(fake.additions, additions)
    XCTAssertEqual(renewed["pendingCount"] as? Int, 50)
  }
  func testQueueReadbackRepairsAnIncorrectInterruptionLevel() throws {
    guard #available(macOS 12.0, *) else { return }
    let fake = FakePrayerNotifications()
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    _ = try configure(service)
    let original = try XCTUnwrap(fake.pending.values.first)
    let content = original.content.mutableCopy() as! UNMutableNotificationContent
    content.interruptionLevel = .timeSensitive
    fake.pending[original.identifier] = UNNotificationRequest(identifier: original.identifier, content: content, trigger: original.trigger)
    let additions = fake.additions
    _ = apply(service, method: "status")
    XCTAssertEqual(fake.additions, additions + 1)
    XCTAssertEqual(fake.pending[original.identifier]?.content.interruptionLevel, .active)
  }
  func testPresentationRefreshPreservesLegacyShortSoundNearPrayer() throws {
    var config = MacPrayerConfiguration(); config.legacyNotifications = true
    try MacPrayerStore(directory: directory).save(config)
    var values = try schedule()
    let base = try MacPrayerJSON.decode(MacPrayerSchedule.self, values)
    let fajr = try XCTUnwrap(base.times(on: Date())["fajr"])
    var offsets = values["offsets"] as! [String: Int]
    offsets["fajr"] = Int(ceil(Date().addingTimeInterval(60).timeIntervalSince(fajr) / 60))
    values["offsets"] = offsets
    let fake = FakePrayerNotifications()
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    _ = apply(service, method: "configure", values: ["expectedRevision": service.configuration.revision,
      "schedule": values, "configurationSignature": "legacy-near-due"])
    let imminent = try XCTUnwrap(fake.pending.values.first {
      ($0.content.userInfo["hudaEvent"] as? [String: Any])?["prayer"] as? String == "fajr" &&
        (($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()?.timeIntervalSinceNow ?? 999) < 120
    })
    XCTAssertNotNil(imminent.content.sound)
    _ = apply(service, method: "setPresentation", values: ["locale": "en", "primaryColor": 0xFF134E4A,
      "themeMode": "dark", "use24HourClock": true, "strings": ["fajrTitle": "Changed title"]])
    XCTAssertTrue(service.configuration.legacyNotifications)
    XCTAssertNotNil(fake.pending[imminent.identifier]?.content.sound)
  }
  func testNotificationPreviewUsesIndependentIdentityAndDoesNotClaimAPrayer() throws {
    let fake = FakePrayerNotifications()
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    _ = try configure(service)
    _ = apply(service, method: "previewNotification", values: ["sessionId": "preview:unit-test",
      "experience": MacPrayerExperience().dictionary()])
    XCTAssertEqual(fake.pending["299999999"]?.content.userInfo["hudaPreview"] as? Bool, true)
    XCTAssertEqual(fake.pending.filter { MacPrayerService.isPrayerRequest($0.value) }.count, 50)
    XCTAssertTrue(service.ledger.claims.isEmpty)
    _ = apply(service, method: "stopPreview", values: ["sessionId": "preview:stale"])
    XCTAssertNotNil(fake.pending["299999999"])
    _ = apply(service, method: "stopPreview", values: ["sessionId": "preview:unit-test"])
    XCTAssertNil(fake.pending["299999999"])
    XCTAssertEqual(fake.pending.count, 51) // + the renewal notice
  }
  func testRequestIdentityUsesSourcePrayerDayAcrossDateOffsets() throws {
    let location = try MacPrayerJSON.decode(MacPrayerSchedule.self, schedule()).location
    let instant = ISO8601DateFormatter().date(from: "2026-10-10T07:00:00Z")!
    let first = MacPrayerEvent(prayer: "isha", instant: instant, civilDay: "2026-10-04",
      location: location, revision: 1, signature: "offset")
    let other = MacPrayerEvent(prayer: "isha", instant: instant.addingTimeInterval(60), civilDay: "2026-10-10",
      location: location, revision: 2, signature: "updated")
    let shifted = MacPrayerEvent(prayer: "isha", instant: instant.addingTimeInterval(86400), civilDay: first.civilDay,
      location: location, revision: 3, signature: "shifted")
    XCTAssertNotEqual(first.notificationIdentifier, other.notificationIdentifier)
    XCTAssertEqual(first.notificationIdentifier, shifted.notificationIdentifier)
    XCTAssertEqual(first.dictionary(strings: [:])["occurrenceKey"] as? String, first.key)
  }
  func testCrossDateCutoverKeepsBothImminentNotificationIdentities() throws {
    var values = try schedule()
    let base = try MacPrayerJSON.decode(MacPrayerSchedule.self, values)
    var calendar = Calendar(identifier: .gregorian); calendar.timeZone = base.location.zone
    let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: Date()))
    let rawTomorrow = try XCTUnwrap(base.times(on: tomorrow)["isha"])
    var offsets = values["offsets"] as! [String: Int]
    offsets["isha"] = Int(ceil(Date().addingTimeInterval(45).timeIntervalSince(rawTomorrow) / 60))
    values["offsets"] = offsets
    let fake = FakePrayerNotifications()
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    _ = apply(service, method: "configure", values: ["expectedRevision": service.configuration.revision,
      "schedule": values, "configurationSignature": "cross-date-before"])
    let key = "\(base.dayKey(tomorrow))/isha"
    let original = try XCTUnwrap(fake.pending.values.first { $0.content.userInfo["hudaKey"] as? String == key })
    let instant = try XCTUnwrap((original.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate())
    let later = instant.addingTimeInterval(60)
    guard calendar.isDate(instant, inSameDayAs: later) else { throw XCTSkip("Two near-midnight instants cross the civil-day boundary.") }
    let rawToday = try XCTUnwrap(base.times(on: Date())["isha"])
    offsets["isha"] = Int(round(later.timeIntervalSince(rawToday) / 60))
    values["offsets"] = offsets
    let status = apply(service, method: "configure", values: ["expectedRevision": service.configuration.revision,
      "schedule": values, "configurationSignature": "cross-date-after"])
    let retained = try XCTUnwrap(fake.pending[original.identifier])
    XCTAssertEqual(retained.content.userInfo["hudaKey"] as? String, key)
    XCTAssertEqual((retained.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate(), instant)
    let replacementKey = "\(base.dayKey(Date()))/isha"
    let replacement = try XCTUnwrap(fake.pending.values.first { $0.content.userInfo["hudaKey"] as? String == replacementKey })
    XCTAssertNotEqual(retained.identifier, replacement.identifier)
    XCTAssertEqual((replacement.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate(), later)
    XCTAssertEqual(status["pendingCount"] as? Int, 50)
    XCTAssertTrue(status["error"] is NSNull)
  }
  func testCommitmentKeepsEmergencyExitAndPreservesDeadlineAcrossDisplayChanges() {
    let panels = MacPrayerPanelController()
    var config = MacPrayerConfiguration(); config.experience.focusCommitment = true
    panels.show(session: "preview:panel-test", prayer: "fajr", time: Date(), zone: .current,
      configuration: config, preview: true)
    defer { panels.dismiss(force: true) }
    let visible = NSApp.windows.filter { String(describing: type(of: $0)) == "MacPrayerPanel" && $0.isVisible }
    XCTAssertEqual(visible.count, 1)
    XCTAssertEqual(visible.first?.frame.size, NSSize(width: 420, height: 480))
    XCTAssertEqual(visible.first?.level, .screenSaver)
    visible.first?.contentView?.layoutSubtreeIfNeeded()
    XCTAssertEqual(visible.first?.frame.size, NSSize(width: 420, height: 480))
    let deadline = panels.deadline
    XCTAssertFalse(panels.canDismiss)
    panels.dismiss(session: "preview:panel-test")
    XCTAssertEqual(panels.session, "preview:panel-test")
    NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
    XCTAssertEqual(panels.deadline, deadline)
    panels.dismiss(session: "preview:stale", force: true)
    XCTAssertNotNil(panels.session)
    panels.dismiss(force: true)
    XCTAssertNil(panels.session)
  }
  func testPartialReplacementRetainsWorkingQueueAndGenericReminders() throws {
    let fake = FakePrayerNotifications()
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    _ = try configure(service)
    let before = fake.pending
    // The production cutover intentionally preserves policies within two
    // minutes of prayer. Reject a distant replacement so this test is stable
    // even when the suite happens to run near an actual prayer time.
    let identifier = try XCTUnwrap(before.values.filter {
      (($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()?.timeIntervalSinceNow ?? 0) > 300
    }.map(\.identifier).sorted().first)
    fake.rejected.insert(identifier)
    let status = apply(service, method: "setPresentation", values: ["locale": "en", "primaryColor": 0xFF134E4A,
      "themeMode": "dark", "use24HourClock": true, "strings": ["fajrTitle": "Changed title"]])
    XCTAssertNotNil(status["error"] as? String)
    XCTAssertNotNil(fake.pending[identifier])
    XCTAssertEqual(fake.pending[identifier]?.content.title, before[identifier]?.content.title)
    let renewal = MacPrayerService.renewalIdentifier
    XCTAssertEqual(fake.pending.keys.filter { $0 != renewal }.count, before.keys.filter { $0 != renewal }.count)
  }
  func testDisableStopsNativeRequestsButLeavesOtherReminders() throws {
    let fake = FakePrayerNotifications()
    fake.pending["1004"] = UNNotificationRequest(identifier: "1004", content: UNMutableNotificationContent(), trigger: nil)
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    _ = try configure(service)
    var policy = MacPrayerExperience(); policy.enabled = false; policy.configured = true
    let status = apply(service, method: "setExperience", values: ["experience": policy.dictionary(),
      "expectedRevision": service.configuration.revision])
    XCTAssertEqual(status["pendingCount"] as? Int, 0)
    XCTAssertEqual(Set(fake.pending.keys), ["1004"])
    XCTAssertEqual(fake.permissionRequests, 0)
  }
  func testDisabledRemindersReportRequestsThatSurviveCancellation() throws {
    let fake = FakePrayerNotifications()
    let service = MacPrayerService(directory: directory, notifications: fake)
    service.start(); defer { service.stop() }
    _ = try configure(service)
    fake.discardRemovals = true
    var policy = MacPrayerExperience(); policy.enabled = false; policy.configured = true
    let status = apply(service, method: "setExperience", values: ["experience": policy.dictionary(),
      "expectedRevision": service.configuration.revision])
    XCTAssertEqual(status["pendingCount"] as? Int, 50)
    XCTAssertNotNil(status["error"] as? String)
    XCTAssertTrue(status["coverageMillis"] is NSNull)
  }
  func testLedgerClaimsBeforeEffectsAndSurvivesRelaunch() throws {
    let now = Date()
    let ledger = MacPrayerLedger(directory: directory)
    XCTAssertTrue(try ledger.claim("2026-10-10/fajr", at: now))
    ledger.notificationOutcome("2026-10-10/fajr", "presented")
    ledger.outcome("2026-10-10/fajr", playback: "suppressed", overlay: "notRequested")
    let saved = try XCTUnwrap(MacPrayerLedger(directory: directory).claims["2026-10-10/fajr"])
    XCTAssertEqual(saved.notification, "presented")
    XCTAssertEqual(saved.playback, "suppressed")
    XCTAssertEqual(saved.overlay, "notRequested")
    XCTAssertFalse(try MacPrayerLedger(directory: directory).claim("2026-10-10/fajr", at: now))
    try Data("corrupt".utf8).write(to: directory.appendingPathComponent("occurrences.json"))
    XCTAssertThrowsError(try MacPrayerLedger(directory: directory).claim("2026-10-10/dhuhr", at: now))
  }
  func testColdWakeExpiryAndGracePolicy() {
    let now = Date()
    XCTAssertTrue(MacPrayerDuePolicy.shouldDeliver(instant: now.addingTimeInterval(-60), now: now, continuouslyRunning: true))
    XCTAssertFalse(MacPrayerDuePolicy.shouldDeliver(instant: now.addingTimeInterval(-61), now: now, continuouslyRunning: true))
    XCTAssertFalse(MacPrayerDuePolicy.shouldDeliver(instant: now, now: now, continuouslyRunning: false))
  }
  func testBundledFullAndShortAssetsAreIndependentAndVerified() throws {
    let audio = MacPrayerAudio(directory: directory)
    _ = try audio.paths()
    XCTAssertTrue(audio.isReady(MacPrayerExperience()))
    // The independently normalized clip is packaged as a signed root-bundle WAV.
    XCTAssertFalse(FileManager.default.fileExists(atPath: audio.bundledDirectory.appendingPathComponent("v1/huda-default/notification.caf").path))
    let sound = try audio.notificationSound(MacPrayerExperience())
    XCTAssertTrue(sound.hasPrefix("huda-short-")); XCTAssertTrue(sound.hasSuffix(".wav"))
    let packaged = try AVAudioFile(forReading: audio.notificationDirectory.appendingPathComponent(sound))
    XCTAssertEqual(packaged.fileFormat.streamDescription.pointee.mFormatID, kAudioFormatLinearPCM)
    XCTAssertEqual(Double(packaged.length) / packaged.fileFormat.sampleRate, 18.131, accuracy: 0.05)
  }
  func testAllSharedCatalogRecitersHaveVerifiedBundledShortSounds() throws {
    let audio = MacPrayerAudio(directory: directory)
    let manifest = try JSONSerialization.jsonObject(with: Data(contentsOf: audio.notificationDirectory.appendingPathComponent("huda_notification_sounds.json"))) as! [String: Any]
    let entries = manifest["sounds"] as! [[String: Any]]
    XCTAssertEqual(entries.count, 6)
    for entry in entries {
      let url = audio.notificationDirectory.appendingPathComponent(entry["filename"] as! String)
      let data = try Data(contentsOf: url)
      XCTAssertEqual(data.count, entry["bytes"] as? Int)
      let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
      XCTAssertEqual(digest, entry["sha256"] as? String)
      XCTAssertEqual(entry["filename"] as? String, "huda-short-\(digest.prefix(16)).wav")
      let file = try AVAudioFile(forReading: url)
      XCTAssertEqual(file.fileFormat.streamDescription.pointee.mFormatID, kAudioFormatLinearPCM)
      XCTAssertLessThan(Double(file.length) / file.fileFormat.sampleRate, 30)
    }
  }
  func testDownloadedClipResolvesToItsBundledSoundByHash() throws {
    // A small bundle: the real default plus one clip made from a known source.
    let bundleURL = directory.appendingPathComponent("Fake.bundle", isDirectory: true)
    let adhan = bundleURL.appendingPathComponent("Adhan/v1/huda-default", isDirectory: true)
    try FileManager.default.createDirectory(at: adhan, withIntermediateDirectories: true)
    let real = MacPrayerAudio(directory: directory)
    for name in ["manifest.json", "full.mp3"] {
      try FileManager.default.copyItem(at: real.bundledDirectory.appendingPathComponent("v1/huda-default/\(name)"),
        to: adhan.appendingPathComponent(name))
    }
    let defaultEntry = (try JSONSerialization.jsonObject(with: Data(contentsOf: real.notificationDirectory
      .appendingPathComponent("huda_notification_sounds.json"))) as! [String: Any])["sounds"] as! [[String: Any]]
    let builtIn = defaultEntry.first { $0["reciter_id"] as? String == "huda-default" }!
    try FileManager.default.copyItem(at: real.notificationDirectory.appendingPathComponent(builtIn["filename"] as! String),
      to: bundleURL.appendingPathComponent(builtIn["filename"] as! String))
    let format = try XCTUnwrap(AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false))
    let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16_000))
    buffer.frameLength = 16_000
    for i in 0..<16_000 { buffer.floatChannelData![0][i] = sin(Float(i) * 0.1) * 0.5 }
    let source = directory.appendingPathComponent("source.wav")
    do {
      let wav = try AVAudioFile(forWriting: source, settings: [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 16_000,
        AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16], commonFormat: .pcmFormatFloat32, interleaved: false)
      try wav.write(from: buffer)
    }
    // Downloaded clips are bundled as downloaded.
    func sha(_ url: URL) throws -> String { SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined() }
    let clipHash = try sha(source), sourceHash = clipHash
    let clipName = "huda-short-\(clipHash.prefix(16)).wav"
    try FileManager.default.copyItem(at: source, to: bundleURL.appendingPathComponent(clipName))
    let clipBytes = try Data(contentsOf: bundleURL.appendingPathComponent(clipName)).count
    try JSONSerialization.data(withJSONObject: ["schema_version": 1, "audio_version": "v1", "sounds": [builtIn,
      ["reciter_id": "nasser-al-qatami", "source_sha256": sourceHash, "filename": clipName, "sha256": clipHash, "bytes": clipBytes]]])
      .write(to: bundleURL.appendingPathComponent("huda_notification_sounds.json"))
    let audio = MacPrayerAudio(directory: directory, bundle: try XCTUnwrap(Bundle(url: bundleURL)))
    var policy = MacPrayerExperience(); policy.reciterId = "nasser-al-qatami"
    let folder = audio.cacheDirectory.appendingPathComponent("v1/nasser-al-qatami")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    try FileManager.default.copyItem(at: source, to: folder.appendingPathComponent("notification.wav"))
    let bytes = try Data(contentsOf: source).count
    try JSONSerialization.data(withJSONObject: ["audio_version": "v1", "reciter": ["id": policy.reciterId,
      "notification": ["bytes": bytes, "sha256": sourceHash]]]).write(to: folder.appendingPathComponent("manifest.json"))
    XCTAssertEqual(try audio.notificationSound(policy), clipName)
    XCTAssertNil(audio.error)
    // A corrupt downloaded source cannot bypass verification by matching ID.
    try Data([0]).write(to: folder.appendingPathComponent("notification.wav"))
    XCTAssertEqual(try audio.notificationSound(policy), builtIn["filename"] as? String)
    XCTAssertNotNil(audio.error)
  }
  func testMissingSelectedShortSoundFallsBackWithoutReportingReady() throws {
    let audio = MacPrayerAudio(directory: directory)
    var policy = MacPrayerExperience(); policy.reciterId = "mishary-rashid-alafasy"
    XCTAssertFalse(audio.isReady(policy))
    let defaultSound = try audio.notificationSound(MacPrayerExperience())
    XCTAssertEqual(try audio.notificationSound(policy), defaultSound)
    XCTAssertNotNil(audio.error)
  }
  func testAudioCutoffRunsWhileAppKitIsTrackingMenuInput() {
    let audio = MacPrayerAudio(directory: directory)
    defer { audio.stop() }
    var policy = MacPrayerExperience(); policy.volume = 0; policy.stopAfterSeconds = 1
    XCTAssertTrue(audio.play(policy, session: "preview:cutoff-test"))
    let deadline = Date().addingTimeInterval(1.5)
    while Date() < deadline && audio.session != nil {
      _ = RunLoop.main.run(mode: .eventTracking, before: deadline)
    }
    XCTAssertNil(audio.session)
  }
}
