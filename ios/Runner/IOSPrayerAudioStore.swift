import Foundation
import AVFoundation
import CryptoKit

struct IOSPrayerAudioStore {
  /// Huda ships one recording, `full.mp3`; the notification clip and alarm
  /// files are made from it in Library/Sounds. The default keeps the names the
  /// bundled files had, so alerts scheduled before an update still find them.
  static let defaultShortName = "adhan.caf"
  static let defaultFullName = "adhan_full.caf"
  static let defaultOpeningName = "adhan_opening.caf"
  /// AlarmKit repeats a custom sound until Stop; silence after the adhan
  /// (whole or opening) makes it play once. 30 min so an unanswered
  /// alarm doesn't start again (~0.45 MB of AAC silence per file).
  static let alarmPadding: Double = 30 * 60
  static let paddingTag = "p\(Int(alarmPadding / 60))"
  static let bundledFull = Bundle.main.url(forResource: "full", withExtension: "mp3", subdirectory: "Adhan/v1/huda-default")
  private static let derivedKey = "iosPrayerDerivedDefault"
  let sounds: URL
  init() {
    sounds = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("Sounds", isDirectory: true)
  }
  /// A 29-second alarm chime for pre-AlarmKit notifications. The OS plays it
  /// once, including when Huda is terminated; no silent background audio.
  func prepareSahurSound() throws {
    let target = sounds.appendingPathComponent("huda-sahur.caf")
    guard !FileManager.default.fileExists(atPath: target.path) else { return }
    try FileManager.default.createDirectory(at: sounds, withIntermediateDirectories: true)
    let rate = 22_050.0
    guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: rate, channels: 1, interleaved: false),
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(rate * 29)) else {
      throw IOSPrayerError.invalid("audioDecode")
    }
    buffer.frameLength = buffer.frameCapacity
    for index in 0..<Int(buffer.frameLength) {
      let time = Double(index) / rate
      let beat = time.truncatingRemainder(dividingBy: 1)
      let envelope = beat < 0.6 ? min(1, beat / 0.015) * exp(-beat * 5) : 0
      buffer.floatChannelData![0][index] = Float(0.5 * envelope * sin(2 * .pi * (beat < 0.3 ? 880 : 1100) * time))
    }
    let temporary = sounds.appendingPathComponent(".sahur-\(UUID().uuidString).caf")
    defer { try? FileManager.default.removeItem(at: temporary) }
    do {
      let output = try AVAudioFile(forWriting: temporary, settings: [AVFormatIDKey: kAudioFormatAppleIMA4,
        AVSampleRateKey: rate, AVNumberOfChannelsKey: 1])
      try output.write(from: buffer)
    }
    try FileManager.default.moveItem(at: temporary, to: target)
  }
  /// Makes the default's clip, and its alarm files (whole and opening) when
  /// [full], once per bundled recording. False when the clip can't be made; prayers then use
  /// the system sound.
  @discardableResult
  func prepareDefault(full withFull: Bool) -> Bool {
    guard let source = Self.bundledFull,
      let size = (try? source.resourceValues(forKeys: [.fileSizeKey]))?.fileSize else { return false }
    let stamp = withFull ? "\(size)/\(Self.alarmPadding)" : "\(size)"
    let short = sounds.appendingPathComponent(Self.defaultShortName)
    let full = sounds.appendingPathComponent(Self.defaultFullName)
    let opening = sounds.appendingPathComponent(Self.defaultOpeningName)
    let fm = FileManager.default
    if UserDefaults.standard.string(forKey: Self.derivedKey) == stamp, fm.fileExists(atPath: short.path),
      !withFull || fm.fileExists(atPath: full.path) && fm.fileExists(atPath: opening.path) { return true }
    do {
      try derive(source, to: short, limit: 29, padding: 0, format: kAudioFormatAppleIMA4)
      if withFull {
        try derive(source, to: full, limit: nil, padding: Self.alarmPadding, format: kAudioFormatMPEG4AAC)
        try derive(source, to: opening, limit: 29, padding: Self.alarmPadding, format: kAudioFormatMPEG4AAC)
      }
      UserDefaults.standard.set(stamp, forKey: Self.derivedKey)
      return true
    } catch { return false }
  }
  /// Writes the first [limit] seconds (all when nil) of [source], faded out
  /// when cut, then [padding] seconds of silence, as a CAF.
  func derive(_ source: URL, to target: URL, limit: Double?, padding: Double, format: AudioFormatID) throws {
    let input = try AVAudioFile(forReading: source)
    let pcm = input.processingFormat
    guard pcm.channelCount == 1 || pcm.channelCount == 2 else { throw IOSPrayerError.invalid("audioInvalid") }
    let rate = pcm.sampleRate
    var settings: [String: Any] = [AVFormatIDKey: format, AVSampleRateKey: rate, AVNumberOfChannelsKey: 1]
    if format == kAudioFormatMPEG4AAC { settings[AVEncoderBitRateKey] = 64_000 }
    try FileManager.default.createDirectory(at: sounds, withIntermediateDirectories: true)
    let temporary = sounds.appendingPathComponent(".\(target.lastPathComponent).\(UUID().uuidString).caf")
    defer { try? FileManager.default.removeItem(at: temporary) }
    guard let mono = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: rate, channels: 1, interleaved: false),
      let chunk = AVAudioPCMBuffer(pcmFormat: pcm, frameCapacity: 32_768),
      let out = AVAudioPCMBuffer(pcmFormat: mono, frameCapacity: 32_768) else { throw IOSPrayerError.invalid("audioDecode") }
    do {
      let output = try AVAudioFile(forWriting: temporary, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
      let end = limit.map { min(input.length, AVAudioFramePosition($0 * rate)) } ?? input.length
      let fade = limit == nil ? 0 : AVAudioFramePosition(0.5 * rate)
      var position: AVAudioFramePosition = 0
      while position < end {
        chunk.frameLength = 0
        try input.read(into: chunk, frameCount: AVAudioFrameCount(min(32_768, end - position)))
        let frames = Int(chunk.frameLength)
        if frames == 0 { break }
        let channels = Int(pcm.channelCount)
        for i in 0..<frames {
          var sample: Float = 0
          for c in 0..<channels { sample += chunk.floatChannelData![c][i] }
          sample /= Float(channels)
          let frame = position + AVAudioFramePosition(i)
          if fade > 0, frame > end - fade { sample *= Float(end - frame) / Float(fade) }
          out.floatChannelData![0][i] = sample
        }
        out.frameLength = AVAudioFrameCount(frames)
        try output.write(from: out)
        position += AVAudioFramePosition(frames)
      }
      var silence = AVAudioFramePosition(padding * rate)
      if silence > 0 {
        memset(out.floatChannelData![0], 0, 32_768 * MemoryLayout<Float>.size)
        while silence > 0 {
          out.frameLength = AVAudioFrameCount(min(32_768, silence))
          try output.write(from: out)
          silence -= AVAudioFramePosition(out.frameLength)
        }
      }
    }
    // Closing the writer finishes the file; check it decodes before using it.
    let check = try AVAudioFile(forReading: temporary)
    guard check.length > 0 else { throw IOSPrayerError.invalid("audioDecode") }
    if FileManager.default.fileExists(atPath: target.path) {
      _ = try FileManager.default.replaceItemAt(target, withItemAt: temporary)
    } else {
      try FileManager.default.moveItem(at: temporary, to: target)
    }
  }
  /// Makes a downloaded reciter's alarm file from its verified `full.mp3`.
  func installFull(path: String, reciter: String, version: String, bytes: Int, hash: String) throws -> String {
    guard hash.range(of: "^[a-f0-9]{64}$", options: .regularExpression) != nil, bytes > 0, bytes <= 8_388_608
    else { throw IOSPrayerError.invalid("audioInvalid") }
    let source = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
    let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].standardizedFileURL
    guard source.path.hasPrefix(library.path + "/"), source.pathExtension.lowercased() == "mp3"
    else { throw IOSPrayerError.invalid("audioInvalid") }
    let data = try Data(contentsOf: source, options: .mappedIfSafe)
    guard data.count == bytes, SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == hash
    else { throw IOSPrayerError.invalid("audioHash") }
    let name = "huda-\(version)-\(reciter)-alarm-\(Self.paddingTag)-\(hash.prefix(16)).caf"
    let target = sounds.appendingPathComponent(name)
    if !FileManager.default.fileExists(atPath: target.path) {
      try derive(source, to: target, limit: nil, padding: Self.alarmPadding, format: kAudioFormatMPEG4AAC)
    }
    return name
  }
  /// Makes the opening-only alarm file from an installed reciter's clip.
  func installOpening(_ audio: IOSPrayerInstalledAudio) throws -> String {
    guard ready(audio) else { throw IOSPrayerError.invalid("audioMissing") }
    let name = "huda-\(audio.version)-\(audio.reciterId)-opening-\(Self.paddingTag)-\(audio.shortHash.prefix(16)).caf"
    let target = sounds.appendingPathComponent(name)
    if !FileManager.default.fileExists(atPath: target.path) {
      try derive(sounds.appendingPathComponent(audio.shortName), to: target, limit: nil,
        padding: Self.alarmPadding, format: kAudioFormatMPEG4AAC)
    }
    return name
  }
  /// Files made with another padding are outdated, so they're made again.
  func fullReady(_ audio: IOSPrayerInstalledAudio) -> Bool { exists(audio.fullName) }
  func openingReady(_ audio: IOSPrayerInstalledAudio) -> Bool { exists(audio.openingName) }
  private func exists(_ name: String?) -> Bool {
    guard let name, !name.contains("/"), name.contains("-\(Self.paddingTag)-") else { return false }
    return FileManager.default.fileExists(atPath: sounds.appendingPathComponent(name).path)
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
