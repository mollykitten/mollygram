import 'dart:io';

import 'package:mollygram_tdlib/mollygram_tdlib.dart' as td;

import 'file_controller.dart';

/// The local resource for a selected ID. Only a removed saved tone falls back
/// to default (TDLib's explicit contract). Network/decoding errors stay quiet.
final class NotificationSoundResource {
  const NotificationSoundResource({this.path, this.fallbackDefault = false});
  final String? path;
  final bool fallbackDefault;
}

/// Account-owned Telegram tones; no cross-account or stale local-path cache.
/// Upload/removal deliberately aren't exposed until their complete UI exists.
final class NotificationSounds {
  NotificationSounds(this._client, this._files);
  final td.TdClient _client;
  final FileController _files;

  Stream<void> get changes => _client.updates
      .where((u) => u is td.UpdateSavedNotificationSounds)
      .map((_) {});

  Future<List<td.NotificationSound>> load() async =>
      (await _client.send(const td.GetSavedNotificationSounds()))
          .notificationSounds;

  Future<NotificationSoundResource> resolve(int id) async {
    if (id == 0) return const NotificationSoundResource();
    if (id < 0) {
      return const NotificationSoundResource(fallbackDefault: true);
    }
    late td.NotificationSound sound;
    try {
      sound = await _client.send(
        td.GetSavedNotificationSound(notificationSoundId: id),
      );
    } on td.TdException catch (error) {
      if (error.code != 404) rethrow;
      return const NotificationSoundResource(fallbackDefault: true);
    }
    // TDLib OptionManager defaults; server options may lower or raise these.
    final maxSize = await _limit('notification_sound_size_max', 307200);
    final maxDuration = await _limit('notification_sound_duration_max', 5);
    if (sound.duration < 0 ||
        sound.duration > maxDuration ||
        sound.sound.size > maxSize ||
        sound.sound.expectedSize > maxSize) {
      throw StateError('Notification tone exceeds Telegram limits');
    }
    var file = _files.latest(sound.sound);
    if (downloadedPath(file) == null) {
      file = await _files
          .downloadNow(file.id)
          .timeout(const Duration(seconds: 2));
    }
    final path = downloadedPath(file);
    if (path == null) throw StateError('Notification tone download incomplete');
    final stat = await File(path).stat();
    if (stat.type != FileSystemEntityType.file) {
      throw FileSystemException('Notification tone file unavailable', path);
    }
    if (stat.size <= 0 || stat.size > maxSize) {
      throw StateError('Notification tone file exceeds Telegram limits');
    }
    return NotificationSoundResource(path: path);
  }

  Future<int> _limit(String name, int fallback) async {
    final value = await _client.send(td.GetOption(name: name));
    return value is td.OptionValueInteger && value.value > 0
        ? value.value
        : fallback;
  }
}
