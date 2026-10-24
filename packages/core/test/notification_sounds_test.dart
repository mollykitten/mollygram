import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_tdlib/mollygram_tdlib.dart' as td;
import 'package:test/test.dart';

void main() {
  late _Json json;
  late td.Td tdlib;
  late NotificationSounds sounds;
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('notification-sounds-');
    final path = '${directory.path}/tone.mp3';
    await File(path).writeAsBytes([1, 2, 3]);
    json = _Json(path);
    tdlib = td.Td.custom(json, td.InlineTdEventSource(json));
    final client = tdlib.createClient();
    sounds = NotificationSounds(client, FileController(client));
  });
  tearDown(() async {
    await tdlib.close();
    await directory.delete(recursive: true);
  });
  test(
    'lists saved tones and resolves default and silence without I/O',
    () async {
      expect((await sounds.load()).single.id, 42);
      json.sent.clear();
      expect((await sounds.resolve(-1)).fallbackDefault, isTrue);
      expect((await sounds.resolve(0)).path, isNull);
      expect((await sounds.resolve(0)).fallbackDefault, isFalse);
      expect(json.sent, isEmpty);
    },
  );
  test(
    'downloads saved MP3 through FileController, retaining exact ID',
    () async {
      final sound = await sounds.resolve(42);
      expect(sound.path, json.path);
      expect(sound.fallbackDefault, isFalse);
      expect(
        json.sent.singleWhere(
          (r) => r['@type'] == 'downloadFile',
        )['synchronous'],
        isTrue,
      );
    },
  );
  test('failed downloads are errors, never default playback', () async {
    json.failDownload = true;
    await expectLater(sounds.resolve(42), throwsA(isA<td.TdException>()));
  });
  test(
    'missing local file is an error even if TDLib reports completion',
    () async {
      await File(json.path).delete();
      await expectLater(
        sounds.resolve(42),
        throwsA(isA<FileSystemException>()),
      );
    },
  );
  test('deleted saved ID follows TDLib documented default fallback', () async {
    json.removed = true;
    expect((await sounds.resolve(42)).fallbackDefault, isTrue);
  });
  test('honors server size and duration limits before download', () async {
    json.duration = 6;
    await expectLater(sounds.resolve(42), throwsA(isA<StateError>()));
    expect(json.sent.where((r) => r['@type'] == 'downloadFile'), isEmpty);
    json.duration = 1;
    json.size = 307201;
    await expectLater(sounds.resolve(42), throwsA(isA<StateError>()));
    json.size = 3;
    json.maxSize = 2;
    await expectLater(sounds.resolve(42), throwsA(isA<StateError>()));
  });
  test(
    'replacement account never reuses another accounts tone or file',
    () async {
      await sounds.resolve(42);
      final other = _Json('${directory.path}/missing.mp3')..removed = true;
      final otherTd = td.Td.custom(other, td.InlineTdEventSource(other));
      final client = otherTd.createClient();
      final replacement = NotificationSounds(client, FileController(client));
      expect((await replacement.load()).single.title, 'Test tone');
      expect((await replacement.resolve(42)).fallbackDefault, isTrue);
      expect(
        other.sent.any((r) => r['@type'] == 'getSavedNotificationSound'),
        isTrue,
      );
      await otherTd.close();
    },
  );
}

final class _Json implements td.TdJson {
  _Json(this.path);
  final String path;
  final _queue = Queue<String>();
  final sent = <Map<String, Object?>>[];
  bool failDownload = false;
  bool removed = false;
  int duration = 1;
  int size = 3;
  int maxSize = 307200;
  Map<String, Object?> get file => {
    '@type': 'file',
    'id': 7,
    'size': size,
    'expected_size': size,
    'local': {
      '@type': 'localFile',
      'path': path,
      'can_be_downloaded': true,
      'is_downloading_completed': false,
    },
    'remote': {'@type': 'remoteFile', 'id': '', 'unique_id': ''},
  };
  Map<String, Object?> get tone => {
    '@type': 'notificationSound',
    'id': '42',
    'duration': duration,
    'date': 0,
    'title': 'Test tone',
    'data': '',
    'sound': file,
  };
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
    final response = switch (r['@type']) {
      'getSavedNotificationSounds' => {
        '@type': 'notificationSounds',
        'notification_sounds': [tone],
      },
      'getSavedNotificationSound' =>
        removed ? {'@type': 'error', 'code': 404, 'message': 'removed'} : tone,
      'getOption' => {
        '@type': 'optionValueInteger',
        'value': '${r['name'] == 'notification_sound_size_max' ? maxSize : 5}',
      },
      'downloadFile' =>
        failDownload
            ? {'@type': 'error', 'code': 500, 'message': 'offline'}
            : {
                ...file,
                'local': {
                  ...file['local'] as Map,
                  'is_downloading_completed': true,
                },
              },
      _ => {'@type': 'ok'},
    };
    _queue.add(
      jsonEncode({...response, '@client_id': 1, '@extra': r['@extra']}),
    );
    if (r['@type'] == 'close') {
      _queue.add(
        jsonEncode({
          '@type': 'updateAuthorizationState',
          '@client_id': 1,
          'authorization_state': {'@type': 'authorizationStateClosed'},
        }),
      );
    }
  }
}
