import 'dart:collection';
import 'dart:convert';

import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_tdlib/mollygram_tdlib.dart' as td;
import 'package:test/test.dart';

void main() {
  late _Json json;
  late td.Td tdlib;
  late ChatSearch search;
  late SearchSuggestionsController controller;

  setUp(() {
    json = _Json();
    tdlib = td.Td.custom(json, td.InlineTdEventSource(json));
    search = ChatSearch(tdlib.createClient());
    controller = SearchSuggestionsController(search);
  });
  tearDown(() async {
    controller.dispose();
    await tdlib.close();
  });

  test(
    'loads real recent search and top users without writing history',
    () async {
      final pending = controller.load();
      expect(controller.state.loading, isTrue);
      await pending;
      expect(controller.state.recent, [2, 1]);
      expect(controller.state.top, [3, 1]);
      expect(controller.state.loading, isFalse);
      expect(json.sent.map((r) => r['@type']), [
        'searchRecentlyFoundChats',
        'getTopChats',
      ]);
      expect(json.sent.first['query'], '');
      expect(json.sent.first['type_filter'], isNull);
      expect(json.sent.last['category'], {'@type': 'topChatCategoryUsers'});
      expect(json.sent.last['limit'], 5);
    },
  );

  test('failed reload retains each section and exposes retry state', () async {
    await controller.load();
    json.fail.add('getTopChats');
    json.recent = [4];
    await controller.load();
    expect(controller.state.recent, [4]);
    expect(controller.state.top, [3, 1]);
    expect(controller.state.topFailed, isTrue);
    expect(controller.state.recentFailed, isFalse);
    json.fail.clear();
    json.top = [5];
    await controller.load();
    expect(controller.state.top, [5]);
    expect(controller.state.topFailed, isFalse);
  });

  test(
    'remove and clear change only recent metadata after acknowledgement',
    () async {
      await controller.load();
      await controller.remove(2);
      expect(controller.state.recent, [1]);
      expect(controller.state.top, [3, 1]);
      expect(json.sent.last['@type'], 'removeRecentlyFoundChat');
      expect(json.sent.last['chat_id'], 2);
      await controller.clear();
      expect(controller.state.recent, isEmpty);
      expect(controller.state.top, [3, 1]);
      expect(json.sent.last['@type'], 'clearRecentlyFoundChats');
      await controller.load();
      expect(controller.state.recent, isEmpty);
    },
  );

  test(
    'failed removal and clear preserve history, retry can succeed',
    () async {
      await controller.load();
      json.fail.addAll(['removeRecentlyFoundChat', 'clearRecentlyFoundChats']);
      await controller.remove(2);
      expect(controller.state.recent, [2, 1]);
      expect(controller.state.actionFailed, isTrue);
      await controller.clear();
      expect(controller.state.recent, [2, 1]);
      expect(controller.state.actionFailed, isTrue);
      json.fail.clear();
      await controller.clear();
      expect(controller.state.recent, isEmpty);
      expect(controller.state.actionFailed, isFalse);
    },
  );

  test('cannot clear or remove during initial load', () async {
    json.hold = true;
    final load = controller.load();
    await controller.clear();
    await controller.remove(2);
    expect(json.sent.map((r) => r['@type']), [
      'searchRecentlyFoundChats',
      'getTopChats',
    ]);
    json.release();
    await load;
  });

  test(
    'serializes mutation and reload; no duplicate delete while pending',
    () async {
      await controller.load();
      json.hold = true;
      final remove = controller.remove(2);
      expect(controller.state.mutating, isTrue);
      expect(controller.state.recent, [2, 1]);
      await controller.clear();
      await controller.load();
      expect(
        json.sent.where((r) => r['@type'] == 'clearRecentlyFoundChats'),
        isEmpty,
      );
      json.release();
      await remove;
      expect(controller.state.recent, [1]);
      expect(controller.state.mutating, isFalse);
    },
  );

  test('records chosen chat with TDLib, never a raw query', () async {
    await search.rememberChat(3);
    await controller.load();
    expect(controller.state.recent, [3, 2, 1]);
    expect(json.sent.first['@type'], 'addRecentlyFoundChat');
    expect(json.sent.first['chat_id'], 3);
  });

  test(
    'disposed account rejects late load; new account starts empty',
    () async {
      json.hold = true;
      final load = controller.load();
      controller.dispose();
      final next = SearchSuggestionsController(search);
      expect(next.state.recent, isEmpty);
      expect(next.state.top, isEmpty);
      json.release();
      await load;
      expect(controller.state.recent, isEmpty);
      expect(next.state.recent, isEmpty);
      next.dispose();
    },
  );

  test('disposed account rejects late mutation and future requests', () async {
    await controller.load();
    json.hold = true;
    final remove = controller.remove(2);
    controller.dispose();
    json.release();
    await remove;
    expect(controller.state.recent, [2, 1]);
    final count = json.sent.length;
    await controller.clear();
    await controller.load();
    expect(json.sent, hasLength(count));
  });
}

final class _Json implements td.TdJson {
  final _queue = Queue<String>();
  final _held = <String>[];
  final sent = <Map<String, dynamic>>[];
  final fail = <String>{};
  var recent = [2, 1];
  var top = [3, 1];
  var hold = false;

  void release() {
    hold = false;
    _queue.addAll(_held);
    _held.clear();
  }

  @override
  int createClientId() => 1;
  @override
  String? execute(String request) => null;
  @override
  String? receive(double timeout) =>
      _queue.isEmpty ? null : _queue.removeFirst();
  @override
  void send(int clientId, String request) {
    final r = jsonDecode(request) as Map<String, dynamic>;
    sent.add(r);
    final type = r['@type'] as String;
    Map<String, dynamic> result;
    if (fail.contains(type)) {
      result = {'@type': 'error', 'code': 500, 'message': 'offline'};
    } else {
      switch (type) {
        case 'searchRecentlyFoundChats':
          result = {
            '@type': 'chats',
            'total_count': recent.length,
            'chat_ids': recent,
          };
        case 'getTopChats':
          result = {
            '@type': 'chats',
            'total_count': top.length,
            'chat_ids': top,
          };
        case 'addRecentlyFoundChat':
          recent = [
            r['chat_id'] as int,
            ...recent.where((id) => id != r['chat_id']),
          ];
          result = {'@type': 'ok'};
        case 'removeRecentlyFoundChat':
          recent = recent.where((id) => id != r['chat_id']).toList();
          result = {'@type': 'ok'};
        case 'clearRecentlyFoundChats':
          recent = [];
          result = {'@type': 'ok'};
        default:
          result = {'@type': 'ok'};
      }
    }
    final encoded = jsonEncode({
      ...result,
      '@client_id': clientId,
      '@extra': r['@extra'],
    });
    if (type == 'close') {
      _queue.add(
        jsonEncode({
          '@type': 'updateAuthorizationState',
          'authorization_state': {'@type': 'authorizationStateClosed'},
          '@client_id': clientId,
        }),
      );
    }
    if (hold) {
      _held.add(encoded);
    } else {
      _queue.add(encoded);
    }
  }
}
