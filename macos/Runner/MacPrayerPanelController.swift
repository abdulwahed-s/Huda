import Cocoa
import CoreText
import SwiftUI

private final class MacPrayerPanel: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
  var emergencyExit: (() -> Void)?
  override func cancelOperation(_ sender: Any?) { emergencyExit?() }
  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if event.type == .keyDown && event.keyCode == 53 { emergencyExit?(); return true }
    return super.performKeyEquivalent(with: event)
  }
}

final class MacPrayerPanelController: ObservableObject {
  @Published private(set) var remaining: TimeInterval = 0
  @Published private(set) var audioPlaying = false
  private(set) var session: String?
  private(set) var deadline: Date?
  private(set) var policy = MacPrayerExperience()
  private var configuration = MacPrayerConfiguration()
  private var prayer = "fajr"
  private var prayerTime = Date()
  private var zone = TimeZone.current
  private var total: TimeInterval = 600
  private var panels: [MacPrayerPanel] = []
  private var timer: Timer?
  private var screenObserver: NSObjectProtocol?
  private var activity: NSObjectProtocol?
  private static var registeredFonts: [String: String] = [:]
  var stopAudio: (() -> Void)?
  var onDismiss: ((String) -> Void)?
  var onChanged: (() -> Void)?
  var canDismiss: Bool { !policy.focusCommitment || remaining <= 0 }

  init() {
    screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
      object: nil, queue: .main) { [weak self] _ in self?.rebuildPanels() }
  }
  deinit { if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) } }
  func show(session: String, prayer: String, time: Date, zone: TimeZone,
    configuration: MacPrayerConfiguration, preview: Bool) {
    dismiss(force: true)
    self.session = session; self.prayer = prayer; prayerTime = time; self.zone = zone
    self.configuration = configuration; policy = configuration.experience
    registerFont()
    total = preview ? 15 : TimeInterval(policy.focusDurationSeconds)
    deadline = Date().addingTimeInterval(total); remaining = total
    activity = ProcessInfo.processInfo.beginActivity(options: .userInitiated, reason: "Showing prayer Focus timer")
    rebuildPanels()
    let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
      guard let self, let deadline = self.deadline else { return }
      self.remaining = max(0, deadline.timeIntervalSinceNow)
      if self.remaining <= 0 { self.dismiss(force: true) }
    }
    RunLoop.main.add(timer, forMode: .common); self.timer = timer
    onChanged?()
  }
  func setAudioPlaying(_ value: Bool) { audioPlaying = value }
  func dismiss(session: String? = nil, force: Bool = false) {
    if let session, self.session != session { return }
    guard force || canDismiss else { return }
    let old = self.session
    timer?.invalidate(); timer = nil
    panels.forEach { $0.orderOut(nil); $0.close() }; panels.removeAll()
    self.session = nil; deadline = nil; remaining = 0
    if let activity { ProcessInfo.processInfo.endActivity(activity) }; activity = nil
    if let old { onDismiss?(old) }
    onChanged?()
  }
  private func rebuildPanels() {
    guard session != nil else { return }
    panels.forEach { $0.orderOut(nil); $0.close() }; panels.removeAll()
    let screens = NSScreen.screens
    var selected: [NSScreen]
    if policy.focusDisplay == "all" { selected = screens }
    else if policy.focusDisplay.hasPrefix("display:"),
      let id = UInt32(policy.focusDisplay.dropFirst(8)),
      let screen = screens.first(where: { ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == id }) {
      selected = [screen]
    } else {
      selected = [screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main].compactMap { $0 }
    }
    for screen in selected {
      let immersive = policy.focusStyle == .immersive
      let visible = screen.visibleFrame
      let frame = immersive ? screen.frame : NSRect(x: visible.maxX - 436, y: visible.maxY - 496, width: 420, height: 480)
      let panel = MacPrayerPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
      panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
      if #available(macOS 13.0, *) { panel.collectionBehavior.insert(.canJoinAllApplications) }
      panel.hidesOnDeactivate = false; panel.isFloatingPanel = true
      // isFloatingPanel resets the level to floating; apply our level last.
      panel.level = .screenSaver
      panel.isReleasedWhenClosed = false
      panel.backgroundColor = .windowBackgroundColor; panel.hasShadow = !immersive
      panel.emergencyExit = { [weak self] in self?.dismiss(force: true) }
      if configuration.themeMode != "system" {
        panel.appearance = NSAppearance(named: configuration.themeMode == "dark" ? .darkAqua : .aqua)
      }
      let host = NSHostingController(rootView: MacPrayerFocusView(controller: self)
        .environment(\.layoutDirection, PrayerMenuBarController.usesRightToLeftLayout(for: configuration.locale) ? .rightToLeft : .leftToRight)
        .frame(width: frame.width, height: frame.height))
      // A flexible ScrollView has no intrinsic height. The screen selection
      // owns sizing, so SwiftUI must not resize the window to that ideal size.
      if #available(macOS 13.0, *) { host.sizingOptions = [] }
      panel.contentViewController = host
      panel.setFrame(frame, display: false)
      panel.orderFrontRegardless()
      // Nonactivating panels can receive keyboard input without activating the
      // app. Escape must work immediately, including over another app's space.
      panel.makeKey()
      panels.append(panel)
    }
  }
  func text(_ key: String, _ fallback: String) -> String { configuration.strings[key] ?? fallback }
  private func registerFont() {
    let family = configuration.fontFamily ?? "Amiri"
    guard Self.registeredFonts[family] == nil,
      let filename = ["Amiri": "Amiri-Regular.ttf", "IndoPak": "Indopak.ttf", "uthmanic": "hafs-uthmanic-v14-full-org.ttf"][family],
      let frameworks = Bundle.main.privateFrameworksURL else { return }
    let url = frameworks.appendingPathComponent("App.framework/Resources/flutter_assets/assets/fonts/\(filename)")
    if FileManager.default.fileExists(atPath: url.path) {
      CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
      let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor]
      let nativeFamily = descriptors?.first.flatMap { CTFontDescriptorCopyAttribute($0, kCTFontFamilyNameAttribute) as? String }
      Self.registeredFonts[family] = nativeFamily ?? family
    }
  }
  func font(_ size: Double) -> Font {
    let family = configuration.fontFamily ?? "Amiri"
    return .custom(Self.registeredFonts[family] ?? family, size: size * textScale)
  }
  var textScale: Double { configuration.textScale ?? 1 }
  private var presentationLocale: Locale {
    Locale(identifier: "\(configuration.locale)@numbers=\(configuration.numerals == "eastern" ? "arab" : "latn")")
  }
  var prayerName: String { text(prayer, prayer.capitalized) }
  var clock: String {
    let f = DateFormatter(); f.locale = presentationLocale; f.timeZone = zone
    if configuration.use24HourClock { f.dateFormat = "HH:mm" } else { f.timeStyle = .short }
    return f.string(from: prayerTime)
  }
  var countdown: String {
    let seconds = max(0, Int(ceil(remaining)))
    let f = NumberFormatter(); f.locale = presentationLocale
    func number(_ n: Int) -> String { f.minimumIntegerDigits = 2; return f.string(from: NSNumber(value: n)) ?? "\(n)" }
    return "\(number(seconds / 60)):\(number(seconds % 60))"
  }
  var progress: Double { min(1, max(0, 1 - remaining / total)) }
  var accent: Color {
    let color = configuration.primaryColor
    return Color(.sRGB, red: Double((color >> 16) & 255) / 255,
      green: Double((color >> 8) & 255) / 255, blue: Double(color & 255) / 255, opacity: 1)
  }
}

