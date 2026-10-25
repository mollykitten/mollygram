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

## tests

`flutter test` runs widget tests and golden images (`test/goldens/`). goldens
are rendered on linux, like CI, and are skipped on other hosts. after an
intended visual change, update them on linux:

```sh
flutter test --update-goldens
```
