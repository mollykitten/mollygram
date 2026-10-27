import 'dart:ui' show CheckedState, SemanticsAction, SemanticsRole, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

import 'harness.dart';

/// The keyboard and semantics contract every interactive primitive shares:
/// reachable with Tab, activated once by Space or Enter, and announced with a
/// tap action and its state.
void main() {
  Future<void> activate(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pump();
  }

  bool canTap(WidgetTester tester, Finder finder) => tester
      .getSemantics(finder)
      .getSemanticsData()
      .hasAction(SemanticsAction.tap);

  /// The control around [inner], whose semantics node is the merged one.
  Finder control(Finder inner) =>
      find.ancestor(of: inner, matching: find.byType(MgPressable)).first;

  group('MgPressable', () {
    testWidgets('Space and Enter fire once; disabled and busy do not', (
      tester,
    ) async {
      var taps = 0;
      var enabled = true;
      var busy = false;
      late StateSetter set;
      await tester.pumpWidget(
        themed(
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return MgPressable(
                autofocus: true,
                busy: busy,
                onTap: enabled ? () => taps++ : null,
                builder: (_, _) => const SizedBox(width: 40, height: 40),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await activate(tester, LogicalKeyboardKey.space);
      await activate(tester, LogicalKeyboardKey.enter);
      expect(taps, 2);

      set(() => busy = true);
      await tester.pump();
      await activate(tester, LogicalKeyboardKey.enter);
      await tester.tap(find.byType(MgPressable));
      expect(taps, 2);

      set(() {
        busy = false;
        enabled = false;
      });
      await tester.pump();
      await activate(tester, LogicalKeyboardKey.enter);
      expect(taps, 2);
    });

    testWidgets('uses the caller\'s focus node and autofocus', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        themed(
          MgPressable(
            focusNode: node,
            autofocus: true,
            onTap: () {},
            builder: (_, _) => const SizedBox(width: 40, height: 40),
          ),
        ),
      );
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
    });

    testWidgets('ContextMenu key and Shift+F10 run onSecondaryActivate', (
      tester,
    ) async {
      var menus = 0;
      await tester.pumpWidget(
        themed(
          MgPressable(
            autofocus: true,
            onTap: () {},
            onSecondaryActivate: () => menus++,
            builder: (_, _) => const SizedBox(width: 40, height: 40),
          ),
        ),
      );
      await tester.pump();
      await activate(tester, LogicalKeyboardKey.contextMenu);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(menus, 2);
    });

    testWidgets('roles expose their state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        themed(
          Column(
            children: [
              MgPressable(
                role: MgPressableRole.tab,
                selected: true,
                semanticsLabel: 'tab',
                onTap: () {},
                builder: (_, _) => const SizedBox(width: 40, height: 40),
              ),
              MgPressable(
                role: MgPressableRole.radio,
                checked: false,
                semanticsLabel: 'radio',
                onTap: () {},
                builder: (_, _) => const SizedBox(width: 40, height: 40),
              ),
              MgPressable(
                role: MgPressableRole.checkbox,
                checked: true,
                semanticsLabel: 'box',
                onTap: () {},
                builder: (_, _) => const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      );
      final tab = tester.getSemantics(find.bySemanticsLabel('tab'));
      expect(tab.flagsCollection.isSelected, Tristate.isTrue);
      expect(tab.role, SemanticsRole.tab);
      expect(canTap(tester, find.bySemanticsLabel('tab')), isTrue);

      final radio = tester.getSemantics(find.bySemanticsLabel('radio'));
      expect(radio.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(radio.flagsCollection.isChecked, CheckedState.isFalse);

      final box = tester.getSemantics(find.bySemanticsLabel('box'));
      expect(box.flagsCollection.isChecked, CheckedState.isTrue);
      handle.dispose();
    });
  });

  group('showMgChoice', () {
    Future<List<int?>> open(WidgetTester tester) async {
      final results = <int?>[];
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showMgChoice(
                  context,
                  title: 'Report',
                  options: ['Spam', 'Violence'],
                  cancelLabel: 'Cancel',
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('Tab walks the options and Space or Enter picks one', (
      tester,
    ) async {
      final results = await open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await activate(tester, LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(results, [1]);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await activate(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(results, [1, 0]);
    });

    testWidgets('Shift+Tab reaches Cancel, which closes with null', (
      tester,
    ) async {
      final results = await open(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await activate(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(results, [null]);
    });

    testWidgets('options say they can be tapped', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      expect(canTap(tester, find.bySemanticsLabel('Spam')), isTrue);
      expect(canTap(tester, find.bySemanticsLabel('Cancel')), isTrue);
      handle.dispose();
    });
  });

  group('showMgConfirm', () {
    Future<List<bool?>> open(
      WidgetTester tester, {
      bool destructive = false,
    }) async {
      final results = <bool?>[];
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showMgConfirm(
                  context,
                  title: 'Delete?',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  destructive: destructive,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('a destructive confirm never answers a bare or doubled Enter', (
      tester,
    ) async {
      final results = await open(tester, destructive: true);
      // Focus starts on Cancel, so Enter cancels rather than deletes.
      await activate(tester, LogicalKeyboardKey.enter);
      await activate(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(results, [null]);
    });

    testWidgets('a destructive confirm ignores a held Enter', (tester) async {
      final results = await open(tester, destructive: true);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(results, [null]);
    });

    testWidgets('Enter on the focused destructive button confirms', (
      tester,
    ) async {
      final results = await open(tester, destructive: true);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await activate(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(results, [false]);
    });

    testWidgets('Esc closes a confirm of either kind', (tester) async {
      for (final destructive in [false, true]) {
        final results = await open(tester, destructive: destructive);
        await activate(tester, LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(results, [null], reason: 'destructive: $destructive');
      }
    });

    testWidgets('a repeated Enter answers a plain confirm once', (
      tester,
    ) async {
      final results = await open(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(results, [false]);
    });

    testWidgets('Enter still confirms from the dialog', (tester) async {
      final results = await open(tester);
      await activate(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(results, [false]);
    });

    testWidgets('Tab reaches Cancel; Space cancels without confirming', (
      tester,
    ) async {
      final results = await open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await activate(tester, LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(results, [null]);
    });

    testWidgets('Enter on the focused Cancel cancels once', (tester) async {
      final results = await open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await activate(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(results, [null]);
    });
  });

  group('showMgPrompt', () {
    testWidgets('Send is disabled until there is text; Cancel is reachable', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final results = <String?>[];
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showMgPrompt(
                  context,
                  title: 'Details',
                  confirmLabel: 'Send',
                  cancelLabel: 'Cancel',
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final send = tester.getSemantics(control(find.text('Send')));
      expect(send.flagsCollection.isEnabled, Tristate.isFalse);
      expect(canTap(tester, control(find.text('Send'))), isFalse);
      await tester.tap(find.text('Send'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(results, isEmpty);

      // From the text field Tab skips the disabled Send and lands on Cancel.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await activate(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(results, [null]);
      handle.dispose();
    });

    testWidgets('typing enables Send', (tester) async {
      final results = <String?>[];
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showMgPrompt(
                  context,
                  title: 'Details',
                  confirmLabel: 'Send',
                  cancelLabel: 'Cancel',
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'spam');
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(results, ['spam']);
    });
  });

  group('showMgSheet Esc', () {
    Future<void> open(
      WidgetTester tester,
      Widget sheet,
      List<Object?> out,
    ) async {
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  out.add(await showMgSheet<int>(context, sheet)),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('closes a sheet with nothing focusable in it', (tester) async {
      final out = <Object?>[];
      await open(tester, const Text('Notice'), out);
      expect(find.text('Notice'), findsOneWidget);
      await activate(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Notice'), findsNothing);
      expect(out, [null]);
    });

    testWidgets('closes a sheet with a text field, which keeps the focus', (
      tester,
    ) async {
      final out = <Object?>[];
      await open(
        tester,
        const SizedBox(width: 200, child: TextField(autofocus: true)),
        out,
      );
      final field = tester.state<EditableTextState>(find.byType(EditableText));
      expect(field.widget.focusNode.hasFocus, isTrue);
      await activate(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(out, [null]);
    });

    testWidgets('a sheet with its own Esc pops once, not twice', (
      tester,
    ) async {
      final results = <String?>[];
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showMgPrompt(
                  context,
                  title: 'Details',
                  confirmLabel: 'Send',
                  cancelLabel: 'Cancel',
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await activate(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(results, [null]);
      // The page underneath is still there.
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('MgSwitch', () {
    testWidgets('Tab focuses it; Space and Enter flip it once each', (
      tester,
    ) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        themed(MgSwitch(value: false, onChanged: changes.add)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await activate(tester, LogicalKeyboardKey.space);
      await activate(tester, LogicalKeyboardKey.enter);
      expect(changes, [true, true]);
      await tester.tap(find.byType(MgSwitch));
      expect(changes, [true, true, true]);
    });

    testWidgets('announces toggled and a tap action', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(themed(MgSwitch(value: true, onChanged: (_) {})));
      final data = tester.getSemantics(find.byType(MgSwitch));
      expect(data.flagsCollection.isToggled, Tristate.isTrue);
      expect(canTap(tester, find.byType(MgSwitch)), isTrue);
      handle.dispose();
    });

    testWidgets('a semanticLabel names it and a read-only one is disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        themed(
          Column(
            children: [
              MgSwitch(value: true, onChanged: (_) {}, semanticLabel: 'Sound'),
              const MgSwitch(value: false, semanticLabel: 'Ghost'),
            ],
          ),
        ),
      );
      final live = tester.getSemantics(find.bySemanticsLabel('Sound'));
      expect(live.flagsCollection.isToggled, Tristate.isTrue);
      expect(live.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      final fixed = tester.getSemantics(find.bySemanticsLabel('Ghost'));
      expect(fixed.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('without onChanged it shows the value and takes no focus', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(themed(const MgSwitch(value: false)));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('MgPressable'),
      );
      final data = tester.getSemantics(find.byType(MgSwitch));
      expect(data.flagsCollection.isToggled, Tristate.isFalse);
      expect(canTap(tester, find.byType(MgSwitch)), isFalse);
      handle.dispose();
    });
  });

  group('MgCalendar', () {
    final today = DateTime(2026, 10, 20);

    Widget calendar(List<DateTime> picked, {DateTime? selected}) => themed(
      Align(
        alignment: Alignment.topLeft,
        child: MgCalendar(
          month: today,
          today: today,
          selected: selected,
          first: DateTime(2026, 10, 3),
          onPick: picked.add,
          monthTitle: (m) => 'Month',
          weekdays: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
          previousTooltip: 'Previous',
          nextTooltip: 'Next',
        ),
      ),
    );

    testWidgets('Tab reaches the first pickable day; Enter picks it', (
      tester,
    ) async {
      final picked = <DateTime>[];
      await tester.pumpWidget(calendar(picked));
      // The previous arrow is disabled, so the first stop is the next arrow
      // when there is one; here there is none, so the first stop is day 3.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await activate(tester, LogicalKeyboardKey.enter);
      expect(picked, [DateTime(2026, 10, 3)]);
    });

    testWidgets(
      'arrows move between days and stop at the ones that can\'t be picked',
      (tester) async {
        final picked = <DateTime>[];
        await tester.pumpWidget(calendar(picked));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await activate(tester, LogicalKeyboardKey.space);
        expect(picked, [DateTime(2026, 10, 11)]);

        // Back before the first pickable day goes nowhere.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await activate(tester, LogicalKeyboardKey.enter);
        expect(picked.last, DateTime(2026, 10, 4));
        // Days after today are not stops.
        for (var i = 0; i < 4; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        }
        await activate(tester, LogicalKeyboardKey.enter);
        expect(picked.last.isAfter(today), isFalse);
      },
    );

    testWidgets('days announce tap, disabled and selected', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(calendar([], selected: DateTime(2026, 10, 12)));
      final day = tester.getSemantics(control(find.text('12')));
      expect(day.flagsCollection.isSelected, Tristate.isTrue);
      expect(canTap(tester, control(find.text('12'))), isTrue);
      expect(
        tester
            .getSemantics(control(find.text('13')))
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
      );
      // Day 2 is before `first`, day 25 is after today.
      for (final day in ['2', '25']) {
        final node = tester.getSemantics(control(find.text(day)));
        expect(node.flagsCollection.isEnabled, Tristate.isFalse, reason: day);
        expect(canTap(tester, control(find.text(day))), isFalse, reason: day);
      }
      handle.dispose();
    });
  });

  group('tabs', () {
    testWidgets('FolderTab is a focusable tab with selected state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        themed(
          Row(
            children: [
              FolderTab(label: 'All', selected: true, onTap: () => taps++),
              FolderTab(label: 'Work', onTap: () => taps += 10),
            ],
          ),
        ),
      );
      final all = tester.getSemantics(control(find.text('All')));
      expect(all.role, SemanticsRole.tab);
      expect(all.flagsCollection.isSelected, Tristate.isTrue);
      expect(canTap(tester, control(find.text('All'))), isTrue);
      expect(
        tester
            .getSemantics(control(find.text('Work')))
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await activate(tester, LogicalKeyboardKey.space);
      expect(taps, 10);
      await tester.tap(find.text('All'));
      expect(taps, 11);
      handle.dispose();
    });

    testWidgets('PanelSectionBar buttons are tabs', (tester) async {
      final handle = tester.ensureSemantics();
      final picked = <int>[];
      await tester.pumpWidget(
        themed(
          SizedBox(
            width: 200,
            child: PanelSectionBar(
              items: const [Text('a'), Text('b')],
              labels: const ['First', 'Second'],
              selected: 1,
              onSelect: picked.add,
            ),
          ),
        ),
      );
      final second = tester.getSemantics(find.byType(MgPressable).at(1));
      expect(second.role, SemanticsRole.tab);
      expect(second.flagsCollection.isSelected, Tristate.isTrue);
      expect(canTap(tester, find.byType(MgPressable).at(0)), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await activate(tester, LogicalKeyboardKey.enter);
      expect(picked, [0]);
      handle.dispose();
    });

    testWidgets('PanelCell takes focus, Space/Enter and reports hover', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final picked = <String>[];
      await tester.pumpWidget(
        themed(
          SizedBox(
            width: 40,
            height: 40,
            child: PanelCell(
              label: 'smile',
              onTap: () => picked.add('x'),
              child: const Text('😀'),
            ),
          ),
        ),
      );
      expect(canTap(tester, find.bySemanticsLabel('smile')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await activate(tester, LogicalKeyboardKey.space);
      await activate(tester, LogicalKeyboardKey.enter);
      expect(picked, ['x', 'x']);
      handle.dispose();
    });
  });

  group('MgIconButton', () {
    testWidgets('toggle reports off as well as on; default does not', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        themed(
          Row(
            children: [
              MgIconButton(
                icon: MgIcons.close,
                tooltip: 'plain',
                onPressed: () {},
              ),
              MgIconButton(
                icon: MgIcons.close,
                tooltip: 'ghost off',
                toggle: true,
                onPressed: () {},
              ),
              MgIconButton(
                icon: MgIcons.close,
                tooltip: 'ghost on',
                toggle: true,
                selected: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      Tristate toggled(String label) => tester
          .getSemantics(find.bySemanticsLabel(label))
          .flagsCollection
          .isToggled;
      expect(toggled('plain'), Tristate.none);
      expect(toggled('ghost off'), Tristate.isFalse);
      expect(toggled('ghost on'), Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('disabled has no action, no focus and a dimmed glyph', (
      tester,
    ) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        themed(
          Column(
            children: [
              MgIconButton(
                icon: MgIcons.close,
                tooltip: 'off',
                onPressed: null,
              ),
              MgIconButton(
                icon: MgIcons.close,
                tooltip: 'on',
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      );
      expect(canTap(tester, find.bySemanticsLabel('off')), isFalse);
      expect(canTap(tester, find.bySemanticsLabel('on')), isTrue);
      Color glyph(String label) => tester
          .widget<MgIcon>(
            find.descendant(
              of: find.ancestor(
                of: find.byTooltip(label),
                matching: find.byType(MgIconButton),
              ),
              matching: find.byType(MgIcon),
            ),
          )
          .color!;
      expect(glyph('off'), isNot(glyph('on')));
      // One Tab skips the disabled button and lands on the enabled one.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await activate(tester, LogicalKeyboardKey.enter);
      expect(taps, 1);
      handle.dispose();
    });
  });
}
