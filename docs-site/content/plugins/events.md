# Events

Subscribe with `mg.on(event, handler)`. Call it while the plugin loads, not later, and list the event in the manifest's `hooks`. Handlers may be `async`.

```ts
mg.on("message.filter", ({ message }) => {
  if (message.text?.includes("spoiler")) {
    return { filter: "collapse", reason: "Spoiler" };
  }
});
```

## What the app delivers today

The host supports every event below, but the app sends only four so far:

- `message.render.code`
- `message.render.text`
- `message.filter`
- `ui.action`, for the buttons your own plugin drew

Plugins that subscribe to the other events load and run, and never receive a call. `messages.read: chats[]` plugins get no events yet, because the app has no screen for granting chats. Use `all` for now.

## Event list

| Event | Needs | Payload | Return |
|---|---|---|---|
| `app.ready` | | | |
| `chat.opened` | `messages.read: chats[]` or `all` | `{ chatId }` | |
| `message.incoming` | same | `{ message }` | |
| `message.edited` | same | `{ message, oldText? }` | |
| `message.deleted` | same | `{ chatId, messageIds }` | |
| `message.sending` | `composer.write` | `{ chatId, text, replyTo? }` | `{ cancel: true }`, `{ modify: draft }` or nothing |
| `message.render.code` | nothing | `{ message?, language?, code }` | UI nodes |
| `message.render.voice` | `media.read: [voice]` | `{ message }` | UI nodes |
| `message.render.round` | `media.read: [round]` | `{ message }` | UI nodes |
| `message.render.text` (1.1) | `messages.read: chats[]` or `all` | `{ message }` | UI nodes |
| `message.filter` (1.1) | same | `{ message }` | `{ filter: "hide" \| "collapse", reason? }` or nothing |
| `ui.action` | nothing | `{ action, payload?, message? }` | UI nodes |
| `notification.incoming` | `notifications.manage` | `{ chatId, messageId, title, body }` | `{ cancel: true }`, `{ modify: notification }` or nothing |
| `settings.changed` | nothing | `{ key, value }` | |

Events marked 1.1 need `sdk: ^1.1` in the manifest. `{ defer: seconds }` appears in the types for `notification.incoming`, but the host ignores it today.

## Handlers

- Several handlers for one event in one plugin run in registration order. There is no priority.
- For `message.sending` and `notification.incoming`, `{ modify: x }` replaces the payload for the next handler, and `{ cancel: true }` stops the chain and cancels the event. Other event kinds ignore `cancel`.
- For render events, the nodes returned by all handlers are joined into one list.
- For `message.filter`, the strongest answer wins: `hide` over `collapse`. A collapsed message becomes a thin row with the `reason` (up to 100 characters) and a way to expand it. A hidden one is not shown.

## Render events

`message.render.text` draws your nodes below the message text. `message.render.code` hands you one code block, not the message. Without `messages.read`, `message` is at most `{ chatId, id }`, and the app may leave it out. A `code` node is used only when its spans spell exactly the code you received, so you can color a block but never change what it says.

A plugin that hooks `message.render.code` and also has `net` must declare `messages.read: all`.

## Buttons

A `button` node carries an `action` and an optional `payload`. A click reaches your plugin as `ui.action` with the message it was drawn under. The nodes you return replace the ones shown before.

```ts
mg.on("ui.action", async ({ action, message }) => {
  if (action !== "refresh" || !message) return;
  return [{ type: "text", text: "Done", style: "secondary" }];
});
```
