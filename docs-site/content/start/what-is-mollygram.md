# What is Mollygram

Mollygram is an open source Telegram client for macOS, written in Flutter on top of TDLib, Telegram's own client library. It uses your Telegram account and talks to the regular Telegram servers.

## How it differs from Telegram Desktop

- **Tabs and split view.** Open several chats in tabs, or two chats side by side in one tab. The layout comes back after a restart. See [Tabs and split view](../using/tabs-and-split-view.md).
- **Command palette.** Press ⌘K to jump to a chat, a person, a message or a command. See [Command palette](../using/command-palette.md).
- **Ghost mode.** Turns off read receipts, typing and online status in one switch.
- **Saved deleted messages.** When a chat partner deletes a message, you can keep it, with its edit history, in an encrypted local store.
- **Plugins.** Small JavaScript plugins run in a sandbox and ask for permissions before they touch anything. See [Plugin authors](../plugins/quick-start.md).

## Status

The app has not been released. You can build it from source today ([Install](install.md)). Release builds will appear on GitHub Releases.

What works now:

- Sign in with QR code, phone number and two-step password, with up to three accounts.
- Chat list with folders, chat view, replies, edits, forwards, reactions, polls, voice messages, stickers, GIFs.
- Tabs, split view and the command palette.
- Ghost mode, saved deleted messages and edit history.
- The plugin sandbox with permissions, and two built-in plugins.

What does not work yet:

- Picture-in-picture.
- Calls and screen sharing. Research is done, the app has no call UI.
- Settings parity with Telegram Desktop, and chat and account management, are still in progress.
- Windows and Linux builds. macOS comes first.

See [What's next](../project/whats-next.md) for the order of work.
