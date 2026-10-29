import 'package:flutter/material.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

/// A text pill in a tool panel, such as an aspect ratio. The selected one
/// takes the accent.
class EditorChip extends StatefulWidget {
  const EditorChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.toggle = false,
  });

  final String label;
  final bool selected;

  /// Null disables the chip: no focus, and screen readers hear it so.
  final VoidCallback? onPressed;

  /// The chip is an on/off switch (a fill, say) rather than one choice of a
  /// strip; screen readers hear [selected] as its state.
  final bool toggle;

  @override
  State<EditorChip> createState() => _EditorChipState();
}

class _EditorChipState extends State<EditorChip> {
  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    return MgPressable(
      role: widget.toggle ? MgPressableRole.toggle : MgPressableRole.tab,
      selected: widget.toggle ? null : widget.selected,
      toggled: widget.toggle ? widget.selected : null,
      semanticsLabel: widget.label,
      onTap: widget.onPressed,
      scale: 1,
      focusRadius: 13,
      builder: (context, st) {
        final bg = widget.selected
            ? c.accent
            : (st.hovered ? c.hover : const Color(0x00000000));
        final fg = widget.selected ? c.onAccent : (st.hovered ? c.fg : c.fg2);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          constraints: BoxConstraints(minHeight: MgMetrics.scaled(context, 26)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            widget.label,
            style: mgTextStyle(
              c,
              size: MgType.small,
              weight: FontWeight.w500,
              color: fg,
              height: 1,
            ),
          ),
        );
      },
    );
  }
}

/// A thin vertical line between groups of controls.
class EditorDivider extends StatelessWidget {
  const EditorDivider({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 18,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: MgColors.of(context).separator,
  );
}
