import AVFoundation
import AudioToolbox
import CryptoKit
import Foundation

/// Paths are derived from validated catalog identities; callers cannot supply
/// filesystem paths. No network operation is part of delivery or fallback.
final class MacPrayerAudio: NSObject, AVAudioPlayerDelegate {
  let cacheDirectory: URL
  let bundledDirectory: URL
  let notificationDirectory: URL
  let soundsDirectory: URL?
  private var player: AVAudioPlayer?
  private var cutoff: Timer?
  private var activity: NSObjectProtocol?
  private(set) var session: String?
  private(set) var error: String?
  var onChanged: ((Bool) -> Void)?
  #if DEBUG
  var deviceVerificationState: [String: Any] {
    guard let player else { return ["playing": false] }
    return ["playing": player.isPlaying, "currentTime": player.currentTime, "duration": player.duration,
      "volume": player.volume, "loops": player.numberOfLoops,
      "file": player.url?.lastPathComponent ?? "", "reciter": player.url?.deletingLastPathComponent().lastPathComponent ?? ""]
  }
  #endif

  init(directory: URL, bundle: Bundle = .main) {
    cacheDirectory = directory.appendingPathComponent("audio", isDirectory: true)
    bundledDirectory = (bundle.resourceURL ?? directory).appendingPathComponent("Adhan", isDirectory: true)
    notificationDirectory = bundle.resourceURL ?? directory
    // Keep the previous staging location available for diagnostic readback and
    // already-pending requests. New requests use signed root-bundle WAV clips.
    soundsDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.hudaHomeApp")?
      .appendingPathComponent("Library/Sounds", isDirectory: true)
  }
  private func directory(_ policy: MacPrayerExperience) -> URL {
    let base = policy.reciterId == "huda-default" && policy.audioVersion == "v1" ? bundledDirectory : cacheDirectory
    return base.appendingPathComponent(policy.audioVersion).appendingPathComponent(policy.reciterId)
  }
  private func checked(_ policy: MacPrayerExperience, full: Bool) throws -> URL {
    try policy.validate()
    let folder = directory(policy).resolvingSymlinksInPath()
    let root = (policy.reciterId == "huda-default" && policy.audioVersion == "v1" ? bundledDirectory : cacheDirectory).resolvingSymlinksInPath()
    guard folder.path.hasPrefix(root.path + "/") else { throw MacPrayerError.invalid("Audio directory is outside Huda storage.") }
    let manifestURL = folder.appendingPathComponent("manifest.json")
    let manifestData = try Data(contentsOf: manifestURL)
    guard manifestData.count <= 65536,
      let manifest = try JSONSerialization.jsonObject(with: manifestData) as? [String: Any],
      manifest["audio_version"] as? String == policy.audioVersion,
      let reciter = manifest["reciter"] as? [String: Any], reciter["id"] as? String == policy.reciterId,
      let metadata = reciter[full ? "full" : "notification"] as? [String: Any],
      let size = metadata["bytes"] as? Int, (1...8_388_608).contains(size),
      let digest = metadata["sha256"] as? String, MacPrayerExperience.matches(digest, "^[a-f0-9]{64}$")
    else { throw MacPrayerError.invalid("Adhan metadata is invalid.") }
    let filename = full ? "full.mp3" : "notification.wav"
    let url = folder.appendingPathComponent(filename).resolvingSymlinksInPath()
    guard url.path.hasPrefix(folder.path + "/"),
      (try url.resourceValues(forKeys: [.fileSizeKey])).fileSize == size
    else { throw MacPrayerError.invalid("Adhan file is missing or has changed.") }
    let bytes = try Data(contentsOf: url, options: .mappedIfSafe)
    guard bytes.count == size, SHA256.hash(data: bytes).map({ String(format: "%02x", $0) }).joined() == digest
    else { throw MacPrayerError.invalid("Adhan integrity verification failed.") }
    let sound = try AVAudioPlayer(contentsOf: url)
    guard sound.duration.isFinite, sound.duration > 0, full ? sound.duration <= 3600 : sound.duration < 30
    else { throw MacPrayerError.invalid("Adhan duration is invalid.") }
    if !full {
      let file = try AVAudioFile(forReading: url)
      guard file.fileFormat.streamDescription.pointee.mFormatID == kAudioFormatLinearPCM else {
        throw MacPrayerError.invalid("Notification audio must use PCM encoding.")
      }
    }
    return url
  }
  func isReady(_ policy: MacPrayerExperience) -> Bool {
    (try? checked(policy, full: true)) != nil && (try? bundledNotificationSound(policy)) != nil
  }
  func paths() throws -> [String: Any] {
    try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    let bundled = directory(MacPrayerExperience())
    let raw = try Data(contentsOf: bundled.appendingPathComponent("manifest.json"))
    let manifest = try JSONSerialization.jsonObject(with: raw) as! [String: Any]
    guard manifest["reciter"] is [String: Any] else { throw MacPrayerError.invalid("Adhan metadata is invalid.") }
    return ["cache": cacheDirectory.path, "bundled": bundledDirectory.path]
  }
  private func resolved(_ policy: MacPrayerExperience, full: Bool) throws -> URL {
    do { return try checked(policy, full: full) }
    catch {
      self.error = error.localizedDescription
      guard policy.reciterId != "huda-default" else { throw error }
      return try checked(MacPrayerExperience(), full: full)
    }
  }
  func notificationSound(_ policy: MacPrayerExperience) throws -> String {
    error = nil
    do {
      return try bundledNotificationSound(policy)
    } catch {
      self.error = error.localizedDescription
      guard policy.reciterId != "huda-default" else { throw error }
      return try bundledNotificationSound(MacPrayerExperience())
    }
  }
  /// The signed clip for [policy]. The default uses its approved normalized
  /// clip; a downloaded reciter's is found by its notification.wav hash.
  private func bundledNotificationSound(_ policy: MacPrayerExperience) throws -> String {
    try policy.validate()
    let builtIn = policy.reciterId == "huda-default" && policy.audioVersion == "v1"
    let sourceHash = builtIn ? nil
      : SHA256.hash(data: try Data(contentsOf: checked(policy, full: false))).map { String(format: "%02x", $0) }.joined()
    let manifestURL = notificationDirectory.appendingPathComponent("huda_notification_sounds.json")
    guard ((try manifestURL.resourceValues(forKeys: [.fileSizeKey])).fileSize ?? Int.max) <= 65536 else {
      throw MacPrayerError.invalid("Bundled notification audio metadata is too large.")
    }
    let data = try Data(contentsOf: manifestURL)
    guard let manifest = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      manifest["schema_version"] as? Int == 1,
      let entries = manifest["sounds"] as? [[String: Any]], entries.count <= 64,
      let metadata = entries.first(where: { sourceHash == nil
        ? $0["reciter_id"] as? String == policy.reciterId : $0["source_sha256"] as? String == sourceHash }),
      let digest = metadata["sha256"] as? String, MacPrayerExperience.matches(digest, "^[a-f0-9]{64}$"),
      let filename = metadata["filename"] as? String, filename == "huda-short-\(digest.prefix(16)).wav",
      let size = metadata["bytes"] as? Int, (1...8_388_608).contains(size)
    else { throw MacPrayerError.invalid("The selected short Adhan is not packaged in this Huda release.") }
    let url = notificationDirectory.appendingPathComponent(filename).resolvingSymlinksInPath()
    guard url.deletingLastPathComponent() == notificationDirectory.resolvingSymlinksInPath(),
      (try url.resourceValues(forKeys: [.fileSizeKey])).fileSize == size else {
      throw MacPrayerError.invalid("Bundled notification audio is missing or has changed.")
    }
    let bytes = try Data(contentsOf: url, options: .mappedIfSafe)
    guard bytes.count == size,
      SHA256.hash(data: bytes).map({ String(format: "%02x", $0) }).joined() == digest else {
      throw MacPrayerError.invalid("Bundled notification audio integrity verification failed.")
    }
    let file = try AVAudioFile(forReading: url)
    let format = file.fileFormat.streamDescription.pointee
    let duration = Double(file.length) / file.fileFormat.sampleRate
    // Notification Center rejects IMA4 here, unlike iOS.
    guard format.mFormatID == kAudioFormatLinearPCM, format.mBitsPerChannel == 16,
      (1...2).contains(format.mChannelsPerFrame), duration.isFinite, duration > 0, duration < 30 else {
      throw MacPrayerError.invalid("Bundled notification audio format or duration is invalid.")
    }
    return filename
  }
  @discardableResult
  func play(_ policy: MacPrayerExperience, session: String) -> Bool {
    stop()
    error = nil
    do {
      let url = try resolved(policy, full: true)
      let player = try AVAudioPlayer(contentsOf: url)
      player.delegate = self
      player.volume = Float(policy.volume)
      player.numberOfLoops = 0
      player.prepareToPlay()
      guard player.play() else { throw MacPrayerError.invalid("The Adhan player could not start.") }
      self.player = player; self.session = session
      activity = ProcessInfo.processInfo.beginActivity(options: [.userInitiated, .latencyCritical], reason: "Playing prayer Adhan")
      if let seconds = policy.stopAfterSeconds {
        let timer = Timer(timeInterval: Double(seconds), repeats: false) { [weak self] _ in self?.stop() }
        RunLoop.main.add(timer, forMode: .common); cutoff = timer
      }
      onChanged?(true)
      return true
    } catch { self.error = error.localizedDescription; onChanged?(false); return false }
  }
  func stop(session: String? = nil) {
    if let session, session != self.session { return }
    let wasPlaying = self.session != nil
    cutoff?.invalidate(); cutoff = nil
    player?.stop(); player = nil; self.session = nil
    if let activity { ProcessInfo.processInfo.endActivity(activity) }; activity = nil
    if wasPlaying { onChanged?(false) }
  }
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    if !flag { error = "Adhan playback did not complete." }
    stop()
  }
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    self.error = error?.localizedDescription ?? "Adhan decoding failed."; stop()
  }
}
