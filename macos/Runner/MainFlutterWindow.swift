import Cocoa
import CoreLocation
import FlutterMacOS
import MapKit

class MainFlutterWindow: NSWindow {
  private let prayerLocationResolver = PrayerAppleLocationResolver()
  private var prayerLocationChannel: FlutterMethodChannel?
  private var prayerSystemChannel: FlutterMethodChannel?
  private var prayerSystemObservers: [NSObjectProtocol] = []

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

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
