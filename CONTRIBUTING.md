# contributing to mollygram

thanks for being here. this doc covers how the project is organized and what a change needs before it can be merged.

by taking part you agree to the [code of conduct](CODE_OF_CONDUCT.md). security issues go through [`SECURITY.md`](SECURITY.md), not public issues.

## getting started

flutter is managed with [fvm](https://fvm.app), the version is pinned in [`.fvmrc`](.fvmrc).

```sh
git clone --recurse-submodules https://github.com/mollykitten/mollygram.git
cd mollygram
fvm install
fvm flutter pub get
```

already cloned without submodules? run `git submodule update --init --recursive`, the plugin host builds quickjs from the `quickjs-ng` submodule.

run the app from `packages/app` with your own telegram api keys (see the [readme](README.md#development)):

```sh
cd packages/app
fvm flutter run -d macos --dart-define-from-file=../../config/telegram.json
```

the repo is a [pub workspace](https://dart.dev/tools/pub/workspaces): one `pub get` at the root resolves every package under `packages/`. the [readme](README.md#development) has the package layout and the api keys setup.

before opening a pr, run the same checks as ci for the packages you touched:

```sh
dart format packages/<name>
fvm flutter analyze packages/<name>
cd packages/<name> && fvm flutter test   # or `dart test` for pure dart packages
```

if you change the tdlib schema or the generator, regenerate the bindings with `dart run packages/tdlib/tool/generate.dart` and commit the result.

## language and style

- english is the language of the codebase: identifiers, comments, docs, commit messages, issues and prs.
- dart code follows [effective dart](https://dart.dev/effective-dart) and is formatted with `dart format`. doc comments use `///`, start with a one-sentence summary and explain *why* instead of restating the code.
- ui strings are written in english first. every user-facing string has a russian translation that stays in sync with the english one. in russian strings only the first word is capitalized ("Режим призрака", not "Режим Призрака").

## branches

work happens on short-lived branches off `main`, named `<type>/<short-description>`, for example:

```
feat/chat-tabs
fix/circle-playback-stutter
docs/plugin-permissions
```

`main` is always releasable. don't push to it directly.

## commit messages

mollygram follows [conventional commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

- **type** is one of:

  | type | use for | version bump |
  |---|---|---|
  | `feat` | a new user-facing feature | minor |
  | `fix` | a bug fix | patch |
  | `perf` | a performance improvement | patch |
  | `refactor` | code change that neither fixes a bug nor adds a feature | none |
  | `docs` | documentation only | none |
  | `test` | adding or fixing tests | none |
  | `build` | build system, dependencies, flutter or tdlib version | none |
  | `ci` | ci and release workflows | none |
  | `style` | formatting, no code change | none |
  | `chore` | anything else that doesn't touch shipped code | none |
  | `revert` | reverting an earlier commit | depends |

- **scope** is optional and names the area: `app`, `core`, `tdlib`, `ui_kit`, `media`, `shell`, `plugin_host`, `plugin_sdk`, `plugins_ui`, `calls`, `design`, `web`, `docs`, `ci`, `deps`, `release`.
- **description** is imperative, lowercase, no trailing period: `add split view for two chats`, not `Added split view.`
- a gitmoji may follow the colon if you like: `feat(app): ✨ add split view for two chats`. keep the type first, the changelog and release tooling read it.
- breaking changes add `!` after the type or scope and explain the change in a `BREAKING CHANGE:` footer.

examples:

```
feat(app): add command palette on cmd+k
fix(tdlib): close the client when the receive isolate exits
perf(media): reuse the decoder between video messages
docs(plugins): describe the storage permission
feat(plugin_sdk)!: rename onMessage to onMessageRender

BREAKING CHANGE: plugins must subscribe to message.render instead of message.
```

## pull requests

- keep a pr focused on one change. fill in the [pr template](.github/pull_request_template.md).
- **the pr title must be a conventional commit** (`feat(app): add chat tabs`). ci checks it, prs are squash-merged and the title becomes the commit on `main`.
- ci must be green: format, analyze, codegen check and tests. prs run these on linux only, the macOS, windows and linux builds run after merge to `main`. add the `full-ci` label to run the builds on a pr, for example when you touch native code or platform folders.
- ui changes need screenshots or a short recording, in both light and dark themes.
- new features need tests where it's practical, bug fixes need a test that reproduces the bug.

## versioning and releases

mollygram follows [semver](https://semver.org). while the version is `0.x`, a minor bump may contain breaking changes.

releases are automated with [release-please](https://github.com/googleapis/release-please):

1. every push to `main` updates a release pr titled `chore: release <version>`. it bumps the version in [`packages/app/pubspec.yaml`](packages/app/pubspec.yaml) and [`.release-please-manifest.json`](.release-please-manifest.json) and adds new entries to [`CHANGELOG.md`](CHANGELOG.md), all derived from commit messages.
2. merging the release pr creates the `v<version>` tag and the github release.
3. the [release workflow](.github/workflows/release.yml) builds macOS, windows and linux and attaches the archives to that release.

don't edit `CHANGELOG.md` or version numbers by hand, write a good commit message instead.

before the first app release, keep [`.release-please-manifest.json`](.release-please-manifest.json) empty (`{}`): it tracks released versions, not the dev version in `pubspec.yaml`. the [`initial-version` setting](release-please-config.json) picks `0.1.0` for the first release pr, so leave the app's `0.1.0+1` dev version alone until that pr updates it. this is release-please's documented [manual bootstrap](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md#bootstrap-manually). after the first release pr is merged, release-please owns the manifest too.

## plugins

the plugin api and manifest format are documented in [`docs/plugins.md`](docs/plugins.md). changes to the plugin sdk are part of the public api, mark breaking ones with `!`.

## license

by contributing you agree that your contributions are licensed under the [gpl-3.0](LICENSE).
