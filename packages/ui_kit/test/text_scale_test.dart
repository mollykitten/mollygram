import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

import 'harness.dart';

Widget _scaled(double scale, Widget child) => themed(
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: Center(child: SizedBox(width: 320, child: child)),
    ),
  ),
);

void main() {
  group('MgMetrics.scaled', () {
    testWidgets('never shrinks and grows with the text scale', (tester) async {
      final seen = <double>[];
      for (final scale in [0.8, 1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          _scaled(
            scale,
            Builder(
              builder: (context) {
                seen.add(MgMetrics.scaled(context, 30));
                return const SizedBox();
              },
            ),
          ),
        );
      }
      expect(seen.last, 60);
      expect(seen, containsAllInOrder([30, 30, 45, 60]));
    });
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    group('text scale $scale', () {
      testWidgets('MgTextButton keeps its label whole', (tester) async {
        await tester.pumpWidget(
          _scaled(scale, MgTextButton(label: 'Sign in', onPressed: () {})),
        );
        expect(tester.takeException(), isNull);
        final h = tester.getSize(find.byType(MgTextButton)).height;
        expect(h, greaterThanOrEqualTo(30));
        if (scale == 1.0) expect(h, 30);
        if (scale > 1) expect(h, greaterThanOrEqualTo(30 * scale));
      });

      testWidgets('MgSearchField does not overflow', (tester) async {
        await tester.pumpWidget(
          _scaled(scale, const MgSearchField(hintText: 'Search')),
        );
        expect(tester.takeException(), isNull);
        final h = tester.getSize(find.byType(MgSearchField)).height;
        expect(h, greaterThanOrEqualTo(30));
        if (scale == 1.0) expect(h, 30);
      });

      testWidgets('ChatListTile fits its computed extent', (tester) async {
        late double extent;
        await tester.pumpWidget(
          _scaled(
            scale,
            Builder(
              builder: (context) {
                extent = ChatListTile.extentOf(context);
                return SizedBox(
                  height: extent,
                  child: const ChatListTile(
                    title: 'Anna Petrova',
                    subtitle:
                        'see you tomorrow, long long long long text '
                        'that wraps onto the second line of the row',
                    time: '21:10',
                    unread: 3,
                  ),
                );
              },
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(extent, greaterThanOrEqualTo(ChatListTile.extent));
        if (scale == 1.0) expect(extent, ChatListTile.extent);
        if (scale > 1) expect(extent, greaterThan(ChatListTile.extent));
        expect(
          tester.getSize(find.byType(ChatListTile)).height,
          lessThanOrEqualTo(extent),
        );
      });
    });
  }
}
