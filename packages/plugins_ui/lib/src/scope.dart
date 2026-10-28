import 'package:flutter/material.dart' show Theme, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart'
    show MgColors, MgMetrics, MgType, buildMgTheme, mgTextStyle;

import 'colors.dart';

/// The one boundary between the app's theme and the plugins screen.
///
/// Everything the screen shows is built under it, and it hands down exactly:
///
///  * the color tokens ([MgColors]) and layout metrics ([MgMetrics]), as a
///    fresh theme built from them: nothing else of the app's [ThemeData]
///    (its other extensions, text theme, colors) reaches the screen;
///  * the media settings the screen follows: the text scale
///    (`textScaler`), reduced motion (`disableAnimations`) and the light or
///    dark mode (`platformBrightness`); the other [MediaQueryData] fields
///    pass through unchanged;
///  * the base text style, from `mgTextStyle`.
///
/// With [brightness] set the screen is light or dark on its own; without it
/// follows the tokens of the app theme above, and without one the platform
/// brightness.
class PluginsThemeScope extends StatelessWidget {
  const PluginsThemeScope({super.key, this.brightness, required this.child});

  final Brightness? brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    final ambient = Theme.of(context);
    final mg = switch (brightness) {
      Brightness.dark => MgColors.dark,
      Brightness.light => MgColors.light,
      null =>
        ambient.extension<MgColors>() ??
            (media.platformBrightness == Brightness.dark
                ? MgColors.dark
                : MgColors.light),
    };
    final metrics = ambient.extension<MgMetrics>() ?? MgMetrics.defaults;
    return Theme(
      data: buildMgTheme(mg, metrics: metrics),
      child: MediaQuery(
        data: media.copyWith(
          textScaler: media.textScaler,
          disableAnimations: media.disableAnimations,
          platformBrightness: mg.brightness,
        ),
        child: PluginsTheme(
          colors: PluginsColors.from(mg),
          child: DefaultTextStyle(
            style: mgTextStyle(
              mg,
              size: MgType.small,
            ).copyWith(decoration: TextDecoration.none),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The screen's text: the app's type tokens at [size] (13 by default) in the
/// screen's [PluginsColors.fg] unless [color] says otherwise.
TextStyle pluginsText(
  BuildContext context, {
  double size = MgType.small,
  FontWeight? weight,
  Color? color,
  double height = 1.4,
}) => mgTextStyle(
  MgColors.of(context),
  size: size,
  weight: weight,
  color: color ?? PluginsColors.of(context).fg,
  height: height,
);

/// [base] points, grown with the text scale: geometry tied to text.
double pluginsScaled(BuildContext context, double base) =>
    MgMetrics.scaled(context, base);
