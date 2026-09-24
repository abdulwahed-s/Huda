import CoreLocation
import Flutter
import MapKit
import UIKit
import UserNotifications
import alarm
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
    if #available(iOS 13.0, *) {
      WorkmanagerPlugin.registerPeriodicTask(
        withIdentifier: "com.aw.huda.prayerNotifications.refresh",
        frequency: NSNumber(value: 12 * 60 * 60)
      )
    }

    if let controller = window?.rootViewController as? FlutterViewController {
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
      let monitor = PrayerTravelMonitor(channel: monitorChannel)
      monitorChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "sync":
          let arguments = call.arguments as? [String: Any]
          result(
            monitor.sync(
              enabled: arguments?["enabled"] as? Bool ?? false,
              locationMode: arguments?["locationMode"] as? String ?? "manual"
            ))
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
    SwiftAlarmPlugin.registerBackgroundTasks()

    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    application.registerForRemoteNotifications()
    prayerTravelMonitor?.restoreEnrollment()
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
    if notification.request.content.userInfo["type"] as? String == "prayer_time" {
      completionHandler([.banner, .list, .sound, .badge])
      return
    }
    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
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

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyKilometer
    manager.distanceFilter = 5_000
    manager.pausesLocationUpdatesAutomatically = true
  }

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

    let backgroundTask = PrayerBackgroundTaskLease { [weak self] in
      self?.locationResolver.cancel()
    }
    locationResolver.resolve(fix) { [weak self] resolved, _ in
      defer { backgroundTask.end() }
      guard let self,
        !backgroundTask.expired,
        self.requestedEnabled,
        self.locationMode == "automatic",
        let zone = resolved?.timeZoneId,
        TimeZone(identifier: zone) != nil
      else { return }
      var candidate: [String: Any] = [
        "schemaVersion": 1,
        "latitude": fix.coordinate.latitude,
        "longitude": fix.coordinate.longitude,
        "timeZoneId": zone,
        "capturedAtUtc": ISO8601DateFormatter().string(from: fix.timestamp),
        "accuracyMeters": fix.horizontalAccuracy,
        "submittedAtUtc": ISO8601DateFormatter().string(from: Date()),
        "source": "iosSignificantChange",
        "nonce": UUID().uuidString,
      ]
      if let countryCode = resolved?.countryCode,
        !countryCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        candidate["countryCode"] = countryCode.uppercased()
      }
      guard let data = try? JSONSerialization.data(withJSONObject: candidate),
        let encoded = String(data: data, encoding: .utf8)
      else { return }
      let defaults = UserDefaults.standard
      defaults.set(encoded, forKey: Self.candidateKey)
      guard defaults.synchronize() else { return }
      self.channel?.invokeMethod("candidateAvailable", arguments: nil)
    }
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
