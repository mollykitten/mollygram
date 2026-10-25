# Superset workspaces

Workspace creation initializes the QuickJS submodule, installs the pinned Flutter
SDK with FVM, resolves the root pub workspace, and builds the website. Install
FVM, Node.js 22 or newer, and Python 3 on the host first. The website has no npm
dependencies.

Setup copies ignored `.env`, `.env.*`, and `*.env` files from the root checkout
(`SUPERSET_ROOT_PATH`) in the repository root, `website`, and `packages/app`, plus
`config/telegram.json` when present. Existing workspace configuration is preserved;
missing secrets are not fabricated. Setup can be rerun safely.

The **Run** button builds and serves the static website on loopback. The operating
system assigns a free port at bind time; the Run pane prints its URL, and Superset
discovers the listening port. Stop or restart it using Superset's Run controls.
Refresh the browser after restarting Run to see website edits. This preview uses
Python's standard HTTP server rather than downloading `http-server` through npx.

Setup starts no background services or containers, so teardown has no resources
to clean up. Dependencies and build output live in the disposable worktree.

The native Flutter desktop application is separate from the website preview.
Launch it with the Flutter tooling described in the root README, using
`config/telegram.json`. The app relies on native TDLib and has no web target.

## ACP agent roles

The role launcher opens Superset chat panes rather than terminal agents. It
requires Python 3, the current Superset CLI, and `SUPERSET_WORKSPACE_ID` for the
current local workspace. No workspace ID is committed. From this checkout:

```sh
sh .superset/agent.sh implement
# In the opened ACP pane, check model/mode and select the required effort.
sh .superset/agent.sh send implement <session-id> 'implement the assigned task'
```

| Role | Agent / model | Reasoning / effort | Contract |
| --- | --- | --- | --- |
| `implement` | Codex / `gpt-6.1-sol` | `medium` | implementation |
| `risky` | Codex / `gpt-6.1-sol` | `high` | risky implementation, with review |
| `review` | Codex / `gpt-6.1-sol` | `high` | review, no edits |
| `check` | Codex / `gpt-6-luna` | `medium` | verification, no edits |
| `mechanical` | Codex / `gpt-6-luna` | `medium` | bounded small edits |
| `plan` | Claude ACP / Fable | `high` | advice and planning, no edits |
| `plan-astra` | Codex / `gpt-6-astra` | `high` | explicit planning fallback |

Codex uses per-session `agent-full-access`; Claude uses `bypassPermissions`.
These do not change global security settings. The planning role's no-edit
restriction is a task contract, not a permission mode.

The CLI's `sessions create` supports model and mode but has no effort flag.
The first command therefore creates an **idle** chat without a task and opens
its picker. The `send` command reads actual ACP session configuration and
refuses to dispatch unless harness, model, mode, and effort all match. Setting
effort in a prompt does not configure reasoning. Verify each fresh chat; model
startup can briefly show defaults. If no configuration event is available yet,
wait for startup and retry the same send command.

For Fable, `--model claude-fable-5-1` has been observed to leave the actual
model at `opus`. Select the actual `claude-fable-5-1[1m]` picker option before
dispatching `plan`; the launcher requires that actual ID. If Fable ACP is
unavailable, explicitly launch `plan-astra`; there is no silent fallback.

Read progress and results with `superset sessions list/read --local --workspace
<workspace-id>`; use `send` for follow-ups and `open` for the chat pane. Worker
prompts request `SUPERSET_WORKER_DONE` / `SUPERSET_WORKER_BLOCKED` text markers
with files and checks. These markers are not push notifications: the
coordinator must read completed results, inspect the diff and verification,
and close only its own idle worker sessions with `sessions close`. Closing
stops the agent while retaining chat history. Never close another worker's
session or the coordinator's session.

## Hooks and formatting

The Waveform-style Claude `PostToolUse` hook in `.claude/settings.json` formats
owned Dart files after `Write` / `Edit`. Its command is quoted for checkout
paths with spaces. It uses the worktree's pinned `.fvm/flutter_sdk/bin/dart`,
skips generated/vendored files and paths outside this worktree (including
escaping symlinks), and reports a missing SDK without downloading anything.
Restart Claude ACP after changing hook settings so the harness reloads them.

Codex ACP does not load Claude hooks: format edited Dart sources through Dart
MCP or `fvm dart format` and run appropriate package checks explicitly. Neither
hook starts, restarts, or kills an application. Hook/launcher checks:

```sh
python3 -m unittest discover -s .superset/tests -v
```

## Native runtime ownership

Worktrees share the native app's bundle ID and can share OS app data, Telegram
sessions, and deep links. Before launch, DTD attachment, hot reload, or stop,
establish one owning workspace. Keep an ownership record outside git, such as
`~/.local/state/mollygram/runtime-owner.json`, containing the workspace path,
MCP running-app ID, and DTD URI. Do not copy application sessions into worktrees
or record private runtime URIs in tracked files.

Use Dart/Flutter MCP to manage only the app whose ownership record matches this
worktree. Missing/stale ownership requires checking the runtime first. Before
handoff, stop your app by its MCP app ID, confirm exit, and clear your record.
Do not use `pkill` or launch another instance with the same bundle ID. Creating
or using agent roles does not automatically launch the Flutter application.
