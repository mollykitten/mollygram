# mollygram_shell

the window layout of mollygram: chat tabs, split view and the ⌘K command palette.

![command palette](../../docs/assets/shell/palette_light.png)

## workspace instead of routes

the window has no route stack. its state is a `Workspace`: a list of tabs, each with one or two panes, and each pane shows one chat (or waits for one). every change is a pure function on an immutable value, held by a `WorkspaceController`:

```dart
final workspace = WorkspaceController();
workspace.open(chatId);                              // ⏎  focused pane
workspace.open(chatId, target: OpenTarget.split);    // ⌘⏎ next to the current chat
workspace.open(chatId, target: OpenTarget.newTab);   // ⌥⏎ a new tab
```

rules that keep it predictable:

- a chat that's already open is revealed instead of being opened twice. split view only avoids duplicates inside the active tab.
- ⌘W closes the focused half of a split view first, then the tab. closing the last tab leaves one empty tab.
- closing the active tab activates its right neighbour, like in browsers. ⌘9 is always the last tab.
- `toJson` / `Workspace.fromJson` save and restore the layout, malformed data falls back to one empty tab.

## the shell widget

`WorkspaceShell` draws the sidebar slot, the tab strip (only with two or more tabs), the panes with a draggable divider (double click resets it), and the palette. it reads chats only through the `ChatDirectory` interface, `MockChatDirectory` covers tests and development until the TDLib-backed directory lands.

```dart
WorkspaceShell(
  controller: workspace,
  directory: directory,
  sidebar: const ChatList(),
  sidebarWidth: 320,
  commands: [/* app and plugin commands */],
  paneBuilder: (context, chat, focused) =>
      chat == null ? EmptyPane(strings: strings) : ChatView(chat),
);
```

## shortcuts

| keys | action |
|---|---|
| ⌘K | command palette |
| ⌘T | new tab |
| ⌘W | close the split pane or the tab |
| ⌘\ | split view on or off |
| ⌘1 … ⌘9 | go to a tab, ⌘9 is the last one |
| ⌃⇥ / ⌃⇧⇥ | next and previous tab |
| ⌘⌥← / ⌘⌥→ | focus the left or right pane |

on windows and linux ⌘ is Ctrl and ⌥ is Alt.

## palette

the palette opens and closes instantly and doesn't dim the window. prefixes are the same in every language: `>` commands, `@` people, `#` messages. built-in commands also match their title in the other UI language. other packages add commands through `WorkspaceShell.commands`.

strings live in `ShellStrings` in english and russian. both implement one interface, so a missing translation won't compile.

## screenshots

`MG_SHOT_DIR=/tmp/shots flutter test test/screenshot_test.dart` renders the window in light and dark themes, with and without the palette.
