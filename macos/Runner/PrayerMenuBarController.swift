import Cocoa
import CoreFoundation
import FlutterMacOS
import SwiftUI

private enum PrayerMenuStyle: String, CaseIterable {
  case iconOnly
  case iconNameCountdown
  case iconNameClock

  static func fromStorage(_ value: String?) -> Self {
    switch value {
    case "iconOnly": return .iconOnly
    case "iconNameClock", "nextPrayerClock": return .iconNameClock
    default: return .iconNameCountdown
    }
  }
}

struct PrayerMenuSnapshot {
  static let iqamahDefaults = ["fajr": 25, "dhuhr": 20, "asr": 20, "maghrib": 5, "isha": 20]

  static func iqamahMinutes(_ raw: Any?) -> [String: Int] {
    let values = raw as? [String: Any] ?? [:]
    return iqamahDefaults.merging(values.compactMapValues { value -> Int? in
      guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
        number.doubleValue.isFinite else { return nil }
      return Int(min(60, max(0, number.doubleValue)))
    }.filter { iqamahDefaults[$0.key] != nil }) { _, value in value }
  }

  static func storedIqamahMinutes() -> [String: Int] {
    let defaults = UserDefaults(suiteName: "group.hudaHomeApp")
    for key in ["prayer_widget_display_v1", "prayer_widget_settings_v2"] {
      if let raw = defaults?.string(forKey: key), let data = raw.data(using: .utf8),
        let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        return iqamahMinutes(value["iqamahMinutes"])
      }
    }
    return iqamahDefaults
  }
  static let displayPrayers = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]
  static let obligatoryPrayers = ["fajr", "dhuhr", "asr", "maghrib", "isha"]

  let timeZone: TimeZone
  let location: String
  let method: String
  let provisional: Bool
  let days: [String: [String: Date]]
  var iqamahMinutes = iqamahDefaults

  static func parse(_ raw: String) -> PrayerMenuSnapshot? {
    guard let data = raw.data(using: .utf8),
      let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      (value["version"] as? NSNumber)?.intValue == 4,
      let revision = (value["revision"] as? NSNumber)?.int64Value,
      revision > 0,
      let zoneId = value["timeZoneId"] as? String,
      let zone = TimeZone(identifier: zoneId),
      let rawDays = value["precomputedDays"] as? [String: [String: Any]]
    else { return nil }

    var days: [String: [String: Date]] = [:]
    for (day, entries) in rawDays {
      guard day.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else {
        continue
      }
      var times: [String: Date] = [:]
      for name in displayPrayers {
        guard let number = entries[name] as? NSNumber else { continue }
        let milliseconds = number.doubleValue
        guard milliseconds.isFinite, milliseconds > 0 else { continue }
        times[name] = Date(timeIntervalSince1970: milliseconds / 1000)
      }
      if !times.isEmpty { days[day] = times }
    }
    guard !days.isEmpty else { return nil }

    let locality = (value["locality"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let country = (value["countryName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let place = [locality, country].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: ", ")
    let method = (value["methodLabel"] as? String)
      ?? (value["calculationMethod"] as? String) ?? ""
    return PrayerMenuSnapshot(
      timeZone: zone,
      location: place.isEmpty ? zoneId : place,
      method: method,
      provisional: (value["provisional"] as? Bool) ?? false,
      days: days,
      iqamahMinutes: iqamahMinutes(value["iqamahMinutes"])
    )
  }

  func dayKey(for instant: Date) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let parts = calendar.dateComponents([.year, .month, .day], from: instant)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
  }

  func today(at now: Date) -> [String: Date]? { days[dayKey(for: now)] }

  func nextPrayer(after now: Date) -> (name: String, time: Date)? {
    guard today(at: now) != nil else { return nil }
    return days.values.flatMap { day in
      Self.obligatoryPrayers.compactMap { name -> (name: String, time: Date)? in
        guard let time = day[name], time > now else { return nil }
        return (name, time)
      }
    }.min { $0.time < $1.time }
  }

  func moment(at now: Date) -> (name: String, time: Date, isElapsed: Bool, stateEnd: Date)? {
    guard today(at: now) != nil else { return nil }
    if let previous = previousPrayer(before: now) {
      let end = previous.time.addingTimeInterval(TimeInterval(iqamahMinutes[previous.name] ?? 0) * 60)
      if now < end { return (previous.name, previous.time, true, end) }
    }
    guard let next = nextPrayer(after: now) else { return nil }
    return (next.name, next.time, false, next.time)
  }

  func previousPrayer(before now: Date) -> (name: String, time: Date)? {
    days.values.flatMap { day in
      Self.obligatoryPrayers.compactMap { name -> (name: String, time: Date)? in
        guard let time = day[name], time <= now else { return nil }
        return (name, time)
      }
    }.max { $0.time < $1.time }
  }
}

private final class PrayerMenuPanel: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
}

private struct PrayerMenuBackground: NSViewRepresentable {
  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = .popover
    view.blendingMode = .behindWindow
    view.state = .active
    view.wantsLayer = true
    view.layer?.cornerRadius = 12
    view.layer?.masksToBounds = true
    return view
  }

  func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

final class PrayerMenuBarController: NSObject, ObservableObject {
  static let appGroupId = "group.hudaHomeApp"
  private static let preferencesKey = "prayer_menu_bar_preferences_v1"
  private static let presentationKey = "prayer_menu_bar_presentation_v1"

  static func usesRightToLeftLayout(for localeCode: String) -> Bool {
    let language = Locale(identifier: localeCode).languageCode ?? localeCode
    return ["ar", "ur"].contains(language)
  }

  static func imagePosition(for localeCode: String, showsText: Bool) -> NSControl.ImagePosition {
    guard showsText else { return .imageOnly }
    return usesRightToLeftLayout(for: localeCode) ? .imageLeft : .imageRight
  }

  static func parsedPrimaryColor(_ raw: Any?) -> UInt32? {
    guard let number = raw as? NSNumber else { return nil }
    let value = number.int64Value
    guard value >= 0, value <= Int64(UInt32.max), (value & 0xFF000000) == 0xFF000000 else {
      return nil
    }
    return UInt32(value)
  }

  @Published private(set) var snapshot: PrayerMenuSnapshot?
  @Published private(set) var now = Date()
  @Published private(set) var strings: [String: String] = [:]
  @Published private(set) var localeCode = "en"
  @Published private(set) var primaryColorARGB: UInt32 = 0xFF134E4A
  @Published private(set) var prayerAudioSession: String?
  @Published private(set) var prayerFocusSession: String?
  @Published private(set) var prayerFocusCanDismiss = true
  @Published private(set) var prayerServiceError: String?

  var accentColor: Color {
    Color(
      .sRGB,
      red: Double((primaryColorARGB >> 16) & 0xFF) / 255,
      green: Double((primaryColorARGB >> 8) & 0xFF) / 255,
      blue: Double(primaryColorARGB & 0xFF) / 255,
      opacity: 1
    )
  }

  private let defaults = UserDefaults(suiteName: appGroupId) ?? .standard
  private var statusItem: NSStatusItem?
  private var panel: PrayerMenuPanel?
  private var previousActivationPolicy: NSApplication.ActivationPolicy?
  private var globalClickMonitor: Any?
  private var localEventMonitor: Any?
  private var timer: Timer?
  private var observers: [NSObjectProtocol] = []
  private var channel: FlutterMethodChannel?
  private var flutterReady = false
  private var pendingSettingsAction = false
  private var started = false
  private(set) var enabled = true
  private var style: PrayerMenuStyle = .iconNameCountdown

  func start(channel: FlutterMethodChannel) {
    self.channel = channel
    if started { return }; started = true
    let stored = defaults.dictionary(forKey: Self.preferencesKey) ?? [:]
    enabled = stored["enabled"] as? Bool ?? true
    style = PrayerMenuStyle.fromStorage(stored["style"] as? String)
    let presentation = defaults.dictionary(forKey: Self.presentationKey) ?? [:]
    localeCode = presentation["locale"] as? String ?? "en"
    strings = presentation["strings"] as? [String: String] ?? [:]
    primaryColorARGB = Self.parsedPrimaryColor(presentation["primaryColor"]) ?? primaryColorARGB
    let menuPanel = PrayerMenuPanel(
      contentRect: NSRect(x: 0, y: 0, width: 322, height: 180),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    menuPanel.isFloatingPanel = true
    menuPanel.hidesOnDeactivate = false
    // Full-screen apps can cover ordinary floating and status-bar window levels.
    menuPanel.level = .screenSaver
    menuPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    if #available(macOS 13.0, *) {
      menuPanel.collectionBehavior.insert(.canJoinAllApplications)
    }
    menuPanel.isOpaque = false
    menuPanel.backgroundColor = .clear
    menuPanel.hasShadow = true
    menuPanel.isReleasedWhenClosed = false
    menuPanel.contentViewController = NSHostingController(
      rootView: PrayerMenuPopover(controller: self).background(PrayerMenuBackground())
    )
    panel = menuPanel
    reloadSnapshot()
    updateStatusItem()
    updateTimer()
    let center = NotificationCenter.default
    for name in [NSNotification.Name.NSSystemClockDidChange,
                 NSNotification.Name.NSSystemTimeZoneDidChange] {
      observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        self?.reloadSnapshot()
      })
    }
    observers.append(NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
    ) { [weak self] _ in self?.reloadSnapshot() })
  }

  deinit {
    timer?.invalidate()
    if let globalClickMonitor { NSEvent.removeMonitor(globalClickMonitor) }
    if let localEventMonitor { NSEvent.removeMonitor(localEventMonitor) }
    for observer in observers {
      NotificationCenter.default.removeObserver(observer)
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
    }
  }

  func preferences() -> [String: Any] { ["enabled": enabled, "style": style.rawValue] }

  func setPreferences(_ arguments: [String: Any]) -> Bool {
    guard let newEnabled = arguments["enabled"] as? Bool,
      let rawStyle = arguments["style"] as? String,
      let newStyle = PrayerMenuStyle(rawValue: rawStyle) else { return false }
    enabled = newEnabled
    style = newStyle
    defaults.set(preferences(), forKey: Self.preferencesKey)
    updateTimer()
    updateStatusItem()
    return true
  }

  func setPresentation(_ arguments: [String: Any]) -> Bool {
    guard let locale = arguments["locale"] as? String,
      let nextStrings = arguments["strings"] as? [String: String],
      let nextPrimaryColor = Self.parsedPrimaryColor(arguments["primaryColor"]),
      !locale.isEmpty else { return false }
    localeCode = locale
    strings = nextStrings
    primaryColorARGB = nextPrimaryColor
    defaults.set(
      ["locale": locale, "strings": nextStrings, "primaryColor": Int(nextPrimaryColor)],
      forKey: Self.presentationKey
    )
    updateStatusItem()
    return true
  }

  func markFlutterReady() {
    flutterReady = true
    if pendingSettingsAction {
      pendingSettingsAction = false
      channel?.invokeMethod("openPrayerSettings", arguments: nil)
    }
  }

  func reloadSnapshot() {
    if let theme = (NSApp.delegate as? AppDelegate)?.prayerService.configuration.themeMode {
      panel?.appearance = theme == "system" ? nil : NSAppearance(named: theme == "dark" ? .darkAqua : .aqua)
    }
    let raw = defaults.string(forKey: "prayer_widget_display_v1")
    snapshot = (NSApp.delegate as? AppDelegate)?.prayerService.menuSnapshot() ?? raw.flatMap(PrayerMenuSnapshot.parse)
    let hasToday = snapshot?.today(at: Date()) != nil
    panel?.setContentSize(NSSize(width: 322, height: hasToday ? 560 : 250))
    if panel?.isVisible == true, let button = statusItem?.button {
      positionPanel(below: button)
    }
    tick()
  }

  private func tick() {
    now = Date()
    if !enabled && panel?.isVisible != true { return }
    updateStatusItem()
    updateTimer()
  }

  private func updateTimer() {
    timer?.invalidate(); timer = nil
    guard enabled else { return }
    let minute = floor(now.timeIntervalSince1970 / 60) * 60 + 60
    let boundary = min(snapshot?.moment(at: now)?.stateEnd.timeIntervalSince1970 ?? minute,
                       snapshot?.nextPrayer(after: now)?.time.timeIntervalSince1970 ?? minute)
    timer = Timer(timeInterval: max(0.05, min(minute, boundary) - now.timeIntervalSince1970), repeats: false) {
      [weak self] _ in self?.tick()
    }
    if let timer { RunLoop.main.add(timer, forMode: .common) }
  }

  func refreshServiceState() {
    guard let service = (NSApp.delegate as? AppDelegate)?.prayerService else { return }
    prayerAudioSession = service.audio.session
    prayerFocusSession = service.panels.session
    prayerFocusCanDismiss = service.panels.canDismiss
    prayerServiceError = service.status()["error"] as? String
    reloadSnapshot()
  }
  func stopAdhan() { (NSApp.delegate as? AppDelegate)?.prayerService.audio.stop() }
  func dismissFocus() { (NSApp.delegate as? AppDelegate)?.prayerService.panels.dismiss() }

  private func updateStatusItem() {
    guard enabled else {
      if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
      statusItem = nil
      closePanel()
      return
    }
    if statusItem == nil {
      statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
      statusItem?.button?.target = self
      statusItem?.button?.action = #selector(togglePanel(_:))
      statusItem?.button?.sendAction(on: [.leftMouseUp])
    }
    guard let button = statusItem?.button else { return }
    let next = snapshot?.moment(at: now)
    if button.image == nil {
      let image = NSImage(named: NSImage.Name("HudaMenuIcon"))?.copy() as? NSImage
      image?.isTemplate = true
      image?.size = NSSize(width: 20, height: 11)
      button.image = image
    }
    button.imagePosition = Self.imagePosition(
      for: localeCode, showsText: next != nil && style != .iconOnly
    )
    guard let next else {
      button.title = ""
      button.toolTip = localized("prayerTimes", fallback: "Prayer Times")
      return
    }
    let name = strings[next.name] ?? next.name.capitalized
    switch style {
    case .iconOnly:
      button.title = ""
    case .iconNameCountdown:
      let pattern = next.isElapsed
        ? (strings["nameElapsed"] ?? "{prayer} {time}")
        : (strings["nameCountdown"] ?? "{prayer} in {time}")
      let counter = next.isElapsed
        ? elapsedText(now.timeIntervalSince(next.time))
        : countdownText(next.time.timeIntervalSince(now))
      button.title = pattern.replacingOccurrences(of: "{prayer}", with: name)
        .replacingOccurrences(of: "{time}", with: "\u{2068}\(counter)\u{2069}") + "  "
    case .iconNameClock:
      button.title = "\(name) \(clockText(next.time))  "
    }
    button.toolTip = "\(name) \(clockText(next.time))"
  }

  func localized(_ key: String, fallback: String) -> String { strings[key] ?? fallback }

  func clockText(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = presentationLocale
    formatter.timeZone = snapshot?.timeZone ?? .current
    if (NSApp.delegate as? AppDelegate)?.prayerService.configuration.use24HourClock == true {
      formatter.dateFormat = "HH:mm"
    } else { formatter.timeStyle = .short }
    return formatter.string(from: date)
  }

  func dateText(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = presentationLocale
    formatter.timeZone = snapshot?.timeZone ?? .current
    formatter.dateStyle = .full
    return formatter.string(from: date)
  }

  func elapsedText(_ interval: TimeInterval) -> String {
    "+" + countdownText(floor(max(0, interval) / 60) * 60)
  }

  func countdownText(_ interval: TimeInterval) -> String {
    let minutes = max(0, Int(ceil(interval / 60)))
    let hours = minutes / 60
    let remainder = minutes % 60
    let number = NumberFormatter()
    number.numberStyle = .decimal
    number.locale = presentationLocale
    let hourText = number.string(from: NSNumber(value: hours)) ?? "\(hours)"
    let minuteText = number.string(from: NSNumber(value: remainder)) ?? "\(remainder)"
    let hourUnit = localized("hourUnit", fallback: "h")
    let minuteUnit = localized("minuteUnit", fallback: "m")
    return hours > 0
      ? "\(hourText)\(hourUnit) \(minuteText)\(minuteUnit)"
      : "\(minuteText)\(minuteUnit)"
  }

  private var presentationLocale: Locale {
    let numerals = (NSApp.delegate as? AppDelegate)?.prayerService.configuration.numerals
    return Locale(identifier: "\(localeCode)@numbers=\(numerals == "eastern" ? "arab" : "latn")")
  }

  @objc private func togglePanel(_ sender: Any?) {
    guard let button = statusItem?.button, let panel else { return }
    if panel.isVisible {
      closePanel()
      return
    }
    reloadSnapshot()
    positionPanel(below: button)
    let policy = NSApp.activationPolicy()
    // Accessory mode lets the panel join another app's full-screen Space.
    // Restore Huda's normal Dock presence as soon as the panel closes.
    if policy != .accessory, NSApp.setActivationPolicy(.accessory) {
      previousActivationPolicy = policy
    }
    panel.orderFrontRegardless()
    panel.makeKey()
    installDismissMonitors()
  }

  private func positionPanel(below button: NSStatusBarButton) {
    guard let panel, let statusWindow = button.window else { return }
    let buttonFrame = statusWindow.convertToScreen(button.convert(button.bounds, to: nil))
    let visibleFrame = (statusWindow.screen ?? NSScreen.main)?.visibleFrame ?? buttonFrame
    let margin: CGFloat = 8
    let x = min(
      max(buttonFrame.maxX - panel.frame.width, visibleFrame.minX + margin),
      visibleFrame.maxX - panel.frame.width - margin
    )
    let y = max(
      min(buttonFrame.minY - panel.frame.height - 4, visibleFrame.maxY - panel.frame.height - margin),
      visibleFrame.minY + margin
    )
    panel.setFrameOrigin(NSPoint(x: x, y: y))
  }

  private func installDismissMonitors() {
    globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown]
    ) { [weak self] _ in
      let point = NSEvent.mouseLocation
      DispatchQueue.main.async {
        guard let self, !self.isInsideMenuOrStatusItem(at: point) else { return }
        self.closePanel()
      }
    }
    localEventMonitor = NSEvent.addLocalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown, .keyDown]
    ) { [weak self] event in
      guard let self else { return event }
      if event.type == .keyDown {
        if event.keyCode == 53 {
          self.closePanel()
          return nil
        }
      } else if !self.isInsideMenuOrStatusItem(at: NSEvent.mouseLocation) {
        self.closePanel()
      }
      return event
    }
  }

  private func isInsideMenuOrStatusItem(at point: NSPoint) -> Bool {
    if panel?.frame.contains(point) == true { return true }
    guard let button = statusItem?.button, let window = button.window else { return false }
    let buttonFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
    return buttonFrame.insetBy(dx: -3, dy: -3).contains(point)
  }

  private func closePanel() {
    panel?.orderOut(nil)
    if let globalClickMonitor {
      NSEvent.removeMonitor(globalClickMonitor)
      self.globalClickMonitor = nil
    }
    if let localEventMonitor {
      NSEvent.removeMonitor(localEventMonitor)
      self.localEventMonitor = nil
    }
    if let previousActivationPolicy {
      self.previousActivationPolicy = nil
      NSApp.setActivationPolicy(previousActivationPolicy)
    }
  }

  func requestSettings() {
    closePanel()
    (NSApp.delegate as? AppDelegate)?.revealMainWindow()
    if flutterReady { channel?.invokeMethod("openPrayerSettings", arguments: nil) }
    else { pendingSettingsAction = true }
  }

  func quit() { NSApp.terminate(nil) }
}

