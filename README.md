<p align="center">
  <img src="docs/assets/banner.png" alt="mollygram" width="840">
</p>

<p align="center">
  a desktop telegram client on flutter for macOS, windows and linux. same layout as the official one, plus liquid glass and the stuff it's missing
</p>

<p align="center">
  <a href="https://mollygram.dev">website</a> · <a href="https://docs.mollygram.dev">docs</a> · <a href="https://docs.mollygram.dev/plugins/quick-start/">write a plugin</a>
</p>

<p align="center">
  <a href="https://github.com/mollykitten/mollygram/actions/workflows/ci.yml"><img src="https://github.com/mollykitten/mollygram/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/mollykitten/mollygram?color=D6336C" alt="License"></a>
  <a href="https://github.com/mollykitten/mollygram/commits/main"><img src="https://img.shields.io/github/last-commit/mollykitten/mollygram?color=D6336C" alt="Last commit"></a>
  <img src="https://img.shields.io/badge/status-prototype-D6336C" alt="Status: prototype">
  <a href="https://www.conventionalcommits.org"><img src="https://img.shields.io/badge/Conventional%20Commits-1.0.0-D6336C" alt="Conventional Commits"></a>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white" alt="Dart"></a>
  <a href="https://github.com/tdlib/td"><img src="https://img.shields.io/badge/TDLib-FFI-26A5E4?logo=telegram&logoColor=white" alt="TDLib"></a>
  <img src="https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/Windows-0078D4?logo=windows11&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black" alt="Linux">
</p>

---

layout is the same as telegram desktop, so there's nothing to relearn. on top of it: liquid glass and the features the official client doesn't have.

> [!NOTE]
> early stage, but already works: sign-in, chat list, chats with every message type, tabs, split view and the command palette. guides for users and plugin authors are at [docs.mollygram.dev](https://docs.mollygram.dev). what comes next is in [`docs/roadmap.md`](docs/roadmap.md), the backlog vs the official client in [`docs/parity.md`](docs/parity.md).

## planned features

| | |
|---|---|
| **plugins** | sandbox with explicit permissions declared in the manifest, s/o exteraGram. |
| **privacy** | ghost mode: no read receipts, no "typing", no "online". deleted messages and edit history saved locally. |
| **media** | video messages at 120 fps and up to 640×640, photos and videos go uncompressed by default. |
| **chat workflow** | tabs, split view for two chats, command palette on <kbd>⌘</kbd> <kbd>K</kbd>. |
| **look** | liquid glass only on the floating layer: sidebar, chat header, composer, palette. light and dark themes. |

## stack

| component | tech |
|---|---|
| ui | [Flutter](https://flutter.dev) desktop, stable channel |
| protocol | [TDLib](https://github.com/tdlib/td) via `dart:ffi` |
| plugins | javascript and typescript on [QuickJS-ng](https://github.com/quickjs-ng/quickjs), more in [`docs/plugins.md`](docs/plugins.md) |
| platforms | macOS, windows, linux |

## development

| package | what's in it |
|---|---|
| [`packages/tdlib`](packages/tdlib) | `dart:ffi` bindings to td_json, the `td_receive` loop in a background isolate, td_api types generated from the schema |
| `packages/core` | models and state on top of tdlib, no flutter dependency |
| `packages/ui_kit` | shared widgets, glass, theme |
| `packages/media` | video, video messages, voice messages |
| [`packages/shell`](packages/shell) | window layout: chat tabs, split view, ⌘K command palette |
| [`packages/plugin_host`](packages/plugin_host) | plugin sandbox and the built-in filters and translate plugins |
| `packages/plugins_ui` | plugins settings screen |
| `packages/plugin_sdk` | typescript types for plugin authors |
| `packages/app` | the app itself |

flutter comes through [fvm](https://fvm.app). the version is pinned in [`.fvmrc`](.fvmrc), ci uses the same one. we track latest stable.

```sh
git clone --recurse-submodules https://github.com/mollykitten/mollygram.git
cd mollygram
fvm install
fvm flutter pub get
```

forgot `--recurse-submodules`? run `git submodule update --init --recursive` once, the plugin host builds quickjs from the [quickjs-ng](https://github.com/quickjs-ng/quickjs) submodule.

it's a monorepo on [pub workspaces](https://dart.dev/tools/pub/workspaces), so `pub get` at the root installs deps for every package.

telegram api keys never go into the repo. grab your `api_id` and `api_hash` at [my.telegram.org](https://my.telegram.org), copy [`config/telegram.example.json`](config/telegram.example.json) to `config/telegram.json` (it's gitignored) and run:

```sh
cd packages/app
fvm flutter run -d macos --dart-define-from-file=../../config/telegram.json
```

release builds take the same values from the repo secrets `TELEGRAM_API_ID` and `TELEGRAM_API_HASH`.

## contributing

prs are welcome. read [`CONTRIBUTING.md`](CONTRIBUTING.md) first: we use [conventional commits](https://www.conventionalcommits.org) and [semver](https://semver.org), the changelog is generated from commit messages. be nice, see the [code of conduct](CODE_OF_CONDUCT.md). vulnerabilities go privately, see [`SECURITY.md`](SECURITY.md).

## ci/cd

| workflow | runs on | what it does |
|---|---|---|
| [`ci.yml`](.github/workflows/ci.yml) | push to `main`, prs | `dart format`, `flutter analyze`, `flutter test`, then release builds for macOS, windows and linux |
| [`pr-title.yml`](.github/workflows/pr-title.yml) | prs | checks that the pr title follows conventional commits |
| [`release-please.yml`](.github/workflows/release-please.yml) | push to `main` | keeps a release pr with the next version and `CHANGELOG.md` up to date, merging it tags `v*` and starts the release |
| [`release.yml`](.github/workflows/release.yml) | `v*` tag, release pr merge | builds all three platforms with keys from secrets and attaches the archives to the github release |
| [`plugin_host.yml`](.github/workflows/plugin_host.yml) | changes to the plugin packages | builds quickjs, runs the plugin host tests on all three platforms and tests the plugins screen |
| [`tdlib.yml`](.github/workflows/tdlib.yml) | tdlib version change, manual | builds a universal `libtdjson.dylib` for macOS and publishes it to the `tdlib-<version>` release |

## brand

<img src="docs/assets/icon.svg" alt="Mollygram icon" width="96" align="right">

icon is a white speech bubble with an m on raspberry. the neon wordmark is promo only: readme, website, channel. the app itself has no neon.

| color | light | dark |
|---|---|---|
| default accent | ![](https://img.shields.io/badge/-%230071E3-0071E3) | ![](https://img.shields.io/badge/-%230A84FF-0A84FF) |
| raspberry accent (optional) | ![](https://img.shields.io/badge/-%23D6336C-D6336C) | ![](https://img.shields.io/badge/-%23FF5C93-FF5C93) |
| outgoing bubbles, raspberry theme | ![](https://img.shields.io/badge/-%23FCE4EE-FCE4EE) | ![](https://img.shields.io/badge/-%235A2338-5A2338) |
| neon, promo only | ![](https://img.shields.io/badge/-%23FF2E88-FF2E88) | ![](https://img.shields.io/badge/-%2312070F-12070F) |

accent is system blue by default, raspberry is a toggle in settings. icon sources are in [`docs/assets`](docs/assets).

## design mockups

`design/` has the sources of the interactive mockups: main window, chat media and files, plugins, command palette, settings. each one switches between english and russian. they're in the design canvas format (`.dc.html`) so a plain browser won't open them.

## license

[GPL-3.0](LICENSE)
