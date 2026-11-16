import CoreLocation
import Flutter
import MapKit
import UIKit
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var miqaatLockHandler: MiqaatLockMethodHandler?
  private var prayerPushChannel: FlutterMethodChannel?
  private var prayerLocationChannel: FlutterMethodChannel?
  private var prayerLocationMonitorChannel: FlutterMethodChannel?
  private var prayerSystemChannel: FlutterMethodChannel?
  private var prayerTravelMonitor: PrayerTravelMonitor?
  private let prayerLocationResolver = PrayerAppleLocationResolver()
  private var apnsDeviceToken: String?
  private var iosPrayerBridge: IOSPrayerBridge?
  private var reminderNotificationsChannel: FlutterMethodChannel?

  private var apnsEnvironment: String {
    #if DEBUG
      return "development"
    #else
      return "production"
    #endif
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    IOSPrayerBackgroundRefresh.shared.register()
    // Native enrollment and travel monitoring also run on a cold background
    // launch where there is no Flutter view controller.
    prayerTravelMonitor = PrayerTravelMonitor(channel: nil)
    IOSPrayerBackgroundRefresh.shared.refreshLocation = { [weak self] in
      await self?.prayerTravelMonitor?.recoverNativeCandidate()
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      iosPrayerBridge = IOSPrayerBridge(messenger: controller.binaryMessenger)
      reminderNotificationsChannel = ReminderNotificationsChannel.register(
        messenger: controller.binaryMessenger
      )
      miqaatLockHandler = MiqaatLockMethodHandler(messenger: controller.binaryMessenger)
      let channel = FlutterMethodChannel(
        name: "com.aw.huda/prayer_push",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "register" else {
          result(FlutterMethodNotImplemented)
          return
        }
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
        result(self?.registrationPayload() ?? ["environment": "development"])
      }
      prayerPushChannel = channel

      let locationChannel = FlutterMethodChannel(
        name: "com.aw.huda/prayer_location",
        binaryMessenger: controller.binaryMessenger
      )
      locationChannel.setMethodCallHandler { call, result in
        guard call.method == "resolveTimeZone" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard
          let arguments = call.arguments as? [String: Any],
          let latitude = arguments["latitude"] as? Double,
          let longitude = arguments["longitude"] as? Double,
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
        let location = CLLocation(latitude: latitude, longitude: longitude)
        self.prayerLocationResolver.resolve(location) { resolved, error in
          guard let identifier = resolved?.timeZoneId else {
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

      let monitorChannel = FlutterMethodChannel(
        name: "com.aw.huda/prayer_location_monitor",
        binaryMessenger: controller.binaryMessenger
      )
      let monitor = prayerTravelMonitor!
      monitor.attach(channel: monitorChannel)
      monitorChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "sync":
          let arguments = call.arguments as? [String: Any]
          result(
            monitor.sync(
              enabled: arguments?["enabled"] as? Bool ?? false,
              locationMode: arguments?["locationMode"] as? String ?? "manual"
            ))
        case "consumeCandidate":
          result(monitor.consumeCandidate(expected: call.arguments as? String))
        case "status":
          result(monitor.status())
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      prayerLocationMonitorChannel = monitorChannel
      prayerTravelMonitor = monitor

      let systemChannel = FlutterMethodChannel(
        name: "com.aw.huda/prayer_system",
        binaryMessenger: controller.binaryMessenger
      )
      prayerSystemChannel = systemChannel
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    prayerTravelMonitor?.restoreEnrollment()
    IOSPrayerBackgroundRefresh.shared.submit()
    Task { try? await IOSPrayerService.shared.reconcile() }
    return launched
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    apnsDeviceToken = deviceToken.map { String(format: "%02x", $0) }.joined()
    prayerPushChannel?.invokeMethod("tokenUpdated", arguments: registrationPayload())
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func applicationSignificantTimeChange(_ application: UIApplication) {
    Task { try? await IOSPrayerService.shared.reconcile() }
    prayerSystemChannel?.invokeMethod(
      "systemChanged",
      arguments: "significantTimeChange"
    )
    super.applicationSignificantTimeChange(application)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    prayerPushChannel?.invokeMethod(
      "registrationFailed",
      arguments: error.localizedDescription
    )
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if let presentation = IOSPrayerNotificationRouter.presentation(notification) {
      completionHandler(presentation)
      return
    }
    if notification.request.content.userInfo["type"] as? String == "prayer_time" {
      completionHandler([.banner, .list, .sound, .badge])
      return
    }
    if let presentation = ReminderNotificationsChannel.presentation(notification.request.content.userInfo) {
      completionHandler(presentation)
      return
    }
    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    if UserDefaults(suiteName: "group.hudaHomeApp")?.bool(forKey: "iosPrayerOpenTimes") == true {
      iosPrayerBridge?.publishOpenPrayerTimes()
    }
    Task {
      if let status = try? await IOSPrayerService.shared.reconcile() {
        iosPrayerBridge?.publish(status)
        IOSPrayerBackgroundRefresh.shared.submit()
      }
    }
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    IOSPrayerBackgroundRefresh.shared.submit()
    super.applicationDidEnterBackground(application)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if IOSPrayerNotificationRouter.response(response) {
      UserDefaults(suiteName: "group.hudaHomeApp")?.set(true, forKey: "iosPrayerOpenTimes")
      iosPrayerBridge?.publishOpenPrayerTimes()
      completionHandler()
      return
    }
    // Reminders, and anything older releases queued through the plugin.
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
      let payload = response.notification.request.content.userInfo["payload"] as? String
    {
      ReminderNotificationsChannel.tapped(payload)
      completionHandler()
      return
    }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  private func registrationPayload() -> [String: String] {
    var payload = ["environment": apnsEnvironment]
    if let token = apnsDeviceToken {
      payload["token"] = token
    }
    return payload
  }
}

private final class PrayerTravelMonitor: NSObject, CLLocationManagerDelegate {
  private static let preferencePrefix = "flutter."
  private static let enabledKey = preferencePrefix + "prayer_background_travel_enabled"
  private static let modeKey = preferencePrefix + "prayer_location_mode"
  private static let candidateKey = preferencePrefix + "prayer_location_native_candidate_v1"
  private static let maximumFixAge: TimeInterval = 30 * 60
  private static let futureTolerance: TimeInterval = 2 * 60
  private static let maximumAccuracy = 5_000.0

  private let manager = CLLocationManager()
  private let locationResolver = PrayerAppleLocationResolver()
  private weak var channel: FlutterMethodChannel?
  private var requestedEnabled = false
  private var locationMode = "manual"

  init(channel: FlutterMethodChannel?) {
    self.channel = channel
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyKilometer
    manager.distanceFilter = 5_000
    manager.pausesLocationUpdatesAutomatically = true
  }

  func attach(channel: FlutterMethodChannel) { self.channel = channel }

  func restoreEnrollment() {
    requestedEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
    locationMode = UserDefaults.standard.string(forKey: Self.modeKey) ?? "manual"
    applyEnrollment()
  }

  func sync(enabled: Bool, locationMode: String) -> [String: Any] {
    requestedEnabled = enabled
    self.locationMode = locationMode == "automatic" ? "automatic" : "manual"
    let defaults = UserDefaults.standard
    defaults.set(enabled, forKey: Self.enabledKey)
    defaults.set(self.locationMode, forKey: Self.modeKey)
    defaults.synchronize()
    applyEnrollment()
    if UserDefaults.standard.string(forKey: Self.candidateKey) != nil {
      DispatchQueue.main.async { [weak self] in
        self?.channel?.invokeMethod("candidateAvailable", arguments: nil)
      }
    }
    return status()
  }

  func consumeCandidate(expected: String?) -> Bool {
    let defaults = UserDefaults.standard
    guard let expected, defaults.string(forKey: Self.candidateKey) == expected else { return false }
    defaults.removeObject(forKey: Self.candidateKey)
    return defaults.synchronize()
  }

  func status() -> [String: Any] {
    guard requestedEnabled, locationMode == "automatic" else {
      return ["state": "disabled", "enrolled": false]
    }
    guard CLLocationManager.locationServicesEnabled(),
      CLLocationManager.significantLocationChangeMonitoringAvailable()
    else {
      return ["state": "unavailable", "enrolled": false]
    }
    switch manager.authorizationStatus {
    case .authorizedAlways:
      return ["state": "enabled", "enrolled": true]
    case .authorizedWhenInUse:
      return ["state": "foregroundOnly", "enrolled": false]
    case .notDetermined, .denied, .restricted:
      return ["state": "permissionRequired", "enrolled": false]
    @unknown default:
      return ["state": "unavailable", "enrolled": false]
    }
  }

  private func applyEnrollment() {
    let shouldRun =
      requestedEnabled && locationMode == "automatic" && CLLocationManager.locationServicesEnabled()
      && CLLocationManager.significantLocationChangeMonitoringAvailable()
      && manager.authorizationStatus == .authorizedAlways
    if shouldRun {
      manager.startMonitoringSignificantLocationChanges()
    } else {
      manager.stopMonitoringSignificantLocationChanges()
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    applyEnrollment()
    channel?.invokeMethod("monitorStatusChanged", arguments: status())
  }

  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    guard requestedEnabled, locationMode == "automatic" else { return }
    let now = Date()
    guard
      let fix = locations.reversed().first(where: { location in
        location.coordinate.latitude.isFinite && location.coordinate.longitude.isFinite
          && (-90.0...90.0).contains(location.coordinate.latitude)
          && (-180.0...180.0).contains(location.coordinate.longitude)
          && location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= Self.maximumAccuracy
          && now.timeIntervalSince(location.timestamp) <= Self.maximumFixAge
          && location.timestamp.timeIntervalSince(now) <= Self.futureTolerance
      })
    else { return }

    let candidate: [String: Any] = [
      "schemaVersion": 1,
      "latitude": fix.coordinate.latitude,
      "longitude": fix.coordinate.longitude,
      "capturedAtUtc": ISO8601DateFormatter().string(from: fix.timestamp),
      "accuracyMeters": fix.horizontalAccuracy,
      "submittedAtUtc": ISO8601DateFormatter().string(from: now),
      "source": "iosSignificantChange",
      "nonce": UUID().uuidString,
    ]
    guard let data = try? JSONSerialization.data(withJSONObject: candidate),
      let encoded = String(data: data, encoding: .utf8) else { return }
    let defaults = UserDefaults.standard
    if let previous = defaults.string(forKey: Self.candidateKey),
      let bytes = previous.data(using: .utf8),
      let object = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
      let captured = object["capturedAtUtc"] as? String,
      let timestamp = ISO8601DateFormatter().date(from: captured), timestamp >= fix.timestamp { return }
    defaults.set(encoded, forKey: Self.candidateKey)
    guard defaults.synchronize() else { return }
    Task { await processNativeCandidate(encoded, fix: fix) }
  }

  private func processNativeCandidate(_ encoded: String, fix: CLLocation) async {
    let resolved: PrayerResolvedAppleLocation? = await withCheckedContinuation { continuation in
      locationResolver.resolve(fix) { value, _ in continuation.resume(returning: value) }
    }
    guard requestedEnabled, locationMode == "automatic",
      !Task.isCancelled,
      UserDefaults.standard.string(forKey: Self.candidateKey) == encoded else { return }
    do {
      let adopted = try await IOSPrayerService.shared.adoptTravel(fix, resolved: resolved)
      if adopted {
        _ = consumeCandidate(expected: encoded)
        IOSPrayerBackgroundRefresh.shared.submit()
        channel?.invokeMethod("nativeScheduleChanged", arguments: nil)
      } else { channel?.invokeMethod("candidateAvailable", arguments: nil) }
    } catch { channel?.invokeMethod("candidateAvailable", arguments: nil) }
  }
  func recoverNativeCandidate() async {
    guard requestedEnabled, locationMode == "automatic",
      let encoded = UserDefaults.standard.string(forKey: Self.candidateKey),
      let data = encoded.data(using: .utf8), let candidate = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let latitude = candidate["latitude"] as? Double, let longitude = candidate["longitude"] as? Double,
      let accuracy = candidate["accuracyMeters"] as? Double, accuracy >= 0, accuracy <= Self.maximumAccuracy,
      (-90...90).contains(latitude), (-180...180).contains(longitude),
      let captured = candidate["capturedAtUtc"] as? String, let date = ISO8601DateFormatter().date(from: captured),
      Date().timeIntervalSince(date) <= Self.maximumFixAge, date.timeIntervalSinceNow <= Self.futureTolerance else { return }
    await processNativeCandidate(encoded, fix: CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
      altitude: 0, horizontalAccuracy: accuracy, verticalAccuracy: -1, timestamp: date))
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    channel?.invokeMethod(
      "monitorStatusChanged",
      arguments: ["state": "unavailable", "error": error.localizedDescription]
    )
  }
}

private final class PrayerBackgroundTaskLease {
  private var identifier: UIBackgroundTaskIdentifier = .invalid
  private var expirationHandler: (() -> Void)?
  private(set) var expired = false

  init(onExpiration: @escaping () -> Void) {
    expirationHandler = onExpiration
    identifier = UIApplication.shared.beginBackgroundTask(
      withName: "Huda prayer travel candidate"
    ) { [weak self] in
      self?.expire()
    }
  }

  func end() {
    guard identifier != .invalid else { return }
    let completedIdentifier = identifier
    identifier = .invalid
    expirationHandler = nil
    UIApplication.shared.endBackgroundTask(completedIdentifier)
  }

  private func expire() {
    guard identifier != .invalid else { return }
    let expiredIdentifier = identifier
    identifier = .invalid
    expired = true
    let handler = expirationHandler
    expirationHandler = nil
    handler?()
    UIApplication.shared.endBackgroundTask(expiredIdentifier)
  }

  deinit {
    end()
  }
}

struct PrayerResolvedAppleLocation {
  let timeZoneId: String
  let countryCode: String?
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
    if #available(iOS 26.0, *) {
      resolveModern(location, token: token)
    } else {
      resolveLegacy(location, token: token)
    }
  }

  func cancel() {
    let completion = cancelPending()
    completion?(nil, PrayerAppleLocationResolverError.superseded)
  }

  private func cancelPending()
    -> ((PrayerResolvedAppleLocation?, Error?) -> Void)?
  {
    let completion = pendingCompletion
    legacyGeocoder.cancelGeocode()
    if #available(iOS 26.0, *) {
      (modernRequest as? MKReverseGeocodingRequest)?.cancel()
    }
    modernRequest = nil
    activeToken = nil
    pendingCompletion = nil
    return completion
  }

  @available(iOS 26.0, *)
  private func resolveModern(_ location: CLLocation, token: UUID) {
    guard let request = MKReverseGeocodingRequest(location: location) else {
      finish(token: token, resolved: nil, error: nil)
      return
    }
    modernRequest = request
    request.getMapItems { [weak self] items, error in
      guard let self else { return }
      let item = items?.first(where: { mapItem in
        guard let identifier = mapItem.timeZone?.identifier else { return false }
        return TimeZone(identifier: identifier) != nil
      })
      let countryCode =
        item?.addressRepresentations?
        .value(forKey: "regionCode") as? String
      let identifier = item?.timeZone?.identifier
      let resolved = identifier.map { identifier in
        PrayerResolvedAppleLocation(
          timeZoneId: identifier,
          countryCode: Self.normalizedCountryCode(countryCode)
        )
      }
      self.finish(token: token, resolved: resolved, error: error)
    }
  }

  private func resolveLegacy(_ location: CLLocation, token: UUID) {
    legacyGeocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
      let placemark = placemarks?.first(where: { place in
        guard let identifier = place.timeZone?.identifier else { return false }
        return TimeZone(identifier: identifier) != nil
      })
      let identifier = placemark?.timeZone?.identifier
      let resolved = identifier.map { identifier in
        PrayerResolvedAppleLocation(
          timeZoneId: identifier,
          countryCode: Self.normalizedCountryCode(placemark?.isoCountryCode)
        )
      }
      self?.finish(token: token, resolved: resolved, error: error)
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

  private static func normalizedCountryCode(_ value: String?) -> String? {
    let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return normalized.isEmpty ? nil : normalized.uppercased()
  }
}

/// Reminders, random Athkar and calendar events for `AppleReminderBackend`.
/// Requests keep the identifier and userInfo keys flutter_local_notifications
/// used (the decimal ID, `NotificationId`, `payload`), so requests from older
/// releases are listed, replaced and cancelled the same way, and taps route by
/// payload. The macOS runner has the same channel in `MainFlutterWindow.swift`.
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
    if #available(iOS 15.0, *) {
      content.interruptionLevel =
        arguments["timeSensitive"] as? Bool == true ? .timeSensitive : .active
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

  /// The plugin's shape. The ID comes from the identifier or `NotificationId`,
  /// so prayers queued by `IOSPrayerNotificationScheduler` are listed too.
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
