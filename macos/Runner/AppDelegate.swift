import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  lazy var prayerMenuBar = PrayerMenuBarController()
  lazy var prayerService = MacPrayerService()

  func revealMainWindow() {
    guard let window = NSApp.windows.first(where: { $0 is MainFlutterWindow }) else { return }
    NSApp.setActivationPolicy(.regular)
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
