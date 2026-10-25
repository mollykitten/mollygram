# `mg` API

`mg` is a global, frozen object. Its types are in `packages/plugin_sdk/index.d.ts`. Calls that return a `Promise` run in the app, after the app checks your permissions.

| Call | Returns | Needs |
|---|---|---|
| `mg.on(event, handler)` | | Call during load only |
| `mg.command("/name", handler)` | | A matching entry in `commands`; during load only |
| `mg.settings.get<T>(key)` | `T`, synchronous | |
| `mg.storage.get<T>(key)` | `Promise<T \| null>` | `storage` |
| `mg.storage.set(key, value)` | `Promise<void>` | `storage` |
| `mg.storage.delete(key)` | `Promise<void>` | `storage` |
| `mg.messages.get(chatId, messageId)` | `Promise<Message \| null>` | `messages.read` |
| `mg.messages.history(chatId, { limit?, before? })` | `Promise<Message[]>` | `messages.read` |
| `mg.messages.translate(chatId, messageId, { to })` (1.1) | `Promise<{ text }>` | `messages.read` |
| `mg.text.detectLanguage(text)` (1.1) | `Promise<{ language, confidence } \| null>` | |
| `mg.app.locale()` (1.1) | The UI language, `"en"` or `"ru"` | |
| `mg.composer.insert(text)` | `Promise<void>` | `composer.write` |
| `mg.media.transcribe(media, { language? })` | `Promise<{ text, language }>` | `media.read` for the media kind |
| `mg.net.fetch(url, init?)` | `Promise<FetchResponse>` | `net` |
| `mg.ui.toast(text)` | `Promise<void>` | |
| `mg.log(...)`, `console.log/info/warn/error(...)` | | |

## Details

- **Storage.** Keys are strings of 1 to 128 characters. Values are JSON. A write that would exceed the manifest's `storage` size fails with `quota_exceeded` and changes nothing. Writing `null` deletes the key.
- **Translation.** `messages.translate` uses Telegram's own translation and can fail with `translation_failed`.
- **Language detection.** `mg.text.detectLanguage` runs on the device, takes up to 4000 characters and returns `null` when unsure.
- **Transcription.** The app recognizes speech on the device. The plugin decides when.
- **Fetch.** `init` takes `method` (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`), `headers` and `body` (a string or an object). The response has `status`, `headers` and `text`. No cookies are sent.
- **Toast.** `mg.ui.toast` is accepted and shows nothing yet.
- **Log.** Lines show on the plugin's page in **Settings → Plugins**: the last 200 of this run, each cut to 1000 characters.

## Types

```ts
type ChatId = number;
type MessageId = number;

interface MediaRef {
  kind: "voice" | "round" | "photo" | "video" | "document";
  fileId: string;
  duration?: number;
}

interface Message {
  chatId: ChatId;
  id: MessageId;
  senderId: number;
  date: number;
  text?: string;
  media?: MediaRef;
  outgoing: boolean;
}
```

The global `Mg` namespace has all of them, for example `Mg.Message` and `Mg.UiNode`.

## Errors

A failed host call throws an `Error` with a `code` property:

| Code | Meaning |
|---|---|
| `permission_denied` | The manifest does not grant it |
| `bad_argument` | Wrong argument |
| `no_method` | Unknown method |
| `host_failure` | The host failed |
| `quota_exceeded` | Storage is full |
| `translation_failed` | Telegram could not translate |
| `unavailable` | The app does not provide it yet |

```ts
try {
  await mg.storage.set("k", "v");
} catch (e) {
  mg.log("storage failed", (e as { code?: string }).code ?? String(e));
}
```
