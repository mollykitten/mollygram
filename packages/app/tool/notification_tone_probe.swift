import AVFoundation
import Foundation
import UserNotifications

/// Compile with NotificationToneStore.swift. Uses an own generated MP3, never
/// TDLib, accounts, notification permissions, or notification-center delivery.
@main
struct NotificationToneProbe {
  static func check(_ value: Bool) { precondition(value) }
  static func main() throws {
    let input = CommandLine.arguments[1]
    let root = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
    let store = NotificationToneStore(directory: root)
    let args: [String: Any] = ["sound": true, "soundId": "9876543210123456",
      "soundPath": input, "soundSession": "probe-one"]
    check(try store.notificationSound(["sound": true, "soundId": "-1"]) != nil)
    check(try store.notificationSound(["sound": true, "soundId": "0"]) == nil)
    check(try store.notificationSound(args.merging(["quiet": true]) { _, new in new }) == nil)
    check(try store.notificationSound(args.merging(["sound": false]) { _, new in new }) == nil)
    check(try store.notificationSound(args) != nil)
    let url = try store.prepare(args)
    let file = try AVAudioFile(forReading: url)
    check(file.fileFormat.settings[AVFormatIDKey] as? UInt32 == kAudioFormatLinearPCM)
    check(Double(file.length) / file.fileFormat.sampleRate < 30)
    // Confirm the actual native playback path starts on the audio device.
    try store.preview(args, volume: 0.1)
    check(store.isPreviewing)
    RunLoop.current.run(until: Date().addingTimeInterval(1.0))
    check(!store.isPreviewing)
    let other = try store.prepare(args.merging(["soundSession": "probe-two"]) { _, new in new })
    check(url != other)
    store.release(session: "probe-one")
    check(!FileManager.default.fileExists(atPath: url.path))
    check(FileManager.default.fileExists(atPath: other.path))
    do {
      _ = try store.prepare(args.merging(["soundPath": input + ".missing"]) { _, new in new })
      fatalError("missing input accepted")
    } catch { print("PASS missing input fails closed") }
    store.release(session: "probe-two")
    print("PASS default/silent/quiet/custom PCM CAF/native playback/account isolation/cleanup")
  }
}
