import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram_plugins_ui/mollygram_plugins_ui.dart';

import 'screen_test.dart' show pumpScreen;

class _Secret extends ThemeExtension<_Secret> {
  const _Secret();
  @override
  _Secret copyWith() => this;
  @override
  _Secret lerp(_Secret? other, double t) => this;
}

Widget _host({
  required Widget child,
  Brightness? brightness,
  TextScaler scaler = TextScaler.noScaling,
  bool still = false,
  ThemeData? theme,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(
      size: const Size(1440, 900),
      textScaler: scaler,
      disableAnimations: still,
    ),
    child: Theme(
      data: theme ?? ThemeData(),
      child: PluginsThemeScope(brightness: brightness, child: child),
    ),
  ),
);

void main() {
  testWidgets('light and dark give different colors', (tester) async {
    late PluginsColors light;
    late PluginsColors dark;
    Widget probe(void Function(PluginsColors) set) => Builder(
      builder: (context) {
        set(PluginsColors.of(context));
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      _host(brightness: Brightness.light, child: probe((c) => light = c)),
    );
    await tester.pumpWidget(
      _host(brightness: Brightness.dark, child: probe((c) => dark = c)),
    );
    expect(light.dark, isFalse);
    expect(dark.dark, isTrue);
    for (final pair in [
      (light.pane, dark.pane),
      (light.surface, dark.surface),
      (light.fg, dark.fg),
      (light.off, dark.off),
      (light.code, dark.code),
    ]) {
      expect(pair.$1, isNot(pair.$2));
    }
  });

  testWidgets('the mode reaches the media query and the theme', (tester) async {
    late Brightness media;
    late Brightness theme;
    await tester.pumpWidget(
      _host(
        brightness: Brightness.dark,
        child: Builder(
          builder: (context) {
            media = MediaQuery.platformBrightnessOf(context);
            theme = Theme.of(context).brightness;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(media, Brightness.dark);
    expect(theme, Brightness.dark);
  });

  testWidgets('text scale and reduced motion reach the subtree', (
    tester,
  ) async {
    late TextScaler scaler;
    late bool still;
    await tester.pumpWidget(
      _host(
        scaler: const TextScaler.linear(1.5),
        still: true,
        child: Builder(
          builder: (context) {
            scaler = MediaQuery.textScalerOf(context);
            still = MediaQuery.disableAnimationsOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(scaler.scale(10), 15);
    expect(still, isTrue);
  });

  testWidgets('nothing of the app theme but the tokens is visible', (
    tester,
  ) async {
    ThemeData? inside;
    await tester.pumpWidget(
      _host(
        theme: ThemeData(
          extensions: const [_Secret()],
          scaffoldBackgroundColor: const Color(0xFF123456),
        ),
        child: Builder(
          builder: (context) {
            inside = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(inside!.extension<_Secret>(), isNull);
    expect(inside!.scaffoldBackgroundColor, isNot(const Color(0xFF123456)));
  });

  testWidgets('the screen follows the text scale without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final builtins = await tester.runAsync(loadBuiltinPlugins);
    final controller = PluginsController([
      for (final b in builtins!) b.entry,
      ...mockPlugins(now: DateTime.now()),
    ], selected: 'io.graphy.stats');
    controller.requestInstall('io.graphy.stats');
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(1440, 900),
              textScaler: TextScaler.linear(1.5),
            ),
            child: PluginsScreen(
              controller: controller,
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        MediaQuery.textScalerOf(tester.element(find.text('Search').first))
            .scale(10),
        15,
      );
    }
  });

  testWidgets('screen colors differ between light and dark', (tester) async {
    final colors = <bool, Color>{};
    for (final dark in [false, true]) {
      await pumpScreen(
        tester,
        brightness: dark ? Brightness.dark : Brightness.light,
        selected: 'io.graphy.stats',
      );
      colors[dark] = PluginsColors.of(
        tester.element(find.byType(Overlay).first),
      ).pane;
    }
    expect(colors[false], isNot(colors[true]));
  });
}
