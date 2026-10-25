import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram/l10n/app_localizations.dart';
import 'package:mollygram/src/notifications/notification_audio.dart';
import 'package:mollygram/src/notifications/notification_scope_page.dart';
import 'package:mollygram/src/notifications/notification_settings.dart';
import 'package:mollygram/src/notifications/notification_sounds_page.dart';
import 'package:mollygram/src/notifications/notifications_page.dart';
import 'package:mollygram/src/notifications/system_notifications.dart';
import 'package:mollygram/src/settings/settings_style.dart';
import 'package:mollygram/src/settings/settings_window.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_tdlib/mollygram_tdlib.dart' as td;
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late _ScopeJson json;
  late td.Td tdlib;
  late NotificationController controller;
  final audioCalls = <MethodCall>[];
  const audioChannel = MethodChannel('mollygram/notifications');

  setUp(() async {
    json = _ScopeJson();
    tdlib = td.Td.custom(json, td.InlineTdEventSource(json));
    controller = NotificationController(tdlib.createClient());
    await controller.start();
    audioCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (call) async {
          audioCalls.add(call);
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, null);
    await tdlib.close();
  });

  Future<void> page(
    WidgetTester tester, {
    bool dark = false,
    Locale locale = const Locale('en'),
    Widget content = const NotificationScopePage(
      scope: NotificationScope.groups,
    ),
    void Function(String, WidgetBuilder)? onPush,
  }) async {
    final pageJson = json;
    final pageController = controller;
    addTearDown(() async {
      if (pageJson._held != null) pageJson.completeWrite();
      if (pageJson._heldTones != null) pageJson.completeTones();
      await tester.pumpWidget(const SizedBox.shrink());
      final disposed = pageController.dispose();
      // Queued writes were created in the widget test's fake async zone.
      // Let their completion listeners run before awaiting disposal outside it.
      await settle(tester);
      await disposed;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationControllerProvider.overrideWithValue(controller),
          notificationAudioProvider.overrideWith((ref) {
            final audio = NotificationAudioSession(
              ref.watch(notificationControllerProvider).sounds,
              supported: true,
            );
            ref.onDispose(() => audio.dispose());
            return audio;
          }),
          notificationSettingsStorageProvider.overrideWithValue(
            MemoryNotificationSettingsStorage(),
          ),
          notificationPermissionProvider.overrideWith(
            (ref) async => NotificationPermission.authorized,
          ),
        ],
        child: MaterialApp(
          theme: buildMgTheme(dark ? MgColors.dark : MgColors.light),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: const ValueKey('scope-page'),
            child: Material(
              color: dark ? const Color(0xFF202020) : const Color(0xFFF2F2F2),
              child: SettingsNavigation(
                push: onPush ?? (_, _) {},
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  bool toggled(WidgetTester tester, String label) => tester
      .widget<SettingsSwitchRow>(find.widgetWithText(SettingsSwitchRow, label))
      .value;

  testWidgets(
    'tone selector shows actual selected saved sound and saves exact IDs',
    (tester) async {
      await page(
        tester,
        content: const NotificationSoundsPage(scope: NotificationScope.groups),
      );
      expect(find.text('Test tone'), findsOneWidget);
      for (final (label, id) in [
        (en.notificationSoundDefault, '-1'),
        (en.notificationSoundNone, '0'),
        ('Test tone', '42'),
      ]) {
        await tester.tap(find.text(label));
        await settle(tester);
        expect(json.settings['sound_id'], id);
        expect(json.writes.last['disable_mention_notifications'], isTrue);
      }
    },
  );

  Finder tone(int id) => find.byKey(ValueKey(('notificationTone', id)));
  Future<void> tonesPage(WidgetTester tester, {bool dark = false}) => page(
    tester,
    dark: dark,
    content: const NotificationSoundsPage(scope: NotificationScope.groups),
  );

  testWidgets('tone save failure keeps selection and retry reads it back', (
    tester,
  ) async {
    await tonesPage(tester);
    json.failWrite = true;
    await tester.tap(find.text(en.notificationSoundNone));
    await settle(tester);
    expect(find.text(en.saveFailed), findsOneWidget);
    expect(json.settings['sound_id'], '42');
    json.failWrite = false;
    await tester.tap(find.text(en.notificationSoundNone));
    await settle(tester);
    expect(find.text(en.saveFailed), findsNothing);
    expect(json.settings['sound_id'], '0');
    expect(
      find.descendant(of: tone(0), matching: find.byType(MgIcon)),
      findsOneWidget,
    );
  });

  testWidgets('tone readback failure disables choices until retry', (
    tester,
  ) async {
    await tonesPage(tester);
    json.failReadAfterWrite = true;
    await tester.tap(find.text(en.notificationSoundNone));
    await settle(tester);
    expect(find.text(en.saveFailed), findsNothing);
    expect(find.text(en.notificationsLoadFailed), findsOneWidget);
    expect(tester.widget<SettingsRow>(tone(-1)).onTap, isNull);
    json.failRead = false;
    await tester.tap(find.text(en.tryAgain));
    await settle(tester);
    expect(tester.widget<SettingsRow>(tone(-1)).onTap, isNotNull);
    expect(json.settings['sound_id'], '0');
  });

  testWidgets('tone loading and saved-list errors offer an honest retry', (
    tester,
  ) async {
    json.holdTones = true;
    await tonesPage(tester);
    expect(find.byType(SettingsSpinner), findsWidgets);
    expect(find.text('Test tone'), findsNothing);
    json.failTones = true;
    json.completeTones();
    await settle(tester);
    expect(find.text(en.notificationsLoadFailed), findsOneWidget);
    json.failTones = false;
    await tester.tap(find.text(en.tryAgain));
    await settle(tester);
    expect(find.text('Test tone'), findsOneWidget);
  });

  testWidgets(
    'tone pending disables choices, preview never saves, failed custom stays selected',
    (tester) async {
      await tonesPage(tester);
      await tester.tap(
        find.descendant(
          of: tone(-1),
          matching: find.text(en.notificationSoundPreview),
        ),
      );
      await settle(tester);
      expect(audioCalls.last.method, 'previewSound');
      expect((audioCalls.last.arguments as Map)['soundId'], '-1');
      expect(json.writes, isEmpty);
      await tester.tap(
        find.descendant(
          of: tone(42),
          matching: find.text(en.notificationSoundPreview),
        ),
      );
      await settle(tester);
      expect(find.text(en.notificationSoundUnavailable), findsOneWidget);
      expect(json.settings['sound_id'], '42');
      expect(json.writes, isEmpty);
      json.holdWrites = true;
      await tester.tap(find.text(en.notificationSoundNone));
      await settle(tester);
      expect(tester.widget<SettingsRow>(tone(42)).onTap, isNull);
      expect(find.byType(SettingsSpinner), findsOneWidget);
      json.completeWrite();
      await settle(tester);
    },
  );

  testWidgets('keyboard can select a tone with an explicit focus indicator', (
    tester,
  ) async {
    await tonesPage(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(json.settings['sound_id'], '-1');
  });

  testWidgets(
    'account replacement clears pending UI and ignores stale failure',
    (tester) async {
      await tonesPage(tester);
      final oldJson = json..holdWrites = true;
      final oldTd = tdlib;
      await tester.tap(find.text(en.notificationSoundNone));
      await settle(tester);
      json = _ScopeJson()..settings['sound_id'] = '-1';
      await tester.runAsync(() async {
        tdlib = td.Td.custom(json, td.InlineTdEventSource(json));
        controller = NotificationController(tdlib.createClient());
        await controller.start();
      });
      await tonesPage(tester);
      oldJson.failWrite = true;
      oldJson.completeWrite();
      await settle(tester);
      expect(find.text(en.saveFailed), findsNothing);
      expect(tester.widget<SettingsRow>(tone(0)).onTap, isNotNull);
      expect(json.writes, isEmpty);
      expect(audioCalls.any((c) => c.method == 'releaseSoundSession'), isTrue);
      addTearDown(oldTd.close);
    },
  );

  testWidgets('saved-list updates reload titles without writing settings', (
    tester,
  ) async {
    await tonesPage(tester);
    json.toneTitle = 'Updated tone';
    json.push({
      '@type': 'updateSavedNotificationSounds',
      'notification_sound_ids': ['42'],
    });
    await settle(tester);
    expect(find.text('Updated tone'), findsOneWidget);
    expect(find.text('Test tone'), findsNothing);
    expect(json.writes, isEmpty);
  });

  testWidgets('loads the group defaults from Telegram', (tester) async {
    json.settings['mute_for'] = 3600;
    json.settings['show_preview'] = false;
    await page(tester);
    expect(toggled(tester, en.notificationsShow), isFalse);
    expect(toggled(tester, en.notificationsPreview), isFalse);
    expect(find.text('Test tone'), findsOneWidget);
    expect(json.scopes.toSet(), {'notificationSettingsScopeGroupChats'});
    expect(json.writes, isEmpty);
  });

  testWidgets('the overview opens the selected category', (tester) async {
    NotificationScope? opened;
    await page(
      tester,
      content: const NotificationsPage(),
      onPush: (_, builder) {
        final context = tester.element(find.byType(NotificationsPage));
        opened = (builder(context) as NotificationScopePage).scope;
      },
    );
    expect(json.scopes.toSet(), {
      'notificationSettingsScopePrivateChats',
      'notificationSettingsScopeGroupChats',
      'notificationSettingsScopeChannelChats',
    });
    for (final scope in NotificationScope.values) {
      await tester.tap(find.text(notificationScopeTitle(en, scope)));
      await tester.pumpAndSettle();
      expect(opened, scope);
    }
    expect(json.writes, isEmpty);
  });

  testWidgets('saves one field, disables pending controls and reads back', (
    tester,
  ) async {
    await page(tester);
    json.holdWrites = true;
    await tester.tap(find.text(en.notificationsPreview));
    await settle(tester);
    expect(toggled(tester, en.notificationsPreview), isFalse);
    for (final row in tester.widgetList<SettingsSwitchRow>(
      find.byType(SettingsSwitchRow),
    )) {
      expect(row.onChanged, isNull);
    }
    expect(json.writes.single['show_preview'], isFalse);
    expect(json.writes.single['sound_id'], '42');
    expect(json.writes.single['disable_mention_notifications'], isTrue);
    json.completeWrite();
    await settle(tester);
    expect(toggled(tester, en.notificationsPreview), isFalse);
    expect(
      tester
          .widget<SettingsSwitchRow>(
            find.widgetWithText(SettingsSwitchRow, en.notificationsShow),
          )
          .onChanged,
      isNotNull,
    );
    expect(json.scopes.length, greaterThanOrEqualTo(3));
  });

  testWidgets('failed save rolls back and can be retried', (tester) async {
    await page(tester);
    json.failWrite = true;
    await tester.tap(find.text(en.notificationsPreview));
    await settle(tester);
    expect(find.text(en.saveFailed), findsOneWidget);
    expect(toggled(tester, en.notificationsPreview), isTrue);
    json.failWrite = false;
    await tester.tap(find.text(en.notificationsPreview));
    await settle(tester);
    expect(find.text(en.saveFailed), findsNothing);
    expect(toggled(tester, en.notificationsPreview), isFalse);
  });

  testWidgets('successful save with failed readback offers a load retry', (
    tester,
  ) async {
    await page(tester);
    json.failReadAfterWrite = true;
    await tester.tap(find.text(en.notificationsPreview));
    await settle(tester);
    expect(json.settings['show_preview'], isFalse);
    expect(find.text(en.saveFailed), findsNothing);
    expect(find.text(en.notificationsLoadFailed), findsOneWidget);
    expect(find.text(en.tryAgain), findsOneWidget);
    json.failRead = false;
    await tester.tap(find.text(en.tryAgain));
    await settle(tester);
    expect(toggled(tester, en.notificationsPreview), isFalse);
    expect(find.text(en.notificationsLoadFailed), findsNothing);
  });

  testWidgets('failed load has retry, never editable fake defaults', (
    tester,
  ) async {
    json.failRead = true;
    await page(tester);
    expect(find.byType(SettingsSwitchRow), findsNothing);
    expect(find.text(en.tryAgain), findsOneWidget);
    json.failRead = false;
    await tester.tap(find.text(en.tryAgain));
    await settle(tester);
    expect(find.byType(SettingsSwitchRow), findsNWidgets(2));
  });

  testWidgets('follows settings changed on another device', (tester) async {
    await page(tester);
    json.settings['show_preview'] = false;
    json.push({
      '@type': 'updateScopeNotificationSettings',
      'scope': {'@type': 'notificationSettingsScopeGroupChats'},
      'notification_settings': json.settings,
    });
    await settle(tester);
    expect(toggled(tester, en.notificationsPreview), isFalse);
    expect(json.writes, isEmpty);
  });

  testWidgets('Russian strings are applied', (tester) async {
    await page(tester, locale: const Locale('ru'));
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(find.text(ru.notificationsPreview), findsOneWidget);
    expect(find.text(ru.notificationsScopeHint), findsOneWidget);
  });

  for (final dark in [false, true]) {
    for (final state in [
      'ready',
      'loading',
      'error',
      'pending',
      'focus',
      'preview_error',
    ]) {
      testWidgets('tone selector $state ${dark ? 'dark' : 'light'}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(600, 480));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        json.holdTones = state == 'loading';
        json.failTones = state == 'error';
        await tonesPage(tester, dark: dark);
        if (state == 'pending') {
          json.holdWrites = true;
          await tester.tap(find.text(en.notificationSoundNone));
          await settle(tester);
        }
        if (state == 'focus') {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await settle(tester);
        }
        if (state == 'preview_error') {
          await tester.tap(
            find.descendant(
              of: tone(42),
              matching: find.text(en.notificationSoundPreview),
            ),
          );
          await settle(tester);
        }
        await expectLater(
          find.byKey(const ValueKey('scope-page')),
          matchesGoldenFile(
            'goldens/notification_tones_${state}_${dark ? 'dark' : 'light'}${Platform.isMacOS ? '_macos' : ''}.png',
          ),
        );
      });
    }
    testWidgets('scope settings ${dark ? 'dark' : 'light'}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await page(tester, dark: dark);
      await expectLater(
        find.byKey(const ValueKey('scope-page')),
        matchesGoldenFile(
          'goldens/notification_scope_${dark ? 'dark' : 'light'}${Platform.isMacOS ? '_macos' : ''}.png',
        ),
      );
    });
  }
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }
}

final class _ScopeJson implements td.TdJson {
  final _queue = Queue<String>();
  final scopes = <String>[];
  final writes = <Map<String, Object?>>[];
  var settings = <String, Object?>{
    '@type': 'scopeNotificationSettings',
    'mute_for': 0,
    'sound_id': '42',
    'show_preview': true,
    'use_default_mute_stories': true,
    'mute_stories': true,
    'story_sound_id': '99',
    'show_story_poster': false,
    'disable_pinned_message_notifications': true,
    'disable_mention_notifications': true,
  };
  var failRead = false;
  var failWrite = false;
  var failReadAfterWrite = false;
  var holdWrites = false;
  var holdTones = false;
  var failTones = false;
  var toneTitle = 'Test tone';
  Map<String, Object?>? _heldTones;
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
    switch (r['@type']) {
      case 'getSavedNotificationSounds':
        if (holdTones) {
          _heldTones = r;
          return;
        }
        if (failTones) {
          _reply(r, {'@type': 'error', 'code': 500, 'message': 'offline'});
          return;
        }
        _reply(r, {
          '@type': 'notificationSounds',
          'notification_sounds': [
            {
              '@type': 'notificationSound',
              'id': '42',
              'duration': 1,
              'date': 0,
              'title': toneTitle,
              'data': '',
              'sound': {
                '@type': 'file',
                'id': 7,
                'local': {'@type': 'localFile', 'path': ''},
                'remote': {'@type': 'remoteFile', 'id': '', 'unique_id': ''},
              },
            },
          ],
        });
      case 'getScopeNotificationSettings':
        scopes.add((r['scope'] as Map)['@type'] as String);
        _reply(
          r,
          failRead
              ? {'@type': 'error', 'code': 500, 'message': 'offline'}
              : settings,
        );
      case 'setScopeNotificationSettings':
        writes.add(
          Map<String, Object?>.from(r['notification_settings'] as Map),
        );
        if (holdWrites) {
          _held = r;
        } else {
          _save(r);
        }
      default:
        _reply(r, {'@type': 'ok'});
        if (r['@type'] == 'close') {
          push({
            '@type': 'updateAuthorizationState',
            'authorization_state': {'@type': 'authorizationStateClosed'},
          });
        }
    }
  }

  void _save(Map<String, Object?> r) {
    if (failWrite) {
      _reply(r, {'@type': 'error', 'code': 500, 'message': 'offline'});
    } else {
      settings = Map<String, Object?>.from(r['notification_settings'] as Map);
      if (failReadAfterWrite) failRead = true;
      _reply(r, {'@type': 'ok'});
    }
  }

  void completeWrite() {
    holdWrites = false;
    final held = _held!;
    _held = null;
    _save(held);
  }

  void completeTones() {
    holdTones = false;
    final held = _heldTones!;
    _heldTones = null;
    send(1, jsonEncode(held));
  }

  void _reply(Map<String, Object?> r, Map<String, Object?> value) => _queue.add(
    jsonEncode({...value, '@client_id': 1, '@extra': r['@extra']}),
  );
  void push(Map<String, Object?> update) =>
      _queue.add(jsonEncode({...update, '@client_id': 1}));
}
