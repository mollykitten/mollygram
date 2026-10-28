import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram/src/auth/country_picker.dart';
import 'package:mollygram/src/chat/bot_keyboard.dart';
import 'package:mollygram/src/chat/segmented_tabs.dart';
import 'package:mollygram/src/profile/manage_sheet.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

Widget _host(Widget child, {double scale = 1}) => MaterialApp(
  theme: buildMgTheme(MgColors.light),
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: app!,
  ),
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);

Future<void> _activate(
  WidgetTester tester,
  Finder target,
  LogicalKeyboardKey key,
) async {
  // Tab until the control under test holds focus, then press the key.
  for (var i = 0; i < 12; i++) {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused != null &&
        (find
                .descendant(
                  of: target,
                  matching: find.byWidgetPredicate((w) => true),
                )
                .evaluate()
                .any((e) => e == focused) ||
            focused.findAncestorWidgetOfExactType<MgPressable>() ==
                tester.widget(
                  find
                      .ancestor(of: target, matching: find.byType(MgPressable))
                      .first,
                ))) {
      break;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  const countries = [
    PhoneCountry(code: 'RU', name: 'Russia', callingCodes: ['7']),
    PhoneCountry(code: 'DE', name: 'Germany', callingCodes: ['49']),
  ];

  testWidgets('SegmentedTabs: Enter and Space select, semantics are tabs', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var selected = 'a';
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, set) => SegmentedTabs<String>(
            selected: selected,
            labels: const {'a': 'Media', 'b': 'Files'},
            onSelect: (v) => set(() => selected = v),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Media')),
      matchesSemantics(
        label: 'Media',
        role: SemanticsRole.tab,
        isSelected: true,
        isEnabled: true,
        hasEnabledState: true,
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    await _activate(tester, find.text('Files'), LogicalKeyboardKey.enter);
    expect(selected, 'b');
    await _activate(tester, find.text('Media'), LogicalKeyboardKey.space);
    expect(selected, 'a');
    handle.dispose();
  });

  testWidgets(
    'CountryPicker: Enter picks the focused row, no overflow at 1.5x',
    (tester) async {
      PhoneCountry? picked;
      await tester.pumpWidget(
        _host(
          CountryPicker(
            countries: countries,
            searchHint: 'Search',
            emptyText: 'none',
            onSelected: (c) => picked = c,
          ),
          scale: 1.5,
        ),
      );
      expect(tester.takeException(), isNull);
      await _activate(tester, find.text('Germany'), LogicalKeyboardKey.enter);
      expect(picked?.code, 'DE');
    },
  );

  testWidgets('BotMenuPill: Space activates, labelled as a button, scales', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _host(BotMenuPill(label: 'Menu', onPressed: () => taps++), scale: 1.5),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSemantics(find.text('Menu')),
      matchesSemantics(
        label: 'Menu',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    await _activate(tester, find.text('Menu'), LogicalKeyboardKey.space);
    expect(taps, 1);
    expect(
      tester.getSize(find.byType(BotMenuPill)).height,
      greaterThanOrEqualTo(
        MgMetrics.scaled(tester.element(find.byType(BotMenuPill)), 30),
      ),
    );
    handle.dispose();
  });

  testWidgets('PersonRow: Enter opens, long text does not overflow at 1.5x', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        PersonRow(
          name: 'A person with a rather long name indeed',
          avatar: const SizedBox(width: 36, height: 36),
          subtitle: 'last seen recently',
          onTap: () => taps++,
        ),
        scale: 1.5,
      ),
    );
    expect(tester.takeException(), isNull);
    await _activate(
      tester,
      find.textContaining('A person'),
      LogicalKeyboardKey.enter,
    );
    expect(taps, 1);
  });
}
