#if DEBUG
import Cocoa
import FlutterMacOS
import UserNotifications

/// Opt-in controller for signed, on-device verification of the real app.
/// No command listener or files are created in ordinary launches or Release.
final class MacPrayerDeviceVerification {
  private weak var delegate: AppDelegate?
  private var timer: Timer?
  private var busy = false
  private var lastID = ""
  private var observers: [(NotificationCenter, NSObjectProtocol)] = []
  private let folder: URL
  private let began = Date()

  init?(delegate: AppDelegate) {
    guard ProcessInfo.processInfo.environment["HUDA_PRAYER_DEVICE_VERIFY"] == "1" ||
      UserDefaults.standard.bool(forKey: "hudaPrayerDeviceVerificationEnabled") else { return nil }
    self.delegate = delegate
    folder = delegate.prayerService.store.directory.appendingPathComponent("DeviceVerification", isDirectory: true)
    do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
    catch { return nil }
    try? FileManager.default.removeItem(at: folder.appendingPathComponent("command.json"))
    write(["pid": ProcessInfo.processInfo.processIdentifier, "started": began.timeIntervalSince1970], to: "ready.json")
    let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in self?.poll() }
    RunLoop.main.add(timer, forMode: .common); self.timer = timer
    observeLifecycle()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
      self?.snapshot { state in self?.write(state, to: "launch-\(ProcessInfo.processInfo.processIdentifier).json") }
    }
  }
  deinit {
    timer?.invalidate()
    for (center, observer) in observers { center.removeObserver(observer) }
  }
  private func observeLifecycle() {
    let workspace = NSWorkspace.shared.notificationCenter
    let local = NotificationCenter.default
    for (center, name) in [(workspace, NSWorkspace.willSleepNotification), (workspace, NSWorkspace.didWakeNotification),
      (workspace, NSWorkspace.sessionDidBecomeActiveNotification), (workspace, NSWorkspace.sessionDidResignActiveNotification),
      (local, .NSSystemClockDidChange), (local, .NSSystemTimeZoneDidChange), (local, NSApplication.willTerminateNotification)] {
      let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] event in
        guard let self else { return }
        let entry: [String: Any] = ["time": Date().timeIntervalSince1970, "event": name.rawValue,
          "injected": event.userInfo?["verificationInjected"] as? Bool ?? false,
          "pid": ProcessInfo.processInfo.processIdentifier]
        let file = self.folder.appendingPathComponent("lifecycle.jsonl")
        if let data = try? JSONSerialization.data(withJSONObject: entry, options: [.sortedKeys]) {
          if !FileManager.default.fileExists(atPath: file.path) { FileManager.default.createFile(atPath: file.path, contents: nil) }
          if let handle = try? FileHandle(forWritingTo: file) {
            defer { try? handle.close() }; try? handle.seekToEnd(); try? handle.write(contentsOf: data + Data([10]))
          }
        }
      }
      observers.append((center, observer))
    }
  }

  private func write(_ object: Any, to name: String) {
    guard JSONSerialization.isValidJSONObject(object),
      let bytes = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else { return }
    try? bytes.write(to: folder.appendingPathComponent(name), options: .atomic)
  }
  private func finish(_ id: String, _ value: Any?) {
    if let error = value as? FlutterError {
      write(["id": id, "error": error.code, "message": error.message ?? ""], to: "response.json")
    } else {
      write(["id": id, "result": value ?? NSNull()], to: "response.json")
    }
    busy = false
  }
  private func poll() {
    guard !busy, let delegate,
      let bytes = try? Data(contentsOf: folder.appendingPathComponent("command.json")), bytes.count <= 262_144,
      let command = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
      let id = command["id"] as? String, id != lastID, let operation = command["operation"] as? String else { return }
    lastID = id; busy = true
    let service = delegate.prayerService
    var args = command["arguments"] as? [String: Any] ?? [:]
    switch operation {
    case "snapshot": snapshot { self.finish(id, $0) }
    case "service":
      guard let method = command["method"] as? String else { finish(id, ["error": "Missing method"]); return }
      args["schemaVersion"] = 1
      if ["configure", "setExperience"].contains(method) { args["expectedRevision"] = service.configuration.revision }
      service.handle(FlutterMethodCall(methodName: method, arguments: args)) { self.finish(id, $0) }
    case "close":
      NSApp.windows.first(where: { $0 is MainFlutterWindow })?.performClose(nil)
      finish(id, ["requested": true])
    case "reveal": delegate.revealMainWindow(); finish(id, ["requested": true])
    case "quit":
      finish(id, ["requested": true]); DispatchQueue.main.async { NSApp.terminate(nil) }
    case "menu": finish(id, delegate.prayerMenuBar.setPreferences(args))
    case "menuStop": delegate.prayerMenuBar.stopAdhan(); finish(id, service.status())
    case "menuDismiss": delegate.prayerMenuBar.dismissFocus(); finish(id, service.status())
    case "persistForLogin":
      UserDefaults.standard.set(args["enabled"] as? Bool ?? false, forKey: "hudaPrayerDeviceVerificationEnabled")
      finish(id, ["enabled": UserDefaults.standard.bool(forKey: "hudaPrayerDeviceVerificationEnabled")])
    case "panelStop": service.panels.stopAudio?(); finish(id, service.status())
    case "escape":
      NSApp.windows.first(where: { $0 is NSPanel && $0.isVisible && $0.level == .screenSaver })?.cancelOperation(nil)
      finish(id, service.status())
    case "render":
      var images: [String] = []
      for window in NSApp.windows where window is NSPanel && window.isVisible {
        guard let view = window.contentView,
          let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { continue }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        if let data = bitmap.representation(using: .png, properties: [:]) {
          let name = "panel-\(id)-\(window.windowNumber).png"
          try? data.write(to: folder.appendingPathComponent(name)); images.append(name)
        }
      }
      finish(id, images)
    case "signal":
      let info = ["verificationInjected": true]
      switch args["name"] as? String {
      case "clock": NotificationCenter.default.post(name: .NSSystemClockDidChange, object: nil, userInfo: info)
      case "zone": NotificationCenter.default.post(name: .NSSystemTimeZoneDidChange, object: nil, userInfo: info)
      case "sleep": NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil, userInfo: info)
      case "wake": NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil, userInfo: info)
      case "lock": NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.sessionDidResignActiveNotification, object: nil, userInfo: info)
      case "unlock": NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, userInfo: info)
      case "display": NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
      default: finish(id, ["error": "Unknown signal"]); return
      }
      finish(id, service.status())
    case "armPrayer":
      do {
        guard let saved = service.configuration.schedule else { throw MacPrayerError.invalid("Set a schedule first.") }
        let prayer = args["prayer"] as? String ?? "fajr"
        guard MacPrayerSchedule.obligatory.contains(prayer) else { throw MacPrayerError.invalid("Invalid test prayer.") }
        var object = try MacPrayerJSON.object(saved)
        object["offsets"] = Dictionary(uniqueKeysWithValues: MacPrayerSchedule.names.map { ($0, 0) })
        let base = try MacPrayerJSON.decode(MacPrayerSchedule.self, object)
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = base.location.zone
        let day = calendar.date(byAdding: .day, value: args["sourceDayOffset"] as? Int ?? 0, to: Date())!
        guard let raw = base.times(on: day)[prayer] else { throw MacPrayerError.invalid("Test prayer is unavailable.") }
        let delay = args["delay"] as? Double ?? 8
        let minutes = Int(ceil((Date().addingTimeInterval(delay).timeIntervalSince(raw)) / 60))
        var offsets = Dictionary(uniqueKeysWithValues: MacPrayerSchedule.names.map { ($0, 0) })
        offsets[prayer] = minutes; object["offsets"] = offsets
        let next = try MacPrayerJSON.decode(MacPrayerSchedule.self, object); try next.validate()
        let instant = next.times(on: day)[prayer]!
        let key = "\(next.dayKey(day))/\(prayer)"
        guard !service.ledger.contains(key) else { throw MacPrayerError.invalid("Test occurrence was already claimed.") }
        service.handle(FlutterMethodCall(methodName: "configure", arguments: ["schemaVersion": 1,
          "expectedRevision": service.configuration.revision, "schedule": object,
          "configurationSignature": "device-verification:\(id)"])) { result in
          if result is FlutterError { self.finish(id, result) }
          else { self.finish(id, ["key": key, "instantMillis": instant.timeIntervalSince1970 * 1000,
            "offsetMinutes": minutes, "status": result ?? NSNull()]) }
        }
      } catch { finish(id, FlutterError(code: "arm_failed", message: error.localizedDescription, details: nil)) }
    case "soundProbe":
      let name = args["name"] as? String ?? ""
      let delay = args["delay"] as? Double ?? 30
      guard ["huda-notification-probe.caf", "huda-notification-probe.wav", "huda-notification-probe.aiff"].contains(name),
        delay.isFinite, (5...120).contains(delay) else {
        finish(id, FlutterError(code: "invalid_probe", message: "Use a bounded diagnostic sound and delay.", details: nil)); return
      }
      let content = UNMutableNotificationContent()
      content.title = "Huda notification audio verification"
      content.body = "Listen for the short Adhan recording."
      content.userInfo = ["payload": "device-verification", "presentBanner": true]
      let soundName: String
      if args["location"] as? String == "group", let directory = service.audio.soundsDirectory {
        soundName = directory.appendingPathComponent(name).path
      } else { soundName = name }
      content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
      if #available(macOS 12.0, *), service.status()["supportsTimeSensitive"] as? Bool == true {
        content.interruptionLevel = .timeSensitive
      }
      UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "199900070", content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false))) { error in
          DispatchQueue.main.async {
            if let error {
              self.finish(id, FlutterError(code: "probe_failed", message: error.localizedDescription, details: nil))
            } else {
              self.finish(id, ["name": soundName, "dueMillis": Date().addingTimeInterval(delay).timeIntervalSince1970 * 1000])
            }
          }
      }
    case "clearSoundProbe":
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["199900070"])
      UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["199900070"])
      finish(id, ["requested": true])
    case "generic":
      let content = UNMutableNotificationContent(); content.title = "Huda device verification"
      content.body = "Generic reminder compatibility check"; content.userInfo = ["payload": "device-verification", "presentBanner": true]
      let count = min(65, max(1, args["count"] as? Int ?? 1))
      let group = DispatchGroup(); var errors: [String] = []
      for index in 0..<count {
        group.enter()
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "\(199900000 + index)", content: content,
          trigger: UNTimeIntervalNotificationTrigger(timeInterval: args["delay"] as? Double ?? 7200, repeats: false))) { error in
          DispatchQueue.main.async { if let error { errors.append(error.localizedDescription) }; group.leave() }
        }
      }
      group.notify(queue: .main) { self.finish(id, ["errors": errors]) }
    case "clearGeneric":
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: (0..<65).map { "\(199900000 + $0)" })
      UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: (0..<65).map { "\(199900000 + $0)" })
      finish(id, ["requested": true])
    case "clearPrayerDelivered":
      let keys = Set(args["keys"] as? [String] ?? [])
      UNUserNotificationCenter.current().getDeliveredNotifications { delivered in
        let ids = delivered.compactMap { notification -> String? in
          guard let key = notification.request.content.userInfo["hudaKey"] as? String,
            keys.contains(key), MacPrayerService.isPrayerRequest(notification.request) else { return nil }
          return notification.request.identifier
        }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
        DispatchQueue.main.async { self.finish(id, ["removedCount": ids.count]) }
      }
    default: finish(id, ["error": "Unknown operation"])
    }
  }
  private func snapshot(_ completion: @escaping ([String: Any]) -> Void) {
    guard let delegate else { completion([:]); return }
    let service = delegate.prayerService
    let soundFiles = service.audio.soundsDirectory.flatMap {
      try? FileManager.default.contentsOfDirectory(atPath: $0.path)
    }?.filter { $0.hasPrefix("huda-") } ?? []
    let bundleSounds = (try? FileManager.default.contentsOfDirectory(atPath: service.audio.notificationDirectory.path))?
      .filter { $0.hasPrefix("huda-short-") && $0.hasSuffix(".wav") } ?? []
    func request(_ r: UNNotificationRequest) -> [String: Any] {
      let instant = (r.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ??
        (r.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
      var result: [String: Any] = ["id": r.identifier, "prayer": MacPrayerService.isPrayerRequest(r), "sound": r.content.sound.map { String(describing: $0) } as Any? ?? NSNull(),
       "nextMillis": instant.map { $0.timeIntervalSince1970 * 1000 } as Any? ?? NSNull(),
       "key": r.content.userInfo["hudaKey"] as Any? ?? NSNull(), "category": r.content.categoryIdentifier]
      // UNNotificationSound.description omits its name on this OS. Compare
      // against actual bundle/staged filenames using public NSObject equality.
      let soundNames = bundleSounds + soundFiles + soundFiles.compactMap { service.audio.soundsDirectory?.appendingPathComponent($0).path }
      result["soundName"] = r.content.sound.flatMap { sound in
        sound == UNNotificationSound.default ? "default" : soundNames.first {
          sound == UNNotificationSound(named: UNNotificationSoundName($0))
        }
      } as Any? ?? NSNull()
      if #available(macOS 12.0, *) { result["interruptionLevel"] = r.content.interruptionLevel.rawValue }
      return result
    }
    UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
      UNUserNotificationCenter.current().getDeliveredNotifications { delivered in
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          DispatchQueue.main.async {
            var notificationSettings: [String: Any] = ["authorization": settings.authorizationStatus.rawValue,
              "alert": settings.alertSetting.rawValue, "sound": settings.soundSetting.rawValue]
            if #available(macOS 12.0, *) { notificationSettings["timeSensitive"] = settings.timeSensitiveSetting.rawValue }
            completion(["pid": ProcessInfo.processInfo.processIdentifier, "time": Date().timeIntervalSince1970,
              "launchContext": String(describing: MacPrayerLaunchClassifier.shared.context),
              "activationPolicy": NSApp.activationPolicy().rawValue, "active": NSApp.isActive,
              "status": service.status(), "configuration": (try? MacPrayerJSON.object(service.configuration)) ?? [:],
              "player": service.audio.deviceVerificationState,
              "menu": delegate.prayerMenuBar.preferences(), "pending": pending.map(request),
              "delivered": delivered.map { request($0.request) },
              "notificationSettings": notificationSettings,
              "focus": ["deadlineMillis": service.panels.deadline.map { $0.timeIntervalSince1970 * 1000 } as Any? ?? NSNull(),
                "remaining": service.panels.remaining, "clock": service.panels.clock, "countdown": service.panels.countdown],
              "windows": NSApp.windows.map { ["type": String(describing: type(of: $0)), "id": $0.windowNumber,
                "visible": $0.isVisible, "restorable": $0.isRestorable, "level": $0.level.rawValue,
                "presentationOrders": ($0 as? MainFlutterWindow)?.verificationPresentationOrders as Any? ?? NSNull(),
                "frame": NSStringFromRect($0.frame), "appearance": $0.effectiveAppearance.name.rawValue] }])
          }
        }
      }
    }
  }
}
#endif
