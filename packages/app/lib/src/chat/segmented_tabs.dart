import 'package:flutter/widgets.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

/// A row of equal tabs in a rounded field, the selected one raised on a
/// white (or lighter) pill, as macOS draws a segmented control.
class SegmentedTabs<T extends Object> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final T selected;
  final Map<T, String> labels;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.field,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (final MapEntry(key: kind, value: label) in labels.entries)
            Expanded(
              child: MgPressable(
                onTap: () => onSelect(kind),
                role: MgPressableRole.tab,
                selected: kind == selected,
                semanticsLabel: label,
                scale: 1,
                focusRadius: 6,
                builder: (context, _) => AnimatedContainer(
                  constraints: BoxConstraints(
                    minHeight: MgMetrics.scaled(context, 24),
                  ),
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kind == selected
                        ? (c.isDark
                              ? const Color(0x2EFFFFFF)
                              : const Color(0xFFFFFFFF))
                        : const Color(0x00FFFFFF),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: kind == selected && !c.isDark
                        ? const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 2,
                              offset: Offset(0, 0.5),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: mgTextStyle(
                      c,
                      size: MgType.small,
                      weight: kind == selected ? FontWeight.w500 : null,
                      color: kind == selected ? c.fg : c.fg2,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
