import 'package:flutter/widgets.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart' show MgColors;

/// The colors of the plugins screen, derived from the app's [MgColors].
///
/// Only the screen's own tokens (the pane, the off switch, the code block)
/// are defined here; everything shared comes from [MgColors], so the screen
/// follows the app theme. Read them with [PluginsColors.of].
@immutable
class PluginsColors {
  const PluginsColors._({
    required this.dark,
    required this.pane,
    required this.surface,
    required this.fg,
    required this.fg2,
    required this.sep,
    required this.accent,
    required this.onAccent,
    required this.onAccentSecondary,
    required this.hover,
    required this.field,
    required this.off,
    required this.code,
    required this.glass,
    required this.rim,
    required this.hi,
    required this.glow,
    required this.shadow,
    required this.wallBase,
    required this.wall,
  });

  /// The screen's colors for [mg].
  factory PluginsColors.from(MgColors mg) {
    final dark = mg.isDark;
    return PluginsColors._(
      dark: dark,
      pane: dark ? mg.windowBackground : _paneLight,
      surface: mg.bubbleIn,
      fg: mg.fg,
      fg2: mg.fg2,
      sep: mg.separator,
      accent: mg.accent,
      onAccent: mg.onAccent,
      onAccentSecondary: mg.onAccentSecondary,
      hover: mg.hover,
      field: mg.field,
      off: dark ? _offDark : _offLight,
      code: dark ? _codeDark : _codeLight,
      glass: mg.glass,
      rim: mg.rim,
      hi: mg.highlight,
      glow: mg.glow,
      shadow: mg.shadow,
      wallBase: mg.wallpaperBase,
      wall: mg.wallpaper,
    );
  }

  // The tokens MgColors has no counterpart for.
  static const _paneLight = Color(0xFFF5F5F7);
  static const _offLight = Color(0xFFD9D9DE);
  static const _offDark = Color(0xFF48484C);
  static const _codeLight = Color(0xFFF0F0F3);
  static const _codeDark = Color(0xFF232326);

  final bool dark;
  final Color pane;
  final Color surface;
  final Color fg;
  final Color fg2;
  final Color sep;
  final Color accent;

  /// Text and glyphs on top of [accent].
  final Color onAccent;
  final Color onAccentSecondary;
  final Color hover;
  final Color field;

  /// A switch that is off.
  final Color off;
  final Color code;
  final Color glass;
  final Color rim;
  final Color hi;
  final Color glow;
  final Color shadow;
  final Color wallBase;

  /// The four points of the Telegram gradient wallpaper, in mockup order.
  final List<Color> wall;

  static const danger = Color(0xFFE5484D);
  static const warning = Color(0xFFFF9F0A);

  /// Behind a sheet over the screen.
  static const scrim = Color(0x14000000);

  static final _fallback = PluginsColors.from(MgColors.light);

  /// The colors of the nearest [PluginsThemeScope]; the light ones without
  /// one.
  static PluginsColors of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PluginsTheme>()?.colors ??
      _fallback;
}

/// Provides [PluginsColors] to the screen's widgets.
class PluginsTheme extends InheritedWidget {
  const PluginsTheme({super.key, required this.colors, required super.child});

  final PluginsColors colors;

  @override
  bool updateShouldNotify(PluginsTheme old) => old.colors != colors;
}