private struct PrayerMenuPopover: View {
  @ObservedObject var controller: PrayerMenuBarController

  private var accent: Color { controller.accentColor }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let snapshot = controller.snapshot,
        let today = snapshot.today(at: controller.now),
        let next = snapshot.nextPrayer(after: controller.now) {
        header(date: controller.dateText(controller.now))
        HStack(spacing: 10) {
          VStack(alignment: .leading, spacing: 2) {
            Text(controller.localized(next.name, fallback: next.name.capitalized))
              .font(.title2).fontWeight(.bold)
            Text(controller.countdownText(next.time.timeIntervalSince(controller.now)))
              .font(.callout).foregroundColor(.secondary)
          }
          Spacer()
          Text(controller.clockText(next.time))
            .font(.title3).fontWeight(.semibold).foregroundColor(accent)
        }
        Divider()
        ForEach(PrayerMenuSnapshot.displayPrayers, id: \.self) { prayer in
          let time = today[prayer]
          prayerRow(prayer, time: time, isNext: next.name == prayer && next.time == time)
        }
        Divider()
        VStack(alignment: .leading, spacing: 3) {
          Label(snapshot.location, systemImage: "location")
          if !snapshot.method.isEmpty {
            Label(snapshot.method, systemImage: "moon.circle")
          }
          if snapshot.provisional {
            Label(controller.localized("verifyLocation", fallback: "Verify location in Huda"),
                  systemImage: "exclamationmark.triangle")
              .foregroundColor(.orange)
          }
        }
        .font(.caption).foregroundColor(.secondary)
      } else {
        header()
        VStack(alignment: .leading, spacing: 8) {
          Text(controller.localized("prayerTimes", fallback: "Prayer Times"))
            .font(.headline)
          Text(controller.localized("needsSetup", fallback: "Open Huda Prayer Times to set your location."))
            .font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      Divider()
      if controller.prayerAudioSession != nil {
        Button(action: controller.stopAdhan) {
          Label(controller.localized("stopAdhan", fallback: "Stop Adhan"), systemImage: "stop.circle")
        }.buttonStyle(.plain)
      }
      if controller.prayerFocusSession != nil && controller.prayerFocusCanDismiss {
        Button(controller.localized("dismissFocus", fallback: "Dismiss"), action: controller.dismissFocus).buttonStyle(.plain)
      }
      if controller.prayerServiceError != nil {
        Text(controller.localized("serviceError", fallback: "Prayer reminders need attention. Open Prayer Settings."))
          .font(.caption).foregroundColor(.orange).lineLimit(3)
      }
      Button(action: controller.requestSettings) {
        Label(controller.localized("prayerSettings", fallback: "Prayer Settings…"),
              systemImage: "slider.horizontal.3")
          .frame(maxWidth: .infinity, alignment: .leading)
      }.buttonStyle(.plain)
      Button(action: controller.quit) {
        Label(controller.localized("quitHuda", fallback: "Quit Huda"), systemImage: "power")
          .frame(maxWidth: .infinity, alignment: .leading)
      }.buttonStyle(.plain)
    }
    .padding(14)
    .frame(width: 322, height: controller.snapshot?.today(at: controller.now) == nil ? 250 : 560,
           alignment: .topLeading)
    .environment(\.locale, Locale(identifier: controller.localeCode))
    .environment(\.layoutDirection,
                 PrayerMenuBarController.usesRightToLeftLayout(for: controller.localeCode)
                   ? .rightToLeft : .leftToRight)
  }

