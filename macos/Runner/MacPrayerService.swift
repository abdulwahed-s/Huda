import Cocoa
import FlutterMacOS
import UserNotifications
import Security

/// One resident native owner for calculation, due effects and queue renewal.
/// All mutation/due dispatch is serialized on the main run loop. OS queue work
/// uses callbacks; subsequent reconciliations coalesce until readback finishes.
final class MacPrayerService {
  private struct Due {
    let event: MacPrayerEvent
    let configuration: MacPrayerConfiguration
  }
  let store: MacPrayerStore
  let ledger: MacPrayerLedger
  let audio: MacPrayerAudio
  let panels = MacPrayerPanelController()
  let startup = MacPrayerStartup()
  let router = MacPrayerNotificationRouter()
  private let center: MacPrayerNotificationBackend
  private let installsSystemRouter: Bool
  private(set) var configuration: MacPrayerConfiguration
  private var due: [Due] = []
  private var dueTimer: Timer?
  private var dueActivity: NSObjectProtocol?
  private var maintenance = NSBackgroundActivityScheduler(identifier: "com.aw.huda.prayer.maintenance")
  private var observers: [NSObjectProtocol] = []
  private var workspaceObservers: [NSObjectProtocol] = []
  private var distributedObservers: [NSObjectProtocol] = []
  private var started = false
  private var suspended = false
  private var locked = false
  private var reconciling = false
  private var needsReconcile = false
  private var retryCount = 0
  private var retryTimer: Timer?
  private var authorization = "notDetermined"
  private var notificationAlertStyle = "unknown"
  private var pendingEvents: [[String: Any]] = []
  private var pendingCount = 0
  private var coverage: Date?
  private var queueError: String?
  private var commandError: String?
  private var offlineReady = false
  private var previewSession: String?
  // A numeric identifier keeps the existing plugin's pending/tap parsers valid.
  private let previewNotificationId = "299999999"
  static let renewalIdentifier = "huda.prayer.renewal"
  private var previewExpiry: Timer?
  private var deferredCommands: [(FlutterMethodCall, FlutterResult)] = []
  weak var channel: FlutterMethodChannel?
  var onChanged: (() -> Void)?
  var hiddenLaunch = false

  init(directory: URL? = nil, notifications: MacPrayerNotificationBackend? = nil) {
    let directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("HudaPrayer", isDirectory: true)
    store = MacPrayerStore(directory: directory)
    center = notifications ?? MacPrayerSystemNotifications()
    installsSystemRouter = notifications == nil
    ledger = MacPrayerLedger(directory: directory)
    audio = MacPrayerAudio(directory: directory)
    if let saved = store.load() { configuration = saved }
    else {
      var migrated = MacPrayerConfiguration()
      let shared = UserDefaults(suiteName: PrayerMenuBarController.appGroupId)
      let legacyMenu = shared?.dictionary(forKey: "prayer_menu_bar_preferences_v1")
      let existing = shared?.string(forKey: "prayer_widget_settings_v2") != nil ||
        shared?.string(forKey: "prayer_widget_display_v1") != nil || legacyMenu != nil ||
        UserDefaults.standard.bool(forKey: "flutter.onboarding_completed")
      migrated.legacyNotifications = existing
      migrated.experience.backgroundEnabled = existing && (legacyMenu?["enabled"] as? Bool ?? true)
      configuration = migrated
      do { try store.save(migrated) } catch { queueError = error.localizedDescription }
    }
    audio.onChanged = { [weak self] playing in
      guard let self else { return }
      self.panels.setAudioPlaying(playing)
      self.channel?.invokeMethod(playing ? "audioStarted" : "audioStopped", arguments: nil)
      self.emit()
    }
    panels.stopAudio = { [weak self] in self?.audio.stop() }
    panels.onDismiss = { [weak self] session in self?.audio.stop(session: session) }
    panels.onChanged = { [weak self] in self?.emit() }
    router.stop = { [weak self] session in self?.audio.stop(session: session) }
    router.observed = { [weak self] key, outcome in self?.ledger.notificationOutcome(key, outcome) }
  }

