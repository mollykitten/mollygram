import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

import '../data/chat_directory.dart';
import '../l10n/shell_strings.dart';
import '../model/workspace.dart';
import '../palette/palette_search.dart';
import '../shortcuts.dart';
import 'glyphs.dart';

/// The ⌘K palette: chats, people, messages and commands in one list.
///
/// It appears and disappears instantly and does not dim the window, as the
/// design asks. ⏎ opens the selection, ⌘⏎ opens a chat in the split view,
/// ⌥⏎ in a new tab, Esc or a click outside closes the palette.
class CommandPalette extends StatefulWidget {
  const CommandPalette({
    super.key,
    required this.directory,
    required this.commands,
    required this.strings,
    required this.onOpenChat,
    required this.onClose,
    this.onOpenMessage,
    this.initialQuery = '',
    this.chatAvatar,
  });

  /// Draws a chat row's avatar at [size]; the default is its monogram.
  final Widget Function(ChatSummary chat, double size)? chatAvatar;

  final ChatDirectory directory;
  final List<PaletteCommand> commands;
  final ShellStrings strings;
  final void Function(ChatId chat, OpenTarget target) onOpenChat;

  /// Opens a found message. Without it the message's chat is opened.
  final void Function(MessageHit message, OpenTarget target)? onOpenMessage;
  final VoidCallback onClose;
  final String initialQuery;

