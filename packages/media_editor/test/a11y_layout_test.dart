import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mollygram_media_editor/mollygram_media_editor.dart';
import 'package:mollygram_media_editor/src/ui/draw_panel.dart';
import 'package:mollygram_media_editor/src/ui/overlay_panels.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

void main() {
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('media_editor_a11y');
    path = '${dir.path}/photo.png';
    File(path).writeAsBytesSync(
      img.encodePng(
        img.Image(width: 64, height: 32)..clear(img.ColorRgb8(200, 30, 30)),
      ),
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Widget host(Widget child, {double scale = 1}) => MaterialApp(
    theme: buildMgTheme(MgColors.light),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: app!,
    ),
    home: Material(type: MaterialType.transparency, child: child),
  );

  testWidgets('a swatch is a radio: Space and Enter pick it', (tester) async {
    final handle = tester.ensureSemantics();
    final picked = <Color>[];
    await tester.pumpWidget(
      host(
        Center(
          child: ColorSwatches(color: brushColors.first, onColor: picked.add),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(picked, [brushColors[1], brushColors[1]]);
    handle.dispose();
  });

  testWidgets('an emoji cell is focusable and named', (tester) async {
    final handle = tester.ensureSemantics();
    final picked = <String>[];
    await tester.pumpWidget(
      host(Center(child: EmojiGridPanel(onEmoji: picked.add))),
    );
    expect(find.bySemanticsLabel(editorEmoji.first), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(picked, [editorEmoji.first]);
    handle.dispose();
  });

  testWidgets('the slider is a slider with step values and arrow keys', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var value = 0.5;
    await tester.pumpWidget(
      host(
        Center(
          child: StatefulBuilder(
            builder: (context, set) => EditorSlider(
              value: value,
              color: Colors.red,
              label: 'Thickness',
              onChanged: (v) => set(() => value = v),
            ),
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('Thickness'));
    expect(node.value, '50%');
    expect(node.increasedValue, '60%');
    expect(node.decreasedValue, '40%');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(value, greaterThan(0.5));
    handle.dispose();
  });

  for (final scale in [1.5, 2.0]) {
    for (final tool in ['Crop', 'Draw', 'Shapes', 'Adjust', 'Text']) {
      testWidgets('no overflow at ${scale}x text, 480 px, $tool', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(480, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            supportedLocales: const [Locale('en'), Locale('ru')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: buildMgTheme(MgColors.light),
            builder: (context, app) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: app!,
            ),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => showMediaEditor(
                  context,
                  path: path,
                  outputDirectory: dir.path,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        for (var i = 0; i < 100; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
          final done = find.byType(MgPrimaryButton);
          if (done.evaluate().isNotEmpty &&
              tester.widget<MgPrimaryButton>(done).onPressed != null) {
            break;
          }
        }
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(tool), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
