import Cocoa
import Carbon
import ServiceManagement

/// Captures the initial open-application event before AppKit handles it. The
/// previous handler is called with its original refcon, preserving AppKit and
/// Flutter/plugin forwarding. The main nib window remains unordered meanwhile.
final class MacPrayerLaunchClassifier {
  static let shared = MacPrayerLaunchClassifier()
  enum Context { case pending, manual, login }
  private(set) var context = Context.pending
  private var previousHandler: AEEventHandlerUPP?
  private var previousRefcon: UnsafeMutableRawPointer?
  private var installed = false
  var onClassified: ((Context) -> Void)?

  static func context(property: OSType?) -> Context {
    property == OSType(keyAELaunchedAsLogInItem) || property == OSType(keyAELaunchedAsServiceItem) ? .login : .manual
  }
  func install() {
    guard !installed else { return }
    installed = true
    AEGetEventHandler(AEEventClass(kCoreEventClass), AEEventID(kAEOpenApplication), &previousHandler, &previousRefcon, false)
    let callback: AEEventHandlerUPP = { event, reply, refcon in
      guard let refcon else { return OSErr(errAEEventNotHandled) }
      let classifier = Unmanaged<MacPrayerLaunchClassifier>.fromOpaque(refcon).takeUnretainedValue()
      return classifier.handle(event, reply: reply)
    }
    AEInstallEventHandler(AEEventClass(kCoreEventClass), AEEventID(kAEOpenApplication), callback, Unmanaged.passUnretained(self).toOpaque(), false)
  }
  func handle(_ event: UnsafePointer<AppleEvent>?, reply: UnsafeMutablePointer<AppleEvent>?) -> OSErr {
    var property: OSType = 0
    var actualType: DescType = 0
    var size = 0
    let result = AEGetParamPtr(event, AEKeyword(keyAEPropData), DescType(typeWildCard), &actualType,
      &property, MemoryLayout<OSType>.size, &size)
    if context == .pending {
      context = Self.context(property: result == noErr ? property : nil)
      onClassified?(context)
    }
    if let previousHandler { return previousHandler(event, reply, previousRefcon) }
    return OSErr(noErr)
  }
  func restoreHandler() {
    guard installed else { return }; installed = false
    if let previousHandler {
      AEInstallEventHandler(AEEventClass(kCoreEventClass), AEEventID(kAEOpenApplication), previousHandler, previousRefcon, false)
    }
  }
  func finishIfNoOpenEvent() {
    // Direct executable/debug launches need not send an open-application event.
    if context == .pending { context = .manual; onClassified?(context) }
  }
}

/// app_links handles Get URL Apple events directly instead of invoking the
/// application's openURLs delegate. Reveal Huda and forward the same event to
/// that plugin, retaining its refcon and result.
final class MacPrayerURLHandler {
  private var previousHandler: AEEventHandlerUPP?
  private var previousRefcon: UnsafeMutableRawPointer?
  private var callback: AEEventHandlerUPP?
  var onOpenURL: ((URL) -> Void)?

  func install() {
    guard callback == nil else { return }
    AEGetEventHandler(AEEventClass(kInternetEventClass), AEEventID(kAEGetURL), &previousHandler, &previousRefcon, false)
    let handler: AEEventHandlerUPP = { event, reply, refcon in
      guard let refcon else { return OSErr(errAEEventNotHandled) }
      return Unmanaged<MacPrayerURLHandler>.fromOpaque(refcon).takeUnretainedValue().handle(event, reply: reply)
    }
    callback = handler
    AEInstallEventHandler(AEEventClass(kInternetEventClass), AEEventID(kAEGetURL), handler,
      Unmanaged.passUnretained(self).toOpaque(), false)
  }
  func handle(_ event: UnsafePointer<AppleEvent>?, reply: UnsafeMutablePointer<AppleEvent>?) -> OSErr {
    var descriptor = AEDesc()
    if AEGetParamDesc(event, AEKeyword(keyDirectObject), DescType(typeWildCard), &descriptor) == noErr {
      let value = NSAppleEventDescriptor(aeDescNoCopy: &descriptor)
      if let text = value.stringValue, let url = URL(string: text) { onOpenURL?(url) }
    }
    return previousHandler?(event, reply, previousRefcon) ?? OSErr(noErr)
  }
  func restoreHandler() {
    guard let callback else { return }
    if let previousHandler {
      AEInstallEventHandler(AEEventClass(kInternetEventClass), AEEventID(kAEGetURL), previousHandler, previousRefcon, false)
    } else {
      AERemoveEventHandler(AEEventClass(kInternetEventClass), AEEventID(kAEGetURL), callback, false)
    }
    self.callback = nil
  }
  deinit { restoreHandler() }
}

final class MacPrayerStartup {
  private(set) var error: String?
  var state: String {
    guard #available(macOS 13.0, *) else { return "unavailable" }
    switch SMAppService.mainApp.status {
    case .notRegistered: return "notRegistered"
    case .enabled: return "enabled"
    case .requiresApproval: return "requiresApproval"
    case .notFound: return "notFound"
    @unknown default: return "error"
    }
  }
  func setEnabled(_ enabled: Bool) throws {
    guard #available(macOS 13.0, *) else {
      throw MacPrayerError.invalid("Login startup requires macOS 13 or later.")
    }
    error = nil
    do {
      if enabled { try SMAppService.mainApp.register() }
      else if SMAppService.mainApp.status != .notRegistered { try SMAppService.mainApp.unregister() }
    } catch { self.error = error.localizedDescription; throw error }
  }
  func openSettings() {
    if #available(macOS 13.0, *) { SMAppService.openSystemSettingsLoginItems() }
  }
}
