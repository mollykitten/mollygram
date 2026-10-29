# mollygram_ui_kit

the mollygram design system in Flutter, ported from `design/*.dc.html` and the
glass prototype from #4.

- **tokens**: `MgColors.light` / `MgColors.dark` (a `ThemeExtension`),
  `buildMgTheme`, the `MgType` scale and `mgTextStyle` (system font, 13 px).
- **glass**: `Glass` and `GlassScope`. glass is for the floating layer only:
  the sidebar island, the two chat header capsules, the composer and the
  command palette. messages and rows stay solid. wrap the window in one
  `GlassScope` so all panels share a single backdrop read, `blur: false` is
  the reduced transparency fallback.
- **wallpaper**: the four-point telegram gradient.
- **sign-in**: `SignInPage`, `SignInHeader`, `QrFrame`, `SignInSteps`, `PhoneNumberField`, `MgUnderlineField`, `MgPrimaryButton`, `MgTextButton`. plain window background, no wallpaper and no glass, like in the official telegram apps.
- **widgets**: `SidebarIsland`, `MgSearchField`, `FolderTabBar` / `FolderTab`,
  `ChatListTile`, `ChatHeaderBar` with `ChatTitleCapsule` and
  `ChatActionsCapsule`, `Composer`, `MessageBubble`, `TextMessageBubble`,
  `MessageMeta`, `DatePill`, `MediaPill`, `MonogramAvatar`, `UnreadBadge`,
  `MgIconButton`, `MgSendButton`, and the `MgIcons` set.

the kit has no strings of its own. every label, tooltip and placeholder comes
from the app, which owns localization.

## ui contract

every clickable thing in the app goes through the kit's primitives, so press
feedback, the keyboard, screen readers and large text behave the same
everywhere. `test/ui_contract_guard_test.dart` fails on a new hand-made tap
area, and `test/contract_matrix_test.dart` runs the primitives at text scale
1.0, 1.5 and 2.0.

**which primitive**

| need | use |
| --- | --- |
| any custom row, chip, tile or card that reacts to a click | `MgPressable` |
| the main action of a form or screen | `MgPrimaryButton` (`loading` while it works) |
| a quiet secondary action next to it | `MgTextButton` |
| a round icon action, or an on/off icon (`toggle: true`) | `MgIconButton` |
| an on/off setting | `MgSwitch` (give `semanticLabel` unless a row labels it) |
| a search box | `MgSearchField` |
| a loading, empty or error state of a list or page | `MgStatusView.loading` / `.empty` / `.error` |
| a small wait inside a row or a button | `MgSpinner` (use `delay` so fast loads never flash it) |

never write `GestureDetector(onTap: ...)`, `InkWell` or a `MouseRegion` with the
click cursor for a control. `GestureDetector` stays fine for gestures that are
not controls (drag, pan, double-tap to zoom, window drag areas).

**sizes and tokens**

- tie heights that hold text to `MgMetrics.scaled(context, 30)`: it grows with
  the text scale and never goes below the design size. no fixed `height:` on
  something that contains a label; use `constraints: BoxConstraints(minHeight:)`.
- radii from `MgRadius`, gaps and paddings from `MgSpace`, font sizes from
  `MgType` via `mgTextStyle`. no magic numbers for these.

**semantics**

`MgPressable` announces a tap action and enabled state. set what the control
is: `role` (`button`, `radio`, `tab`, `checkbox`, `toggle`), `selected` for the
current tab or choice, `checked` for radio and checkbox, `toggled` for
switches, and `semanticsLabel` when the child has no text of its own. no
`onTap` means disabled: no focus and no action. `busy` ignores clicks and
Space/Enter while work runs, so an action cannot fire twice.

**reduced motion**

read `MediaQuery.disableAnimationsOf(context)`. keep colour feedback, drop
scale, slides and repeating animation (`MgSpinner` already does).

**a new button row**

```dart
MgPressable(
  onTap: onOpen, // null disables it
  role: MgPressableRole.button,
  builder: (context, state) => Container(
    constraints: BoxConstraints(minHeight: MgMetrics.scaled(context, 36)),
    padding: const EdgeInsets.symmetric(horizontal: MgSpace.m),
    decoration: BoxDecoration(
      color: state.hovered ? c.hover : null,
      borderRadius: BorderRadius.circular(MgRadius.small),
    ),
    child: Text(label, style: mgTextStyle(c, size: MgType.body)),
  ),
)
```

**review checklist**

- no new entry in the guard's allowlist; migrating a file lowers its number
- a control is reachable with Tab and fires once on Space and Enter
- it has a role, and `selected` / `toggled` / `checked` where it has state
- nothing clips or overflows at text scale 2.0; heights use `MgMetrics.scaled`
- loading, empty and error use `MgStatusView`, not a bare spinner or text
- reduced motion drops movement; tokens instead of raw radii, gaps, sizes
- EN and RU strings added together; light and dark checked

## tests

`flutter test` runs widget tests and golden images (`test/goldens/`). goldens
are rendered on linux, like CI, and are skipped on other hosts. after an
intended visual change, update them on linux:

```sh
flutter test --update-goldens
```
