# Sandbox limits

Each plugin runs in its own JavaScript VM (quickjs-ng) inside a separate Dart isolate. The VM has no files, no network, no timers, no `require`, `std` or `os`. The only way out is the [`mg` API](mg-api.md), checked against your [permissions](permissions.md).

| Limit | Value |
|---|---|
| Memory | 32 MB per plugin. Going over disables the plugin at once. |
| Stack | 512 KB. Deep recursion throws instead of crashing. |
| CPU time on load | 500 ms |
| CPU time per handler call | 100 ms |
| Waiting for an async event handler | 5 s |
| Waiting for a command or a button press | 60 s |
| Script size | 2 MB |
| Storage | The size in the manifest, 50 MB at most |
| Log | 200 lines, 1000 characters each |
| UI tree | 200 nodes, depth 8 |

CPU time is thread CPU time, so a busy machine does not penalize a well-behaved plugin. A call into the host does not extend the budget.

The host sets no limit on how often a plugin calls `mg`.

## Failures

An exception, a timeout or an invalid UI tree counts as a strike. The event then behaves as if your plugin were not installed. A successful call resets the counter. After three strikes in a row the plugin is disabled until the user turns it on again. The plugin's page shows the reason and the log.

The app also gives up on a plugin that does not start within 10 s or does not answer within 6 s. A plugin that fails to start is retried after 10 and 20 seconds, then turned off after three failures in a row.

## Not covered

The VM lives in the app's process. A memory-corruption bug in quickjs-ng itself would crash the app.