  var backgroundEnabled: Bool { configuration.experience.backgroundEnabled }
  static var supportsTimeSensitive: Bool {
    guard #available(macOS 12.0, *), let task = SecTaskCreateFromSelf(nil) else { return false }
    return SecTaskCopyValueForEntitlement(task, "com.apple.developer.usernotifications.time-sensitive" as CFString, nil) as? Bool == true
  }
  func start() {
    guard !started else { return }; started = true
    if installsSystemRouter { router.install() }
    let notifications = NotificationCenter.default
    for name in [NSNotification.Name.NSSystemClockDidChange, NSNotification.Name.NSSystemTimeZoneDidChange] {
      observers.append(notifications.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        self?.resumeWithoutStaleEffects()
      })
    }
    let workspace = NSWorkspace.shared.notificationCenter
    workspaceObservers.append(workspace.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
      self?.suspended = true; self?.stopLiveEffects(); self?.invalidateDueTimer()
    })
    for name in [NSWorkspace.didWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
      workspaceObservers.append(workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        self?.resumeWithoutStaleEffects()
      })
    }
    workspaceObservers.append(workspace.addObserver(forName: NSWorkspace.sessionDidResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
      self?.setLocked(true)
    })
    // Lock broadcasts complement workspace session changes (ordinary screen
    // locking need not switch the console user). No global input monitoring.
    let distributed = DistributedNotificationCenter.default()
    for (name, isLocked) in [("com.apple.screenIsLocked", true), ("com.apple.screenIsUnlocked", false)] {
      distributedObservers.append(distributed.addObserver(forName: NSNotification.Name(name), object: nil, queue: .main) { [weak self] _ in
        self?.setLocked(isLocked)
      })
    }
    maintenance.interval = 30 * 60; maintenance.tolerance = 5 * 60; maintenance.repeats = true
    maintenance.schedule { [weak self] completion in
      DispatchQueue.main.async {
        guard let self, self.started else { completion(.finished); return }
        self.reconcile { completion(.finished) }
      }
    }
    rebuildDue(preserveNearDue: false)
    reconcile()
  }
  func stop() {
    started = false; maintenance.invalidate(); retryTimer?.invalidate(); retryTimer = nil
    invalidateDueTimer(); stopLiveEffects(); clearPreview()
    for observer in observers { NotificationCenter.default.removeObserver(observer) }; observers.removeAll()
    for observer in workspaceObservers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }; workspaceObservers.removeAll()
    for observer in distributedObservers { DistributedNotificationCenter.default().removeObserver(observer) }; distributedObservers.removeAll()
    // Explicit Quit preserves startup registration and existing system requests.
  }
  private func stopLiveEffects() { audio.stop(); panels.dismiss(force: true) }
  private func setLocked(_ value: Bool) {
    locked = value
    if value {
      panels.dismiss(force: true)
      if !configuration.experience.allowLockedAudio { audio.stop() }
    } else { resumeWithoutStaleEffects() }
    emit()
  }
  private func resumeWithoutStaleEffects() {
    suspended = false
    stopLiveEffects()
    rebuildDue(preserveNearDue: false)
    reconcile()
  }
  private func commit(_ next: MacPrayerConfiguration) throws {
    guard next != configuration else { return }
    var next = next
    next.revision = configuration.revision + 1
    next.cutoverMillis = Date().timeIntervalSince1970 * 1000
    try next.validate(); try store.save(next)
    configuration = next
    if !next.legacyNotifications {
      // A deliberate Silent choice overrides audible captured policies while
      // keeping their near-due instants stable across a settings cutover.
      due = due.map { item in
        let policy = next.experience.effective(for: item.event.prayer)
        guard policy.mode == .silent else { return item }
        var captured = item.configuration
        captured.experience = policy
        captured.legacyNotifications = false
        return Due(event: item.event, configuration: captured)
      }
    }
    offlineReady = next.experience.effectivePrayers
      .filter { $0.enabled && ($0.playerAudio || $0.usesShortSound) }
      .allSatisfy(audio.isReady)
    if !next.experience.enabled || next.experience.quiet ||
      next.experience.effectivePrayers.allSatisfy({ !$0.enabled || $0.mode == .silent }) {
      stopLiveEffects(); clearPreview()
    }
    rebuildDue(preserveNearDue: next.experience.enabled)
    emit()
  }
  private func rebuildDue(preserveNearDue: Bool) {
    let now = Date()
    let protected = preserveNearDue ? due.filter { $0.event.instant.timeIntervalSince(now) >= -60 && $0.event.instant.timeIntervalSince(now) <= 120 } : []
    let protectedByKey = Dictionary(protected.map { ($0.event.key, $0) }, uniquingKeysWith: { first, _ in first })
    due = []
    if let schedule = configuration.schedule, configuration.experience.enabled {
      due = schedule.events(from: now, revision: max(1, configuration.revision), signature: configuration.deliverySignature)
        .filter { !ledger.contains($0.key) && configuration.experience.effective(for: $0.prayer).enabled }
        .map { protectedByKey[$0.key] ?? Due(event: $0, configuration: configuration.forPrayer($0.prayer)) }
      for old in protected where !due.contains(where: { $0.event.key == old.event.key }) { due.append(old) }
      due.sort { $0.event.instant < $1.event.instant }
    }
    armDueTimer()
  }
  private func invalidateDueTimer() {
    dueTimer?.invalidate(); dueTimer = nil
    if let dueActivity { ProcessInfo.processInfo.endActivity(dueActivity) }; dueActivity = nil
  }
  private func armDueTimer() {
    invalidateDueTimer()
    guard started, !suspended, let next = due.first else { return }
    // An absolute wall-clock fire date is re-armed after clock/wake changes.
    // Disable App Nap while waiting for an opted-in live media/panel effect.
    // Silent/short notifications are delivered by UNUserNotificationCenter.
    if next.configuration.experience.playerAudio || next.configuration.experience.mode == .focus {
      dueActivity = ProcessInfo.processInfo.beginActivity(options: [.userInitiatedAllowingIdleSystemSleep], reason: "Waiting for the next prayer reminder")
    }
    let timer = Timer(fire: next.event.instant, interval: 0, repeats: false) { [weak self] _ in self?.dispatchDue() }
    timer.tolerance = 0.5
    RunLoop.main.add(timer, forMode: .common); dueTimer = timer
  }
  private func dispatchDue() {
    guard started, !suspended else { return }
    let now = Date()
    let elapsed = due.filter { $0.event.instant <= now }
    due.removeAll { $0.event.instant <= now }
    for item in elapsed {
      guard MacPrayerDuePolicy.shouldDeliver(instant: item.event.instant, now: now, continuouslyRunning: true) else { continue }
      do {
        let queued = pendingEvents.contains { $0["occurrenceKey"] as? String == item.event.key }
        guard try ledger.claim(item.event.key, at: now, notification: queued ? "queued" : "notVerified") else { continue }
        clearPreview(); stopLiveEffects()
        let policy = item.configuration.experience
        let session = "prayer:\(item.event.key)"
        let liveEnabled = configuration.experience.enabled && policy.enabled && policy.mode != .silent && !configuration.experience.quiet
        let canPlay = liveEnabled && !policy.quiet && (!locked || policy.allowLockedAudio)
        let canShow = liveEnabled && !policy.quiet && !locked
        var playback = "notRequested", overlay = "notRequested"
        if policy.playerAudio {
          playback = canPlay ? (audio.play(policy, session: session) ? "started" : "failed") : "suppressed"
        }
        if policy.mode == .focus {
          if canShow {
            panels.show(session: session, prayer: item.event.prayer, time: item.event.instant,
              zone: item.event.location.zone, configuration: item.configuration, preview: false)
            panels.setAudioPlaying(audio.session != nil); overlay = "started"
          } else { overlay = "suppressed" }
        }
        ledger.outcome(item.event.key, playback: playback, overlay: overlay)
      } catch { commandError = error.localizedDescription }
    }
    armDueTimer(); emit()
    if coverage == nil || coverage!.timeIntervalSince(now) < 3 * 86400 { reconcile() }
  }

  static func isPrayerRequest(_ request: UNNotificationRequest) -> Bool {
    if request.content.userInfo["hudaPrayer"] as? Bool == true && request.content.userInfo["hudaPreview"] as? Bool != true { return true }
    guard let id = Int(request.identifier) else { return false }
    return (300_000_000..<400_000_000).contains(id) || (2000...2599).contains(id)
  }
  /// A quiet notification some minutes before a prayer.
  private func advanceRequest(for due: Due, minutes: Int, at: Date) -> UNNotificationRequest {
    let event = due.event, config = due.configuration
    let name = config.strings[event.prayer] ?? event.prayer.capitalized
    let digits = Array("٠١٢٣٤٥٦٧٨٩")
    let count = config.numerals == "eastern"
      ? String(String(minutes).compactMap { $0.wholeNumberValue.map { digits[$0] } })
      : String(minutes)
    let content = UNMutableNotificationContent()
    content.title = name
    content.body = (config.strings["advanceBody"] ?? "{prayer} in {minutes} minutes.")
      .replacingOccurrences(of: "{prayer}", with: name).replacingOccurrences(of: "{minutes}", with: count)
    content.sound = nil
    if #available(macOS 12.0, *) { content.interruptionLevel = .active }
    content.userInfo = ["hudaPrayer": true, "hudaKind": "advance", "payload": event.payload(),
      "presentAlert": true, "presentBanner": true, "presentList": true, "presentBadge": false, "presentSound": false]
    var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: at)
    components.timeZone = calendar.timeZone
    return UNNotificationRequest(identifier: "advance-\(event.key)", content: content,
      trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
  }
  private func request(for due: Due, sound: String?) -> UNNotificationRequest {
    let event = due.event, config = due.configuration
    let dictionary = event.dictionary(strings: config.strings)
    let content = UNMutableNotificationContent()
    content.title = dictionary["title"] as! String
    content.body = dictionary["body"] as! String
    let short = config.legacyNotifications || config.experience.mode == .adhan && config.experience.delivery == .short
    content.sound = short && sound != nil ? UNNotificationSound(named: UNNotificationSoundName(sound!)) : nil
    if #available(macOS 12.0, *) {
      content.interruptionLevel = config.experience.timeSensitive && Self.supportsTimeSensitive ? .timeSensitive : .active
    }
    if config.experience.playerAudio { content.categoryIdentifier = MacPrayerNotificationRouter.category }
    content.userInfo = ["hudaPrayer": true, "hudaEvent": dictionary, "hudaKey": event.key,
      "hudaSession": "prayer:\(event.key)", "payload": event.payload(),
      "presentAlert": true, "presentBanner": true, "presentList": true, "presentBadge": false, "presentSound": short]
    var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: event.instant)
    components.timeZone = calendar.timeZone
    return UNNotificationRequest(identifier: event.notificationIdentifier, content: content,
      trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
  }
  private func matches(_ old: UNNotificationRequest, _ desired: UNNotificationRequest) -> Bool {
    if #available(macOS 12.0, *), old.content.interruptionLevel != desired.content.interruptionLevel { return false }
    return old.content.title == desired.content.title && old.content.body == desired.content.body &&
      old.content.sound == desired.content.sound && old.content.categoryIdentifier == desired.content.categoryIdentifier &&
      NSDictionary(dictionary: old.content.userInfo).isEqual(to: desired.content.userInfo) &&
      (old.trigger as? UNCalendarNotificationTrigger)?.dateComponents == (desired.trigger as? UNCalendarNotificationTrigger)?.dateComponents
  }

  func reconcile(completion: (() -> Void)? = nil) {
    guard started else { completion?(); return }
    if reconciling { needsReconcile = true; completion?(); return }
    reconciling = true; queueError = nil
    if installsSystemRouter {
      router.install(); router.ensureCategory(stopTitle: configuration.strings["stop"] ?? "Stop Adhan")
    }
    offlineReady = audio.isReady(configuration.experience)
    center.getSettings { settings in
      DispatchQueue.main.async {
        switch settings.authorizationStatus {
        case .authorized: self.authorization = "authorized"
        case .provisional: self.authorization = "provisional"
        case .denied: self.authorization = "denied"
        case .notDetermined: self.authorization = "notDetermined"
        @unknown default: self.authorization = "unknown"
        }
        switch settings.alertStyle {
        case .none: self.notificationAlertStyle = "none"
        case .banner: self.notificationAlertStyle = "banner"
        case .alert: self.notificationAlertStyle = "alert"
        @unknown default: self.notificationAlertStyle = "unknown"
        }
        self.center.getPendingNotificationRequests { pending in
          DispatchQueue.main.async { self.applyQueue(pending, completion: completion) }
        }
      }
    }
  }
  private func applyQueue(_ pending: [UNNotificationRequest], completion: (() -> Void)?) {
    guard started else { finishReconcile(completion); return }
    // Refresh the rolling horizon without moving captured near-due policies.
    rebuildDue(preserveNearDue: true)
    let native = pending.filter(Self.isPrayerRequest)
    // The renewal notice sits outside the prayer budget (60 of macOS's 64).
    let renewal = pending.contains { $0.identifier == Self.renewalIdentifier } ? 1 : 0
    let others = pending.count - native.count - renewal
    let budget = MacPrayerDuePolicy.capacity(otherCount: others)
    var soundNames: [String: String] = [:]
    var attemptedSounds = Set<String>()
    let selected = Array(due.prefix(budget))
    let desired = selected.map { item -> UNNotificationRequest in
      let p = item.configuration.experience
      let short = item.configuration.legacyNotifications || p.mode == .adhan && p.delivery == .short
      let key = "\(p.audioVersion)/\(p.reciterId)"
      if short && attemptedSounds.insert(key).inserted {
        do { soundNames[key] = try audio.notificationSound(p) }
        catch { queueError = error.localizedDescription }
      }
      return request(for: item, sound: soundNames[key])
    }
    // Reminders before prayers: the next 48 hours, in the space prayers leave.
    let now = Date()
    let reminders = Array(due.compactMap { item -> UNNotificationRequest? in
      let policy = item.configuration.experience
      let minutes = policy.advanceMinutes ?? 0
      let at = item.event.instant.addingTimeInterval(TimeInterval(-60 * minutes))
      guard policy.enabled, minutes > 0, at > now, at.timeIntervalSince(now) < 48 * 3600 else { return nil }
      return advanceRequest(for: item, minutes: minutes, at: at)
    }.prefix(max(0, min(10, budget - selected.count))))
    let requests = desired + reminders
    let byId = Dictionary(pending.map { ($0.identifier, $0) }, uniquingKeysWith: { first, _ in first })
    let desiredIds = Set(requests.map(\.identifier))
    var obsolete = native.filter { !desiredIds.contains($0.identifier) }.sorted {
      ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? .distantFuture >
        ($1.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? .distantFuture
    }
    var count = pending.count - renewal
    func add(_ index: Int) {
      guard self.started else { self.finishReconcile(completion); return }
      if index == requests.count {
        // Keep working requests when additions fail; trim obsolete ones only
        // after replacements have been submitted. Disable is an explicit clear.
        if self.queueError == nil || !self.configuration.experience.enabled {
          self.center.removePendingNotificationRequests(withIdentifiers: obsolete.map(\.identifier))
        }
        self.center.getPendingNotificationRequests { actual in
          DispatchQueue.main.async { self.readback(actual, desired: desired); self.finishReconcile(completion) }
        }
        return
      }
      let request = requests[index]
      if let existing = byId[request.identifier], self.matches(existing, request) { add(index + 1); return }
      if byId[request.identifier] == nil && count >= 60 {
        // Free only one obsolete, distant request to make room; never clear a
        // working queue first and never cancel another reminder's identifier.
        guard let candidate = obsolete.first,
          ((candidate.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? .distantFuture).timeIntervalSinceNow > 120 else {
          self.queueError = "Prayer notification capacity is exhausted."; add(index + 1); return
        }
        obsolete.removeFirst(); self.center.removePendingNotificationRequests(withIdentifiers: [candidate.identifier]); count -= 1
      }
      self.center.add(request) { error in
        DispatchQueue.main.async {
          if let error { self.queueError = error.localizedDescription }
          else if byId[request.identifier] == nil { count += 1 }
          add(index + 1)
        }
      }
    }
    add(0)
  }
  private func readback(_ actual: [UNNotificationRequest], desired: [UNNotificationRequest]) {
    let byId = Dictionary(actual.map { ($0.identifier, $0) }, uniquingKeysWith: { first, _ in first })
    pendingEvents = []; coverage = nil
    var gap = false
    for request in desired {
      guard let installed = byId[request.identifier], matches(installed, request),
        let event = installed.content.userInfo["hudaEvent"] as? [String: Any],
        let trigger = installed.trigger as? UNCalendarNotificationTrigger, let instant = trigger.nextTriggerDate(), instant > Date()
      else { gap = true; continue }
      pendingEvents.append(event)
      if !gap { coverage = instant }
    }
    pendingCount = actual.filter(Self.isPrayerRequest).count
    if !configuration.experience.enabled && pendingCount > 0 {
      queueError = "Prayer notifications could not be removed."
    }
    if configuration.experience.enabled && configuration.schedule != nil &&
      (gap || coverage == nil || coverage!.timeIntervalSinceNow < 3 * 86400) {
      queueError = queueError ?? "Prayer notification coverage is below three days."
    }
    scheduleRenewal(existing: byId[Self.renewalIdentifier])
  }
  /// "Extend prayer alerts", a day before the queue runs out and 15 minutes
  /// after that day's prayer. Each refill moves it later, so it only shows
  /// once Huda has stopped running (quit, or not opened at login).
  private func scheduleRenewal(existing: UNNotificationRequest?) {
    let fire = coverage.map { max(Date().addingTimeInterval(60), $0.addingTimeInterval(-86400 + 900)) }
    guard configuration.experience.enabled, let coverage, let fire, fire < coverage else {
      if existing != nil { center.removePendingNotificationRequests(withIdentifiers: [Self.renewalIdentifier]) }
      return
    }
    let content = UNMutableNotificationContent()
    content.title = configuration.strings["renewalTitle"] ?? "Extend prayer alerts"
    content.body = configuration.strings["renewalBody"] ?? "Open Huda to extend your scheduled prayer alerts."
    content.sound = nil
    content.userInfo = ["payload": "{\"type\":\"prayer_renewal\"}",
      "presentAlert": true, "presentBanner": true, "presentList": true, "presentBadge": false, "presentSound": false]
    var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fire)
    components.timeZone = calendar.timeZone
    if let existing, existing.content.title == content.title, existing.content.body == content.body,
      (existing.trigger as? UNCalendarNotificationTrigger)?.dateComponents == components { return }
    center.add(UNNotificationRequest(identifier: Self.renewalIdentifier, content: content,
      trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)), withCompletionHandler: nil)
  }
  private func finishReconcile(_ completion: (() -> Void)?) {
    reconciling = false; emit(); completion?()
    if !deferredCommands.isEmpty {
      let (call, result) = deferredCommands.removeFirst()
      handle(call, result: result)
      return
    }
    if needsReconcile { needsReconcile = false; reconcile(); return }
    if queueError != nil && retryCount < 3 && started {
      retryCount += 1
      retryTimer?.invalidate()
      retryTimer = Timer.scheduledTimer(withTimeInterval: pow(2, Double(retryCount)) * 30, repeats: false) { [weak self] _ in self?.reconcile() }
    } else if queueError == nil { retryCount = 0; retryTimer?.invalidate(); retryTimer = nil }
  }

  func status() -> [String: Any] {
    let displays: [[String: Any]] = NSScreen.screens.compactMap { screen in
      guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return nil }
      return ["id": "display:\(id.uint32Value)", "name": screen.localizedName]
    }
    return ["schemaVersion": 1, "revision": configuration.revision,
      "configurationSignature": configuration.configurationSignature, "supportsTimeSensitive": Self.supportsTimeSensitive,
      "experience": configuration.experience.dictionary(), "ready": configuration.schedule != nil && started,
      "startupState": startup.state, "authorization": authorization,
      "notificationAlertStyle": notificationAlertStyle,
      "pendingCount": pendingCount, "coverageMillis": coverage.map { $0.timeIntervalSince1970 * 1000 } as Any? ?? NSNull(),
      "nextEventMillis": due.first.map { $0.event.instant.timeIntervalSince1970 * 1000 } as Any? ?? NSNull(),
      "audioReady": offlineReady, "audioSession": audio.session as Any? ?? NSNull(),
      "focusSession": panels.session as Any? ?? NSNull(), "focusCanDismiss": panels.canDismiss,
      "audioError": audio.error as Any? ?? NSNull(),
      "error": (commandError ?? startup.error ?? queueError ?? ledger.error ?? store.recoveryError) as Any? ?? NSNull(),
      "hiddenLaunch": hiddenLaunch, "displays": displays, "events": pendingEvents]
  }
  func menuSnapshot() -> PrayerMenuSnapshot? {
    guard let schedule = configuration.schedule else { return nil }
    var calendar = Calendar(identifier: .gregorian); calendar.timeZone = schedule.location.zone
    var days: [String: [String: Date]] = [:]
    for offset in -1..<3 {
      if let date = calendar.date(byAdding: .day, value: offset, to: Date()) { days[schedule.dayKey(date)] = schedule.times(on: date) }
    }
    let location = [schedule.location.locality, schedule.location.countryName].compactMap { $0 }.joined(separator: ", ")
    return PrayerMenuSnapshot(timeZone: schedule.location.zone, location: location.isEmpty ? schedule.location.timeZoneId : location,
      method: configuration.strings["method:\(schedule.methodToken)"] ?? "", provisional: false, days: days, iqamahMinutes: PrayerMenuSnapshot.storedIqamahMinutes())
  }
  private func emit() { onChanged?(); channel?.invokeMethod("statusChanged", arguments: status()) }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], args["schemaVersion"] as? Int == 1 else {
      result(FlutterError(code: "unsupported_schema", message: "macOS prayer API v1 is required.", details: nil)); return
    }
    // Status requests promise fresh OS readback. Defer them too so an active
    // renewal cannot acknowledge a queue snapshot from the previous pass.
    if reconciling && ["status", "configure", "setExperience", "setPresentation", "setStartup"].contains(call.method) {
      guard deferredCommands.count < 16 else {
        result(FlutterError(code: "busy", message: "Prayer service has too many pending changes.", details: nil)); return
      }
      deferredCommands.append((call, result)); return
    }
    do {
      commandError = nil
      switch call.method {
      case "status":
        reconcile { result(self.status()) }; return
      case "audioPaths": result(try audio.paths()); return
      case "configure", "setExperience":
        guard !reconciling else { throw MacPrayerError.invalid("Prayer service is reconciling. Retry shortly.") }
        guard args["expectedRevision"] as? Int64 == configuration.revision else {
          result(FlutterError(code: "staleRevision", message: "Prayer configuration changed. Refresh and retry.", details: nil)); return
        }
        var next = configuration
        if call.method == "configure" {
          next.schedule = try MacPrayerJSON.decode(MacPrayerSchedule.self, args["schedule"] as Any)
          guard let signature = args["configurationSignature"] as? String, !signature.isEmpty else { throw MacPrayerError.invalid("Missing schedule signature.") }
          next.configurationSignature = signature
        } else {
          next.experience = try MacPrayerJSON.decode(MacPrayerExperience.self, args["experience"] as Any)
          if args["preserveStartup"] as? Bool == true && next.experience.backgroundEnabled { next.experience.startAtLogin = configuration.experience.startAtLogin }
          next.legacyNotifications = false
          if next.experience.enabled, !next.experience.effectivePrayers
            .filter({ $0.enabled && ($0.playerAudio || $0.usesShortSound) }).allSatisfy(audio.isReady) {
            throw MacPrayerError.invalid("Download and verify the selected Adhan before applying it.")
          }
          if !next.experience.backgroundEnabled && configuration.experience.startAtLogin {
            do { try startup.setEnabled(false) } catch { commandError = error.localizedDescription }
          }
        }
        try commit(next)
        reconcile { result(self.status()) }; return
      case "setStartup":
        guard let enabled = args["enabled"] as? Bool else { throw MacPrayerError.invalid("Missing startup preference.") }
        var next = configuration
        next.experience.startAtLogin = enabled
        if enabled { next.experience.backgroundEnabled = true }
        try commit(next)
        do { try startup.setEnabled(enabled) } catch { commandError = error.localizedDescription }
      case "openLoginSettings": startup.openSettings(); result(nil); return
      case "openNotificationSettings":
        let bundleId = Bundle.main.bundleIdentifier ?? "com.aw.huda"
        let path: String
        if #available(macOS 13.0, *) {
          path = "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleId)"
        } else {
          path = "x-apple.systempreferences:com.apple.preference.notifications?\(bundleId)"
        }
        guard let url = URL(string: path), NSWorkspace.shared.open(url) else {
          throw MacPrayerError.invalid("Could not open notification settings.")
        }
        result(nil); return
      case "requestNotifications":
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
          DispatchQueue.main.async {
            self.commandError = error?.localizedDescription
            self.reconcile { result(self.status()) }
          }
        }; return
      case "setPresentation":
        var next = configuration
        guard let strings = args["strings"] as? [String: String], let locale = args["locale"] as? String,
          let color = PrayerMenuBarController.parsedPrimaryColor(args["primaryColor"]),
          let theme = args["themeMode"] as? String, let clock = args["use24HourClock"] as? Bool else { throw MacPrayerError.invalid("Invalid native presentation.") }
        next.strings = strings; next.locale = locale; next.primaryColor = color; next.themeMode = theme; next.use24HourClock = clock
        next.fontFamily = args["fontFamily"] as? String
        next.numerals = args["numerals"] as? String
        next.textScale = args["textScale"] as? Double
        try commit(next); reconcile { result(self.status()) }; return
      case "stopAudio":
        guard let session = args["sessionId"] as? String else { break }; audio.stop(session: session)
      case "dismissFocus":
        guard let session = args["sessionId"] as? String else { break }; panels.dismiss(session: session)
      case "stopPreview":
        if args["sessionId"] as? String == previewSession { clearPreview() }
      case "previewAdhan", "previewFocus", "previewNotification":
        guard let session = args["sessionId"] as? String, MacPrayerExperience.matches(session, "^preview:[a-zA-Z0-9-]{1,64}$") else { throw MacPrayerError.invalid("A separate preview identity is required.") }
        guard audio.session == nil || audio.session == previewSession,
          panels.session == nil || panels.session == previewSession else { throw MacPrayerError.invalid("A prayer session is active.") }
        var previewConfig = configuration
        previewConfig.experience = try MacPrayerJSON.decode(MacPrayerExperience.self, args["experience"] as Any)
        try previewConfig.experience.validate()
        guard !locked, !suspended else { throw MacPrayerError.invalid("Unlock the Mac to preview a prayer reminder.") }
        clearPreview(); previewSession = session
        // The prayer being tested; older callers didn't send one.
        let prayer = (args["prayer"] as? String).flatMap { ["fajr", "dhuhr", "asr", "maghrib", "isha"].contains($0) ? $0 : nil } ?? "fajr"
        if call.method == "previewNotification" {
          let content = UNMutableNotificationContent()
          content.title = configuration.strings["\(prayer)Title"] ?? "Time for \(prayer.capitalized)"
          content.body = configuration.strings["\(prayer)Body"] ?? "It is time to pray."
          if previewConfig.experience.mode == .adhan && previewConfig.experience.delivery == .short {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(try audio.notificationSound(previewConfig.experience)))
          }
          content.userInfo = ["hudaPrayer": true, "hudaPreview": true, "hudaSession": session]
          center.add(UNNotificationRequest(identifier: previewNotificationId, content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))) { error in
            DispatchQueue.main.async { self.commandError = error?.localizedDescription; result(self.status()) }
          }
          if previewConfig.experience.playerAudio && !previewConfig.experience.quiet { audio.play(previewConfig.experience, session: session) }
          startPreviewExpiry(session); return
        } else if call.method == "previewFocus" {
          panels.show(session: session, prayer: prayer, time: Date(), zone: configuration.schedule?.location.zone ?? .current,
            configuration: previewConfig, preview: true)
          if previewConfig.experience.focusAudio { audio.play(previewConfig.experience, session: session) }
        } else { audio.play(previewConfig.experience, session: session) }
        startPreviewExpiry(session)
      default: result(FlutterMethodNotImplemented); return
      }
      emit(); result(status())
    } catch {
      result(FlutterError(code: "prayer_service_error", message: error.localizedDescription, details: nil))
    }
  }
  private func startPreviewExpiry(_ session: String) {
    let timer = Timer(timeInterval: 15, repeats: false) { [weak self] _ in
      if self?.previewSession == session { self?.clearPreview() }
    }
    RunLoop.main.add(timer, forMode: .common); previewExpiry = timer
  }
  private func clearPreview() {
    if let previewSession { audio.stop(session: previewSession); panels.dismiss(session: previewSession, force: true) }
    previewSession = nil; previewExpiry?.invalidate(); previewExpiry = nil
    center.removePendingNotificationRequests(withIdentifiers: [previewNotificationId])
    center.removeDeliveredNotifications(withIdentifiers: [previewNotificationId])
  }
}
