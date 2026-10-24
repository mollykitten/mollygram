# Tabs and split view

## Tabs

- Press ⌘T or select **+** in the tab strip to open an empty tab. The tab strip appears once you have two or more tabs.
- Close a tab with ⌘W, the cross on the tab, or a middle click.
- Switch tabs with ⌃Tab and ⌃⇧Tab, or jump to tab N with ⌘1 to ⌘8. ⌘9 goes to the last tab.
- Closing the last tab leaves one empty tab. Closing the active tab activates its right neighbour, or the left one for the last tab.
- **Close other tabs** is available in the command palette.

A tab is titled with its chat name, or with both names in a split.

## Split view

A tab can show two chats side by side, never more.

1. Press ⌘\ or run **Open second chat in split view** from the palette. An empty pane opens on the right and takes focus.
2. Open a chat in it. Hold ⌘ when you press Enter in the palette to open the chosen chat in the split.
3. Drag the divider to resize. The panes keep between 20% and 80% of the width.
4. Move focus between the panes with ⌘⌥← and ⌘⌥→.
5. Press ⌘\ again to close the split and keep the focused chat. ⌘W closes the focused pane.

**Swap chats in split view** is in the palette.

A chat is never shown twice in one tab. If it is open already, Mollygram brings it forward.

## Opening a chat from the palette

| Key | Where the chat opens |
|---|---|
| Enter | The current pane |
| ⌘Enter | The split |
| ⌥Enter | A new tab |

## Layout restore

Mollygram saves your tabs, panes, focus and divider position to `workspace.json` in the account's folder, and restores them at the next start. Each account has its own layout. Chats that no longer exist are dropped. A damaged file gives an empty window. Logging out clears the layout.
