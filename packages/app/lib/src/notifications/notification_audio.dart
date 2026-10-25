import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_tdlib/mollygram_tdlib.dart' as td;

import 'notification_scope_page.dart';

/// An opaque session namespace, never a Telegram account ID. It prevents the
/// native file cache/preview of one account from being reused by its replacement.
final class NotificationAudioSession {
  NotificationAudioSession(
    this.sounds, {
    bool? supported,
    this._channel = const MethodChannel('mollygram/notifications'),
  }) : supported = supported ?? Platform.isMacOS;

  final NotificationSounds sounds;
  final bool supported;
  final MethodChannel _channel;
  final String id =
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
  var _disposed = false;
  var _previewGeneration = 0;

  Future<void> preview(int soundId) async {
    if (!supported || _disposed) {
      throw UnsupportedError('Native tones require macOS');
    }
    final generation = ++_previewGeneration;
    await _channel.invokeMethod<void>('stopSoundPreview', {'soundSession': id});
    final resource = await sounds
        .resolve(soundId)
        .timeout(const Duration(seconds: 8));
    if (_disposed || generation != _previewGeneration) return;
    await _channel.invokeMethod<void>('previewSound', {
      'soundId': '$soundId',
      'soundSession': id,
      'soundPath': ?resource.path,
      'soundFallbackDefault': resource.fallbackDefault,
    });
  }

  Future<void> stopPreview() async {
    _previewGeneration++;
    if (supported && !_disposed) {
      await _channel.invokeMethod<void>('stopSoundPreview', {
        'soundSession': id,
      });
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _previewGeneration++;
    if (supported) {
      await _channel.invokeMethod<void>('releaseSoundSession', {
        'soundSession': id,
      });
    }
  }
}

final notificationAudioProvider =
    Provider.autoDispose<NotificationAudioSession>((ref) {
      final audio = NotificationAudioSession(
        ref.watch(notificationControllerProvider).sounds,
      );
      ref.onDispose(() => unawaited(audio.dispose().catchError((Object _) {})));
      return audio;
    });

final savedNotificationSoundsProvider =
    FutureProvider.autoDispose<List<td.NotificationSound>>((ref) {
      final sounds = ref.watch(notificationControllerProvider).sounds;
      final subscription = sounds.changes.listen((_) => ref.invalidateSelf());
      ref.onDispose(subscription.cancel);
      return sounds.load();
    });
