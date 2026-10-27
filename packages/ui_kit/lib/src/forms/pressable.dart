import 'dart:ui' show SemanticsRole;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// What a [MgPressable] knows about its state, for its builder.
class MgPressState {
  const MgPressState({
    required this.hovered,
    required this.pressed,
    required this.focused,
  });

  final bool hovered;
  final bool pressed;

  /// Keyboard focus only; a click does not show the ring.
  final bool focused;
}

/// How a [MgPressable] presents itself to screen readers.
enum MgPressableRole {
  /// A plain button.
  button,

  /// One choice of a group, of which one is picked: use with `checked`.
  radio,

  /// A tab of a tab strip: use with `selected`.
  tab,

  /// A box that is ticked or not: use with `checked`.
  checkbox,

  /// An on/off switch: use with `toggled`.
  toggle,
}

class _SecondaryActivateIntent extends Intent {
  const _SecondaryActivateIntent();
}

/// The one way a control responds to the pointer: it reacts on pointer
/// down (not on release), sinks a hair while pressed and springs back,
/// shows a focus ring for the keyboard, and is activated by Space and Enter.
///
/// Reduced motion keeps the colour feedback and drops the scale.
///
/// A control with no [onTap] is disabled: it takes no focus and says so to
/// screen readers.
class MgPressable extends StatefulWidget {
  const MgPressable({
    super.key,
    required this.builder,
    this.onTap,
    this.onSecondaryTapUp,
    this.semanticsLabel,
    this.cursor,
    this.scale = MgMotion.pressScale,
    this.focusRadius = MgRadius.control,
    this.focusable = true,
    this.toggled,
    this.role = MgPressableRole.button,
    this.selected,
    this.checked,
    this.busy = false,
    this.focusNode,
    this.autofocus = false,
    this.onSecondaryActivate,
    this.excludeSemantics,
    this.onHover,
  });

  final Widget Function(BuildContext context, MgPressState state) builder;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;

  /// What screen readers announce. Unless [excludeSemantics] says otherwise,
  /// giving it also hides the semantics of the [builder]'s subtree, so the
  /// label is the whole description; leave it null to let the child's text
  /// speak (and merge) instead.
  final String? semanticsLabel;
  final MouseCursor? cursor;

  /// Scale while pressed; 1 turns the sink off (large rows).
  final double scale;

  /// Corner radius of the focus ring.
  final double focusRadius;
  final bool focusable;

  /// A toggle's state for screen readers; null for a plain button.
  final bool? toggled;

  /// The kind of control, for screen readers.
  final MgPressableRole role;

  /// Whether a tab or a choice is the current one; null when it has no such
  /// state.
  final bool? selected;

  /// Whether a [MgPressableRole.radio] or [MgPressableRole.checkbox] is on.
  final bool? checked;

  /// Work is under way: Space, Enter and clicks do nothing until it ends,
  /// so an action can't fire twice. Flutter has no busy flag for screen
  /// readers, so the control is only exposed as not tappable.
  final bool busy;

  /// A node of the caller's, to move focus to or watch. Its
  /// `canRequestFocus` and `skipTraversal` follow whether the control is
  /// enabled; the caller disposes it.
  final FocusNode? focusNode;
  final bool autofocus;

  /// Runs on the ContextMenu key or Shift+F10, the keyboard's way to what a
  /// right click does ([onSecondaryTapUp]).
  final VoidCallback? onSecondaryActivate;

  /// Whether the semantics of the [builder]'s subtree are hidden. Null (the
  /// default) hides them exactly when [semanticsLabel] is given.
  final bool? excludeSemantics;

  /// The pointer entered or left the control.
  final ValueChanged<bool>? onHover;

  @override
  State<MgPressable> createState() => _MgPressableState();
}

class _MgPressableState extends State<MgPressable> {
  bool _hover = false;
  bool _pressed = false;
  bool _focus = false;

  FocusNode? _own;

  FocusNode get _focusNode =>
      widget.focusNode ??
      (_own ??= FocusNode(debugLabel: 'MgPressable')
        ..canRequestFocus = _focusable
        ..skipTraversal = !_focusable);

  bool get _enabled => widget.onTap != null && !widget.busy;

  bool get _hasTap => widget.onTap != null;

  void _activate() {
    if (_enabled) widget.onTap!();
  }