private struct MacPrayerFocusView: View {
  @ObservedObject var controller: MacPrayerPanelController
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  var body: some View {
    VStack(spacing: 12) {
      ScrollView {
        VStack(spacing: 12) {
          Text(controller.prayerName).font(controller.font(32)).bold().accessibilityAddTraits(.isHeader)
          // Quran fonts can map eastern digits to verse ornaments or omit them.
          // Use the system's numeral coverage for the localized clock.
          Text(controller.clock).font(.system(size: 20 * controller.textScale)).foregroundColor(.secondary)
          Text(controller.text("focusMessage", "It is time to pray. Take a break.")).multilineTextAlignment(.center)
          Text(controller.text("verse", "Indeed, prayer has been decreed upon the believers at specified times."))
            .font(controller.font(20)).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
          Text(controller.text("verseReference", "An-Nisa · 4:103")).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
      }
      // Keep the timer and exit controls available when the content scrolls at
      // large text sizes. Compact panels stack controls before they compress.
      VStack(spacing: 12) {
        Text(controller.countdown).font(.system(size: 34 * controller.textScale, design: .monospaced))
          .accessibilityLabel(controller.text("remaining", "Time remaining"))
          .accessibilityValue(controller.countdown)
        ProgressView(value: controller.progress).accentColor(controller.accent).accessibilityHidden(true)
        if controller.policy.focusStyle == .compact && controller.textScale > 1.25 {
          VStack(spacing: 8) { controls }
        } else {
          HStack { controls }
        }
      }
      .fixedSize(horizontal: false, vertical: true)
    }
    .padding(controller.policy.focusStyle == .immersive ? 40 : 16)
    .font(controller.font(16))
    .frame(maxWidth: controller.policy.focusStyle == .immersive ? 680 : .infinity,
      maxHeight: controller.policy.focusStyle == .immersive ? 760 : .infinity)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(NSColor.windowBackgroundColor).opacity(reduceTransparency ? 1 : 0.98))
    .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: controller.audioPlaying)
  }
  /// One action at a time: Dismiss also stops the adhan (onDismiss), so
  /// "Stop Adhan" only appears while Focus can't be closed yet.
  @ViewBuilder private var controls: some View {
    if controller.canDismiss {
      Button(controller.text("dismiss", "Dismiss")) { controller.dismiss() }
        .keyboardShortcut(.defaultAction)
    } else {
      if controller.audioPlaying {
        Button(controller.text("stop", "Stop Adhan")) { controller.stopAudio?() }
      }
      Text(controller.text("lockedHint", "Focus ends when the timer reaches zero.")).font(.caption)
    }
    Button(controller.text("emergencyExit", "Emergency exit")) { controller.dismiss(force: true) }
      .keyboardShortcut(.escape, modifiers: [])
  }
}
