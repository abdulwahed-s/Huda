import Foundation
import UserNotifications

struct IOSPrayerNotificationSnapshot {
  var requests: [String: UNNotificationRequest]
  var otherCount: Int
}

struct IOSPrayerNotificationScheduler {
  static let prefix = "huda.prayer."
  static let previewPrefix = "huda.prayer.preview."
  static let renewalIdentifier = "huda.prayer.renewal"
  let center = UNUserNotificationCenter.current()
  static func isOwned(_ request: UNNotificationRequest) -> Bool { request.identifier.hasPrefix(prefix) }
  static func isLegacy(_ request: UNNotificationRequest) -> Bool {
    guard !isOwned(request), let id = Int(request.identifier) else { return false }
    return (300_000_000..<400_000_000).contains(id) || (2000...2599).contains(id)
  }
  static func fireDate(_ request: UNNotificationRequest) -> Date? {
    if let trigger = request.trigger as? UNCalendarNotificationTrigger { return trigger.nextTriggerDate() }
    if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger { return trigger.nextTriggerDate() }
    return nil
  }
  func snapshot() async -> IOSPrayerNotificationSnapshot {
    let requests = await center.pendingNotificationRequests()
    return IOSPrayerNotificationSnapshot(requests: Dictionary(uniqueKeysWithValues: requests.filter(Self.isOwned).map { ($0.identifier, $0) }),
      otherCount: requests.filter { !Self.isOwned($0) }.count)
  }
  func matches(_ request: UNNotificationRequest?, _ occurrence: IOSPrayerOccurrence) -> Bool {
    guard let request, let fire = Self.fireDate(request) else { return false }
    return abs(fire.timeIntervalSince(occurrence.instant)) < 1 &&
      request.content.userInfo["hudaPolicy"] as? String == fingerprint(occurrence) &&
      request.content.userInfo["hudaOccurrence"] as? String == occurrence.key
  }
  func fingerprint(_ occurrence: IOSPrayerOccurrence) -> String {
    IOSPrayerOccurrence.digest("\(occurrence.instant.timeIntervalSince1970)/\(occurrence.policy.effective.rawValue)/\(occurrence.policy.sound ?? "")/\(occurrence.timeSensitive)/\(occurrence.eventJSON.base64EncodedString())")
  }
  func submit(_ occurrence: IOSPrayerOccurrence) async throws {
    try Task.checkCancellation()
    guard occurrence.instant > Date() else { return }
    let content = UNMutableNotificationContent()
    let event = occurrence.eventDictionary
    content.title = event["title"] as? String ?? "Prayer time"
    content.body = event["body"] as? String ?? "It is time to pray."
    content.sound = occurrence.policy.effective == .short ? occurrence.policy.sound.map { UNNotificationSound(named: .init($0)) } : nil
    content.interruptionLevel = occurrence.timeSensitive ? .timeSensitive : .active
    var payload = event
    payload["type"] = "prayer_time"
    payload["schemaVersion"] = 3
    payload["occurrenceId"] = occurrence.integerID
    content.userInfo = ["type": "prayer_time", "hudaOccurrence": occurrence.key,
      "hudaPolicy": fingerprint(occurrence), "hudaMode": occurrence.policy.effective.rawValue,
      "NotificationId": occurrence.integerID,
      "payload": String(data: try JSONSerialization.data(withJSONObject: payload), encoding: .utf8)!]
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: occurrence.instant)
    components.timeZone = calendar.timeZone
    try await center.add(UNNotificationRequest(identifier: occurrence.identifier, content: content,
      trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)))
  }
  func remove(_ ids: [String]) { if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) } }
  func removeLegacy(preserveThrough: Date?) async {
    let now = Date()
    let legacy = await center.pendingNotificationRequests().filter { request in
      Self.isLegacy(request) && (preserveThrough == nil || (Self.fireDate(request) ?? now) > preserveThrough!)
    }
    remove(legacy.map(\.identifier))
  }
  func renewal(coverage: Date?, strings: [String: String], enabled: Bool) async throws {
    remove([Self.renewalIdentifier])
    guard enabled, let coverage else { return }
    let pending = await center.pendingNotificationRequests()
    guard pending.count < 60 else { return }
    let fire = max(Date().addingTimeInterval(60), coverage.addingTimeInterval(-86400))
    guard fire < coverage else { return }
    let content = UNMutableNotificationContent()
    content.title = strings["renewalTitle"] ?? "Extend prayer alerts"
    content.body = strings["renewalBody"] ?? "Open Huda to extend prayer alerts."
    content.sound = nil
    content.userInfo = ["NotificationId": 1901, "payload": "{\"type\":\"prayer_renewal\"}"]
    try await center.add(UNNotificationRequest(identifier: Self.renewalIdentifier, content: content,
      trigger: UNTimeIntervalNotificationTrigger(timeInterval: fire.timeIntervalSinceNow, repeats: false)))
  }
}
