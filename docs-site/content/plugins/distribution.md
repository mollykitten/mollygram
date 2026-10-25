# Distribution

## Today

Share the plugin folder: `manifest.yaml` and `index.js`. A user installs it with **Settings → Plugins → Install from file…** and selects `manifest.yaml`. Other files are not accepted.

The app checks the manifest and the script, shows the permission list, and copies the folder to its own `plugins/bundles/<id>` folder once the user allows the access. After that the plugin no longer depends on the original files. Nothing is copied until the user allows it.

## Updates

Install a folder with the same `id` and a higher `version`. The app refuses the same or an older version. A newer version that asks for nothing new replaces the old one at once. One that asks for more access waits on the plugin's page until the user reviews it, and the old version keeps running.

## Built-in plugins

The app ships with plugins built the same way, in `packages/plugin_host/builtin`. They are good examples:

- **Filters** (`dev.mollygram.filters`) hides or collapses advertising and messages with your keywords, using `message.filter`.
- **Code highlight** (`dev.mollygram.codehighlight`) colors code blocks, using `message.render.code`.

A third one, **Translate**, is not installed. Its sources stay in `builtin/translate` as an example of `message.render.text`, `mg.text.detectLanguage` and `mg.messages.translate`.

Each built-in plugin compiles with `npx -p typescript@5.9 tsc -p .` in its folder.

## Later

A catalog with a signed index is planned. It will show permissions before install and never load code from the network at runtime.
