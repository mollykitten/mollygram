# Install

There is no release build yet. Build Mollygram from source on macOS 12 or later. Release builds will be published on [GitHub Releases](https://github.com/mollykitten/mollygram/releases).

## Before you start

- Install [Xcode](https://developer.apple.com/xcode/) and [FVM](https://fvm.app). The repository pins Flutter 3.47.7 in `.fvmrc`.
- Get an `api_id` and `api_hash` at [my.telegram.org](https://my.telegram.org). Mollygram does not ship one. See the [FAQ](../project/faq.md).

## Build and run

1. Clone the repository with its submodules. QuickJS, the plugin engine, lives in a submodule.

    ```bash
    git clone --recurse-submodules https://github.com/mollykitten/mollygram.git
    cd mollygram
    ```

    If you cloned without `--recurse-submodules`, run `git submodule update --init --recursive`.

2. Install Flutter and the dependencies.

    ```bash
    fvm install
    fvm flutter pub get
    ```

3. Copy the example config and fill in your credentials.

    ```bash
    cp config/telegram.example.json config/telegram.json
    ```

    ```json
    {
      "TELEGRAM_API_ID": "your api_id",
      "TELEGRAM_API_HASH": "your api_hash"
    }
    ```

    `config/telegram.json` is git-ignored. Keep it out of commits.

4. Run the app.

    ```bash
    cd packages/app
    fvm flutter run -d macos --dart-define-from-file=../../config/telegram.json
    ```

The Xcode build downloads the prebuilt TDLib library (`libtdjson`) for the version pinned in `packages/tdlib/tdlib.json` and checks its sha256. You do not build TDLib yourself. To use your own library, set `TDJSON_PATH`.

Next: [Sign in](sign-in.md).
