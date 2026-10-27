import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram/src/settings/settings_style.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: buildMgTheme(MgColors.light),
    home: Material(
      type: MaterialType.transparency,
      child: SizedBox(width: 400, child: child),
    ),
  );

  testWidgets('one node per row, with state, enabled and a tap', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final changes = <bool>[];
    await tester.pumpWidget(
      host(
        SettingsSwitchRow(title: 'Sounds', value: true, onChanged: changes.add),
      ),
    );
    final row = tester.getSemantics(find.byType(MgPressable));
    expect(row.label, contains('Sounds'));
    expect(row.flagsCollection.isToggled, Tristate.isTrue);
    expect(row.flagsCollection.isEnabled, Tristate.isTrue);
    expect(row.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(changes, [false]);
    await tester.tap(find.text('Sounds'));
    expect(changes, [false, false]);
    handle.dispose();
  });

  testWidgets('without onChanged it still tells on or off, disabled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const SettingsSwitchRow(title: 'Sounds', value: false, onChanged: null),
      ),
    );
    final row = tester.getSemantics(find.text('Sounds'));
    expect(row.flagsCollection.isToggled, Tristate.isFalse);
    expect(row.flagsCollection.isEnabled, Tristate.isFalse);
    expect(row.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });
}
