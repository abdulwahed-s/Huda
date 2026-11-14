import Foundation
import CryptoKit

/// `fullAlarm` plays the reciter's whole adhan as the AlarmKit sound. Apple
/// documents sounds under 30 seconds; longer ones from Library/Sounds play to
/// the end from iOS 26.1 (tested on 26.6.2), so it falls back to `alarm` before.
enum IOSPrayerMode: String, Codable, CaseIterable { case off, silent, short, alarm, fullAlarm }

struct IOSPrayerOverride: Codable, Equatable {
  var mode: IOSPrayerMode?
  var reciterId: String?
  var advanceMinutes: Int?
  var advanceMode: IOSPrayerMode?
}

struct IOSPrayerExperience: Codable, Equatable {
  var version = 1
  var enabled = true
  var mode = IOSPrayerMode.short
  var reciterId = "huda-default"
  var audioVersion = "v1"
  var fallback = IOSPrayerMode.short
  // 4.3.0's prayers were Time Sensitive; keep them breaking through Focus.
  var timeSensitive = true
  var advanceMinutes = 0
  var advanceMode = IOSPrayerMode.silent
  var overrides: [String: IOSPrayerOverride] = [:]
  func validate() throws {
    let lead = [0, 5, 10, 15, 30]
    guard version == 1, validReciter(reciterId),
      audioVersion.range(of: "^v[1-9][0-9]*$", options: .regularExpression) != nil,
      [.silent, .short].contains(fallback), lead.contains(advanceMinutes),
      [.silent, .short].contains(advanceMode), overrides.count <= 5,
      overrides.allSatisfy({ key, value in
        IOSPrayerSchedule.obligatory.contains(key) &&
        (value.reciterId == nil || validReciter(value.reciterId!)) &&
        (value.advanceMinutes == nil || lead.contains(value.advanceMinutes!)) &&
        (value.advanceMode == nil || [.silent, .short].contains(value.advanceMode!))
      }) else { throw IOSPrayerError.invalid("invalidPolicy") }
  }
  private func validReciter(_ value: String) -> Bool {
    value.count <= 100 && value.range(of: "^[a-z0-9]+(?:-[a-z0-9]+)*$", options: .regularExpression) != nil
  }
  func policy(for prayer: String) -> IOSPrayerResolvedPolicy {
    let override = overrides[prayer]
    return IOSPrayerResolvedPolicy(mode: enabled ? override?.mode ?? mode : .off,
      reciterId: override?.reciterId ?? reciterId,
      advanceMinutes: override?.advanceMinutes ?? advanceMinutes,
      advanceMode: override?.advanceMode ?? advanceMode)
  }
}

struct IOSPrayerResolvedPolicy: Codable, Equatable {
  var mode: IOSPrayerMode
  var reciterId: String
  var advanceMinutes: Int
  var advanceMode: IOSPrayerMode
}

struct IOSPrayerCapabilities {
  var notifications = false
  var notificationSound = false
  var alarms = false
  var supportsAlarms = false
  var customAlarmSound = false
  var installedShort: [String: String] = ["huda-default": "adhan.caf"]
  /// Alarm files of the whole adhan per reciter, when custom alarm sounds are
  /// supported (26.1+).
  var installedFull: [String: String] = [:]
  /// Opening-only alarm files (the clip, then silence) per reciter.
  var installedOpening: [String: String] = [:]
  /// The reciter's full alarm file, else the default's.
  func fullSound(_ reciter: String) -> (sound: String, fallback: Bool)? {
    if let file = installedFull[reciter] { return (file, false) }
    return installedFull["huda-default"].map { ($0, true) }
  }
}

struct IOSPrayerEffectivePolicy: Codable, Equatable {
  let desired: IOSPrayerMode
  let effective: IOSPrayerMode
  let reciterId: String
  let sound: String?
  let reason: String?
  var backend: String { [.alarm, .fullAlarm].contains(effective) ? "alarm" : "notification" }
  static func resolve(_ desired: IOSPrayerMode, reciter: String, fallback: IOSPrayerMode,
    capabilities c: IOSPrayerCapabilities) -> Self {
    var mode = desired
    var reason: String?
    if mode == .alarm || mode == .fullAlarm {
      if !c.supportsAlarms { reason = "alarmUnsupported"; mode = fallback }
      else if !c.alarms { reason = "alarmPermission"; mode = fallback }
      // Still an alarm, with the short adhan, where the full one can't play.
      else if mode == .fullAlarm && c.fullSound(reciter) == nil { reason = "fullAudioUnavailable"; mode = .alarm }
    }
    var sound: String?
    if mode == .short {
      if let file = c.installedShort[reciter] { sound = file }
      else { mode = .silent; reason = reason ?? "audioMissing" }
      if !c.notificationSound { reason = reason ?? "notificationSoundDisabled"; mode = .silent; sound = nil }
    } else if mode == .alarm {
      // The padded clip plays once; the plain clip would repeat until Stop.
      if c.customAlarmSound { sound = c.installedOpening[reciter] ?? c.installedShort[reciter] }
      if sound == nil { reason = reason ?? "systemAlarmSound" }
    } else if mode == .fullAlarm, let full = c.fullSound(reciter) {
      sound = full.sound
      if full.fallback { reason = reason ?? "fullAudioFallback" }
    }
    if mode != .off && mode != .alarm && mode != .fullAlarm && !c.notifications {
      mode = .off; reason = "notificationPermission"
    }
    return Self(desired: desired, effective: mode, reciterId: reciter, sound: sound, reason: reason)
  }
}

