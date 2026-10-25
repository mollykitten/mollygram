# plugin_host

sandbox for mollygram JS plugins on quickjs-ng: manifest, permissions, events, declarative UI, memory and time limits, execution in a separate isolate. spec: [docs/plugins.md](../../docs/plugins.md).

```sh
git submodule update --init
flutter pub get   # from the repository root: the package is part of the pub workspace
cd packages/plugin_host && dart test
```

the native library (quickjs-ng and `src/mg_qjs.c`) is built by a build hook on the first `dart test` or app build. you need a C compiler (Xcode, MSVC, or clang/gcc).

to rebuild the example after editing `example/transcribe/src/index.ts`:

```sh
cd example/transcribe && npx -p typescript@5.9 tsc -p .
```

built-in plugins live in `builtin/` and are rebuilt the same way:

```sh
cd builtin/filters && npx -p typescript@5.9 tsc -p .
cd builtin/translate && npx -p typescript@5.9 tsc -p .
```
