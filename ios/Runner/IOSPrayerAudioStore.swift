import Foundation
import AVFoundation
import CryptoKit

struct IOSPrayerAudioStore {
  /// The whole built-in adhan for full alarms, when it is in the app bundle.
  static let bundledFullSound: String? =
    Bundle.main.url(forResource: "adhan_full", withExtension: "caf") == nil ? nil : "adhan_full.caf"
  let sounds: URL
  init() {
    sounds = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("Sounds", isDirectory: true)
  }
  func install(path: String, reciter: String, version: String, bytes: Int, hash: String, durationMS: Int) throws -> IOSPrayerInstalledAudio {
    guard reciter.range(of: "^[a-z0-9]+(?:-[a-z0-9]+)*$", options: .regularExpression) != nil, reciter.count <= 100,
      version.range(of: "^v[1-9][0-9]*$", options: .regularExpression) != nil,
      hash.range(of: "^[a-f0-9]{64}$", options: .regularExpression) != nil,
      bytes > 0, bytes <= 8_388_608, durationMS > 0, durationMS < 30_000
    else { throw IOSPrayerError.invalid("audioInvalid") }
    let source = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
    let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].standardizedFileURL
    guard source.path.hasPrefix(library.path + "/"), ["wav", "caf", "aiff"].contains(source.pathExtension.lowercased())
    else { throw IOSPrayerError.invalid("audioInvalid") }
    let data = try Data(contentsOf: source, options: .mappedIfSafe)
    guard data.count == bytes, data.count <= 8_388_608,
      SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == hash
    else { throw IOSPrayerError.invalid("audioHash") }
    let audio = try AVAudioFile(forReading: source)
    let format = audio.processingFormat
    let duration = Double(audio.length) / format.sampleRate
    guard duration > 0, duration < 30, abs(duration * 1000 - Double(durationMS)) < 250,
      (8_000...96_000).contains(format.sampleRate), (1...2).contains(format.channelCount)
    else { throw IOSPrayerError.invalid("audioDuration") }
    let decoder = try AVAudioPlayer(contentsOf: source)
    guard decoder.prepareToPlay() else { throw IOSPrayerError.invalid("audioDecode") }
    let name = "huda-\(version)-\(reciter)-\(hash).\(source.pathExtension.lowercased())"
    try FileManager.default.createDirectory(at: sounds, withIntermediateDirectories: true)
    // Immutable names keep old scheduled alerts valid. Cleanup deliberately
    // retains prior versions until their notification/alarm references expire.
    try data.write(to: sounds.appendingPathComponent(name), options: .atomic)
    return IOSPrayerInstalledAudio(reciterId: reciter, version: version, shortName: name, shortHash: hash, duration: duration)
  }
  func ready(_ audio: IOSPrayerInstalledAudio) -> Bool {
    guard audio.duration > 0, audio.duration < 30, !audio.shortName.contains("/") else { return false }
    let file = sounds.appendingPathComponent(audio.shortName)
    guard let data = try? Data(contentsOf: file, options: .mappedIfSafe), data.count <= 8_388_608 else { return false }
    return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() == audio.shortHash
  }
}

@MainActor
final class IOSPrayerAudioPreview: NSObject, AVAudioPlayerDelegate {
  static let shared = IOSPrayerAudioPreview()
  private var player: AVAudioPlayer?
  var didStop: (() -> Void)?
  func play(_ path: String) throws {
    let file = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
    let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
    guard file.path.hasPrefix(library.path + "/") || file.path.hasPrefix(Bundle.main.bundleURL.path + "/") else { throw IOSPrayerError.invalid("audioInvalid") }
    player?.stop()
    let next = try AVAudioPlayer(contentsOf: file)
    next.delegate = self
    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    try AVAudioSession.sharedInstance().setActive(true)
    guard next.prepareToPlay(), next.play() else { throw IOSPrayerError.invalid("audioDecode") }
    player = next
  }
  func stop() { player?.stop(); player = nil; try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation); didStop?() }
  nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    Task { @MainActor in self.stop() }
  }
}
