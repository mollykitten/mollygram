# Mollygram agent instructions

Read `README.md` and `CONTRIBUTING.md` for the package layout and conventions.
Superset ACP roles, hooks, and runtime ownership are in `.superset/README.md`.
For Dart work, also read `.claude/rules/flutter.md`.

## Workflow

- Implementation requests go directly to execution; design and brainstorming
  require an explicit request. Reproduce bugs and show evidence before editing.
- Discover code with Grep, Glob, and Read, not Bash. Pass this rule to delegates.
  If those tools are unavailable, use a direct filesystem read/search tool.
- Use the pinned Flutter SDK in `.fvmrc` through FVM. This is a pub workspace:
  resolve dependencies at the root and run tests in the affected package.
  Format edited Dart sources explicitly in Codex; Claude's format hook does
  not run in Codex ACP.
- Prefer Dart/Flutter MCP for analysis, tests, launch, logs, and hot reload.
  The native app lives in `packages/app`; it uses TDLib and has no web target.
- Preserve others' edits. Give delegates bounded file ownership and require
  concrete verification; inspect their evidence before reporting completion.
- UI changes need screenshots in light and dark themes. Keep EN/RU strings in
  sync; capitalize only the first word of Russian phrases.
- Authentication, TDLib/FFI, encrypted storage, plugin sandbox permissions,
  native code, and release workflows require high reasoning and review.
- Keep Telegram keys, TDLib sessions, local app data, and runtime URIs out of
  git and tool output. Do not reformat vendored or generated sources.
- Use existing local git identity; do not change global git settings or add AI
  coauthor trailers. Do not commit, push, merge, or publish unless requested.
- Follow `CONTRIBUTING.md` for Conventional Commits and release-please. Do not
  copy Waveform's manual tag/version/changelog release process.

## Model routing

| Task | Model | Reasoning / effort |
| --- | --- | --- |
| Implementation | `gpt-6.1-sol` | `medium` |
| Risky changes and review | `gpt-6.1-sol` | `high` |
| Mechanical changes and verification | `gpt-6-luna` | `medium` |
| Advice / design / planning only | Fable through Claude ACP | `high` |
| Planning fallback when Fable ACP is unavailable | `gpt-6-astra` | `high` |

Prefer Superset ACP chat sessions over terminal agents. Set model and effort
explicitly; never inherit the coordinator's expensive model for execution.
Use per-session Full access (`agent-full-access` for Codex, `bypassPermissions`
for Claude); planning remains read-only by task contract. Never change global
security settings. Check actual harness, model, mode, and effort after startup;
a launch flag alone is not proof. Never silently fall back to another model.
