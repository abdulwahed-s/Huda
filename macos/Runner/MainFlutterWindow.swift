import Cocoa
import CoreLocation
import FlutterMacOS
import MapKit
import UserNotifications
import WidgetKit

class MainFlutterWindow: NSWindow {
  var allowPresentation = false
  #if DEBUG
  private(set) var verificationPresentationOrders = 0
  #endif
  private var prayerServiceChannel: FlutterMethodChannel?

  override func order(_ place: NSWindow.OrderingMode, relativeTo otherWindowNumber: Int) {
    if place != .out && !allowPresentation { return }
    #if DEBUG
    if place != .out { verificationPresentationOrders += 1 }
    #endif
    super.order(place, relativeTo: otherWindowNumber)
  }

  override func close() {
    super.close()
    if let delegate = NSApp.delegate as? AppDelegate, !delegate.prayerService.backgroundEnabled {
      NSApp.terminate(nil)
    }
  }
  private let prayerLocationResolver = PrayerAppleLocationResolver()
  private var prayerLocationChannel: FlutterMethodChannel?
  private var prayerSystemChannel: FlutterMethodChannel?
  private var widgetChannel: FlutterMethodChannel?
  private var prayerMenuChannel: FlutterMethodChannel?
  private var notificationsChannel: FlutterMethodChannel?
  private var prayerSystemObservers: [NSObjectProtocol] = []