  bool get _focusable => widget.focusable && _hasTap;

  @override
  void initState() {
    super.initState();
    _focusNode
      ..canRequestFocus = _focusable
      ..skipTraversal = !_focusable;
  }

  @override
  void didUpdateWidget(MgPressable old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      _own?.dispose();
      _own = null;
    }
    _focusNode
      ..canRequestFocus = _focusable
      ..skipTraversal = !_focusable;
    if (!_enabled) {
      _hover = false;
      _pressed = false;
    }
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final pressed = _pressed && _enabled;
    final child = widget.builder(
      context,
      MgPressState(
        hovered: _hover && _enabled,
        pressed: pressed,
        focused: _focus,
      ),
    );
    final scaled = widget.scale == 1 || still
        ? child
        : AnimatedScale(
            scale: pressed ? widget.scale : 1,
            duration: pressed ? MgMotion.press : MgMotion.settleDuration,
            curve: pressed ? Curves.easeOut : MgMotion.spring,
            child: child,
          );
    final role = widget.role;
    final secondary = widget.onSecondaryActivate;
    return Semantics(
      button: role == MgPressableRole.button || role == MgPressableRole.tab,
      role: role == MgPressableRole.tab ? SemanticsRole.tab : null,
      inMutuallyExclusiveGroup: role == MgPressableRole.radio ? true : null,
      enabled: _hasTap,
      toggled: widget.toggled,
      selected: widget.selected,
      checked: widget.checked,
      label: widget.semanticsLabel,
      onTap: _enabled ? widget.onTap : null,
      excludeSemantics:
          widget.excludeSemantics ?? widget.semanticsLabel != null,
      child: FocusableActionDetector(
        // Always on: switching it off rewraps the subtree and drops the
        // state below (a label to spinner cross-fade, say). Without a tap
        // the node takes no focus and the actions do nothing.
        enabled: true,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        mouseCursor:
            widget.cursor ??
            (_enabled ? SystemMouseCursors.click : MouseCursor.defer),
        onShowHoverHighlight: (v) {
          _set(() => _hover = v);
          widget.onHover?.call(v);
        },
        onShowFocusHighlight: (v) => _set(() => _focus = v),
        shortcuts: {
          const SingleActivator(
            LogicalKeyboardKey.space,
            includeRepeats: false,
          ): const ActivateIntent(),
          const SingleActivator(
            LogicalKeyboardKey.enter,
            includeRepeats: false,
          ): const ActivateIntent(),
          // `includeRepeats: false` only skips a repeat here; without these it
          // would bubble to the app's own shortcuts and activate again.
          const SingleActivator(LogicalKeyboardKey.space):
              const DoNothingAndStopPropagationIntent(),
          const SingleActivator(LogicalKeyboardKey.enter):
              const DoNothingAndStopPropagationIntent(),
          if (secondary != null) ...const {
            SingleActivator(LogicalKeyboardKey.contextMenu):
                _SecondaryActivateIntent(),
            SingleActivator(LogicalKeyboardKey.f10, shift: true):
                _SecondaryActivateIntent(),
          },
        },
        actions: {
          DoNothingAndStopPropagationIntent: DoNothingAction(),
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
          if (secondary != null)
            _SecondaryActivateIntent: CallbackAction<_SecondaryActivateIntent>(
              onInvoke: (_) {
                secondary();
                return null;
              },
            ),
        },
        child: Listener(
          onPointerDown: (e) {
            if (e.buttons == kPrimaryButton) _set(() => _pressed = true);
          },
          onPointerUp: (_) => _set(() => _pressed = false),
          onPointerCancel: (_) => _set(() => _pressed = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The Semantics above speaks for the tap, and only while enabled.
            excludeFromSemantics: true,
            onTap: _enabled ? widget.onTap : null,
            // A drag or a scroll that wins the gesture cancels the tap: the
            // control lets go then, not when the pointer is lifted.
            onTapCancel: () => _set(() => _pressed = false),
            onSecondaryTapUp: widget.onSecondaryTapUp,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.focusRadius),
                border: Border.all(
                  color: _focus
                      ? c.accent.withValues(alpha: 0.7)
                      : const Color(0x00000000),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: scaled,
            ),
          ),
        ),
      ),
    );
  }
}
