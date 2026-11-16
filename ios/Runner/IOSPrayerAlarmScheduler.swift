import Foundation
import AlarmKit
import ActivityKit
import SwiftUI

struct IOSPrayerAlarmRecord {
  let id: UUID
  let instant: Date?
  let active: Bool
}

@available(iOS 26.0, *)
struct IOSPrayerAlarmMetadata: AlarmMetadata { let occurrenceKey: String; let prayer: String; var purpose: String? }

struct IOSPrayerAlarmScheduler {
  var supportsAlarms: Bool { if #available(iOS 26.0, *) { return true }; return false }
  var customSoundSupported: Bool { if #available(iOS 26.1, *) { return true }; return false }
  var authorization: String {
    if #available(iOS 26.0, *) {
      switch AlarmManager.shared.authorizationState {
      case .authorized: return "authorized"
      case .denied: return "denied"
      case .notDetermined: return "notDetermined"
      @unknown default: return "unknown"
      }
    }
    return "unsupported"
  }
  func requestAuthorization() async throws {
    if #available(iOS 26.0, *) { _ = try await AlarmManager.shared.requestAuthorization() }
  }
  func snapshot() throws -> [UUID: IOSPrayerAlarmRecord] {
    if #available(iOS 26.0, *) {
      return Dictionary(uniqueKeysWithValues: try AlarmManager.shared.alarms.map { alarm in
        let instant: Date?
        if case .fixed(let date) = alarm.schedule { instant = date } else { instant = nil }
        return (alarm.id, IOSPrayerAlarmRecord(id: alarm.id, instant: instant, active: alarm.state != .scheduled))
      })
    }
    return [:]
  }
  func submit(_ occurrence: IOSPrayerOccurrence) async throws {
    try Task.checkCancellation()
    guard occurrence.instant > Date() else { return }
    if #available(iOS 26.0, *) {
      let event = occurrence.eventDictionary
      let title = LocalizedStringResource(stringLiteral: event["title"] as? String ?? "Prayer alarm")
      // The secondary button fill and the Lock Screen title use the app's
      // theme color; white text reads on every theme's primary.
      let tint = (event["tint"] as? String).flatMap { UInt32($0, radix: 16) }.map {
        Color(red: Double($0 >> 16 & 0xFF) / 255, green: Double($0 >> 8 & 0xFF) / 255, blue: Double($0 & 0xFF) / 255)
      } ?? .teal
      let open = AlarmButton(text: LocalizedStringResource(stringLiteral: event["openApp"] as? String ?? "Open Huda"),
        textColor: .white, systemImageName: "moon.stars.fill")
      let alert: AlarmPresentation.Alert
      let sahur = occurrence.kind == "sahur"
      if #available(iOS 26.1, *) { alert = .init(title: title, secondaryButton: sahur ? nil : open, secondaryButtonBehavior: sahur ? nil : .custom) }
      else {
        alert = .init(title: title, stopButton: AlarmButton(text: LocalizedStringResource(stringLiteral: event["stop"] as? String ?? "Stop"), textColor: tint, systemImageName: "stop.circle"),
          secondaryButton: sahur ? nil : open, secondaryButtonBehavior: sahur ? nil : .custom)
      }
      let attributes = AlarmAttributes(presentation: AlarmPresentation(alert: alert),
        metadata: IOSPrayerAlarmMetadata(occurrenceKey: occurrence.key, prayer: occurrence.prayer, purpose: occurrence.kind), tintColor: tint)
      let sound: AlertConfiguration.AlertSound = customSoundSupported ? occurrence.policy.sound.map { .named($0) } ?? .default : .default
      let configuration = AlarmManager.AlarmConfiguration(schedule: .fixed(occurrence.instant), attributes: attributes,
        stopIntent: StopHudaPrayerAlarmIntent(alarmID: occurrence.alarmID.uuidString, occurrenceKey: occurrence.key),
        secondaryIntent: sahur ? nil : OpenHudaPrayerAlarmIntent(alarmID: occurrence.alarmID.uuidString, occurrenceKey: occurrence.key),
        sound: sound)
      _ = try await AlarmManager.shared.schedule(id: occurrence.alarmID, configuration: configuration)
    } else { throw IOSPrayerError.invalid("alarmUnsupported") }
  }
  func cancel(_ id: UUID) throws {
    if #available(iOS 26.0, *) { try AlarmManager.shared.cancel(id: id) }
  }
  func stop(_ id: UUID) throws {
    if #available(iOS 26.0, *) { try AlarmManager.shared.stop(id: id) }
  }
}
