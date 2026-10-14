import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  lazy var prayerMenuBar = PrayerMenuBarController()
  lazy var prayerService = MacPrayerService()
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
    super.application(application, open: urls)
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
