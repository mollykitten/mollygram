import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

import 'harness.dart';

Widget _scaled(double scale, Widget child) => themed(
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: Center(child: SizedBox(width: 240, height: 320, child: child)),
    ),
  ),
);

void main() {
  testWidgets('empty shows icon, title and description; not a live region', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      themed(
        const MgStatusView.empty(
          'Nothing found',
          description: 'Try another word',
          icon: MgIcons.chat,
        ),
      ),
    );
    expect(find.text('Nothing found'), findsOneWidget);
    expect(find.text('Try another word'), findsOneWidget);
    expect(find.byType(MgIcon), findsOneWidget);
    expect(find.byType(MgSpinner), findsNothing);
    expect(
      tester.getSemantics(find.text('Nothing found')),
      isNot(matchesSemantics(isLiveRegion: true)),
    );
    handle.dispose();
  });

  testWidgets('loading shows a spinner and is a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      themed(const MgStatusView.loading(title: 'Loading')),
    );
    expect(find.byType(MgSpinner), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    final live = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.liveRegion == true,
    );
    expect(live, findsOneWidget);
    handle.dispose();
  });

  testWidgets('error is a live region and its action fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      themed(
        MgStatusView.error(
          'Failed',
          actionLabel: 'Try again',
          onAction: () => taps++,
        ),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    expect(taps, 1);
  });

  testWidgets('a delayed spinner stays hidden, then fades in', (tester) async {
    await tester.pumpWidget(
      themed(const MgStatusView.loading(delay: Duration(milliseconds: 300))),
    );
    double opacity() =>
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
    expect(opacity(), 0);
    await tester.pump(const Duration(milliseconds: 301));
    expect(opacity(), 1);
  });

  testWidgets('reduced motion draws a still ring', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: themed(const MgSpinner()),
      ),
    );
    final ring = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(ring.value, isNotNull);
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('all variants fit at text scale $scale', (tester) async {
      for (final view in <Widget>[
        const MgStatusView.loading(title: 'Loading the list for you'),
        const MgStatusView.empty(
          'Nothing found here at all',
          description: 'Try a shorter or different word',
          icon: MgIcons.chat,
        ),
        MgStatusView.error(
          'Could not load the list',
          description: 'Check the connection',
          actionLabel: 'Try again',
          onAction: () {},
        ),
      ]) {
        await tester.pumpWidget(_scaled(scale, view));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
