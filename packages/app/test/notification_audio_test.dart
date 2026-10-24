import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram/l10n/app_localizations.dart';
import 'package:mollygram/src/notifications/notification_audio.dart';
import 'package:mollygram/src/notifications/notification_service.dart';

import 'package:mollygram/src/notifications/system_notifications.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_tdlib/mollygram_tdlib.dart' as td;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  const channel = MethodChannel('mollygram/notifications');
  late _Json json;
  late td.Td tdlib;
  late NotificationController controller;
  late Directory directory;
  final calls = <MethodCall>[];

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('notification-audio-');
    final path = '${directory.path}/tone.mp3';
    await File(path).writeAsBytes([1, 2, 3]);
    json = _Json(path);
    tdlib = td.Td.custom(json, td.InlineTdEventSource(json));
    controller = NotificationController(tdlib.createClient());
    await controller.start();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(() async {
    await controller.dispose();
    await tdlib.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'preview resolves custom, default and silence without saving settings',
    () async {
      final audio = NotificationAudioSession(
        controller.sounds,
        supported: true,
      );
      await audio.preview(42);
      expect(calls.last.method, 'previewSound');
      final custom = calls.last.arguments as Map;
      expect(custom['soundId'], '42');
      expect(custom['soundPath'], json.path);
      expect(custom['soundSession'], audio.id);
      await audio.preview(-1);
      expect((calls.last.arguments as Map)['soundFallbackDefault'], isTrue);
      await audio.preview(0);
      expect((calls.last.arguments as Map)['soundId'], '0');
      expect(
        json.sent.any((r) => r['@type'] == 'setScopeNotificationSettings'),
        isFalse,
      );
      await audio.dispose();
    },
  );

  test(
    'preview cancellation and account disposal cannot revive stale playback',
    () async {
      final old = NotificationAudioSession(controller.sounds, supported: true);
      json.hold = true;
      final pending = old.preview(42);
      await json.requested.future;
      await old.dispose();
      final next = NotificationAudioSession(controller.sounds, supported: true);
      expect(next.id, isNot(old.id));
      await next.preview(-1);
      json.complete();
      await pending;
      final previews = calls.where((c) => c.method == 'previewSound').toList();
      expect(previews, hasLength(1));
      expect((previews.single.arguments as Map)['soundSession'], next.id);
      expect(
        calls.any(
          (c) =>
              c.method == 'releaseSoundSession' &&
              (c.arguments as Map)['soundSession'] == old.id,
        ),
        isTrue,
      );
      await next.dispose();
    },
  );

  test(
    'stopping a pending preview prevents its eventual channel playback',
    () async {
      final audio = NotificationAudioSession(
        controller.sounds,
        supported: true,
      );
      json.hold = true;
      final pending = audio.preview(42);
      await json.requested.future;
      await audio.stopPreview();
      json.complete();
      await pending;
      expect(calls.where((c) => c.method == 'previewSound'), isEmpty);
      await audio.dispose();
    },
  );

  test('unsupported platforms expose no pretend playback channel', () async {
    final audio = NotificationAudioSession(controller.sounds, supported: false);
    await expectLater(audio.preview(42), throwsUnsupportedError);
    await audio.dispose();
    expect(calls, isEmpty);
    expect(
      await const UnsupportedSystemNotifications().requestPermission(),
      isFalse,
    );
  });

  for (final id in [-1, 0, 42]) {
    test(
      'delivery retains sound ID $id and resolves only positive audible tones',
      () async {
        final system = _System();
        final service = _service(controller, system);
        await service.start(en);
        json.pushGroup(id);
        await _until(() => system.shown.isNotEmpty);
        final shown = system.shown.single;
        expect(shown.soundId, id);
        expect(shown.sound, id != 0);
        expect(shown.soundPath, id > 0 ? json.path : null);
        // The native path selects default directly from a negative ID. This
        // fallback bit is reserved for a positive saved ID removed in Telegram.
        expect(shown.soundFallbackDefault, isFalse);
        expect(
          json.sent.where((r) => r['@type'] == 'getSavedNotificationSound'),
          hasLength(id > 0 ? 1 : 0),
        );
        await service.dispose();
      },
    );
  }

  test(
    'download failure delivers a silent banner without replacing custom ID',
    () async {
      json.fail = true;
      final system = _System();
      final service = _service(controller, system);
      await service.start(en);
      json.pushGroup(42);
      await _until(() => system.shown.isNotEmpty);
      final shown = system.shown.single;
      expect(shown.soundId, 42);
      expect(shown.sound, isFalse);
      expect(shown.soundPath, isNull);
      expect(shown.soundFallbackDefault, isFalse);
      await service.dispose();
    },
  );

  test('silent messages, global sound-off, edits and muted banners never fetch a tone', () async {
    final system = _System();
    final service = _service(controller, system);
    await service.start(en);
    json.pushGroup(42, silent: true);
    await _until(() => system.shown.length == 1);
    expect(system.shown.last.sound, isFalse);
    service.settings = service.settings.copyWith(sound: false);
    json.pushGroup(42, notificationId: 2);
    await _until(() => system.shown.length == 2);
    expect(system.shown.last.sound, isFalse);
    service.settings = service.settings.copyWith(sound: true);
    json.pushEdit();
    await _until(() => system.shown.length == 3);
    expect(system.shown.last.quiet, isTrue);
    expect(system.shown.last.sound, isFalse);
    service.settings = service.settings.copyWith(enabled: false);
    json.pushGroup(42, notificationId: 3);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(system.shown, hasLength(3));
    expect(
      json.sent.where((r) => r['@type'] == 'getSavedNotificationSound'),
      isEmpty,
    );
    await service.dispose();
  });

  test(
    'removal while a custom tone loads never posts a stale banner',
    () async {
      json.hold = true;
      final system = _System();
      final service = _service(controller, system);
      await service.start(en);
      json.pushGroup(42);
      await json.requested.future;
      json.push({
        '@type': 'updateNotificationGroup',
        'notification_group_id': 1,
        'type': {'@type': 'notificationGroupTypeMessages'},
        'chat_id': 10,
        'notification_settings_chat_id': 10,
        'notification_sound_id': '0',
        'total_count': 0,
        'added_notifications': [],
        'removed_notification_ids': [1],
      });
      await Future<void>.delayed(const Duration(milliseconds: 30));
      json.complete();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(system.shown, isEmpty);
    },
  );

  test(
    'a startup sync can cancel a pending custom-tone notification',
    () async {
      json.hold = true;
      final system = _System();
      final service = _service(controller, system);
      await service.start(en);
      json.pushGroup(42);
      await json.requested.future;
      json.push({'@type': 'updateActiveNotifications', 'groups': []});
      await Future<void>.delayed(const Duration(milliseconds: 30));
      json.complete();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(system.shown, isEmpty);
    },
  );

  test(
    'off then on cannot revive a tone already waiting for download',
    () async {
      json.hold = true;
      final system = _System();
      final service = _service(controller, system);
      await service.start(en);
      json.pushGroup(42);
      await json.requested.future;
      service.settings = service.settings.copyWith(enabled: false);
      service.settings = service.settings.copyWith(enabled: true);
      json.complete();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(system.shown, isEmpty);
    },
  );

  test('disposed account cannot post a delayed custom tone', () async {
    json.hold = true;
    final system = _System();
    final audio = NotificationAudioSession(controller.sounds);
    addTearDown(audio.dispose);
    final service = _service(controller, system, audio: audio);
    await service.start(en);
    json.pushGroup(42);
    await json.requested.future;
    await service.dispose();
    // The signed-in provider scope owns and disposes the audio session.
    await audio.dispose();
    json.complete();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(system.shown, isEmpty);
    expect(
      calls.any((c) => c.method == 'releaseSoundSession'),
      Platform.isMacOS,
    );
  });
}