  override func awakeFromNib() {
    isRestorable = false
    // Load the last valid native configuration before Flutter/plugin readiness.
    (NSApp.delegate as? AppDelegate)?.prayerService.start()
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let serviceChannel = FlutterMethodChannel(name: "com.aw.huda/mac_prayer_service",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    serviceChannel.setMethodCallHandler { call, result in
      (NSApp.delegate as? AppDelegate)?.prayerService.handle(call, result: result)
    }
    prayerServiceChannel = serviceChannel
    if let service = (NSApp.delegate as? AppDelegate)?.prayerService {
      service.channel = serviceChannel
      service.router.install()
    }

    let widgets = FlutterMethodChannel(
      name: "com.aw.huda/mac_widgets",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    widgets.setMethodCallHandler { call, result in
      switch call.method {
      case "initialLink":
        result((NSApp.delegate as? AppDelegate)?.takeInitialWidgetURL())
      case "publish":
        guard
          let arguments = call.arguments as? [String: Any],
          let values = arguments["values"] as? [String: Any],
          let kinds = arguments["kinds"] as? [String],
          let defaults = UserDefaults(suiteName: "group.hudaHomeApp")
        else {
          result(FlutterError(code: "invalid_widget_data", message: "Widget App Group or values unavailable.", details: nil))
          return
        }
        for (key, value) in values {
          if value is NSNull {
            defaults.removeObject(forKey: key)
          } else {
            defaults.set(value, forKey: key)
          }
        }
        (NSApp.delegate as? AppDelegate)?.prayerMenuBar.reloadSnapshot()
        if #available(macOS 14.0, *) {
          if !kinds.isEmpty {
            DispatchQueue.main.async {
              for kind in Set(kinds) {
                WidgetCenter.shared.reloadTimelines(ofKind: kind)
              }
            }
          }
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    widgetChannel = widgets
    (NSApp.delegate as? AppDelegate)?.widgetChannel = widgets

    let menuChannel = FlutterMethodChannel(
      name: "com.aw.huda/mac_prayer_menu",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    menuChannel.setMethodCallHandler { call, result in
      guard let menu = (NSApp.delegate as? AppDelegate)?.prayerMenuBar else {
        result(FlutterError(code: "menu_unavailable", message: "Prayer menu is unavailable.", details: nil))
        return
      }
      switch call.method {
      case "getPreferences":
        result(menu.preferences())
      case "setPreferences":
        guard let arguments = call.arguments as? [String: Any], menu.setPreferences(arguments) else {
          result(FlutterError(code: "invalid_preferences", message: "Invalid prayer menu preferences.", details: nil))
          return
        }
        result(nil)
      case "setPresentation":
        guard let arguments = call.arguments as? [String: Any], menu.setPresentation(arguments) else {
          result(FlutterError(code: "invalid_presentation", message: "Invalid prayer menu labels.", details: nil))
          return
        }
        result(nil)
      case "ready":
        menu.markFlutterReady()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    prayerMenuChannel = menuChannel
    (NSApp.delegate as? AppDelegate)?.prayerMenuBar.start(channel: menuChannel)

    notificationsChannel = ReminderNotificationsChannel.register(
      messenger: flutterViewController.engine.binaryMessenger
    )

    let locationChannel = FlutterMethodChannel(
      name: "com.aw.huda/prayer_location",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    locationChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "resolveTimeZone" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let latitude = arguments["latitude"] as? Double,
        let longitude = arguments["longitude"] as? Double,
        latitude.isFinite,
        longitude.isFinite,
        (-90.0...90.0).contains(latitude),
        (-180.0...180.0).contains(longitude)
      else {
        result(
          FlutterError(
            code: "invalid_coordinates",
            message: "Valid latitude and longitude are required.",
            details: nil
          ))
        return
      }
      guard let self else {
        result(
          FlutterError(
            code: "resolver_unavailable",
            message: "The timezone resolver is unavailable.",
            details: nil
          ))
        return
      }
      self.prayerLocationResolver.resolve(
        CLLocation(latitude: latitude, longitude: longitude)
      ) { resolved, error in
        guard let identifier = resolved?.timeZoneId
        else {
          result(
            FlutterError(
              code: "timezone_unavailable",
              message: error?.localizedDescription
                ?? "No IANA timezone was found for these coordinates.",
              details: nil
            ))
          return
        }
        result(identifier)
      }
    }
    prayerLocationChannel = locationChannel

    let systemChannel = FlutterMethodChannel(
      name: "com.aw.huda/prayer_system",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    prayerSystemChannel = systemChannel
    let center = NotificationCenter.default
    prayerSystemObservers.append(
      center.addObserver(
        forName: NSApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak systemChannel] _ in
        systemChannel?.invokeMethod("systemChanged", arguments: "activation")
      })
    prayerSystemObservers.append(
      center.addObserver(
        forName: NSNotification.Name.NSSystemTimeZoneDidChange,
        object: nil,
        queue: .main
      ) { [weak systemChannel] _ in
        systemChannel?.invokeMethod("systemChanged", arguments: "timeZone")
      })
    prayerSystemObservers.append(
      center.addObserver(
        forName: NSNotification.Name.NSSystemClockDidChange,
        object: nil,
        queue: .main
      ) { [weak systemChannel] _ in
        systemChannel?.invokeMethod("systemChanged", arguments: "clock")
      })
    prayerSystemObservers.append(
      NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didWakeNotification,
        object: nil,
        queue: .main
      ) { [weak systemChannel] _ in
        systemChannel?.invokeMethod("systemChanged", arguments: "wake")
      })

    super.awakeFromNib()
  }

  deinit {
    for observer in prayerSystemObservers {
      NotificationCenter.default.removeObserver(observer)
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
    }
  }

  override func performClose(_ sender: Any?) {
    if (NSApp.delegate as? AppDelegate)?.prayerService.backgroundEnabled == true {
      orderOut(sender)
    } else {
      super.performClose(sender)
    }
  }
}

struct PrayerResolvedAppleLocation {
  let timeZoneId: String
}

enum PrayerAppleLocationResolverError: Error {
  case superseded
}

final class PrayerAppleLocationResolver {
  static func prefersModernAPI(operatingSystemMajorVersion: Int) -> Bool {
    operatingSystemMajorVersion >= 26
  }

  private let legacyGeocoder = CLGeocoder()
  private var modernRequest: AnyObject?
  private var activeToken: UUID?
  private var pendingCompletion: ((PrayerResolvedAppleLocation?, Error?) -> Void)?

  func resolve(
    _ location: CLLocation,
    completion: @escaping (PrayerResolvedAppleLocation?, Error?) -> Void
  ) {
    let supersededCompletion = cancelPending()
    let token = UUID()
    activeToken = token
    pendingCompletion = completion
    supersededCompletion?(nil, PrayerAppleLocationResolverError.superseded)
    guard activeToken == token else { return }
    if #available(macOS 26.0, *) {
      resolveModern(location, token: token)
    } else {
      resolveLegacy(location, token: token)
    }
  }

  private func cancelPending()
    -> ((PrayerResolvedAppleLocation?, Error?) -> Void)?
  {
    let completion = pendingCompletion
    legacyGeocoder.cancelGeocode()
    if #available(macOS 26.0, *) {
      (modernRequest as? MKReverseGeocodingRequest)?.cancel()
    }
    modernRequest = nil
    activeToken = nil
    pendingCompletion = nil
    return completion
  }

  @available(macOS 26.0, *)
  private func resolveModern(_ location: CLLocation, token: UUID) {
    guard let request = MKReverseGeocodingRequest(location: location) else {
      finish(token: token, resolved: nil, error: nil)
      return
    }
    modernRequest = request
    request.getMapItems { [weak self] items, error in
      let identifier = items?.compactMap(\.timeZone?.identifier).first(where: {
        TimeZone(identifier: $0) != nil
      })
      self?.finish(
        token: token,
        resolved: identifier.map(PrayerResolvedAppleLocation.init),
        error: error
      )
    }
  }

  private func resolveLegacy(_ location: CLLocation, token: UUID) {
    legacyGeocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
      let identifier = placemarks?.compactMap(\.timeZone?.identifier).first(where: {
        TimeZone(identifier: $0) != nil
      })
      self?.finish(
        token: token,
        resolved: identifier.map(PrayerResolvedAppleLocation.init),
        error: error
      )
    }
  }

  private func finish(
    token: UUID,
    resolved: PrayerResolvedAppleLocation?,
    error: Error?
  ) {
    guard activeToken == token else { return }
    let completion = pendingCompletion
    activeToken = nil
    pendingCompletion = nil
    modernRequest = nil
    completion?(resolved, error)
  }
}

/// Reminders, random Athkar and calendar events for `AppleReminderBackend`.
/// Requests keep the identifier and userInfo keys flutter_local_notifications
/// used (the decimal ID, `NotificationId`, `payload`), so requests from older
/// releases are listed, replaced and cancelled the same way, and taps route by
/// payload. The iOS runner has the same channel in `AppDelegate.swift`.
enum ReminderNotificationsChannel {
  private static weak var channel: FlutterMethodChannel?
  /// The latest tap, until Flutter takes it; it also covers the tap that
  /// launched Huda.
  private static var pendingTap: String?

  static func register(messenger: FlutterBinaryMessenger) -> FlutterMethodChannel {
    let channel = FlutterMethodChannel(
      name: "com.aw.huda/reminder_notifications",
      binaryMessenger: messenger
    )
    Self.channel = channel
    channel.setMethodCallHandler { call, result in
      let reply: (Any?) -> Void = { value in DispatchQueue.main.async { result(value) } }
      let center = UNUserNotificationCenter.current()
      switch call.method {
      case "schedule", "scheduleOnce":
        guard
          let arguments = call.arguments as? [String: Any],
          let request = request(arguments, repeating: call.method == "schedule")
        else {
          result(FlutterError(code: "invalid_reminder", message: "Invalid or past reminder.", details: nil))
          return
        }
        center.add(request) { error in
          reply(error.map { FlutterError(code: "schedule_failed", message: $0.localizedDescription, details: nil) })
        }
      case "pending":
        center.getPendingNotificationRequests { requests in reply(requests.compactMap(describe)) }
      case "cancel":
        guard let ids = (call.arguments as? [String: Any])?["ids"] as? [Int] else {
          result(FlutterError(code: "invalid_reminder", message: "Cancel needs ids.", details: nil))
          return
        }
        let identifiers = ids.map(String.init)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
        result(nil)
      case "authorization":
        center.getNotificationSettings { settings in
          let status: String =
            switch settings.authorizationStatus {
            case .authorized: "authorized"
            case .denied: "denied"
            case .provisional: "provisional"
            default: "notDetermined"
            }
          reply(status)
        }
      case "requestAuthorization":
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in reply(granted) }
      case "openSettings":
        // The app's own page in Notifications settings, else the Notifications pane.
        let pane = "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        let app = Bundle.main.bundleIdentifier.flatMap { URL(string: "\(pane)?id=\($0)") }
        let opened = app.map { NSWorkspace.shared.open($0) } ?? false
        result(opened || URL(string: "x-apple.systempreferences:com.apple.preference.notifications")
          .map { NSWorkspace.shared.open($0) } ?? false)
      case "takeTap":
        result(pendingTap)
        pendingTap = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    return channel
  }

  /// A tapped notification with a payload: Flutter opens its page.
  static func tapped(_ payload: String) {
    DispatchQueue.main.async {
      pendingTap = payload
      channel?.invokeMethod("tapped", arguments: nil)
    }
  }

  /// How a notification with a payload shows while Huda is in front, from the
  /// `present*` flags flutter_local_notifications stored (absent means shown).
  static func presentation(_ userInfo: [AnyHashable: Any]) -> UNNotificationPresentationOptions? {
    guard userInfo["payload"] is String else { return nil }
    let flag = { (key: String) in userInfo[key] as? Bool ?? true }
    var options: UNNotificationPresentationOptions = []
    if flag("presentBanner") { options.insert(.banner) }
    if flag("presentList") { options.insert(.list) }
    if flag("presentSound") { options.insert(.sound) }
    if flag("presentBadge") { options.insert(.badge) }
    return options
  }

  /// Repeating: fixed minute, optional hour and Apple weekday (Sunday = 1),
  /// with no time zone so it follows the device. Once: a fixed instant.
  static func request(_ arguments: [String: Any], repeating: Bool) -> UNNotificationRequest? {
    guard
      let id = arguments["id"] as? Int,
      let title = arguments["title"] as? String,
      let body = arguments["body"] as? String,
      let payload = arguments["payload"] as? String
    else { return nil }
    let trigger: UNCalendarNotificationTrigger
    if repeating {
      guard let minute = arguments["minute"] as? Int, (0..<60).contains(minute) else { return nil }
      let hour = arguments["hour"] as? Int
      let weekday = arguments["weekday"] as? Int
      if let hour, !(0..<24).contains(hour) { return nil }
      if let weekday, hour == nil || !(1...7).contains(weekday) { return nil }
      var components = DateComponents()
      components.weekday = weekday
      components.hour = hour
      components.minute = minute
      trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    } else {
      guard let utcMillis = arguments["utcMillis"] as? Int else { return nil }
      let date = Date(timeIntervalSince1970: TimeInterval(utcMillis) / 1000)
      guard date > Date() else { return nil }
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = .current
      let components = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute, .second, .timeZone], from: date)
      trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    if #available(macOS 12.0, *) {
      let timeSensitive = arguments["timeSensitive"] as? Bool == true
      content.interruptionLevel =
        timeSensitive && MacPrayerService.supportsTimeSensitive ? .timeSensitive : .active
    }
    content.userInfo = [
      "NotificationId": id,
      "title": title,
      "payload": payload,
      "presentAlert": true,
      "presentSound": true,
      "presentBadge": true,
      "presentBanner": true,
      "presentList": true,
    ]
    return UNNotificationRequest(identifier: String(id), content: content, trigger: trigger)
  }

  /// The plugin's shape. The ID comes from the identifier (prayers queued by
  /// `MacPrayerService` use decimal identifiers too) or `NotificationId`.
  /// `yearly` marks the yearly calendar triggers Huda 4.3.0 queued.
  static func describe(_ request: UNNotificationRequest) -> [String: Any]? {
    guard let id = Int(request.identifier) ?? request.content.userInfo["NotificationId"] as? Int else {
      return nil
    }
    var item: [String: Any] = ["id": id, "title": request.content.title, "body": request.content.body]
    if let payload = request.content.userInfo["payload"] as? String { item["payload"] = payload }
    if let trigger = request.trigger as? UNCalendarNotificationTrigger, trigger.repeats,
      trigger.dateComponents.month != nil, trigger.dateComponents.day != nil
    {
      item["yearly"] = true
    }
    return item
  }
}
