---
paths:
  - "packages/**/*.dart"
  - "packages/**/pubspec.yaml"
  - "pubspec.yaml"
  - ".fvmrc"
---

# Flutter and Dart

- Use Dart/Flutter MCP for analysis, tests, formatting, application launch,
  hot reload/restart, and runtime logs when available. Do not start a parallel
  shell `flutter run`. Read the runtime ownership rules before attaching.
- Use the Flutter version pinned in `.fvmrc`; the format hook uses this
  worktree's `.fvm/flutter_sdk/bin/dart`, never an arbitrary global Dart.
- `packages/core` is pure Dart. Respect package boundaries described in the
  root README; do not add Flutter dependencies to the core package.
- Run `fvm dart format` on edited owned sources. Analyze the affected packages
  and run their tests from each package directory (`fvm flutter test` for
  Flutter packages, `fvm dart test` for pure Dart). Follow `CONTRIBUTING.md`
  for TDLib regeneration and native changes.
- Skip `third_party`, generated TDLib bindings, and `*.g.dart` / `*.freezed.dart`
  during automatic formatting. Regenerate owned outputs with their generator.
- Hot reload only your owned runtime after UI edits; use hot restart when
  initialization or global state changes. Do not restart for comments alone.
- Keep network and heavy computation out of widget builds. Match the existing
  state management and navigation in the affected package.
- Keep English and Russian UI strings synchronized. UI validation includes
  both light and dark themes. API credentials come from ignored local config,
  never hardcoded values.
