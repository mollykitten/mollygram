# AGENTS.md

Instructions for AI coding agents working in this repository (Hermes Agent, Codex, Claude Code via `CLAUDE.md`). Humans: start with [README.md](README.md) and [CONTRIBUTING.md](CONTRIBUTING.md); this file repeats only what an agent needs at hand and adds the rules that are not written down elsewhere.

## What this is

A custom desktop Telegram client in Flutter for macOS, Windows and Linux. The goal: bring the beauty and convenience of the official macOS Swift client (TelegramSwift) to all three desktop platforms in one codebase, then go further than the official client in look and feel, animation quality and UX, while taking the best from every custom client: exteraGram, Inugram (teidesu's patchset over Telegram Android, with a QuickJS plugin engine like ours), Swiftgram, AyuGram and the rest (`docs/forks-research.md` tracks what is taken and what is not). The layout mirrors Telegram Desktop so nothing has to be relearned; on top of it: liquid glass on the floating layer, spring motion, a sandboxed JavaScript plugin system, privacy extras (ghost mode, locally kept deleted messages and edit history), tabs, split view and a ⌘K command palette. Status: prototype.

Design bar for any UI work: premium. Parity with the official client is the floor, not the target. Match the motion tokens and glass in `packages/ui_kit`, check both themes, and treat jank, abrupt transitions and default-looking widgets as bugs.

Where to look before designing anything:

- `docs/roadmap.md`: the order of work (M1 daily driver, M2 full chat, M3 privacy are in progress) and the drift from the original plan.
- `docs/parity.md`: feature backlog against the official macOS client, with done / partial / missing per feature.
- `docs/plugins.md`: plugin manifest, permissions and sandbox rules.
- `docs/privacy-store.md`: the encrypted local store.
- `docs/calls.md`: calls research.
- `design/directions/README.md`: the four main-window directions; the chosen one is A (rail sidebar) with the title capsule from D.

## Layout

A pub-workspaces monorepo: one `pubspec.lock` at the root, packages under `packages/`, no melos. Dependency direction:

```
tdlib → core → ui_kit → shell / media / media_editor / plugins_ui → app
plugin_host → plugins_ui, app
```

| Package | Contents |
|---|---|
| `packages/tdlib` | `dart:ffi` bindings to td_json, the `td_receive` loop in a background isolate, generated td_api types |
| `packages/calls` | `dart:ffi` to libmgcalls (tgcalls + WebRTC) |
| `packages/core` | Models and state on top of TDLib, no Flutter; the SQLCipher store via drift/sqlite3 |
| `packages/ui_kit` | Shared widgets, glass, theme, motion tokens |
| `packages/media` | Video, video messages, voice messages |
| `packages/media_editor` | Photo and video editor before sending |
| `packages/shell` | Window shell: chat tabs, split view, ⌘K palette (state on `ValueNotifier`) |
| `packages/plugin_host` | JavaScript plugin sandbox on quickjs-ng (git submodule) |
| `packages/plugins_ui` | Plugin settings UI |
| `packages/plugin_sdk` | TypeScript types for plugin authors (`index.d.ts`, not a pub package) |
| `packages/app` | The application. Riverpod; entry point `packages/app/lib/main.dart`, features under `lib/src/` |

Packages with their own README (`tdlib`, `calls`, `shell`, `ui_kit`, `media_editor`, `plugin_host`): read it before changing that package.

## Toolchain

- Flutter is pinned in `.fvmrc`; Dart SDK `^3.13`. Locally run everything through `fvm flutter …`. CI installs the same version from `.fvmrc` and calls `flutter` and `dart` directly, so the commands below differ from CI only by the `fvm` prefix.
- First setup:

  ```sh
  git submodule update --init --recursive
  fvm install
  fvm flutter pub get
  ```

- Run the app on macOS:

  ```sh
  cd packages/app && fvm flutter run -d macos --dart-define-from-file=../../config/telegram.json
  ```

- `config/telegram.json` holds the Telegram API id and hash and is gitignored; the template is `config/telegram.example.json`. Code reads them with `int.fromEnvironment('TELEGRAM_API_ID')`. Never commit real keys.
- The TDLib binary is not built in this repo. Its version is pinned in `packages/tdlib/tdlib.json`; on macOS `packages/app/macos/scripts/bundle_tdjson.sh` downloads `libtdjson` into `packages/tdlib/native/macos` (gitignored). The native test needs `TDJSON_PATH`.

## Checks before a pull request

The same checks CI runs (`.github/workflows/ci.yml`), per package you touched:

```sh
dart format --output=none --set-exit-if-changed packages/<name>
fvm flutter analyze packages/<name>
cd packages/<name> && fvm flutter test        # `dart test` for pure Dart: tdlib, core, calls, plugin_host
dart run packages/tdlib/tool/generate.dart && git diff --exit-code packages/tdlib/lib/src/generated
```

- CI covers `tdlib calls core ui_kit media media_editor shell app`. `plugin_host`, `plugins_ui` and `plugin_sdk` have their own workflow (`plugin_host.yml`) with `dart analyze --fatal-infos` and `flutter analyze --fatal-infos`: infos fail there.
- Pull requests run format, analyze, codegen check and tests on Linux only. Platform builds run after merge, or on a PR with the `full-ci` label (use it for native code and platform folders).
- Changes under `docs/`, `design/` and `website/` do not trigger CI.

## Generated code: regenerate, never hand-edit

- `packages/tdlib/lib/src/generated/td_api.dart` comes from `packages/tdlib/schema/td_api.tl` via `dart run packages/tdlib/tool/generate.dart` (`--fetch` pulls a new schema). Commit the regenerated file.
- `packages/app/lib/l10n/app_localizations*.dart` come from the `.arb` files via `l10n.yaml`. Edit `app_en.arb` and `app_ru.arb`, not the Dart output.
- `packages/app/linux/flutter/*` and `packages/app/windows/flutter/*` registrant files are Flutter's.

## Conventions

- Conventional Commits, type first, scope optional, an emoji may follow the colon: `feat(ui_kit): ✨ add pressable primitive`. Scopes: `app`, `core`, `tdlib`, `ui_kit`, `media`, `shell`, `plugin_host`, `plugin_sdk`, `plugins_ui`, `calls`, `design`, `web`, `docs`, `ci`, `deps`, `release`. Description imperative, lowercase, no trailing period.
- Branches `<type>/<short-description>` off `main`. Never push to `main`. PR title is a Conventional Commit (CI checks it); PRs are squash-merged. UI changes come with screenshots in light and dark themes.
- Versions and `CHANGELOG.md` are produced by release-please from commit messages. Do not bump `packages/app/pubspec.yaml` or `.release-please-manifest.json` and do not edit the changelog by hand.
- English everywhere in the codebase: identifiers, comments, docs, commits, PRs. Doc comments use `///` and explain why.
- The analyzer is strict (`analysis_options.yaml`: strict casts, inference and raw types; `unawaited_futures`, `prefer_final_locals`, `avoid_dynamic_calls`, `cancel_subscriptions`, `close_sinks`). Fix findings instead of suppressing them.
- UI strings: English first, Russian kept in sync. Adding a key to one `.arb` means adding it to the other. In Russian only the first word of a phrase is capitalized («Режим призрака», not «Режим Призрака»).
- Plugin SDK changes are public API: breaking ones get `!` and a `BREAKING CHANGE:` footer.
- Security problems go through `SECURITY.md`, not public issues. License: GPL-3.0.

## How to work here

These rules apply to the agent and to every subtask it delegates; copy them into the brief.

- Search precisely: `rg -n 'pattern' packages/<name> -t dart`, `git grep -n 'pattern' -- '*.dart'`, files by `rg --files | rg name` or `git ls-files`. Read the line range you need. No `cat`, `ls -R` or `grep -r` across the whole repository.
- Reproduce a bug and show the observation (log, command output, screenshot) before changing code. If it cannot be reproduced, say so and ask instead of trying fixes against the symptom.
- Do not infer TDLib behaviour from neighbouring Dart code: check `packages/tdlib/schema/td_api.tl` and the TDLib documentation. The same for the plugin API: `docs/plugins.md` is the contract.
- Long-running processes (`flutter run`, emulators, dev servers) go to the background; stop what you started and list it when done.
- Sensitive areas, where any change needs a review and a careful diff read however small: the sign-in and auth flow, the encrypted store (`packages/core/lib/src/store`), the TDLib FFI layer and `td_receive` loop, the plugin sandbox and its permissions (`packages/plugin_host`), the CI and release workflows.
- Local edits and builds are free. Pushing, merging, rebasing and tagging happen only when asked.
- Report with the verdict first (done / partial / blocked and the question), then changed files, then what was checked and how, then what is left.
