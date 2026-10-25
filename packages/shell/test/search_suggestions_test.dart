import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram_shell/mollygram_shell.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

void main() {
  late _Directory directory;
  final opened = <(int, OpenTarget)>[];
  var closed = 0;

  setUpAll(() async {
    // Use the host's system font on macOS, SDK Roboto elsewhere, not Ahem.
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root == null) throw StateError('FLUTTER_ROOT is required for fonts');
    for (final family in ['Roboto', 'CupertinoSystemText']) {
      final loader = FontLoader(family);
      final systemFont = File('/System/Library/Fonts/SFNS.ttf');
      if (Platform.isMacOS && systemFont.existsSync()) {
        final bytes = await systemFont.readAsBytes();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      } else {
        for (final weight in ['Regular', 'Medium', 'Bold']) {
          final file = File(
            '$root/bin/cache/artifacts/material_fonts/Roboto-$weight.ttf',
          );
          final bytes = await file.readAsBytes();
          loader.addFont(Future.value(ByteData.sublistView(bytes)));
        }
      }
      await loader.load();
    }
  });

  setUp(() {
    directory = _Directory();
    opened.clear();
    closed = 0;
  });
  tearDown(() => directory.dispose());

  Widget app({
    _Directory? source,
    ShellStrings strings = ShellStrings.en,
    bool dark = false,
  }) => RepaintBoundary(
    key: const ValueKey('search-render'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildMgTheme(dark ? MgColors.dark : MgColors.light),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 640,
            child: CommandPalette(
              directory: source ?? directory,
              commands: [
                PaletteCommand(id: 'new', title: 'New tab', run: () {}),
              ],
              strings: strings,
              onOpenChat: (id, target) => opened.add((id, target)),
              onClose: () => closed++,
            ),
          ),
        ),
      ),
    ),
  );

  Finder chat(String title) => find.textContaining(title, findRichText: true);

  for (final dark in [false, true]) {
    testWidgets(
      'renders ${dark ? 'dark' : 'light'} search states',
      (tester) async {
        tester.view
          ..physicalSize = const Size(900, 850)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final theme = dark ? 'dark' : 'light';
        directory.pendingLoad = Completer<void>();
        await tester.pumpWidget(app(dark: dark));
        expect(find.text('Loading suggestions…'), findsOneWidget);
        await evidence(tester, '${theme}_loading');

        directory.pendingLoad!.complete();
        await tester.pump();
        await tester.pump();
        expect(chat('Top Ada'), findsOneWidget);
        expect(chat('Recent Bea'), findsOneWidget);
        await evidence(tester, '${theme}_ready');

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await evidence(tester, '${theme}_keyboardfocus');

        await tester.tap(find.text('Clear recent searches'));
        await tester.pump();
        expect(find.text('Clear recent searches?'), findsOneWidget);
        expect(directory.clears, 0);
        await evidence(tester, '${theme}_clearconfirmation');

        await tester.tap(find.text('Cancel'));
        await tester.pump();
        expect(find.text('Clear recent searches?'), findsNothing);
        directory.pendingMutation = Completer<void>();
        await tester.tap(
          find.bySemanticsLabel('Remove Recent Bea from recent searches'),
        );
        await tester.pump();
        expect(directory.searchSuggestions.mutating, isTrue);
        expect(chat('Recent Bea'), findsOneWidget);
        await evidence(tester, '${theme}_pendingmutation');

        directory.failMutation = true;
        directory.pendingMutation!.complete();
        await tester.pump();
        await tester.pump();
        expect(
          find.text('Couldn’t update recent searches. Try again.'),
          findsOneWidget,
        );
        expect(chat('Recent Bea'), findsOneWidget);
        expect(opened, isEmpty);
        expect(closed, 0);
        await evidence(tester, '${theme}_actionerror');
      },
      variant: TargetPlatformVariant.only(
        Platform.isMacOS ? TargetPlatform.macOS : TargetPlatform.linux,
      ),
    );
  }

  testWidgets('empty search loads top and recent; reading never clears', (
    tester,
  ) async {
    directory.pendingLoad = Completer<void>();
    await tester.pumpWidget(app());
    expect(directory.loads, 1);
    expect(find.text('Loading suggestions…'), findsOneWidget);
    expect(directory.removed, isEmpty);
    expect(directory.clears, 0);
    directory.pendingLoad!.complete();
    await tester.pump();
    expect(find.text('Top peers'), findsOneWidget);
    expect(find.text('Recent searches'), findsOneWidget);
    expect(chat('Top Ada'), findsOneWidget);
    expect(chat('Recent Bea'), findsOneWidget);
    expect(find.text('Loading suggestions…'), findsNothing);
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(opened.single, (2, OpenTarget.current));
    expect(directory.recorded, [2]);
    expect(closed, 1);
  });

  testWidgets(
    'removing a recent never activates its row; failure preserves it',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      directory.failMutation = true;
      await tester.tap(
        find.bySemanticsLabel('Remove Recent Bea from recent searches'),
      );
      await tester.pump();
      expect(chat('Recent Bea'), findsOneWidget);
      expect(
        find.text('Couldn’t update recent searches. Try again.'),
        findsOneWidget,
      );
      expect(opened, isEmpty);
      expect(closed, 0);
      directory.failMutation = false;
      await tester.tap(
        find.bySemanticsLabel('Remove Recent Bea from recent searches'),
      );
      await tester.pump();
      expect(chat('Recent Bea'), findsNothing);
      expect(chat('Top Ada'), findsOneWidget);
      expect(directory.removed, [2, 2]);
    },
  );

  testWidgets(
    'clear requires confirmation; Escape cancels; failure keeps data',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.tap(find.text('Clear recent searches'));
      await tester.pump();
      expect(directory.clears, 0);
      expect(find.text('Clear recent searches?'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        directory.clears,
        0,
        reason: 'focus defaults to Cancel, never deletion',
      );
      expect(opened, isEmpty);
      expect(closed, 0);
      await tester.tap(find.text('Clear recent searches'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Clear recent searches?'), findsNothing);
      expect(closed, 0);
      await tester.tap(find.text('Clear recent searches'));
      await tester.pump();
      directory.failMutation = true;
      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(directory.clears, 1);
      expect(chat('Recent Bea'), findsOneWidget);
      expect(
        find.text('Couldn’t update recent searches. Try again.'),
        findsOneWidget,
      );
      directory.failMutation = false;
      await tester.tap(find.text('Clear recent searches'));
      await tester.pump();
      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(chat('Recent Bea'), findsNothing);
      expect(chat('Top Ada'), findsOneWidget);
      expect(directory.clears, 2);
    },
  );

  testWidgets(
    'loading disables clear and removal, pending mutation cannot repeat',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      directory.pendingMutation = Completer<void>();
      await tester.tap(
        find.bySemanticsLabel('Remove Recent Bea from recent searches'),
      );
      await tester.pump();
      expect(directory.removed, [2]);
      // Clearing is unavailable until the acknowledged mutation completes.
      await tester.tap(find.text('Clear recent searches'));
      await tester.pump();
      expect(find.text('Clear recent searches?'), findsNothing);
      expect(directory.clears, 0);
      directory.pendingMutation!.complete();
      await tester.pump();
      await tester.pump();
      expect(chat('Recent Bea'), findsNothing);
    },
  );

  testWidgets(
    'load error and empty states have retry without losing commands',
    (tester) async {
      directory.failLoad = true;
      await tester.pumpWidget(app());
      await tester.pump();
      expect(find.text('Couldn’t load search suggestions.'), findsOneWidget);
      expect(find.text('New tab'), findsOneWidget);
      directory.failLoad = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(chat('Recent Bea'), findsOneWidget);
      directory.empty = true;
      await directory.loadSearchSuggestions();
      await tester.pump();
      expect(find.text('No recent searches or top peers yet'), findsOneWidget);
      expect(find.text('New tab'), findsOneWidget);
    },
  );

  testWidgets('late empty load does not replace a typed query or prefix', (
    tester,
  ) async {
    directory.pendingLoad = Completer<void>();
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(EditableText), '>New');
    await tester.pump();
    directory.pendingLoad!.complete();
    await tester.pump();
    expect(find.text('Commands'), findsNWidgets(2));
    expect(find.text('Recent searches'), findsNothing);
    expect(chat('Top Ada'), findsNothing);
    await tester.enterText(find.byType(EditableText), '@person');
    await tester.pump();
    expect(chat('Found person'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '#message');
    await tester.pump();
    expect(find.text('Messages'), findsNWidgets(2));
    expect(chat('A message'), findsOneWidget);
    expect(directory.recorded, isEmpty);
  });

  testWidgets(
    'slow query cannot overwrite newer search; pending rows not actionable',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      directory.slowSearch = Completer<List<ChatSummary>>();
      await tester.enterText(find.byType(EditableText), '@slow');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(opened, isEmpty);
      await tester.enterText(find.byType(EditableText), '@fast');
      await tester.pump();
      expect(chat('Found fast'), findsOneWidget);
      directory.slowSearch!.complete([
        const ChatSummary(id: 8, title: 'Old slow'),
      ]);
      await tester.pump();
      expect(chat('Old slow'), findsNothing);
      expect(chat('Found fast'), findsOneWidget);
    },
  );

  testWidgets(
    'replacement account drops old suggestions, confirmation and completions',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.tap(find.text('Clear recent searches'));
      await tester.pump();
      final next = _Directory()..empty = true;
      addTearDown(next.dispose);
      next.pendingLoad = Completer<void>();
      await tester.pumpWidget(app(source: next));
      expect(chat('Recent Bea'), findsNothing);
      expect(find.text('Clear recent searches?'), findsNothing);
      expect(directory.clears, 0);
      directory.notifyListeners();
      await tester.pump();
      expect(chat('Recent Bea'), findsNothing);
      next.pendingLoad!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('No recent searches or top peers yet'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closed, 1);
    },
  );

  testWidgets('account replacement invalidates pending typed results', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();
    directory.slowSearch = Completer<List<ChatSummary>>();
    await tester.enterText(find.byType(EditableText), '@slow');
    await tester.pump();
    final next = _Directory()..empty = true;
    addTearDown(next.dispose);
    await tester.pumpWidget(app(source: next));
    await tester.pump();
    directory.slowSearch!.complete([
      const ChatSummary(id: 8, title: 'Private old account'),
    ]);
    await tester.pump();
    expect(chat('Private old account'), findsNothing);
    expect(chat('Found slow'), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    expect(find.text('No recent searches or top peers yet'), findsOneWidget);
  });

  testWidgets('live updates preserve a scrolled duplicate recent selection', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();
    directory._state = SearchSuggestions(
      top: const [ChatSummary(id: 1, title: 'Top Ada')],
      recent: [
        for (var i = 0; i < 19; i++)
          ChatSummary(id: 10 + i, title: 'Recent $i'),
        const ChatSummary(id: 1, title: 'Repeat Ada'),
      ],
    );
    directory.notifyListeners();
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    expect(scroll.offset, greaterThan(0));
    directory.notifyListeners();
    await tester.pump();
    await tester.pump();
    expect(scroll.offset, greaterThan(0));
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.selected == true &&
            w.properties.label == 'Repeat Ada',
      ),
      findsOneWidget,
    );
  });

  testWidgets('search error offers retry and cannot open stale results', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();
    directory.failSearch = true;
    await tester.enterText(find.byType(EditableText), '@fail');
    await tester.pump();
    expect(find.text('Search failed. Try again.'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(opened, isEmpty);
    directory.failSearch = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(chat('Found fail'), findsOneWidget);
  });
}

