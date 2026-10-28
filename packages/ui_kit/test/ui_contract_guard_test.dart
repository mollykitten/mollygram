import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pointer widgets that make an area clickable by hand. Controls go through
/// `MgPressable` (or a primitive built on it) so they get the shared press
/// feedback, focus ring, Space/Enter and semantics. See "UI contract" in
/// `packages/ui_kit/README.md`.
final _handlerWidgets = RegExp(r'\b(GestureDetector|InkWell|InkResponse)\(');
final _mouseRegion = RegExp(r'\bMouseRegion\(');
final _tapHandler = RegExp(
  r'\bon(Tap|TapDown|TapUp|DoubleTap|LongPress|SecondaryTap|SecondaryTapUp)\b',
);
final _clickCursor = RegExp(r'SystemMouseCursors\.click');

/// Returns the text of the call whose `(` is at [open], or null if unbalanced.
String? _callBody(String src, int open) {
  var depth = 0;
  for (var i = open; i < src.length; i++) {
    final c = src[i];
    if (c == '(') depth++;
    if (c == ')' && --depth == 0) return src.substring(open, i + 1);
  }
  return null;
}

/// Number of hand-made tap areas in [src]: a `GestureDetector`, `InkWell` or
/// `InkResponse` with a tap handler, or a `MouseRegion` that shows the click
/// cursor. Comment lines are ignored.
int countHandMadeTaps(String src) {
  final code = src
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('//'))
      .join('\n');
  var n = 0;
  for (final m in _handlerWidgets.allMatches(code)) {
    final body = _callBody(code, m.end - 1);
    if (body != null && _tapHandler.hasMatch(body)) n++;
  }
  for (final m in _mouseRegion.allMatches(code)) {
    final body = _callBody(code, m.end - 1);
    if (body != null && _clickCursor.hasMatch(body)) n++;
  }
  return n;
}

Map<String, int> scanPackages(Directory packages) {
  final found = <String, int>{};
  for (final pkg in packages.listSync().whereType<Directory>()) {
    final lib = Directory('${pkg.path}/lib');
    if (!lib.existsSync()) continue;
    final name = pkg.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final n = countHandMadeTaps(f.readAsStringSync());
      if (n > 0) {
        final rel = f.path.substring(lib.path.length + 1);
        found['$name/lib/$rel'] = n;
      }
    }
  }
  return found;
}

