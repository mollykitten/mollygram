# Declarative UI

A plugin returns a tree of nodes. The app draws it with its own widgets, in its own style. A plugin cannot fake a system dialog or break the layout.

| Node | Fields |
|---|---|
| `text` | `text`, `style`: `body`, `secondary` or `mono` |
| `button` | `label`, `action`, `payload` |
| `toggle` | `label`, `action`, `value` |
| `progress` | `label` |
| `row`, `column` | `children`: a list of nodes |
| `code` | `language`, `spans`: a list of `{ text, token }` |

`code` tokens: `plain`, `keyword`, `string`, `number`, `comment`, `function`, `type`, `punctuation`. The app colors them with the theme.

```ts
const nodes: Mg.UiNode[] = [
  { type: "column", children: [
    { type: "text", text: "3 links found", style: "secondary" },
    { type: "row", children: [
      { type: "button", label: "Copy", action: "copy" },
      { type: "button", label: "Open", action: "open", payload: { index: 0 } },
    ] },
  ] },
];
```

A click on a `button` comes back as the `ui.action` event with your `action` and `payload`.

## Limits

- 200 nodes in a tree, nesting depth 8.
- Strings up to 4000 characters. The `text` of a `text` node up to 16384.
- A `code` node has up to 8000 spans.
- No colors, sizes, images or HTML.
- An unknown node type or `style` makes the tree invalid. An invalid tree is dropped and counts as a failure (see [Sandbox limits](sandbox-limits.md)).
