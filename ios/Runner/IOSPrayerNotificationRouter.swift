import Foundation
import UserNotifications

enum IOSPrayerNotificationRouter {
  static func presentation(_ notification: UNNotification) -> UNNotificationPresentationOptions? {
    guard IOSPrayerNotificationScheduler.isOwned(notification.request) else { return nil }
    var options: UNNotificationPresentationOptions = [.banner, .list]
    if notification.request.content.sound != nil { options.insert(.sound) }
    return options
  }
  static func response(_ response: UNNotificationResponse) -> Bool {
    guard IOSPrayerNotificationScheduler.isOwned(response.notification.request) else { return false }
    return true
  }
}
