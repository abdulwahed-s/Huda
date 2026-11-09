import Foundation
import UserNotifications

enum IOSPrayerNotificationRouter {
  static func presentation(_ notification: UNNotification) -> UNNotificationPresentationOptions? {
    guard IOSPrayerNotificationScheduler.isOwned(notification.request) else { return nil }
    if let key = notification.request.content.userInfo["hudaOccurrence"] as? String {
      Task { try? await IOSPrayerService.shared.observe(key: key, outcome: "presentedForeground") }
    }
    var options: UNNotificationPresentationOptions = [.banner, .list]
    if notification.request.content.sound != nil { options.insert(.sound) }
    return options
  }
  static func response(_ response: UNNotificationResponse) -> Bool {
    guard IOSPrayerNotificationScheduler.isOwned(response.notification.request) else { return false }
    if let key = response.notification.request.content.userInfo["hudaOccurrence"] as? String {
      Task { try? await IOSPrayerService.shared.observe(key: key, outcome: "opened") }
    }
    return true
  }
}
