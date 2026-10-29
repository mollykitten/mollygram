import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

import '../data/chat_directory.dart';
import '../l10n/shell_strings.dart';
import '../model/workspace.dart';
import 'glyphs.dart';

/// The row of chat tabs. Solid, not glass: glass is only for the sidebar,
/// the chat header capsules, the composer and the palette.
///
/// Shown only while there are two or more tabs, so a single chat looks the
/// same as in a client without tabs.
class TabStrip extends StatelessWidget {
  const TabStrip({
    super.key,
    required this.controller,
    required this.directory,
    required this.strings,
  });

  static const double height = 36;

  final WorkspaceController controller;
  final ChatDirectory directory;
  final ShellStrings strings;

  @override
  Widget build(BuildContext context) {
    final workspace = controller.value;
    final c = MgColors.of(context);
    return Semantics(
      container: true,
      label: strings.tabs,
      child: SizedBox(
        height: MgMetrics.scaled(context, height),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              for (var i = 0; i < workspace.tabs.length; i++)
                Flexible(
                  child: _TabPill(
                    key: ValueKey(workspace.tabs[i].id),
                    title: tabTitle(workspace.tabs[i], directory, strings),
                    selected: i == workspace.active,
                    strings: strings,
                    onSelect: () => controller.selectTab(i),
                    onClose: () => controller.closeTab(i),
                  ),
                ),
              const SizedBox(width: 2),
              _IconButton(
                glyph: ShellGlyph.plus,
                label: strings.newTab,
                color: c.fg2,
                onTap: controller.newTab,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tab is named after its chats: "Anna", or "Anna · Product team" in a
/// split view.
String tabTitle(WorkspaceTab tab, ChatDirectory directory, ShellStrings s) {
  final names = [
    for (final id in tab.panes)
      if (id != null) directory.chat(id)?.title ?? '',
  ].where((n) => n.isNotEmpty).toList();
  return names.isEmpty ? s.newTab : names.join(' · ');
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    super.key,
    required this.title,
    required this.selected,
    required this.strings,
    required this.onSelect,
    required this.onClose,
  });

  final String title;
  final bool selected;
  final ShellStrings strings;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    return Listener(
      // Middle click closes a tab, as in browsers.
      onPointerDown: (e) {
        if (e.kind == PointerDeviceKind.mouse &&
            e.buttons == kMiddleMouseButton) {
          onClose();
        }
      },
      child: MgPressable(
        onTap: onSelect,
        role: MgPressableRole.tab,
        selected: selected,
        scale: 1,
        focusRadius: 13,
        builder: (context, state) {
          final showClose = state.hovered || state.focused || selected;
          return Container(
            constraints: BoxConstraints(
              maxWidth: 220,
              minWidth: 64,
              minHeight: MgMetrics.scaled(context, 26),
            ),
            margin: const EdgeInsets.only(right: MgSpace.xxs),
            padding: const EdgeInsets.only(left: MgSpace.ml, right: MgSpace.xs),
            decoration: BoxDecoration(
              color: selected ? c.field : null,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected || state.hovered ? c.fg : c.fg2,
                    ),
                  ),
                ),
                const SizedBox(width: MgSpace.xxs),
                // The slot keeps its width so titles do not jump on hover.
                Opacity(
                  opacity: showClose ? 1 : 0,
                  // Its own node, so the close label does not merge into the
                  // tab's.
                  child: Semantics(
                    container: true,
                    child: _IconButton(
                      glyph: ShellGlyph.close,
                      label: strings.closeTab,
                      color: c.fg2,
                      size: 18,
                      onTap: showClose ? onClose : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.glyph,
    required this.label,
    required this.color,
    required this.onTap,
    this.size = 26,
  });

  final ShellGlyph glyph;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    final side = MgMetrics.scaled(context, size);
    return MgPressable(
      onTap: onTap,
      semanticsLabel: label,
      scale: 1,
      focusRadius: side / 2,
      builder: (context, state) => Container(
        width: side,
        height: side,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: state.hovered ? c.hover : null,
        ),
        child: Glyph(
          glyph,
          size: side * 0.55,
          color: state.hovered ? c.fg : color,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
