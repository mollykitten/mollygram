# Permissions

A plugin gets nothing it did not declare. The user sees the full list on a consent sheet when installing and allows it as a whole.

```yaml
permissions:
  messages.read: all
  storage: 1mb
  net: [api.example.com]
```

| Permission | Values | What it allows |
|---|---|---|
| `messages.read` | `on_command` | Read the current chat while a user-run command executes. |
| | `chats[]` | Read chats from a list the user picks in the plugin's settings. |
| | `all` | Read every chat. The consent sheet shows a separate warning. |
| `composer.write` | `true` | Insert text into the composer and intercept sending. |
| `net` | List of host names, or `user_endpoint` | HTTPS requests to the exact hosts listed. `user_endpoint` allows an address the user types in themselves. No wildcards, no IP addresses. |
| `storage` | `512kb`, `1mb`, up to `50mb` | Private key-value storage. The size is a quota. |
| `notifications.manage` | `true` | Intercept notifications. |
| `media.read` | List of `voice`, `round`, `photo`, `video`, `document` | Process media of these types through the host API. |

Size values take the form `<number> kb` or `<number> mb`. The limit is 50 MB.

A plugin never gets the Telegram session or keys, raw MTProto, the file system, other plugins, other accounts or cookies.

## Network rules

`mg.net.fetch` accepts `https` URLs without credentials in them, and only for a host listed in `net` or granted through `user_endpoint`. A host needs a dot and a letters-only top-level domain.

## Updates

If a new version asks for more access, it stays disabled until the user allows the new permissions. The old version keeps running meanwhile. Updates that add permissions never install on their own.

## Which events need what

See the table in [Events](events.md).
