import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram_shell/mollygram_shell.dart';

void main() {
  late WorkspaceController controller;
  final directory = MockChatDirectory();

  setUp(() => controller = WorkspaceController());
  tearDown(() => controller.dispose());

  Widget app({double scale = 1}) {
    return WidgetsApp(
      color: const Color(0xFF0071E3),
      debugShowCheckedModeBanner: false,
      builder: (context, _) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 13, color: Color(0xFF000000)),
          child: WorkspaceShell(
            controller: controller,
            directory: directory,
            strings: ShellStrings.en,
            commands: const [],
            sidebarWidth: 320,
            sidebar: const SizedBox.expand(),
            paneBuilder: (context, chat, focused) => const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  Future<void> setUp1(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(scale: scale));
    controller
      ..open(1)
      ..open(2, target: OpenTarget.newTab);
    await tester.pump();
  }

  Future<void> openPalette(WidgetTester tester) async {
    final mod = usesCommandKey
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(mod);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(mod);
    await tester.pump();
    await tester.pump();
    expect(find.byType(CommandPalette), findsOneWidget);
  }

  void focusOf(WidgetTester tester, Finder f) {
    Focus.of(tester.element(f)).requestFocus();
  }

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets('${key.debugName} on a focused tab selects it', (tester) async {
      await setUp1(tester);
      expect(controller.value.active, 1);
      focusOf(tester, find.text('Anna Morris'));
      await tester.pump();
      await tester.sendKeyEvent(key);
      await tester.pump();
      expect(controller.value.active, 0);
    });

    testWidgets('${key.debugName} on a focused palette row opens it', (
      tester,
    ) async {
      await setUp1(tester);
      await openPalette(tester);
      focusOf(
        tester,
        find
            .descendant(
              of: find.byType(CommandPalette),
              matching: find.textContaining('Anna Morris', findRichText: true),
            )
            .first,
      );
      await tester.pump();
      await tester.sendKeyEvent(key);
      await tester.pump();
      expect(find.byType(CommandPalette), findsNothing);
      expect(controller.value.focusedChat, 1);
    });
  }

  testWidgets('tabs and the selected palette row expose selected', (
    tester,
  ) async {
    await setUp1(tester);
    final tabs = find.descendant(
      of: find.byType(TabStrip),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.selected != null,
      ),
    );
    expect(
      [
        for (final w in tester.widgetList<Semantics>(tabs))
          w.properties.selected,
      ],
      [false, true],
    );

    await openPalette(tester);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.selected == true &&
            w.properties.label == 'Anna Morris',
      ),
      findsOneWidget,
    );
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('tab strip and palette do not overflow at ${scale}x', (
      tester,
    ) async {
      await setUp1(tester, scale: scale);
      expect(tester.takeException(), isNull);
      await openPalette(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
