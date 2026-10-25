import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram/l10n/app_localizations.dart';
import 'package:mollygram/src/settings/inactive_session_ttl.dart';
import 'package:mollygram/src/settings/settings_style.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_tdlib/mollygram_tdlib.dart' as td;
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late _PeriodJson json;
  late td.Td tdlib;
  late AccountSettings account;

  setUp(() {
    json = _PeriodJson();
    tdlib = td.Td.custom(json, td.InlineTdEventSource(json));
    account = AccountSettings(tdlib.createClient());
  });
  tearDown(() => tdlib.close());

  Future<void> page(
    WidgetTester tester, {
    AccountSettings? replacement,
    bool dark = false,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('period-render'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildMgTheme(dark ? MgColors.dark : MgColors.light),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              MediaQuery.fromView(view: View.of(context), child: child!),
          home: Builder(
            builder: (context) => Material(
              color: SettingsColors.of(context).pane,
              child: SettingsPage(
                children: [
                  InactiveSessionTtlSettings(account: replacement ?? account),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Finder getRow() => find.byKey(const ValueKey('sessionTtlPeriod'));
  Future<void> choose(WidgetTester tester, String label) async {
    await tester.tap(getRow());
    await settle(tester);
    await tester.tap(find.text(label).last);
    await settle(tester);
  }

  testWidgets('fresh server value, custom days and opening never writes', (
    tester,
  ) async {
    json.days = 43;
    await page(tester);
    expect(find.text('43 days'), findsOneWidget);
    expect(json.writes, isEmpty);
    await tester.tap(getRow());
    await settle(tester);
    expect(find.text('43 days'), findsNWidgets(2));
    expect(json.writes, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    json.days = 90;
    await page(tester);
    expect(find.text('3 months'), findsOneWidget);
    expect(json.writes, isEmpty);
  });

  for (final (days, label) in [
    (7, '1 week'),
    (30, '1 month'),
    (90, '3 months'),
    (180, '6 months'),
    (365, '1 year'),
  ]) {
    testWidgets('saves official preset $days after deliberate selection', (
      tester,
    ) async {
      json.days = 43;
      await page(tester);
      await choose(tester, label);
      expect(json.writes, [days]);
      expect(find.text(label), findsOneWidget);
      expect(json.reads, 2);
      expect(
        json.sent.where((r) => (r['@type'] as String).startsWith('terminate')),
        isEmpty,
      );
    });
  }

  testWidgets('blocks repeated writes through acknowledgement and readback', (
    tester,
  ) async {
    json.holdWrite = true;
    await page(tester);
    await choose(tester, '1 week');
    expect(json.writes, [7]);
    expect(json.reads, 1);
    expect(tester.widget<SettingsRow>(getRow()).onTap, isNull);
    expect(find.text('6 months'), findsOneWidget);
    json.holdRead = true;
    json.completeWrite();
    await settle(tester);
    expect(json.reads, 2);
    expect(tester.widget<SettingsRow>(getRow()).onTap, isNull);
    // Display what the server actually returns, not an optimistic choice.
    json.completeRead(days: 44);
    await settle(tester);
    expect(find.text('44 days'), findsOneWidget);
    expect(tester.widget<SettingsRow>(getRow()).onTap, isNotNull);
  });

  testWidgets('write failure is distinct and retry only reads', (tester) async {
    json.failWrite = true;
    await page(tester);
    await choose(tester, '1 week');
    expect(find.text(en.sessionTtlWriteFailed), findsOneWidget);
    expect(tester.widget<SettingsRow>(getRow()).onTap, isNull);
    await tester.tap(find.text(en.tryAgain));
    await settle(tester);
    expect(find.text('6 months'), findsOneWidget);
    expect(json.writes, [7]);
    json.failWrite = false;
    await choose(tester, '1 month');
    expect(json.writes, [7, 30]);
  });

  testWidgets(
    'acknowledged save with failed readback does not claim write failed',
    (tester) async {
      json.holdWrite = true;
      await page(tester);
      await choose(tester, '1 week');
      json.failRead = true;
      json.completeWrite();
      await settle(tester);
      expect(find.text(en.sessionTtlReadbackFailed), findsOneWidget);
      expect(find.text(en.sessionTtlWriteFailed), findsNothing);
      expect(find.text('6 months'), findsNothing);
      expect(tester.widget<SettingsRow>(getRow()).onTap, isNull);
      json.failRead = false;
      await tester.tap(find.text(en.tryAgain));
      await settle(tester);
      expect(find.text('1 week'), findsOneWidget);
      expect(json.writes, [7]);
    },
  );

  for (final invalid in [0, 367]) {
    testWidgets('invalid server value $invalid stays unknown and retryable', (
      tester,
    ) async {
      json.days = invalid;
      await page(tester);
      expect(find.text(en.sessionTtlLoadFailed), findsOneWidget);
      expect(tester.widget<SettingsRow>(getRow()).onTap, isNull);
      json.days = 366;
      await tester.tap(find.text(en.tryAgain));
      await settle(tester);
      expect(find.text('366 days'), findsOneWidget);
      expect(json.writes, isEmpty);
    });
  }

  testWidgets('loading has no guessed default and retries a failed read', (
    tester,
  ) async {
    json.holdRead = true;
    await page(tester);
    expect(find.text('6 months'), findsNothing);
    expect(tester.widget<SettingsRow>(getRow()).onTap, isNull);
    json.completeRead(error: true);
    await settle(tester);
    expect(find.text(en.sessionTtlLoadFailed), findsOneWidget);
    json.holdRead = false;
    json.days = 1;
    await tester.tap(find.text(en.tryAgain));
    await settle(tester);
    expect(find.text('1 day'), findsOneWidget);
    expect(json.writes, isEmpty);
  });

  testWidgets('disposal during write cannot start a readback', (tester) async {
    json.holdWrite = true;
    await page(tester);
    await choose(tester, '1 week');
    await tester.pumpWidget(const SizedBox.shrink());
    json.completeWrite();
    await settle(tester);
    expect(json.reads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account replacement ignores old out-of-order load', (
    tester,
  ) async {
    json.holdRead = true;
    await page(tester);
    final otherJson = _PeriodJson()..days = 30;
    final otherTd = (await tester.runAsync(
      () async => td.Td.custom(otherJson, td.InlineTdEventSource(otherJson)),
    ))!;
    addTearDown(otherTd.close);
    await page(tester, replacement: AccountSettings(otherTd.createClient()));
    expect(find.text('1 month'), findsOneWidget);
    json.completeRead(days: 7);
    await settle(tester);
    expect(find.text('1 month'), findsOneWidget);
    expect(find.text('1 week'), findsNothing);
    expect(otherJson.writes, isEmpty);
  });

  testWidgets('old open menu cannot write to a replaced account', (
    tester,
  ) async {
    await page(tester);
    await tester.tap(getRow());
    await settle(tester);
    final otherJson = _PeriodJson()..days = 30;
    final otherTd = (await tester.runAsync(
      () async => td.Td.custom(otherJson, td.InlineTdEventSource(otherJson)),
    ))!;
    addTearDown(otherTd.close);
    await page(tester, replacement: AccountSettings(otherTd.createClient()));
    await tester.tap(find.text('1 week').last);
    await settle(tester);
    expect(otherJson.writes, isEmpty);
    expect(json.writes, isEmpty);
  });

  testWidgets('keyboard opens and cancels without writing', (tester) async {
    await page(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(find.text('1 week'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.text('1 week'), findsNothing);
    expect(json.writes, isEmpty);
  });

  testWidgets('keyboard can deliberately select a period', (tester) async {
    await page(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(json.writes, hasLength(1));
    expect(inactiveSessionTtlChoices, contains(json.writes.single));
  });

  testWidgets('account replacement during write never reads back old account', (
    tester,
  ) async {
    json.holdWrite = true;
    await page(tester);
    await choose(tester, '1 week');
    final otherJson = _PeriodJson()..days = 30;
    final otherTd = (await tester.runAsync(
      () async => td.Td.custom(otherJson, td.InlineTdEventSource(otherJson)),
    ))!;
    addTearDown(otherTd.close);
    await page(tester, replacement: AccountSettings(otherTd.createClient()));
    json.completeWrite();
    await settle(tester);
    expect(json.reads, 1);
    expect(find.text('1 month'), findsOneWidget);
    expect(otherJson.writes, isEmpty);
  });

  testWidgets('reduced motion pending paint is stable without a ticker', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    json.holdRead = true;
    await page(tester);
    expect(MediaQuery.disableAnimationsOf(tester.element(getRow())), isTrue);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      0.65,
    );
    final before = await render(tester);
    await tester.pump(const Duration(seconds: 2));
    final after = await render(tester);
    expect(after, orderedEquals(before));
    expect(tester.binding.transientCallbackCount, 0);
    json.completeRead();
    json.holdRead = false;
    await settle(tester);
    await choose(tester, '1 week');
    expect(json.writes, [7]);
    expect(tester.binding.transientCallbackCount, 0);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'renders ${dark ? 'dark' : 'light'} loading, focus, menu, pending and error',
      (tester) async {
        tester.view
          ..physicalSize = const Size(720, 360)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final theme = dark ? 'dark' : 'light';
        json.holdRead = true;
        await page(tester, dark: dark);
        await evidence(tester, '${theme}_loading');
        json.completeRead(days: 43);
        await settle(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await settle(tester);
        await evidence(tester, '${theme}_focus');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await settle(tester);
        await evidence(tester, '${theme}_menu');
        json.holdWrite = true;
        await tester.tap(find.text('1 week').last);
        await settle(tester);
        await evidence(tester, '${theme}_pending');
        json.failWrite = true;
        json.completeWrite();
        await settle(tester);
        await evidence(tester, '${theme}_error');
        expect(find.text(en.sessionTtlWriteFailed), findsOneWidget);
      },
    );
  }

  testWidgets('Russian labels preserve exact custom days', (tester) async {
    json.days = 43;
    await page(tester, locale: const Locale('ru'));
    expect(find.text('43 дня'), findsOneWidget);
    await tester.tap(getRow());
    await settle(tester);
    for (final label in [
      '1 неделя',
      '1 месяц',
      '3 месяца',
      '6 месяцев',
      '1 год',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });
}

Future<Uint8List> render(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('period-render')),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
}

/// Optional reproducible render evidence, not cross-platform golden baselines.
/// These PNGs come from Flutter's actual renderer; no tolerance is relaxed.
Future<void> evidence(WidgetTester tester, String name) async {
  final bytes = await render(tester);
  expect(bytes.length, greaterThan(100));
  const directory = String.fromEnvironment('SESSION_EVIDENCE_DIR');
  if (directory.isNotEmpty) {
    await tester.runAsync(() async {
      await Directory(directory).create(recursive: true);
      await File('$directory/${name}_${Platform.operatingSystem}.png')
          .writeAsBytes(bytes);
    });
  }
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _PeriodJson implements td.TdJson {
  int days = 180;
  bool holdRead = false;
  bool holdWrite = false;
  bool failRead = false;
  bool failWrite = false;
  int reads = 0;
  final writes = <int>[];
  final sent = <Map<String, Object?>>[];
  final _queue = Queue<String>();
  Map<String, Object?>? _read;
  Map<String, Object?>? _write;

  @override
  int createClientId() => 1;
  @override
  String? execute(String request) => null;
  @override
  String? receive(double timeout) =>
      _queue.isEmpty ? null : _queue.removeFirst();
  void reply(Map<String, Object?> request, Map<String, Object?> result) {
    _queue.add(
      jsonEncode({...result, '@client_id': 1, '@extra': request['@extra']}),
    );
  }

  @override
  void send(int clientId, String request) {
    final r = jsonDecode(request) as Map<String, Object?>;
    sent.add(r);
    switch (r['@type']) {
      case 'getActiveSessions':
        reads++;
        if (holdRead) {
          _read = r;
        } else {
          reply(r, failRead ? failure : sessions(days));
        }
      case 'setInactiveSessionTtl':
        writes.add(r['inactive_session_ttl_days']! as int);
        if (holdWrite) {
          _write = r;
        } else {
          finishWrite(r);
        }
      default:
        reply(r, {'@type': 'ok'});
        if (r['@type'] == 'close') {
          _queue.add(
            jsonEncode({
              '@client_id': 1,
              '@type': 'updateAuthorizationState',
              'authorization_state': {'@type': 'authorizationStateClosed'},
            }),
          );
        }
    }
  }

  void finishWrite(Map<String, Object?> r) {
    if (!failWrite) days = r['inactive_session_ttl_days']! as int;
    reply(r, failWrite ? failure : {'@type': 'ok'});
  }

  void completeWrite() {
    finishWrite(_write!);
    _write = null;
  }

  void completeRead({int? days, bool error = false}) {
    reply(_read!, error ? failure : sessions(days ?? this.days));
    _read = null;
  }

  Map<String, Object?> sessions(int value) => {
    '@type': 'sessions',
    'sessions': <Object>[],
    'inactive_session_ttl_days': value,
  };
  static const failure = {
    '@type': 'error',
    'code': 500,
    'message': 'Synthetic failure',
  };
}
