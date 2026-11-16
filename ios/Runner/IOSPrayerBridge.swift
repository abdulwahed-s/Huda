import Foundation
import Flutter
import UIKit

@MainActor
final class IOSPrayerBridge {
  private let channel: FlutterMethodChannel
  var openPrayerTimes: (() -> Void)?
  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "com.aw.huda/ios_prayer_service", binaryMessenger: messenger)
    IOSPrayerAudioPreview.shared.didStop = { [weak self] in self?.channel.invokeMethod("audioStopped", arguments: nil) }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      guard let arguments = call.arguments as? [String: Any], arguments["schemaVersion"] as? Int == 1 else {
        result(FlutterError(code: "invalidSchema", message: "Invalid prayer bridge version.", details: nil)); return
      }
      Task { @MainActor in
        do {
          let response = try await self.handle(call.method, arguments)
          result(response)
        } catch {
          let category = (error as? IOSPrayerError)?.errorDescription ?? "nativePrayerUnavailable"
          result(FlutterError(code: category, message: "Prayer settings could not be applied.", details: nil))
        }
      }
    }
  }
  func publish(_ status: [String: Any]) { channel.invokeMethod("statusChanged", arguments: status) }
  func publishOpenPrayerTimes() { channel.invokeMethod("openPrayerTimes", arguments: nil) }
  private func handle(_ method: String, _ args: [String: Any]) async throws -> Any {
    let service = IOSPrayerService.shared
    switch method {
    case "status": return try await service.status()
    case "consumeOpenPrayerTimes":
      let defaults = UserDefaults(suiteName: "group.hudaHomeApp")
      let open = defaults?.bool(forKey: "iosPrayerOpenTimes") ?? false
      defaults?.removeObject(forKey: "iosPrayerOpenTimes")
      return open
    case "reconcile":
      let status = try await service.reconcile(); publish(status)
      IOSPrayerBackgroundRefresh.shared.submit(coverage: date(status["coverageMillis"]))
      return status
    case "configure", "setExperience", "setMigration", "setPresentation", "setSahur":
      guard let revision = args["expectedRevision"] as? Int64 else { throw IOSPrayerError.invalid("revisionRequired") }
      let schedule = try args["schedule"].map { try IOSPrayerJSON.decode(IOSPrayerSchedule.self, $0) }
      let experience = try args["experience"].map { try IOSPrayerJSON.decode(IOSPrayerExperience.self, $0) }
      let sahur = try args["sahur"].map { try IOSPrayerJSON.decode(IOSSahurSettings.self, $0) }
      let status = try await service.configure(expectedRevision: revision, schedule: schedule,
        signature: args["configurationSignature"] as? String, experience: experience,
        strings: args["strings"] as? [String: String], migration: args["migration"] as? String,
        ownershipUntil: date(args["ownershipUntilMillis"]), nativeNotBefore: date(args["nativeNotBeforeMillis"]),
        locationRevisionFloor: (args["locationRevisionFloor"] as? NSNumber)?.int64Value, sahur: sahur)
      publish(status); IOSPrayerBackgroundRefresh.shared.submit(coverage: date(status["coverageMillis"]))
      return status
    case "requestNotifications":
      _ = try await IOSPrayerNotificationScheduler().center.requestAuthorization(options: [.alert, .sound, .badge])
      return try await service.reconcile()
    case "requestAlarms":
      try await IOSPrayerAlarmScheduler().requestAuthorization()
      return try await service.reconcile()
    case "openSettings":
      if let url = URL(string: UIApplication.openSettingsURLString) { await UIApplication.shared.open(url) }
      return try await service.status()
    case "installAudio": return try await service.installAudio(arguments: args)
    case "audioPaths":
      let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
      guard IOSPrayerAudioStore.bundledFull != nil else { throw IOSPrayerError.invalid("audioMissing") }
      return ["cache": library.appendingPathComponent("Caches/PrayerAudio").path,
        "bundled": Bundle.main.bundleURL.appendingPathComponent("Adhan").path]
    case "previewAudio":
      guard let path = args["path"] as? String else { throw IOSPrayerError.invalid("audioInvalid") }
      try IOSPrayerAudioPreview.shared.play(path); return try await service.status()
    case "stopAudio": IOSPrayerAudioPreview.shared.stop(); return try await service.status()
    case "testDelivery": return try await testDelivery(args)
    case "cancelTests":
      let scheduler = IOSPrayerNotificationScheduler()
      let snapshot = await scheduler.snapshot()
      scheduler.remove(snapshot.requests.keys.filter { $0.hasPrefix(IOSPrayerNotificationScheduler.previewPrefix) })
      let delivered = await scheduler.center.deliveredNotifications()
      scheduler.center.removeDeliveredNotifications(withIdentifiers: delivered.map { $0.request.identifier }
        .filter { $0.hasPrefix(IOSPrayerNotificationScheduler.previewPrefix) })
      let defaults = UserDefaults.standard
      for value in defaults.stringArray(forKey: "iosPrayerPreviewAlarms") ?? [] {
        if let uuid = UUID(uuidString: value) { try? IOSPrayerAlarmScheduler().cancel(uuid) }
      }
      defaults.removeObject(forKey: "iosPrayerPreviewAlarms")
      return try await service.status()
    case "cancel":
      let ids = (args["ids"] as? [Int]).map { Set($0) }
      return try await service.cancel(ids: ids, disable: args["disable"] as? Bool ?? false)
    default: return FlutterMethodNotImplemented
    }
  }
  private func date(_ value: Any?) -> Date? { (value as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue / 1000) } }
  private func testDelivery(_ args: [String: Any]) async throws -> [String: Any] {
    guard let mode = args["mode"] as? String, let requested = IOSPrayerMode(rawValue: mode), requested != .off else {
      throw IOSPrayerError.invalid("invalidTestMode")
    }
    let service = IOSPrayerService.shared
    let state = try IOSPrayerStore(directory: IOSPrayerStore.sharedDirectory!).load()
    let reciter = args["reciterId"] as? String ?? state.configuration.experience.reciterId
    let version = args["audioVersion"] as? String ?? state.configuration.experience.audioVersion
    // The same files the prayer itself would use.
    let store = IOSPrayerAudioStore()
    let custom = IOSPrayerAlarmScheduler().customSoundSupported
    let defaultReady = store.prepareDefault(full: custom)
    var sound: String? = reciter == "huda-default" && defaultReady ? IOSPrayerAudioStore.defaultShortName : nil
    var capabilities = IOSPrayerCapabilities()
    if custom && defaultReady {
      capabilities.installedFull["huda-default"] = IOSPrayerAudioStore.defaultFullName
      capabilities.installedOpening["huda-default"] = IOSPrayerAudioStore.defaultOpeningName
    }
    if let installed = state.installedAudio["\(version)/\(reciter)"], store.ready(installed) {
      sound = installed.shortName
      if custom && store.fullReady(installed) { capabilities.installedFull[reciter] = installed.fullName }
      if custom && store.openingReady(installed) { capabilities.installedOpening[reciter] = installed.openingName }
    }
    let full = capabilities.fullSound(reciter)?.sound
    let desired = requested == .fullAlarm && full == nil ? IOSPrayerMode.alarm : requested
    if desired == .fullAlarm { sound = full }
    if desired == .alarm, custom, let opening = capabilities.installedOpening[reciter] { sound = opening }
    if desired == .short && sound == nil { throw IOSPrayerError.invalid("audioMissing") }
    let key = "preview/\(UUID().uuidString)"
    let policy = IOSPrayerEffectivePolicy(desired: desired, effective: desired, reciterId: reciter,
      sound: desired == .silent ? nil : sound, reason: nil)
    let event = IOSPrayerOccurrence(key: key, identifier: "huda.prayer.preview.\(UUID().uuidString)", alarmID: UUID(),
      prayer: "fajr", kind: "preview", instant: Date().addingTimeInterval(10),
      eventJSON: try JSONSerialization.data(withJSONObject: ["id": 1902,
        "title": args["title"] as? String ?? "Huda prayer test", "body": args["body"] as? String ?? "Test prayer alert"]),
      policy: policy, timeSensitive: state.configuration.experience.timeSensitive, revision: state.configuration.revision,
      locationRevision: 0, signature: "preview")
    if desired == .alarm || desired == .fullAlarm {
      guard IOSPrayerAlarmScheduler().authorization == "authorized" else { throw IOSPrayerError.invalid("alarmPermission") }
      var ids = UserDefaults.standard.stringArray(forKey: "iosPrayerPreviewAlarms") ?? []
      ids.append(event.alarmID.uuidString); UserDefaults.standard.set(ids, forKey: "iosPrayerPreviewAlarms")
      try await IOSPrayerAlarmScheduler().submit(event)
    } else {
      let scheduler = IOSPrayerNotificationScheduler()
      guard await scheduler.center.pendingNotificationRequests().count < 60 else { throw IOSPrayerError.invalid("notificationCapacity") }
      try await scheduler.submit(event)
    }
    return try await service.status()
  }
}
