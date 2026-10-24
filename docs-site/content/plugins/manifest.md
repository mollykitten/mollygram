# Manifest

Every plugin has a `manifest.yaml` next to its code.

```yaml
id: com.example.summary
name: Summary
version: 1.0.0
author: Your name
description: Summarizes the current chat.
runtime: js
sdk: ^1.1
main: index.js
permissions:
  messages.read: on_command
commands:
  - { name: /summary, title: Summarize current chat }
settings:
  - { key: short, type: toggle, label: Short summary, default: false }
```

## Fields

| Field | Required | Rules |
|---|---|---|
| `id` | yes | Reverse domain notation in lowercase, at least three parts: `com.example.summary`. Letters, digits and hyphens. The id names the plugin's folder, so `con`, `prn`, `aux`, `nul`, `com1`–`com9` and `lpt1`–`lpt9` are not allowed as a part. |
| `name` | yes | Up to 40 characters. |
| `version` | yes | Semver: `1.0.0`, `1.2.0-beta.1`. |
| `runtime` | yes | `js`. No other value. |
| `sdk` | yes | `^1.0` or `^1.1`. The major version must be 1 and the minor no higher than the app's SDK (1.1 today). Events and APIs marked 1.1 need `^1.1`. |
| `main` | no | Path of the script inside the plugin folder. Defaults to `index.js`. Must end in `.js` and must not leave the folder. |
| `author` | no | Non-empty string. |
| `description` | no | Non-empty string. |
| `permissions` | no | See [Permissions](permissions.md). |
| `hooks` | no | List of events the plugin subscribes to. See [Events](events.md). |
| `commands` | no | List of `{ name, title, shortcut? }`. |
| `settings` | no | List of setting definitions. |

An unknown field, permission or hook makes the manifest invalid. The app lists every error at install time.

## Hooks

`mg.on` accepts only events you list in `hooks`. Three events need no declaration: `ui.action`, `settings.changed` and `app.ready`. A hook that needs a newer SDK than your `sdk` field, or a permission you did not declare, is an error.

## Commands

`name` starts with `/`, then a lowercase letter, then up to 31 lowercase letters, digits or underscores. `title` is the text in the command palette. Register the handler with `mg.command("/summary", handler)` while the plugin loads. The commands of enabled plugins appear in the ⌘K palette and run in the chat in front.

The `shortcut` field is accepted and shown on the plugin's page. The app does not bind it yet.

## Settings

Each setting has a `key` and a `label`. The user edits them on the plugin's page, and the plugin reads them with `mg.settings.get(key)`.

| `type` | Fields | Default |
|---|---|---|
| `toggle` | | A boolean, `false` if omitted |
| `text` | | A string |
| `select` | `options`: a non-empty list of `{ value, label }` | Must be one of the option values |

## Package limits

- The folder contains `manifest.yaml` and the script. Imports, `require` and modules do not work.
- The script is at most 2 MB.
- Symlinks that point outside the folder are rejected.