/// Actual Flutter render evidence, not cross-platform golden baselines.
Future<void> evidence(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('search-render')),
  );
  final bytes = (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  expect(bytes.length, greaterThan(0));
  const directory = String.fromEnvironment('SEARCH_EVIDENCE_DIR');
  if (directory.isNotEmpty) {
    await tester.runAsync(() async {
      await Directory(directory).create(recursive: true);
      await File('$directory/${name}_${Platform.operatingSystem}.png')
          .writeAsBytes(bytes);
    });
  }
}

class _Directory extends MockChatDirectory
    implements SearchSuggestionsDirectory {
  SearchSuggestions _state = const SearchSuggestions();
  @override
  SearchSuggestions get searchSuggestions => _state;
  final _listeners = <VoidCallback>[];
  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);
  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void notifyListeners() {
    for (final listener in [..._listeners]) {
      listener();
    }
  }

  void dispose() => _listeners.clear();
  int loads = 0, clears = 0;
  final removed = <int>[], recorded = <int>[];
  bool failLoad = false,
      failMutation = false,
      failSearch = false,
      empty = false;
  Completer<void>? pendingLoad, pendingMutation;
  Completer<List<ChatSummary>>? slowSearch;

  @override
  Future<void> loadSearchSuggestions() async {
    loads++;
    _state = SearchSuggestions(
      recent: _state.recent,
      top: _state.top,
      loading: true,
    );
    notifyListeners();
    await pendingLoad?.future;
    _state = SearchSuggestions(
      recent: failLoad
          ? _state.recent
          : empty
          ? []
          : [const ChatSummary(id: 2, title: 'Recent Bea')],
      top: failLoad
          ? _state.top
          : empty
          ? []
          : [const ChatSummary(id: 1, title: 'Top Ada')],
      loadFailed: failLoad,
    );
    notifyListeners();
  }

  @override
  Future<void> rememberSearchChat(int id) async {
    recorded.add(id);
  }

  @override
  Future<void> removeRecentSearch(int id) async {
    removed.add(id);
    await _mutate(() => _state.recent.where((c) => c.id != id).toList());
  }

  @override
  Future<void> clearRecentSearches() async {
    clears++;
    await _mutate(() => []);
  }

  Future<void> _mutate(List<ChatSummary> Function() update) async {
    _state = SearchSuggestions(
      recent: _state.recent,
      top: _state.top,
      mutating: true,
    );
    notifyListeners();
    await pendingMutation?.future;
    _state = SearchSuggestions(
      recent: failMutation ? _state.recent : update(),
      top: _state.top,
      actionFailed: failMutation,
    );
    notifyListeners();
  }

  @override
  Future<List<ChatSummary>> searchChats(String query, {int limit = 8}) async {
    if (query == 'slow' && slowSearch != null) return slowSearch!.future;
    if (failSearch) throw StateError('offline');
    return [ChatSummary(id: 7, title: 'Found $query')];
  }

  @override
  Future<List<MessageHit>> searchMessages(
    String query, {
    int limit = 8,
  }) async => [
    const MessageHit(
      chatId: 7,
      messageId: 70,
      text: 'A message',
      chatTitle: 'Found chat',
    ),
  ];
}
