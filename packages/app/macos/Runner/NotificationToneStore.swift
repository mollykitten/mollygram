import AVFoundation
import Cocoa
import UserNotifications

/// Own implementation. Telegram supplies MP3; UNNotificationSound requires
/// PCM/IMA4/uLaw/aLaw in CAF/WAV/AIFF under the app's Library/Sounds (<30s).
/// Never pass an MP3 or arbitrary TDLib path as a notification sound name.
final class NotificationToneStore {
  private let directory: URL
  private var files: [String: [String: URL]] = [:]
  private var player: AVAudioPlayer?
  private var previewSession: String?
  var isPreviewing: Bool { player?.isPlaying ?? false }

  init(directory: URL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("Sounds", isDirectory: true)) {
    self.directory = directory
    removeStaleTones()
  }

  /// Files left behind by a crash or a missed `release`; this process owns
  /// every `mollygram-tone-*.caf` in its directory.
  private func removeStaleTones() {
    let manager = FileManager.default
    guard let names = try? manager.contentsOfDirectory(atPath: directory.path) else { return }
    for name in names where name.hasPrefix("mollygram-tone-") && name.hasSuffix(".caf") {
      try? manager.removeItem(at: directory.appendingPathComponent(name))
    }
  }

  func notificationSound(_ args: [String: Any]) throws -> UNNotificationSound? {
    guard args["sound"] as? Bool == true, args["quiet"] as? Bool != true,
      let text = args["soundId"] as? String, let id = Int64(text), id != 0
    else { return nil }
    if id < 0 || args["soundFallbackDefault"] as? Bool == true { return .default }
    let url = try prepare(args)
    return UNNotificationSound(named: UNNotificationSoundName(url.lastPathComponent))
  }

  func prepare(_ args: [String: Any]) throws -> URL {
    guard let session = args["soundSession"] as? String, !session.isEmpty,
      session.count <= 80, session.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }),
      let id = args["soundId"] as? String, let number = Int64(id), number > 0,
      let path = args["soundPath"] as? String
    else { throw ToneError.unavailable }
    let source = URL(fileURLWithPath: path)
    let values = try source.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey])
    // A defensive native decoding budget, not a substitute for TDLib's dynamic
    // notification_sound_size_max (checked in core before reaching this side).
    guard values.isRegularFile == true, let size = values.fileSize,
      size > 0, size <= 2 * 1024 * 1024 else { throw ToneError.unavailable }
    let key = "\(id):\(path):\(size):\(values.contentModificationDate?.timeIntervalSince1970 ?? 0)"
    if let cached = files[session]?[key], FileManager.default.fileExists(atPath: cached.path) {
      return cached
    }
    let input = try AVAudioFile(forReading: source)
    let format = input.processingFormat
    let duration = Double(input.length) / format.sampleRate
    guard duration.isFinite, duration > 0, duration < 30,
      format.channelCount > 0, format.channelCount <= 2,
      format.sampleRate > 0, format.sampleRate <= 192000
    else { throw ToneError.unavailable }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let target = directory.appendingPathComponent("mollygram-tone-\(session)-\(UUID().uuidString).caf")
    do {
      // Read in bounded chunks; AVAudioFile decodes MP3 and writes PCM CAF.
      let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: format.sampleRate, AVNumberOfChannelsKey: format.channelCount,
        AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsNonInterleaved: false]
      let output = try AVAudioFile(forWriting: target, settings: settings,
        commonFormat: format.commonFormat, interleaved: format.isInterleaved)
      guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096) else {
        throw ToneError.unavailable
      }
      while input.framePosition < input.length {
        try input.read(into: buffer)
        guard buffer.frameLength > 0 else { throw ToneError.unavailable }
        try output.write(from: buffer)
      }
    } catch {
      try? FileManager.default.removeItem(at: target)
      throw error
    }
    files[session, default: [:]][key] = target
    return target
  }

  func preview(_ args: [String: Any], volume: Float = 1) throws {
    stopPreview()
    guard let text = args["soundId"] as? String, let id = Int64(text) else {
      throw ToneError.unavailable
    }
    if id == 0 { return }
    if id < 0 || args["soundFallbackDefault"] as? Bool == true {
      NSSound.beep()
      return
    }
    let next = try AVAudioPlayer(contentsOf: prepare(args))
    next.volume = volume
    guard next.prepareToPlay(), next.play() else { throw ToneError.unavailable }
    player = next
    previewSession = args["soundSession"] as? String
  }

  func stopPreview(session: String? = nil) {
    if let session, session != previewSession { return }
    player?.stop()
    player = nil
    previewSession = nil
  }

  func release(session: String) {
    stopPreview(session: session)
    for url in files.removeValue(forKey: session)?.values ?? [:].values {
      try? FileManager.default.removeItem(at: url)
    }
  }

  enum ToneError: Error { case unavailable }
}
