# Quick start

Build a plugin that shows a word count under long messages. It takes about ten minutes and uses the same sandbox, permissions and build as the plugins that ship with Mollygram.

A plugin is a folder with two files:

```
word-count/
  manifest.yaml
  index.js        # one file, no imports
```

## 1. Write the manifest

```yaml title="manifest.yaml"
id: com.example.wordcount
name: Word count
version: 1.0.0
runtime: js
sdk: ^1.1
permissions:
  messages.read: all
hooks:
  - message.render.text
settings:
  - key: min
    type: select
    label: Show for messages of at least
    default: "50"
    options:
      - { value: "20", label: 20 words }
      - { value: "50", label: 50 words }
      - { value: "100", label: 100 words }
```

`message.render.text` needs `messages.read`. Use `all`: the app has no screen yet for granting single chats, so `chats[]` plugins receive no events. Every field is described in [Manifest](manifest.md).

## 2. Write the plugin in TypeScript

```ts title="src/index.ts"
function words(text: string): number {
  return text.split(/\s+/).filter(Boolean).length;
}

mg.on("message.render.text", ({ message }) => {
  const count = words(message.text ?? "");
  const min = Number(mg.settings.get<string>("min"));
  if (count < min) return;
  return [{ type: "text", text: `${count} words`, style: "secondary" }];
});
```

`mg` is a global object. The handler returns a list of UI nodes, and the app draws them under the message text with its own widgets. A plugin never draws anything itself. See [Declarative UI](declarative-ui.md).

## 3. Compile

The types live in `packages/plugin_sdk/index.d.ts` in the Mollygram repository. Point `tsconfig.json` at that file, adjusting the path to your checkout:

```json title="tsconfig.json"
{
  "compilerOptions": {
    "target": "ES2023",
    "lib": ["ES2023"],
    "types": [],
    "strict": true,
    "outDir": ".",
    "rootDir": "src"
  },
  "files": ["../mollygram/packages/plugin_sdk/index.d.ts", "src/index.ts"]
}
```

```bash
npx -p typescript@5.9 tsc -p .
```

This writes `index.js` next to `manifest.yaml`. Any bundler works if it outputs a single script (an IIFE) with no `import` or `require`.

## 4. Install

1. Open **Settings → Plugins**.
2. Choose **Install from file…** and select `manifest.yaml`.
3. Read the access list on the consent sheet and allow it. `messages.read: all` gets a separate warning.

Open a chat with a long message. The word count appears under it. Open the plugin's page in **Settings → Plugins** to change the setting and to read the plugin's log.

## A bigger example

`packages/plugin_host/example/transcribe` in the repository adds a "Transcribe" button under voice messages. It uses `media.read`, `storage` and `ui.action`. The app does not yet send the voice and round message events, so that plugin loads but shows nothing today. See [Events](events.md) for what the app delivers now.

## Next

- [Manifest](manifest.md), [Permissions](permissions.md), [Events](events.md), [`mg` API](mg-api.md)
- [Sandbox limits](sandbox-limits.md), [Distribution](distribution.md)
