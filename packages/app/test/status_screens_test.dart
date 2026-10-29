import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram/l10n/app_localizations.dart';
import 'package:mollygram/src/chat/contact_picker.dart';
import 'package:mollygram/src/contacts/providers.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

Future<void> _open(
  WidgetTester tester,
  Stream<List<ContactUser>> contacts,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [contactsProvider.overrideWith((ref) => contacts)],
      child: MaterialApp(
        theme: buildMgTheme(MgColors.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => unawaited(pickContact(context)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // The loading ring repeats forever, so the sheet can never "settle".
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('contact picker shows a loading view until contacts arrive', (
    tester,
  ) async {
    final controller = StreamController<List<ContactUser>>();
    addTearDown(controller.close);
    await _open(tester, controller.stream);
    expect(find.byType(MgSearchField), findsOneWidget);
    expect(find.byType(MgStatusView), findsOneWidget);
    expect(find.byType(MgSpinner), findsOneWidget);
    expect(find.text('Nothing found'), findsNothing);
  });

  testWidgets('contact picker says nothing was found on an empty list', (
    tester,
  ) async {
    await _open(tester, Stream.value(const <ContactUser>[]));
    expect(find.byType(MgStatusView), findsOneWidget);
    expect(find.byType(MgSpinner), findsNothing);
    expect(find.text('Nothing found'), findsOneWidget);
  });
}
