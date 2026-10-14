import Cocoa
import UserNotifications

struct MacPrayerNotificationSettings {
  let authorizationStatus: UNAuthorizationStatus
  let alertStyle: UNAlertStyle
}

protocol MacPrayerNotificationBackend {
  func getSettings(_ completion: @escaping (MacPrayerNotificationSettings) -> Void)
  func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void)
  func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)
  func removePendingNotificationRequests(withIdentifiers identifiers: [String])
  func removeDeliveredNotifications(withIdentifiers identifiers: [String])
  func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void)
}

final class MacPrayerSystemNotifications: MacPrayerNotificationBackend {
  private let center = UNUserNotificationCenter.current()
  func getSettings(_ completion: @escaping (MacPrayerNotificationSettings) -> Void) {
    center.getNotificationSettings { settings in
      completion(MacPrayerNotificationSettings(authorizationStatus: settings.authorizationStatus,
        alertStyle: settings.alertStyle))
    }
  }
  func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
    center.getPendingNotificationRequests { completionHandler($0) }
  }
  func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
    center.add(request) { completionHandler?($0) }
  }
  func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
    center.removePendingNotificationRequests(withIdentifiers: identifiers)
  }
  func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
    center.removeDeliveredNotifications(withIdentifiers: identifiers)
  }
  func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
    center.requestAuthorization(options: options) { completionHandler($0, $1) }
  }
}

/// The one notification delegate: prayer controls here, and every other
/// notification with a payload through `ReminderNotificationsChannel`.
/// Prayer playback belongs to the due scheduler, never to notification delivery.
final class MacPrayerNotificationRouter: NSObject, UNUserNotificationCenterDelegate {
  static let category = "huda.prayer.controls.v1"
  static let stopAction = "huda.prayer.stop"
  weak var forwardingDelegate: UNUserNotificationCenterDelegate?
  var stop: ((String) -> Void)?
  var observed: ((String, String) -> Void)?
  func install() {
    let center = UNUserNotificationCenter.current()
    if center.delegate !== self {
      forwardingDelegate = center.delegate
      center.delegate = self
    }
  }
  func ensureCategory(stopTitle: String) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationCategories { categories in
      var merged = categories.filter { $0.identifier != Self.category }
      merged.insert(UNNotificationCategory(identifier: Self.category,
        actions: [UNNotificationAction(identifier: Self.stopAction, title: stopTitle, options: [])],
        intentIdentifiers: [], options: []))
      center.setNotificationCategories(merged)
    }
  }
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if notification.request.content.userInfo["hudaPrayer"] as? Bool == true {
      if let key = notification.request.content.userInfo["hudaKey"] as? String {
        DispatchQueue.main.async { self.observed?(key, "presented") }
      }
      var options: UNNotificationPresentationOptions = [.banner, .list]
      if notification.request.content.sound != nil { options.insert(.sound) }
      completionHandler(options)
    } else if let presentation = ReminderNotificationsChannel.presentation(notification.request.content.userInfo) {
      completionHandler(presentation)
    } else if let delegate = forwardingDelegate,
      delegate.responds(to: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:))) {
      delegate.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
    } else { completionHandler([]) }
  }
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void) {
    let info = response.notification.request.content.userInfo
    if let key = info["hudaKey"] as? String {
      DispatchQueue.main.async { self.observed?(key, "responded") }
    }
    if response.actionIdentifier == Self.stopAction, let session = info["hudaSession"] as? String {
      DispatchQueue.main.async { self.stop?(session); completionHandler() }
    } else if info["hudaPreview"] as? Bool == true {
      completionHandler()
    } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier, let payload = info["payload"] as? String {
      // Prayers, reminders, and anything older releases queued through the plugin.
      ReminderNotificationsChannel.tapped(payload)
      completionHandler()
    } else if let delegate = forwardingDelegate,
      delegate.responds(to: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))) {
      delegate.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
    } else { completionHandler() }
  }
}