/// Files that still hold hand-made tap areas, with how many. The numbers only
/// go down: a new file, or one more tap area in a listed file, fails the test.
/// When you migrate one, lower or delete its line.
const _allowed = <String, int>{
  // Primitives that implement the contract: they own the one GestureDetector
  // the rest of the kit builds on.
  'ui_kit/lib/src/forms/pressable.dart': 1,

  // Window chrome and canvas gestures: double-tap to zoom or maximize, drag
  // areas, hit-testing on a canvas. Not controls, so MgPressable does not fit.
  'app/lib/src/window_drag_area.dart': 1,
  'app/lib/src/home/home_screen.dart': 1,
  'shell/lib/src/widgets/workspace_view.dart': 1,
  'shell/lib/src/widgets/workspace_shell.dart': 1,
  'media_editor/lib/src/editor.dart': 2,
  'media_editor/lib/src/ui/filmstrip.dart': 1,
  'app/lib/src/chat/media_viewer.dart': 11,
  'app/lib/src/chat/location_picker.dart': 3,
  'app/lib/src/chat/timeline_view.dart': 2,

  // TODO(ui-contract): hand-made rows and buttons inside ui_kit chat widgets; move
  // them onto MgPressable (separate change, goldens included).
  'ui_kit/lib/src/chat/action_bar.dart': 2,
  'ui_kit/lib/src/chat/chat_header.dart': 1,
  'ui_kit/lib/src/chat/composer_suggestions.dart': 2,
  'ui_kit/lib/src/chat/link_sheet.dart': 2,
  'ui_kit/lib/src/chat/message_menu.dart': 10,
  'ui_kit/lib/src/chat/message_parts.dart': 12,
  'ui_kit/lib/src/chat/pinned_bar.dart': 2,
  'ui_kit/lib/src/chat/selection.dart': 2,
  'ui_kit/lib/src/chat/selection_menu.dart': 4,
  'ui_kit/lib/src/chat/timeline_parts.dart': 2,
  'ui_kit/lib/src/icon_button.dart': 1,
  'ui_kit/lib/src/sidebar/chat_list_tile.dart': 1,
  'ui_kit/lib/src/sidebar/pinned_grid.dart': 2,
  'ui_kit/lib/src/sign_in/sign_in.dart': 2,

  // TODO(ui-contract): hand-made rows, chips and buttons in app, shell, plugins_ui
  // and media_editor screens; replace with MgPressable or a primitive (separate
  // change per screen).
  'app/lib/src/chat/attachment_preview.dart': 3,
  'app/lib/src/chat/audio_player_bar.dart': 6,
  'app/lib/src/chat/checklist_content.dart': 2,
  'app/lib/src/chat/concealed.dart': 2,
  'app/lib/src/chat/contact_picker.dart': 2,
  'app/lib/src/chat/file_content.dart': 8,
  'app/lib/src/chat/forum_topics.dart': 4,
  'app/lib/src/chat/forward_picker.dart': 4,
  'app/lib/src/chat/hashtag_results.dart': 2,
  'app/lib/src/chat/inline_results.dart': 2,
  'app/lib/src/chat/location_content.dart': 2,
  'app/lib/src/chat/media_content.dart': 2,
  'app/lib/src/chat/message_tile.dart': 5,
  'app/lib/src/chat/other_content.dart': 2,
  'app/lib/src/chat/poll_content.dart': 2,
  'app/lib/src/chat/saved_tags.dart': 2,
  'app/lib/src/chat/saved_topics.dart': 2,
  'app/lib/src/chat/send_as.dart': 4,
  'app/lib/src/chat/sponsored_message.dart': 6,
  'app/lib/src/chat/sticker_suggestions.dart': 2,
  'app/lib/src/chat/topic_sheet.dart': 2,
  'app/lib/src/chat/translate_bar.dart': 4,
  'app/lib/src/chat_search/sender_picker.dart': 2,
  'app/lib/src/contacts/people_sheet.dart': 3,
  'app/lib/src/downloads/downloads_bar.dart': 2,
  'app/lib/src/downloads/downloads_sheet.dart': 1,
  'app/lib/src/folders/folder_chat_picker.dart': 2,
  'app/lib/src/folders/folder_editor.dart': 10,
  'app/lib/src/home/sidebar.dart': 3,
  'app/lib/src/links/join_sheet.dart': 2,
  'app/lib/src/plugins/plugin_ui.dart': 2,
  'app/lib/src/privacy/ghost_mode_capsule.dart': 2,
  'app/lib/src/profile/invite_links_sheet.dart': 2,
  'app/lib/src/profile/member_sheets.dart': 2,
  'app/lib/src/profile/new_chat_sheet.dart': 2,
  'app/lib/src/profile/reactions_sheet.dart': 2,
  'app/lib/src/proxy/proxy_editor.dart': 2,
  'app/lib/src/settings/account_page.dart': 1,
  'app/lib/src/settings/appearance_page.dart': 6,
  'app/lib/src/settings/plugins_page.dart': 2,
  'app/lib/src/settings/privacy/user_picker.dart': 2,
  'app/lib/src/settings/settings_style.dart': 2,
  'app/lib/src/settings/shortcuts/shortcuts_page.dart': 2,
  'app/lib/src/settings/stickers/sticker_set_tile.dart': 1,
  'app/lib/src/voice/voice_record_composer.dart': 7,
  'plugins_ui/lib/src/widgets.dart': 2,
};

void main() {
  test('no new hand-made tap areas outside the allowlist', () {
    final found = scanPackages(Directory.current.parent);
    final added = <String>[];
    final stale = <String>[];
    for (final e in found.entries) {
      final max = _allowed[e.key] ?? 0;
      if (e.value > max) added.add('${e.key}: ${e.value} (allowed $max)');
    }
    for (final e in _allowed.entries) {
      final n = found[e.key] ?? 0;
      if (n < e.value) stale.add('${e.key}: ${e.value} -> $n');
    }
    expect(
      added,
      isEmpty,
      reason:
          'Use MgPressable (or MgPrimaryButton, MgTextButton, MgIconButton, '
          'MgSwitch) instead of GestureDetector/InkWell/click-cursor '
          'MouseRegion. See "UI contract" in packages/ui_kit/README.md.',
    );
    expect(
      stale,
      isEmpty,
      reason:
          'Fewer tap areas than the allowlist says: lower or remove '
          'these entries in ui_contract_guard_test.dart.',
    );
  });

  test('the scanner tells controls from plain gesture widgets', () {
    expect(countHandMadeTaps('GestureDetector(onTap: () {}, child: c)'), 1);
    expect(countHandMadeTaps('InkWell(\n onLongPress: f,\n child: c)'), 1);
    expect(countHandMadeTaps('GestureDetector(onPanUpdate: f)'), 0);
    expect(
      countHandMadeTaps(
        'MouseRegion(cursor: SystemMouseCursors.click, child: c)',
      ),
      1,
    );
    expect(countHandMadeTaps('MouseRegion(onEnter: f, child: c)'), 0);
    expect(countHandMadeTaps('// GestureDetector(onTap: f)'), 0);
  });
}