  static const double width = 640;
  static const double top = 120;
  static const double itemHeight = 38;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialQuery,
  );
  final FocusNode _focus = FocusNode(debugLabel: 'palette');
  final ScrollController _scroll = ScrollController();
  final GlobalKey _selectedKey = GlobalKey();

  late PaletteSearch _search = PaletteSearch(
    directory: widget.directory,
    commands: widget.commands,
  );
  PaletteQuery _query = const PaletteQuery(PaletteMode.all, '');
  List<PaletteGroup> _groups = const [];
  List<PaletteItem> _flat = const [];
  int _selected = 0;
  bool _selectionTouched = false;

  /// Bumped per query so a slow search cannot overwrite a newer one.
  int _generation = 0;
  bool _built = false;
  bool _searching = false;
  bool _searchFailed = false;
  bool _confirmClear = false;

  SearchSuggestionsDirectory? get _suggestions => switch (widget.directory) {
    final SearchSuggestionsDirectory source => source,
    _ => null,
  };
  bool get _emptyQuery => _query == const PaletteQuery(PaletteMode.all, '');

  @override
  void initState() {
    super.initState();
    _text.addListener(_onText);
    // Autofocus would lose to the window's focused shortcut scope.
    _focus.requestFocus();
    _refresh();
    _suggestions?.addListener(_onSuggestions);
    if (_emptyQuery) unawaited(_suggestions?.loadSearchSuggestions());
  }

  @override
  void didUpdateWidget(CommandPalette old) {
    super.didUpdateWidget(old);
    if (old.directory != widget.directory) {
      if (old.directory case final SearchSuggestionsDirectory previous) {
        previous.removeListener(_onSuggestions);
      }
      _suggestions?.addListener(_onSuggestions);
      _confirmClear = false;
      // A query belongs to the old account too. Do not silently send its text
      // through the replacement account's search APIs.
      _text.removeListener(_onText);
      _text.clear();
      _text.addListener(_onText);
      _focus.requestFocus();
    }
    if (old.directory != widget.directory || old.commands != widget.commands) {
      _search = PaletteSearch(
        directory: widget.directory,
        commands: widget.commands,
      );
      _refresh(force: true);
      if (old.directory != widget.directory && _emptyQuery) {
        unawaited(_suggestions?.loadSearchSuggestions());
      }
    }
  }

  @override
  void dispose() {
    _suggestions?.removeListener(_onSuggestions);
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onText() {
    final wasEmpty = _emptyQuery;
    _refresh();
    if (!wasEmpty && _emptyQuery) {
      unawaited(_suggestions?.loadSearchSuggestions());
    }
  }

  void _onSuggestions() {
    if (!mounted || !_emptyQuery) return;
    final entries = [
      for (final group in _groups)
        for (final item in group.items) (group.kind, item),
    ];
    final previous = _selectionTouched
        ? entries.elementAtOrNull(_selected)
        : null;
    _show(_search.runSync(_query) ?? const [], resetScroll: false);
    // Group identity distinguishes a recent row from the same top peer.
    if (previous != null) {
      final next = [
        for (final group in _groups)
          for (final item in group.items) (group.kind, item),
      ];
      final index = next.indexWhere((entry) {
        if (entry.$1 != previous.$1) return false;
        final oldItem = previous.$2;
        final newItem = entry.$2;
        return switch ((oldItem, newItem)) {
          (ChatPaletteItem(chat: final a), ChatPaletteItem(chat: final b)) =>
            a.id == b.id,
          (
            CommandPaletteItem(command: final a),
            CommandPaletteItem(command: final b),
          ) =>
            a.id == b.id,
          _ => false,
        };
      });
      if (index >= 0) _selected = index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _selectedKey.currentContext;
        if (mounted && context != null) Scrollable.ensureVisible(context);
      });
    }
  }

  Future<void> _refresh({bool force = false}) async {
    final query = PaletteQuery.parse(_text.text);
    if (!force && query == _query && _generation > 0) return;
    _query = query;
    _selectionTouched = false;
    final generation = ++_generation;
    _searching = false;
    _searchFailed = false;
    final ready = _search.runSync(query);
    if (ready != null) {
      _show(ready);
      return;
    }
    // Earlier results stay on screen, dimmed and inert, until the search
    // answers: `_searching` also blocks `_activate`.
    if (_built) {
      setState(() => _searching = true);
    } else {
      _searching = true;
    }
    try {
      final groups = await _search.run(query);
      if (!mounted || generation != _generation) return;
      _searching = false;
      _show(groups);
    } catch (_) {
      if (!mounted || generation != _generation) return;
      _searching = false;
      _searchFailed = true;
      _show(const []);
    }
  }

  void _show(List<PaletteGroup> groups, {bool resetScroll = true}) {
    void apply() {
      _groups = groups;
      _flat = [for (final g in groups) ...g.items];
      _selected = 0;
    }

    // Called from initState for the first frame, where setState is not
    // allowed yet.
    if (!_built) {
      apply();
    } else {
      setState(apply);
    }
    if (resetScroll && _scroll.hasClients) _scroll.jumpTo(0);
  }

  void _move(int delta) {
    if (_flat.isEmpty) return;
    _selectionTouched = true;
    setState(() => _selected = (_selected + delta).clamp(0, _flat.length - 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _selectedKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignmentPolicy: delta > 0
              ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
              : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
      }
    });
  }

  OpenTarget _targetFromModifiers() {
    final keys = HardwareKeyboard.instance;
    final primary = usesCommandKey ? keys.isMetaPressed : keys.isControlPressed;
    if (primary) return OpenTarget.split;
    if (keys.isAltPressed) return OpenTarget.newTab;
    return OpenTarget.current;
  }

  void _activate(int index, OpenTarget target) {
    if (_confirmClear || _searching || index < 0 || index >= _flat.length) {
      return;
    }
    final item = _flat[index];
    final suggestions = _suggestions;
    // Close first: a command may open another overlay or move focus.
    widget.onClose();
    switch (item) {
      case ChatPaletteItem(:final chat):
        // Only explicit chat selection records metadata, not typing, message
        // selection, ordinary chat navigation or restored workspace panes.
        unawaited(
          suggestions?.rememberSearchChat(chat.id).catchError((Object _) {}),
        );
        widget.onOpenChat(chat.id, target);
      case MessagePaletteItem(:final message):
        final open = widget.onOpenMessage;
        if (open != null) {
          open(message, target);
        } else {
          widget.onOpenChat(message.chatId, target);
        }
      case CommandPaletteItem(:final command):
        command.run();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape && event is KeyDownEvent) {
      if (_confirmClear) {
        _cancelClear();
      } else {
        widget.onClose();
      }
      return KeyEventResult.handled;
    }
    if (_confirmClear || !_focus.hasFocus) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _activate(_selected, _targetFromModifiers());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _groupTitle(PaletteGroupKind kind) {
    final s = widget.strings;
    return switch (kind) {
      PaletteGroupKind.top => s.groupTopPeers,
      PaletteGroupKind.recentSearches => s.groupRecentSearches,
      PaletteGroupKind.recent => s.groupRecent,
      PaletteGroupKind.chats => s.groupChats,
      PaletteGroupKind.people => s.groupPeople,
      PaletteGroupKind.messages => s.groupMessages,
      PaletteGroupKind.commands => s.groupCommands,
    };
  }

  String? get _modeLabel => switch (_query.mode) {
    PaletteMode.all => null,
    PaletteMode.commands => widget.strings.groupCommands,
    PaletteMode.people => widget.strings.groupPeople,
    PaletteMode.messages => widget.strings.groupMessages,
  };

  void _cancelClear() {
    setState(() => _confirmClear = false);
    _focus.requestFocus();
  }

  void _askClear() {
    if (_suggestions?.searchSuggestions.busy ?? true) return;
    _focus.unfocus();
    setState(() => _confirmClear = true);
  }

  Widget _clearConfirmation(MgColors c) {
    final s = widget.strings;
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        // Safe default: Enter cancels unless the Clear button has focus.
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          _cancelClear();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.confirmClearRecentSearches,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.fg,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.clearRecentExplanation,
              style: TextStyle(color: c.fg2, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MgTextButton(label: s.cancel, onPressed: _cancelClear),
                const SizedBox(width: 8),
                MgTextButton(
                  label: s.clear,
                  onPressed: () {
                    final source = _suggestions;
                    if (source == null || source.searchSuggestions.busy) return;
                    _cancelClear();
                    unawaited(source.clearRecentSearches());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _status(MgColors c) {
    final s = widget.strings;
    final state = _emptyQuery ? _suggestions?.searchSuggestions : null;
    final String label;
    VoidCallback? retry;
    if (_searchFailed) {
      label = s.searchFailed;
      retry = () {
        _focus.requestFocus();
        unawaited(_refresh(force: true));
      };
    } else if (_searching) {
      label = s.searching;
    } else if (state?.loading ?? false) {
      label = s.loadingSuggestions;
    } else if (state?.actionFailed ?? false) {
      label = s.recentUpdateFailed;
    } else if (state?.loadFailed ?? false) {
      label = s.suggestionsFailed;
      retry = state!.busy
          ? null
          : () => unawaited(_suggestions?.loadSearchSuggestions());
    } else if (state != null && state.recent.isEmpty && state.top.isEmpty) {
      label = s.emptySuggestions;
    } else {
      return const SizedBox.shrink();
    }
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 12, color: c.fg2)),
            ),
            if (retry != null) MgTextButton(label: s.retry, onPressed: retry),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _built = true;
    final c = MgColors.of(context);
    final s = widget.strings;
    final base = DefaultTextStyle.of(context).style
        .copyWith(color: c.fg, fontSize: 13);
    final modeLabel = _modeLabel;
    final showEmpty =
        _flat.isEmpty &&
        _query.text.isNotEmpty &&
        !_searching &&
        !_searchFailed;

    final field = EditableText(
      controller: _text,
      focusNode: _focus,
      autofocus: true,
      readOnly: _confirmClear,
      style: base.copyWith(fontSize: 18),
      cursorColor: c.accent,
      backgroundCursorColor: c.fg2,
      selectionColor: c.accent.withValues(alpha: 0.3),
      maxLines: 1,
      textInputAction: TextInputAction.go,
      // Enter is handled in _onKey together with its modifiers.
      onSubmitted: (_) {},
    );

    final panel = Container(
      decoration: BoxDecoration(
        color: _paletteFill(c),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.rim),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border(top: BorderSide(color: c.highlight)),
      ),
      child: DefaultTextStyle(
        style: base,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Glyph(
                      ShellGlyph.search,
                      size: 18,
                      color: c.fg2,
                      strokeWidth: 2,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Stack(
                        alignment: AlignmentDirectional.centerStart,
                        children: [
                          if (_text.text.isEmpty)
                            IgnorePointer(
                              child: Text(
                                s.palettePlaceholder,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: base.copyWith(
                                  fontSize: 18,
                                  color: c.fg2,
                                ),
                              ),
                            ),
                          Semantics(
                            label: s.paletteSearchLabel,
                            textField: true,
                            child: field,
                          ),
                        ],
                      ),
                    ),
                    if (modeLabel != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        modeLabel,
                        style: base.copyWith(fontSize: 12, color: c.fg2),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(height: 0.5, color: c.separator),
            if (_confirmClear)
              _clearConfirmation(c)
            else ...[
              _status(c),
              if (_flat.isNotEmpty || showEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 440),
                  child: showEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 28,
                            horizontal: 12,
                          ),
                          child: Text(
                            s.nothingFound,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.fg2),
                          ),
                        )
                      : Semantics(label: s.paletteResults, child: _results(c)),
                ),
              if (_flat.isNotEmpty || showEmpty)
                Container(height: 0.5, color: c.separator),
            ],
            SizedBox(
              height: 34,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DefaultTextStyle(
                  style: base.copyWith(fontSize: 12, color: c.fg2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: Row(
                    children: [
                      Text('⏎ ${s.hintOpen}'),
                      const SizedBox(width: 16),
                      Text('$primaryModifierLabel⏎ ${s.hintSplit}'),
                      const SizedBox(width: 16),
                      Text('$altModifierLabel⏎ ${s.hintNewTab}'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(s.hintPrefixes, textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Focus(
      onKeyEvent: _onKey,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: s.palette,
        child: CustomPaint(
          painter: _OuterShadow(color: _paletteShadow(c)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(filter: paletteGlassFilter, child: panel),
          ),
        ),
      ),
    );
  }

  Widget _results(MgColors c) {
    var index = 0;
    final children = <Widget>[];
    for (final group in _groups) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _groupTitle(group.kind),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.fg2,
                  ),
                ),
              ),
              if (group.kind == PaletteGroupKind.recentSearches)
                MgTextButton(
                  label: widget.strings.clearRecentSearches,
                  onPressed: (_suggestions?.searchSuggestions.busy ?? true)
                      ? null
                      : _askClear,
                ),
            ],
          ),
        ),
      );
      for (final item in group.items) {
        final i = index++;
        children.add(
          _PaletteRow(
            key: i == _selected ? _selectedKey : null,
            item: item,
            selected: i == _selected,
            strings: widget.strings,
            chatAvatar: widget.chatAvatar,
            removable: group.kind == PaletteGroupKind.recentSearches,
            onRemove:
                group.kind == PaletteGroupKind.recentSearches &&
                    !(_suggestions?.searchSuggestions.busy ?? true)
                ? () {
                    if (item case ChatPaletteItem(:final chat)) {
                      unawaited(_suggestions?.removeRecentSearch(chat.id));
                      _focus.requestFocus();
                    }
                  }
                : null,
            onHover: () {
              _selectionTouched = true;
              if (_selected != i) setState(() => _selected = i);
            },
            onTap: () => _activate(i, _targetFromModifiers()),
          ),
        );
      }
    }
    return IgnorePointer(
      ignoring: _searching,
      child: Opacity(
        opacity: _searching ? 0.5 : 1,
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A shadow drawn only outside the panel, like CSS `box-shadow`, so it does
/// not darken the translucent glass from below.
class _OuterShadow extends CustomPainter {
  _OuterShadow({required this.color});

  final Color color;

  static const radius = Radius.circular(16);

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect((Offset.zero & size).inflate(200))
          ..addRRect(box),
      )
      ..drawRRect(
        box.shift(const Offset(0, 24)),
        Paint()
          ..color = color
          // blur 70 in CSS terms is a sigma of 35.
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_OuterShadow old) => old.color != color;
}

/// The palette floats over everything, so its glass is denser than the
/// sidebar's and its shadow deeper (design/Palette.dc.html).
Color _paletteFill(MgColors c) =>
    c.isDark ? const Color(0x941E2024) : const Color(0x8CFFFFFF);

Color _paletteShadow(MgColors c) =>
    c.isDark ? const Color(0x99000000) : const Color(0x38000000);

/// blur(40px) saturate(190%) from the palette mock; in CSS the blur radius
/// is the sigma.
final ui.ImageFilter paletteGlassFilter = ui.ImageFilter.compose(
  outer: ui.ColorFilter.matrix(_saturation(1.9)),
  inner: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
);

List<double> _saturation(double s) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final i = 1 - s;
  return [
    r * i + s, g * i, b * i, 0, 0, //
    r * i, g * i + s, b * i, 0, 0,
    r * i, g * i, b * i + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    super.key,
    required this.item,
    required this.selected,
    required this.strings,
    required this.onHover,
    required this.onTap,
    this.chatAvatar,
    this.removable = false,
    this.onRemove,
  });

  final Widget Function(ChatSummary chat, double size)? chatAvatar;
  final PaletteItem item;
  final bool selected;
  final ShellStrings strings;
  final VoidCallback onHover;
  final VoidCallback onTap;
  final bool removable;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    final fg = selected ? c.onAccent : c.fg;
    final fg2 = selected ? c.onAccentSecondary : c.fg2;

    final (
      Widget leading,
      String title,
      String? sub,
      String? kbd,
    ) = switch (item) {
      ChatPaletteItem(:final chat) => (
        chatAvatar?.call(chat, 24) ??
            MonogramAvatar(name: chat.title, size: 24),
        chat.title,
        chat.unread > 0
            ? strings.newMessages(chat.unread)
            : (chat.username != null ? '@${chat.username}' : null),
        null,
      ),
      MessagePaletteItem(:final message) => (
        Glyph(message.isFile ? ShellGlyph.file : ShellGlyph.chat, color: fg),
        message.isFile ? message.text : '“${message.text}”',
        message.chatTitle,
        null,
      ),
      CommandPaletteItem(:final command) => (
        Glyph(glyphFor(command.glyph), color: fg),
        command.title,
        command.subtitle,
        command.shortcut == null ? null : shortcutLabel(command.shortcut!),
      ),
    };

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (_) => onHover(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: selected,
          label: title,
          child: Container(
            height: CommandPalette.itemHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected ? c.accent : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(width: 24, height: 24, child: Center(child: leading)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: title,
                      children: [
                        if (sub != null && sub.isNotEmpty)
                          TextSpan(
                            text: '  $sub',
                            style: TextStyle(color: fg2),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg),
                  ),
                ),
                if (kbd != null)
                  Text(kbd, style: TextStyle(fontSize: 12, color: fg2)),
                if (removable)
                  MgIconButton(
                    icon: MgIcons.close,
                    tooltip: strings.removeRecentSearch(title),
                    onPressed: onRemove,
                    size: 28,
                    iconSize: 13,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
