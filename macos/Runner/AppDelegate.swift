import Cocoa
import FlutterMacOS
import app_links

@main
class AppDelegate: FlutterAppDelegate {
  weak var widgetChannel: FlutterMethodChannel?
  lazy var prayerMenuBar = PrayerMenuBarController()
  lazy var prayerService = MacPrayerService()
  private var pendingWidgetURL: String?
  private var initialLinkRequested = false
  private let prayerURLHandler = MacPrayerURLHandler()
  #if DEBUG
  private var deviceVerification: MacPrayerDeviceVerification?
  #endif

  override func applicationWillFinishLaunching(_ notification: Notification) {
    super.applicationWillFinishLaunching(notification)
    let classifier = MacPrayerLaunchClassifier.shared
    classifier.onClassified = { [weak self] context in
      guard let self else { return }
      self.prayerService.hiddenLaunch = context == .login
      if context == .login {
        NSApp.setActivationPolicy(.accessory)
        if !self.prayerService.backgroundEnabled { NSApp.terminate(nil) }
      } else { self.revealMainWindow() }
    }
    classifier.install()
    prayerService.onChanged = { [weak self] in self?.prayerMenuBar.refreshServiceState() }
    prayerService.start()
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Flutter forwards plugin lifecycle notifications through its registrar;
    // FlutterAppDelegate does not implement this optional delegate selector.
    MacPrayerLaunchClassifier.shared.finishIfNoOpenEvent()
    // Install after plugin launch observers have registered their URL handler.
    prayerURLHandler.onOpenURL = { [weak self] url in
      guard url.scheme == "huda", let self else { return }
      self.revealMainWindow()
      self.forwardWidgetURL(url)
    }
    prayerURLHandler.install()
    #if DEBUG
    deviceVerification = MacPrayerDeviceVerification(delegate: self)
    #endif
  }

  override func applicationWillTerminate(_ notification: Notification) {
    prayerURLHandler.restoreHandler()
    prayerService.stop()
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    revealMainWindow()
    for url in urls where url.scheme == "huda" {
      forwardWidgetURL(url)
    }
    super.application(application, open: urls)
  }

  private func forwardWidgetURL(_ url: URL) {
    if initialLinkRequested {
      widgetChannel?.invokeMethod("widgetClicked", arguments: url.absoluteString)
    } else {
      pendingWidgetURL = url.absoluteString
    }
  }

  func takeInitialWidgetURL() -> String? {
    guard !initialLinkRequested else { return nil }
    initialLinkRequested = true
    defer { pendingWidgetURL = nil }
    if let pendingWidgetURL { return pendingWidgetURL }
    // A cold-launch URL can arrive before our forwarding handler is installed.
    // app_links retains that event; its public initial-link method replies synchronously.
    var initialURL: String?
    AppLinks.shared.handle(FlutterMethodCall(methodName: "getInitialLink", arguments: nil)) { value in
      if let text = value as? String, URL(string: text)?.scheme == "huda" { initialURL = text }
    }
    return initialURL
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return !prayerService.backgroundEnabled
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    revealMainWindow()
    return true
  }

  func revealMainWindow() {
    guard let window = NSApp.windows.first(where: { $0 is MainFlutterWindow }) else { return }
    (window as? MainFlutterWindow)?.allowPresentation = true
    NSApp.setActivationPolicy(.regular)
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  func application(_ app: NSApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool { false }
}