struct IOSPrayerOccurrence: Codable, Equatable {
  let key: String
  let identifier: String
  let alarmID: UUID
  let prayer: String
  let kind: String
  let instant: Date
  let eventJSON: Data
  let policy: IOSPrayerEffectivePolicy
  let timeSensitive: Bool
  let revision: Int64
  let locationRevision: Int64
  let signature: String
  var eventDictionary: [String: Any] { (try? JSONSerialization.jsonObject(with: eventJSON)) as? [String: Any] ?? [:] }
  var integerID: Int { kind == "main" ? (eventDictionary["id"] as? Int ?? 0) : 410_000_000 + Int(Self.digest(key).prefix(6), radix: 16)! }
  static func digest(_ value: String) -> String { SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined() }
  static func uuid(_ key: String) -> UUID {
    let bytes = Array(SHA256.hash(data: Data(key.utf8)).prefix(16))
    return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
  }
}

enum IOSPrayerPlanner {
  static func occurrences(schedule: IOSPrayerSchedule, experience: IOSPrayerExperience,
    capabilities: IOSPrayerCapabilities, now: Date, revision: Int64, signature: String,
    strings: [String: String]) -> [IOSPrayerOccurrence] {
    let identity = "\(schedule.location.latitude),\(schedule.location.longitude)/\(schedule.location.timeZoneId)"
    let events = schedule.events(from: now.addingTimeInterval(-1800), days: 14, revision: revision, signature: signature)
    var result: [IOSPrayerOccurrence] = []
    for event in events {
      let policy = experience.policy(for: event.prayer)
      guard policy.mode != .off else { continue }
      for kind in ["main", "advance"] {
        guard kind == "main" || policy.advanceMinutes > 0 else { continue }
        let instant = kind == "main" ? event.instant : event.instant.addingTimeInterval(-Double(policy.advanceMinutes * 60))
        guard instant > now else { continue }
        let effective = IOSPrayerEffectivePolicy.resolve(kind == "main" ? policy.mode : policy.advanceMode,
          reciter: policy.reciterId, fallback: experience.fallback, capabilities: capabilities)
        let key = "\(identity)/\(event.civilDay)/\(event.prayer)/\(kind)"
        var dictionary = event.dictionary(strings: strings)
        if kind == "advance" {
          dictionary["title"] = strings["advanceTitle"] ?? "Prayer reminder"
          dictionary["body"] = (strings["advanceBody"] ?? "{prayer} in {minutes} minutes.")
            .replacingOccurrences(of: "{prayer}", with: strings[event.prayer] ?? event.prayer.capitalized)
            .replacingOccurrences(of: "{minutes}", with: String(policy.advanceMinutes))
        }
        result.append(IOSPrayerOccurrence(key: key, identifier: "huda.prayer.\(kind).\(IOSPrayerOccurrence.digest(key).prefix(32))",
          alarmID: IOSPrayerOccurrence.uuid(key), prayer: event.prayer, kind: kind, instant: instant,
          eventJSON: try! JSONSerialization.data(withJSONObject: dictionary, options: .sortedKeys), policy: effective,
          timeSensitive: experience.timeSensitive, revision: revision, locationRevision: schedule.location.revision, signature: signature))
      }
    }
    return result.sorted { $0.instant == $1.instant ? $0.key < $1.key : $0.instant < $1.instant }
  }
  static func allocate(_ all: [IOSPrayerOccurrence], otherNotifications: Int, reservedNotifications: Int = 1,
    alarmLimit: Int = 50, alarmHorizon: Date) -> [IOSPrayerOccurrence] {
    var notificationSlots = max(0, min(50, 60 - max(0, otherNotifications) - max(0, reservedNotifications)))
    var alarmSlots = max(0, alarmLimit)
    var result: [IOSPrayerOccurrence] = []
    // Main alerts consume capacity first; optional reminders use the remainder.
    // Keep roughly eight days of primary local alerts before spending slots
    // on optional reminders. Without this, fifty main notifications silently
    // starve every advance reminder in a fourteen-day calculation horizon.
    let optional = all.contains { $0.kind == "advance" && $0.policy.effective != .off }
    let primaryEnd = (all.first { $0.kind == "main" }?.instant ?? .distantPast).addingTimeInterval(8 * 86400)
    let ordered = optional ? all.filter { $0.kind == "main" && ($0.policy.backend == "alarm" || $0.instant < primaryEnd) } +
      all.filter { $0.kind == "advance" } + all.filter { $0.kind == "main" && $0.policy.backend != "alarm" && $0.instant >= primaryEnd }
      : all.filter { $0.kind == "main" }
    for event in ordered where event.policy.effective != .off {
        if event.policy.backend == "alarm" {
          guard alarmSlots > 0, event.instant < alarmHorizon else { continue }
          alarmSlots -= 1
        } else {
          guard notificationSlots > 0 else { continue }
          notificationSlots -= 1
        }
        result.append(event)
    }
    return result.sorted { $0.instant < $1.instant }
  }
  static func coverage(_ expected: [IOSPrayerOccurrence], accepted: [String: IOSPrayerOccurrence], kind: String) -> Date? {
    var through: Date?
    for event in expected where event.kind == kind {
      guard let actual = accepted[event.key], actual.instant == event.instant,
        actual.policy.effective != .off else { break }
      through = event.instant
    }
    return through
  }
}
