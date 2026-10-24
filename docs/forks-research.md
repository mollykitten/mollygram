# What to take from Telegram forks

A review of AyuGram, Kotatogram, Forkgram, Materialgram, 64Gram, Nagram/Nekogram, Octogram, Swiftgram, Unigram and Inugram. Based on their READMEs as of 2026-10-12 (Inugram: 2026-10-24); items that could not be verified are marked "?". Cross-checked against the plan and the parity table (stages 2–8).

## Licenses

Mollygram is distributed under GPL-3.0. We do not copy fork code; we take only ideas and user-facing behavior, so there is no licensing issue. If we ever need to reuse code, keep in mind:

- MIT (Inugram, a patchset over Telegram Android): permissive, but the patches apply to GPL-2.0 Telegram Android code, so we copy no code anyway; ideas only.
- GPL-3.0 compatible: tdesktop and its forks (AyuGram Desktop?, 64Gram, Materialgram, Forkgram?, Kotatogram?), Nagram, Unigram.
- GPL-2.0-only (Nekogram, Octogram, AyuGram4A, the Telegram macOS client) is not directly compatible with GPL-3.0.
- Trademarks: the Telegram name and logo cannot be used, and Nagram and several others require forks to be renamed. Our own `api_id` is mandatory, as planned.

## Feature list

Effort: S up to a week, M 1–3 weeks, L more.

| # | Feature | Found in | Why we want it | Effort | Stage |
|---|---------|----------|----------------|--------|-------|
| 1 | Ghost mode: don't send read receipts, "typing", "online" | AyuGram | The main privacy item, already in the plan | M | 5 |
| 2 | Reading without marking as read | AyuGram | Part of ghost mode, a separate per-chat toggle | S | 5 |
| 3 | Keeping deleted messages, marked as deleted | AyuGram | In the plan, own database | M | 5 |
| 4 | Edit history | AyuGram | In the plan; needs "edited/deleted" marks with a configurable style | S | 5 |
| 5 | Forwarding without the author and to several chats at once | Kotatogram, Forkgram, Cherrygram? | A small everyday feature missing from the official client | S | 3 |
| 6 | Sending and forwarding files uncompressed, photo quality and voice bitrate settings | Materialgram, Nekogram? | Matches our priority on attachment quality | M | 6 |
| 7 | Local chat folders | Kotatogram | Folders with no limit and no server; fits the workspace model | M | 4 |
| 8 | Message filters (hide ads, spam, by keyword) | AyuGram4A | A good first built-in plugin on the `message.render` hook | M | 7 |
| 9 | Inline message translation | AyuGram, Swiftgram, Nagram | A Premium feature in the official client, free for us via a plugin | M | 7 |
| 10 | Hiding the phone number in the profile, settings and header | Materialgram | Small, helps with screenshots, nearly free | S | 5 |
| 11 | Streamer mode: hide sensitive data while screen sharing | AyuGram Desktop | Complements privacy and the command palette | S | 5 |
| 12 | Choice of UI font and size, compact chat list | AyuGram, Kotatogram | Part of appearance settings; our design remains the default | S | 3 |
| 13 | Recent chats, "jump to first message", search for selected text from the context menu | Forkgram | Quick commands in the action registry, shown in the ⌘K palette | S | 4 |
| 14 | "Delete for everyone" by default, bulk deletion of more than 100 messages | Forkgram, Materialgram (experimental) | Convenience; bulk deletion needs careful handling of API limits | S | 3 |
| 15 | Noise suppression and voice enhancement while recording | Nagram | Fits into video and voice message recording | L | 6 |
| 16 | Plugin catalog and catalog bot | exteraGram? | Distribution idea: a plugin catalog with manifests and permissions; we do not adopt compatibility | M | 7 |
| 17 | Custom text replacements | Kotatogram | A simple setting, useful in the composer | S | 3 |
| 18 | Syncing saved deleted messages, edit history and state across devices (AyuSync) | AyuGram4A | Decided: we build it. Needs a server or self-hosting, client-side encryption | L | after release |
| 22 | Optional tweaks: nearly every addition lives under one settings section and can be turned off to get the stock experience; "debloat" patches hide stock features behind a toggle | Inugram | A design rule for our settings: every non-stock behavior has a switch and a stock fallback | S | 3 |
| 23 | Searchable settings index, settings import/export, cloud sync of settings | Inugram | Settings will be large; search and export keep them manageable. Sync piggybacks on item 18 | M | 4 |
| 24 | Strip tracking parameters from links, resolve redirects, web preview tweaks | Inugram | Small privacy win in the link handler | S | 5 |
| 25 | Message menu extras: details, repeat, a customizable context menu; chat menu: jump by ID, recent actions, go to beginning | Inugram, Forkgram | Same family as item 13: actions in the registry, shown in the ⌘K palette; the menu layout is user-configurable | S | 4 |
| 26 | Search filters by media type and sender | Inugram | Fits global search and the palette | M | 4 |
| 27 | Higher selection limit, bulk actions on selected messages | Inugram | Complements item 14 | S | 3 |
| 28 | Pull-down action on the chat list (archive, Saved Messages, search or nothing); folder display and unread-counter modes | Inugram | Cheap customization of the chat list | S | 4 |
| 29 | Annoyance toggles: hide trending stickers, AI features, stories, bot commands, server suggestions, upsells | Inugram | Matches the "removed annoyances" idea; each one is a plain setting | S | 3 |
| 30 | Profile extras: estimated registration date, join date | Inugram | Information from public data; the date is an estimate and labeled so | S | 5 |
| 31 | Edit diffs in the admin log, extra event details | Inugram | Useful for admins; builds on item 4 | S | 6 |
| 32 | Per-account passcodes, hidden accounts, panic code, "paranoia" mode (hide selected chats and secret chats, silence them) | Inugram | A local app lock; hiding and silencing is local only. The exit code and hidden chats must stay recoverable, so a lost code is explained in the UI | L | 5 |
| 33 | Biometric confirmation for destructive actions, call and reaction confirmations | Inugram | Safety against accidental taps; macOS Touch ID, Windows Hello | S | 5 |
| 34 | Font stack with fallbacks, a separate monospace font | Inugram | Extends item 12 | S | 3 |
| 35 | Motion tweaks: speed multiplier, reduced menu motion | Inugram | Pairs with the motion tokens in `ui_kit` and reduce-motion support | S | 3 |
| 36 | Plugin engine design: QuickJS runtime, grants in the manifest shown before install (scoped, e.g. `fetch(host)`, `fs(200mb)`, `invokeRpc` per TL method, `onUpdate` per constructor), `not-granted` errors, `interceptRpc`/`interceptUpdate`/`interceptSendMessage`, declarative UI, JS subset "routines" | Inugram | Ideas for the API only, nothing is copied. See the comparison below | M | 7 |

