import Foundation
import Darwin

struct IOSPrayerConfiguration: Codable, Equatable {
  var schemaVersion = 1
  var revision: Int64 = 0
  var policyRevision: Int64 = 0
  var calculationVersion = "prayer-time-plus-0.3.0"
  var schedule: IOSPrayerSchedule?
  var configurationSignature = ""
  var experience = IOSPrayerExperience()
  var strings: [String: String] = [:]
  var migration = "uninitialized"
  var legacyOwnershipUntil: Date?
  var nativeNotBefore: Date?
  var locationRevisionFloor: Int64?
  func validate() throws {
    guard schemaVersion == 1, revision >= 0, revision < 9_007_199_254_740_991,
      policyRevision >= 0, (locationRevisionFloor ?? 0) >= 0, (locationRevisionFloor ?? 0) < 9_007_199_254_740_991,
      configurationSignature.count <= 8192,
      ["uninitialized", "pending", "retired", "native"].contains(migration),
      strings.count <= 80, strings.allSatisfy({ $0.key.count <= 64 && $0.value.count <= 4096 })
    else { throw IOSPrayerError.invalid("invalidConfiguration") }
    try schedule?.validate(); try experience.validate()
  }
}

struct IOSPrayerOperation: Codable {
  var configuration: IOSPrayerConfiguration
  var desired: [IOSPrayerOccurrence]
  var phase = "prepared"
  var started: Date
}

struct IOSPrayerState: Codable {
  var schemaVersion = 1
  var configuration = IOSPrayerConfiguration()
  var operation: IOSPrayerOperation?
  var accepted: [String: IOSPrayerOccurrence] = [:]
  var outcomes: [String: String] = [:]
  var outcomeDates: [String: Date] = [:]
  var primaryCoverage: Date?
  var optionalCoverage: Date?
  var perPrayerCoverage: [String: Date] = [:]
  var lastAttempt: Date?
  var lastSuccess: Date?
  var error: String?
  var backgroundError: String?
  var travelPending = false
  var installedAudio: [String: IOSPrayerInstalledAudio] = [:]
}

struct IOSPrayerInstalledAudio: Codable {
  let reciterId: String
  let version: String
  let shortName: String
  let shortHash: String
  let duration: Double
  var fullName: String?
  /// The opening-only alarm file (the clip followed by silence).
  var openingName: String?
}

/// The host service is the sole writer; widgets and query intents are readers.
/// flock additionally fences overlapping native work across host processes.
final class IOSPrayerStore {
  let directory: URL
  private var lock: Int32 = -1
  init(directory: URL) { self.directory = directory }
  static var sharedDirectory: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.hudaHomeApp")?
      .appendingPathComponent("IOSPrayer", isDirectory: true)
  }
  func beginExclusive() throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let descriptor = open(directory.appendingPathComponent("service.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
    guard descriptor >= 0 else { throw IOSPrayerError.invalid("storageUnavailable") }
    guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else { close(descriptor); throw IOSPrayerError.invalid("busy") }
    lock = descriptor
  }
  func endExclusive() { if lock >= 0 { flock(lock, LOCK_UN); close(lock); lock = -1 } }
  deinit { endExclusive() }
  func load() throws -> IOSPrayerState {
    let file = directory.appendingPathComponent("state.json")
    guard FileManager.default.fileExists(atPath: file.path) || FileManager.default.fileExists(atPath: directory.appendingPathComponent("state.last-good.json").path)
    else { return IOSPrayerState() }
    for name in ["state.json", "state.last-good.json"] {
      do {
        let data = try Data(contentsOf: directory.appendingPathComponent(name))
        guard data.count < 8_388_608 else { throw IOSPrayerError.invalid("storageCorrupt") }
        let value = try JSONDecoder().decode(IOSPrayerState.self, from: data)
        guard value.schemaVersion == 1 else { throw IOSPrayerError.invalid("storageVersion") }
        try value.configuration.validate(); try value.operation?.configuration.validate()
        return value
      } catch { continue }
    }
    throw IOSPrayerError.invalid("storageCorrupt")
  }
  func save(_ value: IOSPrayerState) throws {
    guard lock >= 0 else { throw IOSPrayerError.invalid("storageUnlocked") }
    try value.configuration.validate()
    try value.operation?.configuration.validate()
    let file = directory.appendingPathComponent("state.json")
    if let data = try? Data(contentsOf: file), let old = try? JSONDecoder().decode(IOSPrayerState.self, from: data),
      (try? old.configuration.validate()) != nil,
      old.operation == nil || (try? old.operation!.configuration.validate()) != nil {
      try data.write(to: directory.appendingPathComponent("state.last-good.json"), options: .atomic)
    }
    try JSONEncoder().encode(value).write(to: file, options: .atomic)
    #if os(iOS)
    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: file.path)
    #endif
  }
}
