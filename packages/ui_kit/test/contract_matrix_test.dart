import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

import 'harness.dart';

/// One test over every public interactive primitive at the text scales the
/// app supports: nothing overflows, a control is announced as enabled with a
/// tap action, and Tab then Space or Enter activates it once each.
/// Per-widget details live in interaction_contract_test.dart and
/// text_scale_test.dart; add new primitives to [_controls] here.
typedef _Control = ({
  String name,
  Widget Function(VoidCallback onTap) build,
  bool isButton,
});

final _controls = <_Control>[
  (
    name: 'MgPressable',
    build: (onTap) => MgPressable(
      onTap: onTap,
      semanticsLabel: 'press',
      builder: (_, _) => const SizedBox(width: 120, height: 40),
    ),
    isButton: true,
  ),
  (
    name: 'MgPrimaryButton',
    build: (onTap) => MgPrimaryButton(label: 'Continue', onPressed: onTap),
    isButton: true,
  ),
  (
    name: 'MgTextButton',
    build: (onTap) => MgTextButton(label: 'Back', onPressed: onTap),
    isButton: true,
  ),
  (
    name: 'MgIconButton',
    build: (onTap) =>
        MgIconButton(icon: MgIcons.close, tooltip: 'Close', onPressed: onTap),
    isButton: true,
  ),
  (
    name: 'MgSwitch',
    build: (onTap) =>
        MgSwitch(value: false, onChanged: (_) => onTap(), semanticLabel: 'On'),
    isButton: false,
  ),
  (
    name: 'MgStatusView.error action',
    build: (onTap) => MgStatusView.error(
      'Could not load',
      description: 'Check the connection and try again',
      actionLabel: 'Retry',
      onAction: onTap,
    ),
    isButton: true,
  ),
];

Widget _scaled(double scale, Widget child) => themed(
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: Center(child: SizedBox(width: 320, height: 480, child: child)),
    ),
  ),
);

void main() {
  testWidgets('interactive primitives hold the contract at 1.0, 1.5 and 2.0', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final control in _controls) {
        final where = '${control.name} at x$scale';
        var taps = 0;
        await tester.pumpWidget(_scaled(scale, control.build(() => taps++)));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: where);

        final target = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.onTap != null,
        );
        final data = tester.getSemantics(target.first).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: where);
        expect(data.flagsCollection.isEnabled, Tristate.isTrue, reason: where);
        if (control.isButton) {
          expect(data.flagsCollection.isButton, isTrue, reason: where);
        }

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(taps, 2, reason: '$where: Space and Enter fire once each');
      }

      await tester.pumpWidget(
        _scaled(scale, const MgSearchField(hintText: 'Search')),
      );
      expect(tester.takeException(), isNull, reason: 'MgSearchField x$scale');

      await tester.pumpWidget(
        _scaled(scale, const MgStatusView.empty('Nothing here')),
      );
      expect(tester.takeException(), isNull, reason: 'MgStatusView x$scale');
    }
    handle.dispose();
  });
}
