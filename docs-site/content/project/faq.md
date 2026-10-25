# FAQ

## Is Mollygram an official Telegram client?

No. Mollygram is an independent open source project. It uses Telegram's public client library, TDLib, and the regular Telegram API.

## Can using it put my account at risk?

Telegram's API terms apply to every app that uses an `api_id`, and Telegram decides how it treats an account. Mollygram does not promise anything on Telegram's behalf. The app is unreleased and young. If your account matters a lot, try it first on a spare account. Report any account problem you suspect comes from the app in a [GitHub issue](https://github.com/mollykitten/mollygram/issues).

## Why do I need my own `api_id`?

Telegram issues an `api_id` and `api_hash` per app and developer, on [my.telegram.org](https://my.telegram.org). Mollygram does not ship one, so a build from source uses yours. See [Install](../start/install.md).

## How is it different from Telegram Desktop?

Mollygram adds tabs and split view, a ⌘K command palette, ghost mode, saved deleted messages and a plugin system. It does not have everything the official client has: see [What is Mollygram](../start/what-is-mollygram.md) for the status, and [What's next](whats-next.md) for the plan.

## How is it different from exteraGram?

exteraGram is an Android client whose plugins are written in Python and hook into the app's internals. Mollygram is a macOS client, and its plugins are JavaScript in a sandbox. A plugin declares permissions, the user allows them at install, and a plugin only talks to the app through the [`mg` API](../plugins/mg-api.md). exteraGram plugins do not run in Mollygram.

## Where is my data stored?

On your Mac, in the app's Application Support folder, one folder per account. Encryption keys sit in the macOS Keychain. See [Sign in](../start/sign-in.md).

## Which platforms are supported?

macOS now. Windows and Linux come after the macOS release.

## Is it free?

Yes. Mollygram is open source under GPL-3.0.
