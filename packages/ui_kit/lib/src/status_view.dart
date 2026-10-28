import 'dart:async';

import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:flutter/widgets.dart';

import 'forms/buttons.dart';
import 'icons.dart';
import 'theme/colors.dart';
import 'theme/metrics.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';

/// The small quiet ring for a row or a page that is loading.
///
/// With [delay] it stays invisible until the wait is long enough to notice,
/// so a fast load never flashes it. Under reduced motion it is a still ring
/// and appears without a fade: Flutter's indeterminate ring repeats forever.
class MgSpinner extends StatefulWidget {
  const MgSpinner({
    super.key,
    this.size = 16,
    this.strokeWidth = 1.6,
    this.color,
    this.delay = Duration.zero,
  });

  final double size;
  final double strokeWidth;

  /// The ring's colour; secondary text by default.
  final Color? color;
  final Duration delay;

  @override
  State<MgSpinner> createState() => _MgSpinnerState();
}

class _MgSpinnerState extends State<MgSpinner> {
  late var _visible = widget.delay == Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!_visible) {
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: still ? Duration.zero : MgMotion.fast,
        child: SizedBox.square(
          dimension: widget.size,
          child: CircularProgressIndicator(
            value: still ? 0.65 : null,
            strokeWidth: widget.strokeWidth,
            color: widget.color ?? c.fg2,
          ),
        ),
      ),
    );
  }
}

/// What a place shows instead of its content while there is none: a quiet
/// spinner while it loads, a glyph over a line for an empty or failed one,
/// each with an optional description and a single action ("Try again").
///
/// Loading and failed states are live regions, so a screen reader hears them
/// when they replace the content. Sizes follow the text scale.
class MgStatusView extends StatelessWidget {
  const MgStatusView.loading({
    super.key,
    this.title,
    this.description,
    this.delay = Duration.zero,
  }) : _kind = _Kind.loading,
       icon = null,
       actionLabel = null,
       onAction = null;

  const MgStatusView.empty(
    this.title, {
    super.key,
    this.description,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : _kind = _Kind.empty,
       delay = Duration.zero;

  const MgStatusView.error(
    this.title, {
    super.key,
    this.description,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : _kind = _Kind.error,
       delay = Duration.zero;

  final _Kind _kind;
  final String? title;
  final String? description;
  final MgIconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// How long a loading view waits before its spinner shows.
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    final glyph = icon;
    final title = this.title;
    final description = this.description;
    final actionLabel = this.actionLabel;
    final body = Center(
      child: Padding(
        padding: const EdgeInsets.all(MgSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_kind == _Kind.loading)
              MgSpinner(size: MgMetrics.scaled(context, 16), delay: delay)
            else if (glyph != null)
              MgIcon(
                glyph,
                size: MgMetrics.scaled(context, 28),
                color: c.quiet,
              ),
            if (title != null) ...[
              if (_kind == _Kind.loading || glyph != null)
                const SizedBox(height: MgSpace.ml),
              Text(
                title,
                textAlign: TextAlign.center,
                style: mgTextStyle(
                  c,
                  size: MgType.small,
                  weight: MgWeight.medium,
                  color: c.fg2,
                  height: 1.35,
                ),
              ),
            ],
            if (description != null) ...[
              const SizedBox(height: MgSpace.xs),
              Text(
                description,
                textAlign: TextAlign.center,
                style: mgTextStyle(
                  c,
                  size: MgType.caption,
                  color: c.quiet,
                  height: 1.35,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: MgSpace.l),
              MgTextButton(label: actionLabel, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      liveRegion: _kind != _Kind.empty,
      child: body,
    );
  }
}

enum _Kind { loading, empty, error }
