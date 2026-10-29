import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram_media_editor/src/ui/controls.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: buildMgTheme(MgColors.light),
    home: Material(type: MaterialType.transparency, child: child),
  );

  testWidgets('EditorChip is focusable, activates once and says so', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      host(
        Row(
          children: [
            EditorChip(label: '1:1', selected: true, onPressed: () => taps++),
            EditorChip(label: '16:9', selected: false, onPressed: () {}),
          ],
        ),
      ),
    );
    final chip = tester.getSemantics(find.byType(MgPressable).first);
    expect(chip.flagsCollection.isSelected, Tristate.isTrue);
    expect(chip.label, '1:1');
    expect(chip.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 2);
    await tester.tap(find.text('1:1'));
    expect(taps, 3);
    handle.dispose();
  });

  testWidgets('a toggle chip says on/off; a null onPressed disables it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Row(
          children: [
            EditorChip(
              label: 'Fill',
              selected: false,
              toggle: true,
              onPressed: () {},
            ),
            const EditorChip(
              label: 'Off',
              selected: false,
              toggle: true,
              onPressed: null,
            ),
          ],
        ),
      ),
    );
    final fill = tester.getSemantics(find.byType(MgPressable).first);
    expect(fill.flagsCollection.isToggled, Tristate.isFalse);
    expect(fill.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    final off = tester.getSemantics(find.byType(MgPressable).last);
    expect(off.flagsCollection.isEnabled, Tristate.isFalse);
    expect(off.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    // One Tab skips the disabled chip's slot: only the first is a stop.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('Off'))).hasPrimaryFocus, isFalse);
    handle.dispose();
  });
}
