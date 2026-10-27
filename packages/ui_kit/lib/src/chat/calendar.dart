import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../forms/pressable.dart';
import '../glass/glass.dart';
import '../icon_button.dart';
import '../icons.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';

/// A month of days to jump to, as in Telegram for macOS: the month and
/// year with arrows above a grid of weeks. Days after [today] can't be
/// picked, nor days before [first] when it is given. The kit has no
/// strings: the app formats the month title and the weekday letters.
class MgCalendar extends StatefulWidget {
  const MgCalendar({
    super.key,
    required this.month,
    required this.today,
    required this.onPick,
    required this.monthTitle,
    required this.weekdays,
    required this.previousTooltip,
    required this.nextTooltip,
    this.first,
    this.selected,
    this.firstWeekday = DateTime.monday,
  });

  /// Any day of the month shown first.
  final DateTime month;
  final DateTime today;
  final DateTime? first;

  /// The day the calendar was opened for, if any; screen readers announce
  /// it as selected. It is not drawn differently.
  final DateTime? selected;
  final void Function(DateTime day) onPick;

  /// "October 2026".
  final String Function(DateTime month) monthTitle;

  /// Seven labels from Monday, such as "M", "T", "W".
  final List<String> weekdays;
  final String previousTooltip;
  final String nextTooltip;

  /// [DateTime.monday] or [DateTime.sunday].
  final int firstWeekday;

  static const double cell = 32;
  static const double width = cell * 7 + MgSpace.l * 2;

  @override
  State<MgCalendar> createState() => _MgCalendarState();
}

class _MgCalendarState extends State<MgCalendar> {
  late DateTime _month = DateTime(widget.month.year, widget.month.month);

  DateTime get _today =>
      DateTime(widget.today.year, widget.today.month, widget.today.day);

  DateTime? get _first {
    final first = widget.first;
    return first == null ? null : DateTime(first.year, first.month, first.day);
  }

  bool get _hasPrevious {
    final first = _first;
    return first == null || DateTime(first.year, first.month).isBefore(_month);
  }

  bool get _hasNext => DateTime(_today.year, _today.month).isAfter(_month);

  final _nodes = <int, FocusNode>{};

  FocusNode _node(int day) => _nodes[day] ??= FocusNode(debugLabel: 'day $day');

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Arrows move between the days of the month: ←/→ by a day, ↑/↓ by a
  /// week. A day that can't be picked is not a stop.
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final delta = key == LogicalKeyboardKey.arrowLeft
        ? -1
        : key == LogicalKeyboardKey.arrowRight
        ? 1
        : key == LogicalKeyboardKey.arrowUp
        ? -7
        : key == LogicalKeyboardKey.arrowDown
        ? 7
        : null;
    if (delta == null) return KeyEventResult.ignored;
    final from = _nodes.entries
        .where((e) => e.value.hasPrimaryFocus)
        .map((e) => e.key)
        .firstOrNull;
    if (from == null) return KeyEventResult.ignored;
    final to = from + delta;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    if (to >= 1 &&
        to <= daysInMonth &&
        _enabled(DateTime(_month.year, _month.month, to))) {
      _node(to).requestFocus();
    }
    return KeyEventResult.handled;
  }

  void _move(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  bool _enabled(DateTime day) {
    if (day.isAfter(_today)) return false;
    final first = _first;
    return first == null || !day.isBefore(first);
  }

  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Blank cells before the first of the month.
    final lead = (_month.weekday - widget.firstWeekday + 7) % 7;
    final weeks = ((lead + daysInMonth) / 7).ceil();
    final selected = widget.selected;
    return Glass(
      radius: MgRadius.popover,
      padding: const EdgeInsets.fromLTRB(
        MgSpace.l,
        MgSpace.m,
        MgSpace.l,
        MgSpace.l,
      ),
      child: SizedBox(
        width: MgCalendar.width - MgSpace.l * 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                MgIconButton(
                  icon: MgIcons.back,
                  tooltip: widget.previousTooltip,
                  iconSize: 15,
                  onPressed: _hasPrevious ? () => _move(-1) : null,
                ),
                Expanded(
                  child: Text(
                    widget.monthTitle(_month),
                    textAlign: TextAlign.center,
                    style: mgTextStyle(c, weight: FontWeight.w600),
                  ),
                ),
                MgIconButton(
                  icon: MgIcons.chevron,
                  tooltip: widget.nextTooltip,
                  iconSize: 15,
                  onPressed: _hasNext ? () => _move(1) : null,
                ),
              ],
            ),
            const SizedBox(height: MgSpace.s),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  SizedBox(
                    width: MgCalendar.cell,
                    child: Text(
                      widget.weekdays[(widget.firstWeekday - 1 + i) % 7],
                      textAlign: TextAlign.center,
                      style: mgTextStyle(
                        c,
                        size: MgType.caption,
                        weight: FontWeight.w500,
                        color: c.fg2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MgSpace.xs),
            Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: _onKey,
              child: Column(
                children: [
                  for (var week = 0; week < weeks; week++)
                    Row(
                      children: [
                        for (var i = 0; i < 7; i++)
                          () {
                            final number = week * 7 + i - lead + 1;
                            if (number < 1 || number > daysInMonth) {
                              return const SizedBox.square(
                                dimension: MgCalendar.cell,
                              );
                            }
                            final day = DateTime(
                              _month.year,
                              _month.month,
                              number,
                            );
                            return _Day(
                              key: ValueKey(number),
                              label: '$number',
                              today: day == _today,
                              selected:
                                  selected != null &&
                                  (day.year == selected.year &&
                                      day.month == selected.month &&
                                      day.day == selected.day),
                              focusNode: _node(number),
                              onTap: _enabled(day)
                                  ? () => widget.onPick(day)
                                  : null,
                            );
                          }(),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    super.key,
    required this.label,
    required this.today,
    required this.selected,
    required this.focusNode,
    required this.onTap,
  });

  final String label;
  final bool today;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    final enabled = onTap != null;
    return MgPressable(
      onTap: onTap,
      focusNode: focusNode,
      selected: selected,
      excludeSemantics: false,
      scale: 1,
      focusRadius: MgCalendar.cell / 2,
      builder: (context, st) {
        final lit = (st.hovered || st.focused) && enabled;
        return SizedBox.square(
          dimension: MgCalendar.cell,
          child: Center(
            child: AnimatedContainer(
              duration: MgMotion.fast,
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lit ? c.accent : const Color(0x00000000),
                border: today && !lit
                    ? Border.all(color: c.accent, width: 1.5)
                    : null,
              ),
              child: Text(
                label,
                style: mgTextStyle(
                  c,
                  weight: today ? FontWeight.w600 : FontWeight.w400,
                  color: lit
                      ? c.onAccent
                      : !enabled
                      ? c.fg2.withValues(alpha: 0.4)
                      : today
                      ? c.accent
                      : c.fg,
                  height: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
