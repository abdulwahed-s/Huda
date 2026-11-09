import Foundation
import UIKit
import UserNotifications
import WidgetKit
import CoreLocation

actor IOSPrayerService {
  static let shared = IOSPrayerService()
  private let store: IOSPrayerStore
  private let notifications = IOSPrayerNotificationScheduler()
  private let alarms = IOSPrayerAlarmScheduler()
  private let audio = IOSPrayerAudioStore()
  private var running = false
  private let groupAvailable: Bool
  init(directory: URL? = nil) {
    let group = directory ?? IOSPrayerStore.sharedDirectory
    groupAvailable = group != nil
    store = IOSPrayerStore(directory: group ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("IOSPrayer"))
  }
  private func capabilities(_ state: IOSPrayerState) async -> (IOSPrayerCapabilities, UNNotificationSettings) {
    let settings = await notifications.center.notificationSettings()
    var c = IOSPrayerCapabilities()
    c.notifications = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
    c.notificationSound = settings.soundSetting == .enabled
    c.supportsAlarms = alarms.supportsAlarms
    c.alarms = alarms.authorization == "authorized"
    c.customAlarmSound = alarms.customSoundSupported
    if c.customAlarmSound { c.fullAlarmSound = IOSPrayerAudioStore.bundledFullSound }
    if Bundle.main.url(forResource: "adhan", withExtension: "caf") == nil { c.installedShort = [:] }
    for installed in state.installedAudio.values where installed.version == state.configuration.experience.audioVersion && audio.ready(installed) {
      c.installedShort[installed.reciterId] = installed.shortName
    }
    return (c, settings)
  }
  func configure(expectedRevision: Int64, schedule: IOSPrayerSchedule?, signature: String?,
    experience: IOSPrayerExperience?, strings: [String: String]?, migration: String?,
    ownershipUntil: Date? = nil, nativeNotBefore: Date? = nil, locationRevisionFloor: Int64? = nil) async throws -> [String: Any] {
    guard groupAvailable else { throw IOSPrayerError.invalid("appGroupUnavailable") }
    guard !running else { throw IOSPrayerError.invalid("busy") }
    running = true; defer { running = false }
    try store.beginExclusive(); defer { store.endExclusive() }
    var state = try store.load()
    guard state.operation == nil else {
      try await reconcileLocked(&state)
      throw IOSPrayerError.invalid("revisionChanged")
    }
    guard expectedRevision == state.configuration.revision else { throw IOSPrayerError.invalid("revisionChanged") }
    var proposed = state.configuration
    if let schedule {
      try schedule.validate()
      if let accepted = proposed.schedule, schedule.location.revision < accepted.location.revision { throw IOSPrayerError.invalid("locationSuperseded") }
      proposed.schedule = schedule
    }
    if let signature { proposed.configurationSignature = signature }
    if let locationRevisionFloor { proposed.locationRevisionFloor = max(proposed.locationRevisionFloor ?? 0, locationRevisionFloor) }
    if let experience { try experience.validate(); proposed.experience = experience }
    if let strings { proposed.strings = strings }
    if let migration {
      guard !["native", "retired"].contains(proposed.migration) || ["native", "retired"].contains(migration) else { throw IOSPrayerError.invalid("migrationRegression") }
      proposed.migration = migration
      proposed.legacyOwnershipUntil = ownershipUntil
      proposed.nativeNotBefore = nativeNotBefore
    }
    try proposed.validate()
    if proposed != state.configuration {
      proposed.revision += 1
      if proposed.experience != state.configuration.experience { proposed.policyRevision += 1 }
      state.operation = IOSPrayerOperation(configuration: proposed, desired: [], started: Date())
      try store.save(state)
    }
    try await reconcileLocked(&state)
    return await statusLocked(state)
  }
  func reconcile() async throws -> [String: Any] {
    guard !running else { throw IOSPrayerError.invalid("busy") }
    running = true; defer { running = false }
    try store.beginExclusive(); defer { store.endExclusive() }
    var state = try store.load()
    try await reconcileLocked(&state)
    return await statusLocked(state)
  }
  func adoptTravel(_ fix: CLLocation, resolved: PrayerResolvedAppleLocation?) async throws -> Bool {
    try Task.checkCancellation()
    guard !running else { throw IOSPrayerError.invalid("busy") }
    running = true; defer { running = false }
    try store.beginExclusive(); defer { store.endExclusive() }
    var state = try store.load()
    let defaults = UserDefaults.standard
    guard defaults.bool(forKey: "flutter.prayer_background_travel_enabled"),
      defaults.string(forKey: "flutter.prayer_location_mode") == "automatic",
      ["native", "retired"].contains(state.configuration.migration),
      let old = state.configuration.schedule, old.location.mode == "automatic" else { return false }
    guard Date().timeIntervalSince(fix.timestamp) <= 1800, fix.timestamp.timeIntervalSinceNow <= 120,
      fix.horizontalAccuracy >= 0, fix.horizontalAccuracy <= 5000 else { return false }
    let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let previousDate = formatter.date(from: old.location.capturedAtUtc) ?? ISO8601DateFormatter().date(from: old.location.capturedAtUtc)
    guard previousDate == nil || fix.timestamp > previousDate! else { return false }
    guard let resolved, TimeZone(identifier: resolved.timeZoneId) != nil,
      old.methodToken != "auto" || resolved.countryCode != nil else {
      state.travelPending = true; try store.save(state); return false
    }
    let previous = CLLocation(latitude: old.location.latitude, longitude: old.location.longitude)
    if fix.distance(from: previous) < 5000, resolved.timeZoneId == old.location.timeZoneId,
      resolved.countryCode == old.location.countryCode { state.travelPending = false; try store.save(state); return true }
    let revision = max(old.location.revision, state.configuration.locationRevisionFloor ?? 0) + 1
    var wire = try IOSPrayerJSON.object(old)
    wire["deviceTimeZoneId"] = TimeZone.current.identifier
    wire["location"] = ["schemaVersion": 1, "revision": revision, "mode": "automatic",
      "latitude": fix.coordinate.latitude, "longitude": fix.coordinate.longitude,
      "timeZoneId": resolved.timeZoneId, "timeZoneProvenance": "coordinateResolved",
      "countryCode": resolved.countryCode as Any? ?? NSNull(), "locality": NSNull(), "countryName": NSNull(),
      "capturedAtUtc": IOSPrayerJSON.iso(fix.timestamp), "committedAtUtc": IOSPrayerJSON.iso(Date()),
      "source": "iosSignificantChange", "accuracyMeters": fix.horizontalAccuracy,
      "verificationReasons": [], "resolutionSource": "applePlacemark", "countryCandidates": []] as [String: Any]
    let schedule = try IOSPrayerJSON.decode(IOSPrayerSchedule.self, wire); try schedule.validate()
    var proposed = state.configuration
    proposed.schedule = schedule; proposed.locationRevisionFloor = revision; proposed.revision += 1
    proposed.configurationSignature = "native-travel:\(IOSPrayerOccurrence.digest(String(decoding: try JSONSerialization.data(withJSONObject: wire, options: .sortedKeys), as: UTF8.self)))"
    state.travelPending = false
    try Task.checkCancellation()
    state.operation = IOSPrayerOperation(configuration: proposed, desired: [], started: Date())
    try store.save(state); try await reconcileLocked(&state)
    return true
  }
  private func reconcileLocked(_ state: inout IOSPrayerState) async throws {
    let now = Date()
    state.lastAttempt = now
    let proposed = state.operation?.configuration ?? state.configuration
    if !groupAvailable { throw IOSPrayerError.invalid("appGroupUnavailable") }
    // Pending legacy enrollment retains its existing local/server boundary.
    // Preparing a native configuration never creates overlapping ownership.
    if proposed.migration == "pending" || proposed.migration == "uninitialized" || proposed.schedule == nil {
      state.configuration = proposed; state.operation = nil
      state.error = proposed.migration == "pending" ? "migrationPending" : nil
      try store.save(state); return
    }
    state.configuration = proposed
    let interrupted = state.operation?.desired ?? []
    // Retirement and its boundary are durable before removing legacy requests.
    // Retained imminent legacy alerts still count against the OS queue budget.
    await notifications.removeLegacy(preserveThrough: proposed.experience.enabled ? proposed.nativeNotBefore : nil)
    let (c, _) = await capabilities(state)
    var snapshot = await notifications.snapshot()
    var alarmSnapshot = try alarms.snapshot()
    let schedule = proposed.schedule!
    let all = IOSPrayerPlanner.occurrences(schedule: schedule, experience: proposed.experience, capabilities: c,
      now: now, revision: proposed.revision, signature: proposed.configurationSignature, strings: proposed.strings)
    let expected = all.filter { event in
      guard state.outcomes[event.key] == nil else { return false }
      return proposed.nativeNotBefore == nil || event.instant >= proposed.nativeNotBefore!
    }
    let previews = snapshot.requests.values.filter { $0.identifier.hasPrefix(IOSPrayerNotificationScheduler.previewPrefix) }.count
    let desired = IOSPrayerPlanner.allocate(expected, otherNotifications: snapshot.otherCount,
      reservedNotifications: 1 + previews, alarmHorizon: now.addingTimeInterval(10 * 86400))
    state.operation = IOSPrayerOperation(configuration: proposed, desired: desired, started: state.operation?.started ?? now)
    state.error = nil
    try store.save(state)
    // The mapping is durable before any OS mutation, including new alarm UUIDs.
    var previous = Dictionary(uniqueKeysWithValues: interrupted.map { ($0.key, $0) })
    previous.merge(state.accepted) { _, accepted in accepted }
    let wanted = Dictionary(uniqueKeysWithValues: desired.map { ($0.key, $0) })
    var preserved: [String: IOSPrayerOccurrence] = [:]
    for old in previous.values {
      if old.instant <= now {
        // Expiration is an inferred outcome; it is never called delivery.
        state.outcomes[old.key] = state.outcomes[old.key] ?? "elapsedUnobserved"
        state.outcomeDates[old.key] = state.outcomeDates[old.key] ?? now
      }
      let active = alarmSnapshot[old.alarmID]?.active == true
      let near = old.instant > now && old.instant.timeIntervalSince(now) <= 120
      let actual = old.policy.backend == "alarm" ? alarmSnapshot[old.alarmID] != nil : snapshot.requests[old.identifier] != nil
      if active || near && actual && proposed.experience.policy(for: old.prayer).mode != .off { preserved[old.key] = old; continue }
      if wanted[old.key] == nil {
        if old.policy.backend == "alarm", alarmSnapshot[old.alarmID] != nil { try alarms.cancel(old.alarmID) }
        notifications.remove([old.identifier])
      }
    }
    // Recover obsolete owned records left by a prior interrupted operation.
    let retainedIDs = Set(desired.map(\.identifier) + preserved.values.map(\.identifier))
    notifications.remove(snapshot.requests.keys.filter {
      !retainedIDs.contains($0) && !$0.hasPrefix(IOSPrayerNotificationScheduler.previewPrefix) && $0 != IOSPrayerNotificationScheduler.renewalIdentifier
    })
    var accepted = preserved
    var alarmSubmissionFailed = false
    for event in desired where preserved[event.key] == nil {
      try Task.checkCancellation()
      guard event.instant > Date(), state.outcomes[event.key] == nil else { continue }
      if alarmSubmissionFailed && event.policy.backend == "alarm" { continue }
      let old = previous[event.key]
      do {
        // Remove the old backend before submitting the new one. A crash leaves
        // a journaled gap that recovery repairs, never two live owners.
        if let old, old.policy.backend != event.policy.backend {
          if old.policy.backend == "alarm", alarmSnapshot[old.alarmID] != nil { try alarms.cancel(old.alarmID) }
          else { notifications.remove([old.identifier]) }
        }
        if event.policy.backend == "alarm" {
          if let existing = alarmSnapshot[event.alarmID] {
            if existing.active { accepted[event.key] = old ?? event; continue }
            if existing.instant != event.instant || old?.policy != event.policy || old?.eventJSON != event.eventJSON {
              try alarms.cancel(event.alarmID)
              try await alarms.submit(event)
            }
          } else { try await alarms.submit(event) }
        } else if !notifications.matches(snapshot.requests[event.identifier], event) { try await notifications.submit(event) }
      } catch is CancellationError { throw CancellationError() }
      catch {
        state.error = event.policy.backend == "alarm" ? "alarmSubmitFailed" : "notificationSubmitFailed"
        // Retain already accepted near-term records on a backend limit error.
        if event.policy.backend == "alarm" { alarmSubmissionFailed = true }
      }
    }
    snapshot = await notifications.snapshot()
    alarmSnapshot = try alarms.snapshot()
    for event in desired where preserved[event.key] == nil {
      if event.policy.backend == "alarm" {
        if let record = alarmSnapshot[event.alarmID], record.instant == event.instant || record.active { accepted[event.key] = event }
      } else if notifications.matches(snapshot.requests[event.identifier], event) { accepted[event.key] = event }
    }
    state.accepted = accepted
    state.primaryCoverage = IOSPrayerPlanner.coverage(expected, accepted: accepted, kind: "main")
    state.optionalCoverage = IOSPrayerPlanner.coverage(expected, accepted: accepted, kind: "advance")
    state.perPrayerCoverage = [:]
    for prayer in IOSPrayerSchedule.obligatory {
      state.perPrayerCoverage[prayer] = IOSPrayerPlanner.coverage(expected.filter { $0.prayer == prayer }, accepted: accepted, kind: "main")
    }
    let expectedMain = expected.filter { $0.kind == "main" }
    if !expectedMain.isEmpty, state.primaryCoverage == nil { state.error = state.error ?? "noAcceptedCoverage" }
    if state.error == nil { state.lastSuccess = now }
    state.outcomeDates = state.outcomeDates.filter { now.timeIntervalSince($0.value) < 400 * 86400 }
    state.outcomes = state.outcomes.filter { state.outcomeDates[$0.key] != nil }
    state.operation = nil
    try store.save(state)
    do { try await notifications.renewal(coverage: state.primaryCoverage, strings: proposed.strings, enabled: proposed.experience.enabled && c.notifications) }
    catch { state.error = state.error ?? "renewalSubmitFailed"; try store.save(state) }
    await MainActor.run { WidgetCenter.shared.reloadTimelines(ofKind: "HudaPrayerWidget") }
  }
  func status() async throws -> [String: Any] { await statusLocked(try store.load()) }
  private func statusLocked(_ state: IOSPrayerState) async -> [String: Any] {
    let (c, settings) = await capabilities(state)
    let snapshot = await notifications.snapshot()
    let actualAlarms = (try? alarms.snapshot()) ?? [:]
    let actual = state.accepted.values.filter { occurrence in
      occurrence.policy.backend == "alarm" ? actualAlarms[occurrence.alarmID] != nil : notifications.matches(snapshot.requests[occurrence.identifier], occurrence)
    }.sorted { $0.instant < $1.instant }
    var policies: [String: Any] = [:]
    for prayer in IOSPrayerSchedule.obligatory {
      let policy = state.configuration.experience.policy(for: prayer)
      policies[prayer] = try? IOSPrayerJSON.object(IOSPrayerEffectivePolicy.resolve(policy.mode, reciter: policy.reciterId,
        fallback: state.configuration.experience.fallback, capabilities: c))
    }
    func millis(_ date: Date?) -> Any { date.map { $0.timeIntervalSince1970 * 1000 } ?? NSNull() }
    let permission: String
    switch settings.authorizationStatus {
    case .authorized: permission = "authorized"
    case .provisional: permission = "provisional"
    case .ephemeral: permission = "ephemeral"
    case .denied: permission = "denied"
    case .notDetermined: permission = "notDetermined"
    @unknown default: permission = "unknown"
    }
    var coverage = state.primaryCoverage
    if let firstMissing = state.accepted.values.filter({ $0.kind == "main" && $0.instant > Date() && !actual.contains($0) }).min(by: { $0.instant < $1.instant }),
      coverage != nil && firstMissing.instant <= coverage! { coverage = actual.last(where: { $0.kind == "main" && $0.instant < firstMissing.instant })?.instant }
    return ["schemaVersion": 1, "revision": state.configuration.revision, "policyRevision": state.configuration.policyRevision,
      "configurationSignature": state.configuration.configurationSignature, "ready": state.configuration.schedule != nil,
      "schedule": (try? state.configuration.schedule.map { try IOSPrayerJSON.object($0) }) ?? NSNull(),
      "experience": (try? IOSPrayerJSON.object(state.configuration.experience)) ?? [:], "policies": policies,
      "notificationAuthorization": permission, "notificationSound": c.notificationSound,
      "timeSensitiveAllowed": settings.timeSensitiveSetting == .enabled,
      "alarmAuthorization": alarms.authorization, "supportsAlarms": c.supportsAlarms,
      "fullAlarmAvailable": c.supportsAlarms && c.fullAlarmSound != nil,
      "supportsSiri": ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 16,
      "backgroundRefresh": await MainActor.run { UIApplication.shared.backgroundRefreshStatus == .available },
      "lowPowerMode": ProcessInfo.processInfo.isLowPowerModeEnabled,
      "notificationCount": snapshot.requests.count, "otherNotificationCount": snapshot.otherCount,
      "alarmCount": actual.filter { $0.policy.backend == "alarm" }.count,
      "coverageMillis": millis(coverage), "optionalCoverageMillis": millis(state.optionalCoverage),
      "perPrayerCoverage": state.perPrayerCoverage.mapValues { $0.timeIntervalSince1970 * 1000 },
      "nextAlertMillis": millis(actual.first(where: { $0.kind == "main" && $0.instant > Date() })?.instant),
      "lastAttemptMillis": millis(state.lastAttempt), "lastSuccessMillis": millis(state.lastSuccess),
      "migration": state.configuration.migration, "travelPending": state.travelPending,
      "error": state.error ?? NSNull(), "backgroundError": state.backgroundError ?? NSNull(),
      "events": actual.filter { $0.kind == "main" && $0.instant > Date() }.map(\.eventDictionary)]
  }
  func installAudio(arguments: [String: Any]) async throws -> [String: Any] {
    guard !running else { throw IOSPrayerError.invalid("busy") }
    running = true; defer { running = false }
    try store.beginExclusive(); defer { store.endExclusive() }
    guard let path = arguments["path"] as? String, let reciter = arguments["reciterId"] as? String,
      let version = arguments["audioVersion"] as? String, let bytes = arguments["bytes"] as? Int,
      let hash = arguments["sha256"] as? String, let duration = arguments["durationMs"] as? Int
    else { throw IOSPrayerError.invalid("audioInvalid") }
    var state = try store.load()
    let installed = try audio.install(path: path, reciter: reciter, version: version, bytes: bytes, hash: hash, durationMS: duration)
    state.installedAudio["\(version)/\(reciter)"] = installed
    try store.save(state)
    return await statusLocked(state)
  }
  func observe(key: String, outcome: String, alarmID: UUID? = nil) async throws {
    // Stop the audible alarm even if a concurrent refill owns the store. The
    // observed outcome may be retried; silencing the system alert cannot wait.
    if let alarmID { try alarms.stop(alarmID) }
    guard !running else { throw IOSPrayerError.invalid("busy") }
    try store.beginExclusive(); defer { store.endExclusive() }
    var state = try store.load()
    guard state.accepted[key] != nil || state.operation?.desired.contains(where: { $0.key == key }) == true else { return }
    state.outcomes[key] = outcome; state.outcomeDates[key] = Date()
    try store.save(state)
  }
  func backgroundError(_ category: String?) throws {
    guard !running else { return }
    try store.beginExclusive(); defer { store.endExclusive() }
    var state = try store.load(); state.backgroundError = category; try store.save(state)
  }
  func cancel(ids: Set<Int>? = nil, disable: Bool = false) async throws -> [String: Any] {
    guard !running else { throw IOSPrayerError.invalid("busy") }
    running = true; defer { running = false }
    try store.beginExclusive(); defer { store.endExclusive() }
    var state = try store.load()
    let actualAlarms = try alarms.snapshot()
    let candidates = Array(state.accepted.values) + (state.operation?.desired ?? [])
    for event in candidates where ids == nil || ids!.contains(event.integerID) {
      // Keep the active alarm's mapping so Stop and recovery can still
      // observe it after the user disables future prayer alerts.
      if actualAlarms[event.alarmID]?.active == true { continue }
      notifications.remove([event.identifier])
      if actualAlarms[event.alarmID] != nil, actualAlarms[event.alarmID]?.active != true { try alarms.cancel(event.alarmID) }
      if !disable { state.outcomes[event.key] = "cancelled"; state.outcomeDates[event.key] = Date() }
      state.accepted.removeValue(forKey: event.key)
    }
    if disable {
      state.configuration.experience.enabled = false; state.configuration.revision += 1; state.configuration.policyRevision += 1
      state.operation = nil; state.primaryCoverage = nil; state.optionalCoverage = nil
      state.perPrayerCoverage = [:]
      notifications.remove([IOSPrayerNotificationScheduler.renewalIdentifier])
    }
    try store.save(state)
    return await statusLocked(state)
  }
}