Inugram sources: [README](https://github.com/teidesu/inugram) (MIT, patchset managed with stgit, patch types `bugfix`/`feature`/`debloat`/`hooks`/`misc`, "users can disable the custom tweaks"), [FEATURES.md](https://github.com/teidesu/inugram/blob/main/FEATURES.md) (items 23–35), [sdk/README.md](https://github.com/teidesu/inugram/blob/main/sdk/README.md) and [sdk/docs/grants.md](https://github.com/teidesu/inugram/blob/main/sdk/docs/grants.md) (item 36). Its default states for individual toggles are not listed in FEATURES.md (marked "?"); the plugin API is described by its authors as experimental.

Item 36 compared with `docs/plugins.md` (ideas to evaluate, not decisions):

- Permission scopes. Inugram scopes a grant by host, quota, TL method or update constructor; a grant without a scope covers everything. Ours are coarser (`messages.read: all` and the like). Worth considering scoped `network` hosts and a quota (we already have a `storage` size).
- Escalation. Inugram has no runtime prompt: more access means an update the user approves, as in our `PermissionSet.escalationsFrom`. Same model, so no change.
- Strictness. Inugram ignores unknown grant names (the plugin installs without them) and a linter warns; we reject an unknown permission. We keep ours.
- Interception. `interceptRpc` and `interceptUpdate` are separate grants from observing; we have `message.send` with cancel/modify. Compare granularity before adding RPC-level hooks (item 8 filters need only `message.render`).
- Declarative UI and "routines" (a JS subset compiled to an IR and run by the host, for work that must not wait on the engine). Compare with our declarative UI and the isolate limits.
- Tooling. A CLI (`inu check`), published typings and a porting skill from exteraGram plugins; the typings and a manifest linter are worth having, the porting skill conflicts with our decision not to adopt exteraGram compatibility.
- Escape hatches: `unsafe.jvm`/`unsafe.xposed` hooks into the host. Not for us (see below).

## Risky, but we take them

Project owner's decision: we take them. All of them are client-side, each behind its own toggle in settings, off by default, with an explanation of the risk.

| # | Feature | Found in | Note | Effort | Stage |
|---|---------|----------|------|--------|-------|
| 19 | Local Premium: shows the Premium UI on the client | AyuGram | Server-side features (limits, speed, translation) will not work; the settings say so | S | 5 |
| 20 | Screenshots in secret chats | AyuGram4A | The other party enabled protection on purpose; we show a warning | S | 5 |
| 21 | "Expire" button for TTL photos and videos, without emulator detection | AyuGram4A | Bypasses client restrictions; emulator detection is irrelevant on desktop | S | 5 |

## Not taking

- **exteraGram plugin compatibility**: decided earlier.
- **Inugram `unsafe.*` plugin grants** (`jvm`, `xposed`, `invokeRaw`, `disableApiFiltering`): they bypass the plugin sandbox and hook the host; our plugins stay inside the permission model.
- **Inugram Android-only features** (Monet and Material You theming, navigation drawer and bottom tabs, HD Bluetooth audio, launcher shortcut, native hooking via LSPlant, in-app APK updater): no desktop counterpart or the platform covers it.
- **Inugram patch infrastructure** (stgit patchset over Telegram Android): not applicable, we are not a fork.

## ToS risks

Not verified with Telegram directly; assessed based on fork practice. Items 19–21 are the riskiest: Telegram may restrict the account or the api_id, and these features mislead the other party. Ghost mode, keeping deleted messages and hiding read receipts may be seen as interfering with expected behavior, but large forks with their own `api_id` ship them. All of this is done at the client level without changing the protocol. Recommendation: state plainly in the README that these are client-side features, and provide a single "safe mode" toggle.

## Decisions

1. Saved deleted messages are synced across devices (item 18), via a server or self-hosting, with data encrypted on the client.
2. Local Premium and protection bypasses are taken (items 19–21), behind toggles that are off by default.
3. Filters and translation are built as our own built-in plugins (items 8, 9).
4. Inugram: we take its "every tweak can be switched off" rule and the QoL items 23–35; its plugin grants model is compared with `docs/plugins.md` (item 36) for ideas only, with no code or API compatibility.