  private func header(date: String? = nil) -> some View {
    HStack {
      if let date {
        Text(date.uppercased())
          .font(.caption2).fontWeight(.semibold).foregroundColor(.secondary)
      }
      Spacer(minLength: 20)
      Image("HudaMenuIcon").resizable().renderingMode(.template)
        .frame(width: 30, height: 17).foregroundColor(accent)
    }
  }

  private func prayerRow(_ prayer: String, time: Date?, isNext: Bool) -> some View {
    let isPast = time.map { $0 < controller.now && !isNext } ?? false
    return HStack(spacing: 10) {
      Image(systemName: icon(for: prayer)).frame(width: 18).foregroundColor(isNext ? accent : .secondary)
      Text(controller.localized(prayer, fallback: prayer.capitalized))
        .fontWeight(isNext ? .semibold : .regular)
      Spacer()
      if isNext, let time {
        Text(controller.countdownText(time.timeIntervalSince(controller.now)))
          .font(.caption).foregroundColor(accent)
      }
      Text(time.map(controller.clockText) ?? "--:--").fontWeight(isNext ? .semibold : .regular)
    }
    .font(.callout)
    .padding(.horizontal, 8).padding(.vertical, 5)
    .background(RoundedRectangle(cornerRadius: 8).fill(isNext ? accent.opacity(0.13) : Color.clear))
    .opacity(isPast ? 0.5 : 1)
  }

  private func icon(for prayer: String) -> String {
    switch prayer {
    case "fajr": return "moon.stars"
    case "sunrise": return "sunrise"
    case "dhuhr": return "sun.max"
    case "asr": return "sun.haze"
    case "maghrib": return "sunset"
    default: return "moon"
    }
  }
}
