import Foundation
import AppIntents
import AlarmKit

@available(iOS 26.0, *)
struct StopHudaPrayerAlarmIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Stop Prayer Alarm"
  @Parameter(title: "Alarm") var alarmID: String
  @Parameter(title: "Occurrence") var occurrenceKey: String
  init() {}
  init(alarmID: String, occurrenceKey: String) { self.alarmID = alarmID; self.occurrenceKey = occurrenceKey }
  func perform() async throws -> some IntentResult {
    if let id = UUID(uuidString: alarmID) {
      try AlarmManager.shared.stop(id: id)
    }
    return .result()
  }
}
