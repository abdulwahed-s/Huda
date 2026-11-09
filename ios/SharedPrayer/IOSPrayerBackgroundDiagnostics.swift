import Foundation
import Darwin

/// Task history is separate from prayer state so it can be inspected without
/// foregrounding Huda or mistaking a foreground reconcile for a background run.
struct IOSPrayerBackgroundRecord: Codable, Equatable {
  var timestamp: Date = Date()
  let event: String
  var runID: String?
  var validationLabel: String?
  var processID: Int32 = getpid()
  var debuggerAttached: Bool = IOSPrayerBackgroundDiagnostics.debuggerAttached
  var applicationState: String?
  var backgroundRefresh: String?
  var lowPowerMode: Bool?
  var notificationCount: Int?
  var alarmCount: Int?
  var coverage: Date?
  var earliestBegin: Date?
  var success: Bool?
  var error: String?
}

final class IOSPrayerBackgroundDiagnostics {
  static let fileName = "background-refresh.json"
  static let validationLabelKey = "iosPrayerBackgroundValidationLabel"
  static let shared = IOSPrayerBackgroundDiagnostics(directory:
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("PrayerBackgroundDiagnostics", isDirectory: true))
  let directory: URL
  private let lock = NSLock()
  private let limit: Int
  init(directory: URL, limit: Int = 200) {
    self.directory = directory
    self.limit = max(1, limit)
  }
  static var debuggerAttached: Bool {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var query: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    return sysctl(&query, UInt32(query.count), &info, &size, nil, 0) == 0
      && (info.kp_proc.p_flag & P_TRACED) != 0
  }
  static var validationLabel: String? {
    guard let label = UserDefaults.standard.string(forKey: validationLabelKey),
      !label.isEmpty, label.count <= 64,
      label.utf8.allSatisfy({ (48...57).contains($0) || (65...90).contains($0)
        || (97...122).contains($0) || $0 == 45 || $0 == 95 }) else { return nil }
    return label
  }
  private var file: URL { directory.appendingPathComponent(Self.fileName) }
  private func load() throws -> [IOSPrayerBackgroundRecord] {
    guard FileManager.default.fileExists(atPath: file.path) else { return [] }
    let data = try Data(contentsOf: file)
    guard data.count <= 262_144 else { throw IOSPrayerError.invalid("backgroundDiagnosticsTooLarge") }
    let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode([IOSPrayerBackgroundRecord].self, from: data)
  }
  func read() throws -> [IOSPrayerBackgroundRecord] {
    lock.lock(); defer { lock.unlock() }
    return try load()
  }
  func append(_ record: IOSPrayerBackgroundRecord) throws {
    lock.lock(); defer { lock.unlock() }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    var records = try load()
    records.append(record)
    records = Array(records.suffix(limit))
    let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys]
    try encoder.encode(records).write(to: file, options: .atomic)
    #if os(iOS)
    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: directory.path)
    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: file.path)
    #endif
  }
  func record(_ event: String, runID: String? = nil, label: String? = nil,
    applicationState: String? = nil, backgroundRefresh: String? = nil,
    lowPowerMode: Bool? = nil, status: [String: Any]? = nil,
    earliestBegin: Date? = nil, success: Bool? = nil, error: String? = nil) {
    var value = IOSPrayerBackgroundRecord(event: event)
    value.runID = runID; value.validationLabel = label
    value.applicationState = applicationState; value.backgroundRefresh = backgroundRefresh
    value.lowPowerMode = lowPowerMode
    value.notificationCount = status?["notificationCount"] as? Int
    value.alarmCount = status?["alarmCount"] as? Int
    if let milliseconds = status?["coverageMillis"] as? Double {
      value.coverage = Date(timeIntervalSince1970: milliseconds / 1000)
    }
    value.earliestBegin = earliestBegin; value.success = success; value.error = error
    do { try append(value) }
    catch { NSLog("Huda background diagnostic write failed: %@", String(describing: error)) }
  }
}

/// Expiration and async completion can race on different queues.
final class IOSPrayerBackgroundCompletion {
  private let lock = NSLock()
  private var completed = false
  private let completion: (Bool) -> Void
  init(_ completion: @escaping (Bool) -> Void) { self.completion = completion }
  @discardableResult func finish(_ success: Bool) -> Bool {
    lock.lock()
    guard !completed else { lock.unlock(); return false }
    completed = true; lock.unlock()
    completion(success)
    return true
  }
}