NotificationService _service(
  NotificationController controller,
  _System system, {
  NotificationAudioSession? audio,
}) {
  final service = NotificationService(
    controller: controller,
    system: system,
    audio: audio,
    openChat: (_) {},
  );
  addTearDown(service.dispose);
  return service;
}

Future<void> _until(bool Function() ready) async {
  for (var i = 0; i < 200 && !ready(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(ready(), isTrue, reason: 'notification pipeline did not settle');
}

final class _System implements SystemNotifications {
  final shown = <SystemNotification>[];
  @override
  Stream<NotificationResponse> get responses => const Stream.empty();
  @override
  Future<void> configure(NotificationLabels labels) async {}
  @override
  Future<NotificationPermission> permission() async =>
      NotificationPermission.authorized;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> show(SystemNotification notification) async =>
      shown.add(notification);
  @override
  Future<void> remove(List<String> ids) async {}
  @override
  Future<void> retain(Set<String> ids) async {}
  @override
  Future<void> setBadge(String? label) async {}
  @override
  Future<void> removeAll() async {}
}

final class _Json implements td.TdJson {
  _Json(this.path);
  final String path;
  final _queue = Queue<String>();
  final sent = <Map<String, Object?>>[];
  final requested = Completer<void>();
  bool hold = false;
  bool fail = false;
  Map<String, Object?>? _held;
  @override
  int createClientId() => 1;
  @override
  String? execute(String request) => null;
  @override
  String? receive(double timeout) =>
      _queue.isEmpty ? null : _queue.removeFirst();
  @override
  void send(int clientId, String request) {
    final r = jsonDecode(request) as Map<String, Object?>;
    sent.add(r);
    if (r['@type'] == 'getSavedNotificationSound') {
      if (!requested.isCompleted) requested.complete();
      if (hold) {
        _held = r;
        return;
      }
    }
    final file = {
      '@type': 'file',
      'id': 7,
      'size': 3,
      'expected_size': 3,
      'local': {
        '@type': 'localFile',
        'path': path,
        'is_downloading_completed': true,
      },
      'remote': {'@type': 'remoteFile', 'id': '', 'unique_id': ''},
    };
    final value = switch (r['@type']) {
      'getSavedNotificationSound' =>
        fail
            ? {'@type': 'error', 'code': 500, 'message': 'offline'}
            : {
                '@type': 'notificationSound',
                'id': '42',
                'duration': 1,
                'date': 0,
                'title': 'Own tone',
                'data': '',
                'sound': file,
              },
      'getOption' => {
        '@type': 'optionValueInteger',
        'value': r['name'] == 'notification_sound_size_max' ? '307200' : '5',
      },
      _ => {'@type': 'ok'},
    };
    _queue.add(jsonEncode({...value, '@client_id': 1, '@extra': r['@extra']}));
    if (r['@type'] == 'close') {
      push({
        '@type': 'updateAuthorizationState',
        'authorization_state': {'@type': 'authorizationStateClosed'},
      });
    }
  }

  void complete() {
    hold = false;
    send(1, jsonEncode(_held!));
    _held = null;
  }

  void push(Map<String, Object?> update) =>
      _queue.add(jsonEncode({...update, '@client_id': 1}));
  Map<String, Object?> notification(int id, bool silent) => {
    '@type': 'notification',
    'id': id,
    'date': 1,
    'is_silent': silent,
    'type': {
      '@type': 'notificationTypeNewMessage',
      'show_preview': true,
      'message': {
        '@type': 'message',
        'id': id,
        'chat_id': 10,
        'sender_id': {'@type': 'messageSenderUser', 'user_id': 1},
        'content': {
          '@type': 'messageText',
          'text': {
            '@type': 'formattedText',
            'text': 'hello',
            'entities': <Map<String, Object?>>[],
          },
        },
      },
    },
  };
  void pushGroup(int soundId, {bool silent = false, int notificationId = 1}) =>
      push({
        '@type': 'updateNotificationGroup',
        'notification_group_id': 1,
        'type': {'@type': 'notificationGroupTypeMessages'},
        'chat_id': 10,
        'notification_settings_chat_id': 10,
        'notification_sound_id': '$soundId',
        'total_count': notificationId,
        'added_notifications': [notification(notificationId, silent)],
        'removed_notification_ids': [],
      });
  void pushEdit() => push({
    '@type': 'updateNotification',
    'notification_group_id': 1,
    'notification': notification(1, false),
  });
}
